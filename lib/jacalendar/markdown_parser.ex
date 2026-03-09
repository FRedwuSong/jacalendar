defmodule Jacalendar.MarkdownParser do
  alias Jacalendar.Itinerary
  alias Jacalendar.Itinerary.{Day, Item}

  @fuzzy_time_map %{
    "早上" => :morning,
    "上午" => :morning,
    "午餐" => :afternoon,
    "上午/午餐" => :morning,
    "下午" => :afternoon,
    "下午/傍晚" => :afternoon,
    "傍晚" => :evening,
    "晚上" => :evening,
    "晚餐" => :evening
  }

  @day_header_regex ~r/^### Day \d+:\s*(\d{4})\/(\d{2})\/(\d{2})\s*\((.+?)\)\s*(?:-\s*(.+))?$/
  @exact_time_regex ~r/^\*\s+\*\*(\d{1,2}:\d{2})(?:-\d{1,2}:\d{2})?\s*(?:\([^)]*\))?\*\*:\s*(.+)/
  @bold_label_regex ~r/^\*\s+(?:🏔️\s+)?\*\*(.+?)\*\*:\s*(.*)/
  @sub_item_regex ~r/^\s+\*\s+(.+)/

  def parse(nil), do: {:error, "input is nil"}
  def parse(""), do: {:error, "input is empty"}

  def parse(markdown) when is_binary(markdown) do
    lines = String.split(markdown, "\n")

    {title, date_range} = parse_title(lines)
    metadata = parse_metadata(lines)
    days = parse_days(lines)
    checklist = parse_checklist(lines)

    case {title, days} do
      {nil, []} ->
        {:error, "no itinerary content found"}

      _ ->
        {:ok,
         %Itinerary{
           title: title,
           date_range: date_range,
           metadata: metadata,
           days: days,
           checklist: checklist
         }}
    end
  end

  def parse(_), do: {:error, "input must be a string"}

  defp parse_title(lines) do
    case Enum.find(lines, &String.starts_with?(&1, "# ")) do
      nil ->
        {nil, nil}

      line ->
        title =
          line
          |> String.trim_leading("# ")
          |> String.replace(~r/\s*\(.+$/, "")
          |> String.replace(~r/\s*-\s*最終確認版$/, "")
          |> String.trim()

        date_range = extract_date_range(line)
        {title, date_range}
    end
  end

  defp extract_date_range(line) do
    case Regex.run(~r/(\d{4})\/(\d{2})\/(\d{2})\s*-\s*(\d{2})\/(\d{2})/, line) do
      [_, y, m1, d1, m2, d2] ->
        year = String.to_integer(y)

        with {:ok, start_date} <- Date.new(year, String.to_integer(m1), String.to_integer(d1)),
             {:ok, end_date} <- Date.new(year, String.to_integer(m2), String.to_integer(d2)) do
          {start_date, end_date}
        else
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp parse_metadata(lines) do
    flights = parse_flights(lines)
    hotel = parse_hotel(lines)
    %{flights: flights, hotel: hotel}
  end

  defp parse_flights(lines) do
    flight_section = extract_section(lines, "航班資訊")

    flight_section
    |> Enum.chunk_by(&String.match?(&1, ~r/^\*\s+\*\*/))
    |> Enum.chunk_every(2)
    |> Enum.flat_map(fn
      [header_lines, detail_lines] ->
        header = Enum.find(header_lines, &String.match?(&1, ~r/^\*\s+\*\*/))
        details = Enum.join(detail_lines, " ")

        if header do
          [parse_single_flight(header, details)]
        else
          []
        end

      [header_lines] ->
        header = Enum.find(header_lines, &String.match?(&1, ~r/^\*\s+\*\*/))
        if header, do: [parse_single_flight(header, "")], else: []
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_single_flight(header, details) do
    combined = header <> " " <> details

    direction =
      cond do
        String.contains?(header, "去程") -> :outbound
        String.contains?(header, "回程") -> :return
        true -> :unknown
      end

    flight_number =
      case Regex.run(~r/\*\*([A-Z]{2}\s*\d+)\*\*/, combined) do
        [_, num] -> String.replace(num, " ", "")
        _ -> nil
      end

    date =
      case Regex.run(~r/(\d{4})\/(\d{2})\/(\d{2})/, combined) do
        [_, y, m, d] ->
          case Date.new(String.to_integer(y), String.to_integer(m), String.to_integer(d)) do
            {:ok, date} -> date
            _ -> nil
          end

        _ ->
          nil
      end

    # Parse route details like "TPE 桃園 12:45 -> NRT 成田 17:15"
    {departure, arrival} = parse_flight_route(details)

    # Parse terminal info like "第二航廈"
    terminal =
      case Regex.run(~r/(第[一二三]航廈|Terminal\s*\d)/u, details) do
        [_, t] -> t
        _ -> nil
      end

    %{
      direction: direction,
      flight_number: flight_number,
      date: date,
      departure: departure,
      arrival: arrival,
      terminal: terminal
    }
  end

  defp parse_flight_route(details) do
    clean = String.replace(details, ~r/\*\*/, "")
    route_regex = ~r/([A-Z]{3})\s+(\S+)\s+(\d{1,2}:\d{2})\s*->\s*([A-Z]{3})\s+(\S+)\s+(\d{1,2}:\d{2})/

    case Regex.run(route_regex, clean) do
      [_, dep_code, dep_name, dep_time, arr_code, arr_name, arr_time] ->
        {
          %{code: dep_code, name: dep_name, time: dep_time},
          %{code: arr_code, name: arr_name, time: arr_time}
        }

      _ ->
        {nil, nil}
    end
  end

  defp parse_hotel(lines) do
    hotel_section = extract_section(lines, "住宿資訊")

    name =
      hotel_section
      |> Enum.find_value(fn line ->
        case Regex.run(~r/\*\*飯店\*\*:\s*(.+)/, line) do
          [_, n] -> String.trim(n)
          _ -> nil
        end
      end)

    address =
      hotel_section
      |> Enum.find_value(fn line ->
        case Regex.run(~r/\*\*地址\*\*:\s*(.+)/, line) do
          [_, a] -> String.trim(a)
          _ -> nil
        end
      end)

    phone =
      hotel_section
      |> Enum.find_value(fn line ->
        case Regex.run(~r/\*\*TEL\*\*:\s*(.+)/, line) do
          [_, p] -> String.trim(p)
          _ -> nil
        end
      end)

    %{name: name, address: address, phone: phone}
  end

  defp parse_checklist(lines) do
    section = extract_section(lines, "必訪景點清單")

    section
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&String.match?(&1, ~r/^\d+\./))
    |> Enum.with_index()
    |> Enum.map(fn {line, idx} ->
      # Pattern: "1.  **Name** (Location) - **Note**"
      {name, location, note} =
        case Regex.run(~r/\d+\.\s+\*\*(.+?)\*\*\s*\((.+?)\)\s*(?:-\s*\*\*(.+?)\*\*)?/u, line) do
          [_, n, l, no] -> {n, l, no}
          [_, n, l] -> {n, l, nil}
          _ -> {String.replace(line, ~r/^\d+\.\s+/, ""), nil, nil}
        end

      %{name: name, location: location, note: note, position: idx}
    end)
  end

  defp extract_section(lines, section_name) do
    lines
    |> Enum.drop_while(fn line ->
      not (String.starts_with?(line, "## ") and String.contains?(line, section_name))
    end)
    |> Enum.drop(1)
    |> Enum.take_while(fn line ->
      not (String.starts_with?(line, "## ") or String.starts_with?(line, "---"))
    end)
    |> Enum.reject(&(String.trim(&1) == ""))
  end

  defp parse_days(lines) do
    lines
    |> Enum.with_index()
    |> Enum.reduce([], fn {line, idx}, days ->
      case Regex.run(@day_header_regex, line) do
        [_, y, m, d, weekday | rest] ->
          title =
            case rest do
              [t] -> String.trim(t)
              _ -> ""
            end

          date = Date.new!(String.to_integer(y), String.to_integer(m), String.to_integer(d))

          day = %Day{
            date: date,
            weekday: weekday,
            title: title,
            items: []
          }

          [{day, idx} | days]

        _ ->
          days
      end
    end)
    |> Enum.reverse()
    |> Enum.map(fn {day, start_idx} ->
      day_lines =
        lines
        |> Enum.drop(start_idx + 1)
        |> Enum.take_while(fn line ->
          not (Regex.match?(~r/^### Day \d+:/, line) or
                 String.starts_with?(line, "---") or
                 String.starts_with?(line, "## "))
        end)

      items = parse_items(day_lines)
      %{day | items: items}
    end)
  end

  defp parse_items(lines) do
    lines
    |> Enum.reject(fn line ->
      trimmed = String.trim(line)
      trimmed == "" or String.starts_with?(trimmed, ">") or String.starts_with?(trimmed, "---")
    end)
    |> group_items()
    |> Enum.map(&build_item/1)
  end

  defp group_items(lines) do
    lines
    |> Enum.reduce([], fn line, acc ->
      if top_level_item?(line) do
        [[line] | acc]
      else
        case acc do
          [current | rest] -> [[line | current] | rest]
          [] -> [[line]]
        end
      end
    end)
    |> Enum.map(&Enum.reverse/1)
    |> Enum.reverse()
  end

  defp top_level_item?(line) do
    Regex.match?(~r/^\*\s+/, line)
  end

  defp build_item([main_line | sub_lines]) do
    {time, description} = parse_item_line(main_line)

    sub_items =
      sub_lines
      |> Enum.filter(&Regex.match?(@sub_item_regex, &1))
      |> Enum.map(fn line ->
        [_, content] = Regex.run(@sub_item_regex, line)
        clean_description(String.trim(content))
      end)

    %Item{
      time: time,
      description: description,
      sub_items: sub_items
    }
  end

  defp build_item([]), do: %Item{time: :pending, description: "", sub_items: []}

  defp parse_item_line(line) do
    cond do
      match = Regex.run(@exact_time_regex, line) ->
        [_, time_str, desc] = match
        [h, m] = String.split(time_str, ":")
        time = Time.new!(String.to_integer(h), String.to_integer(m), 0)
        {{:exact, time}, clean_description(desc)}

      match = Regex.run(@bold_label_regex, line) ->
        [_, label, rest] = match
        parse_bold_label(label, rest)

      true ->
        {:pending, clean_description(String.trim(line))}
    end
  end

  defp parse_bold_label(label, rest) do
    clean_label = label |> String.replace(~r/\s*\([^)]*\)/, "") |> String.trim()

    cond do
      Regex.match?(~r/^\d{1,2}:\d{2}/, clean_label) ->
        [h, m] =
          clean_label
          |> String.split(~r/[^0-9:]/, parts: 2)
          |> hd()
          |> String.split(":")

        time = Time.new!(String.to_integer(h), String.to_integer(m), 0)
        desc = if rest == "", do: label_to_desc(label), else: rest
        {{:exact, time}, clean_description(desc)}

      Map.has_key?(@fuzzy_time_map, clean_label) ->
        fuzzy = Map.fetch!(@fuzzy_time_map, clean_label)
        parenthetical = Regex.run(~r/\(([^)]+)\)/, label)

        desc =
          cond do
            rest != "" && parenthetical -> "#{elem(List.to_tuple(parenthetical), 1)}: #{rest}"
            rest != "" -> rest
            parenthetical -> elem(List.to_tuple(parenthetical), 1)
            true -> ""
          end

        {{:fuzzy, fuzzy}, clean_description(desc)}

      true ->
        full_desc =
          if rest == "" do
            clean_label
          else
            clean_label <> ": " <> rest
          end

        {:pending, clean_description(full_desc)}
    end
  end

  defp label_to_desc(label), do: String.trim(label)

  defp clean_description(desc) do
    desc
    |> String.replace(~r/\*\*([^*]+)\*\*/, "\\1")
    |> String.replace(~r/\*([^*]+)\*/, "\\1")
    |> String.trim()
    |> String.trim_trailing("。")
    |> String.trim()
  end
end
