defmodule Jacalendar.FoodParser do
  @moduledoc """
  Parses food recommendation markdown into structured data.
  """

  @category_headers ~r/^### (甜點|烤魚定食|鰻魚|拉麵)\s*$/
  @restaurant_header ~r/^#### \d+\.\s+(.+)$/
  @daily_section ~r/^## 按天安插建議/
  @day_header ~r/^### Day (\d+):\s*(.+)/
  @base_year 2026
  @base_month 4
  @base_start_day 16

  def parse(nil), do: {:error, "input is nil"}
  def parse(""), do: {:error, "input is empty"}

  def parse(markdown) when is_binary(markdown) do
    lines = String.split(markdown, "\n")

    restaurants = parse_restaurants(lines)
    daily_picks = parse_daily_picks(lines)

    {:ok, %{restaurants: restaurants, daily_picks: daily_picks}}
  end

  def parse(_), do: {:error, "input must be a string"}

  # --- Restaurant parsing ---

  defp parse_restaurants(lines) do
    lines
    |> extract_category_sections()
    |> Enum.flat_map(fn {category, section_lines} ->
      parse_category_restaurants(category, section_lines)
    end)
    |> Enum.reject(fn r -> r.address == nil or r.address == "" end)
    |> Enum.with_index()
    |> Enum.map(fn {r, idx} -> Map.put(r, :position, idx) end)
  end

  defp extract_category_sections(lines) do
    lines
    |> Enum.with_index()
    |> Enum.reduce([], fn {line, idx}, acc ->
      case Regex.run(@category_headers, String.trim(line)) do
        [_, category] -> [{category, idx} | acc]
        _ -> acc
      end
    end)
    |> Enum.reverse()
    |> Enum.map(fn {category, start_idx} ->
      section_lines =
        lines
        |> Enum.drop(start_idx + 1)
        |> Enum.take_while(fn l ->
          trimmed = String.trim(l)
          not (String.starts_with?(trimmed, "### ") or String.starts_with?(trimmed, "## ") or trimmed == "---")
        end)

      {category, section_lines}
    end)
  end

  defp parse_category_restaurants(category, lines) do
    lines
    |> chunk_by_restaurant()
    |> Enum.map(fn {name, detail_lines} ->
      parse_restaurant_details(name, category, detail_lines)
    end)
  end

  defp chunk_by_restaurant(lines) do
    lines
    |> Enum.reduce([], fn line, acc ->
      case Regex.run(@restaurant_header, String.trim(line)) do
        [_, name] ->
          [{name, []} | acc]

        _ ->
          case acc do
            [{name, detail_lines} | rest] ->
              [{name, detail_lines ++ [line]} | rest]

            [] ->
              acc
          end
      end
    end)
    |> Enum.reverse()
  end

  defp parse_restaurant_details(name, category, lines) do
    flat = Enum.map(lines, &String.trim/1)

    %{
      name: name,
      category: category,
      area: extract_field(flat, "區域"),
      price_range: extract_field(flat, "大概金額"),
      address: extract_field(flat, "地址"),
      hours: extract_field(flat, "營業時間"),
      reason: extract_reason(flat)
    }
  end

  defp extract_field(lines, field_name) do
    Enum.find_value(lines, fn line ->
      case Regex.run(~r/^\*\s+\*\*#{Regex.escape(field_name)}\*\*:\s*(.+)/, line) do
        [_, value] -> clean_markdown(value)
        _ -> nil
      end
    end)
  end

  defp extract_reason(lines) do
    # Find the 定位 line which is a one-line summary reason
    Enum.find_value(lines, fn line ->
      case Regex.run(~r/^\*\s+\*\*定位\*\*:\s*(.+)/, line) do
        [_, value] -> clean_markdown(value)
        _ -> nil
      end
    end)
  end

  defp clean_markdown(text) do
    text
    |> String.replace(~r/\*\*(.+?)\*\*/, "\\1")
    |> String.replace(~r/`(.+?)`/, "\\1")
    |> String.trim()
  end

  # --- Daily picks parsing ---

  defp parse_daily_picks(lines) do
    daily_start =
      Enum.find_index(lines, fn l -> Regex.match?(@daily_section, String.trim(l)) end)

    if daily_start do
      lines
      |> Enum.drop(daily_start + 1)
      |> Enum.take_while(fn l ->
        trimmed = String.trim(l)
        not (String.starts_with?(trimmed, "## ") and not String.starts_with?(trimmed, "### "))
      end)
      |> chunk_by_day()
      |> Enum.flat_map(&parse_day_picks/1)
      |> Enum.with_index()
      |> Enum.map(fn {pick, idx} -> Map.put(pick, :position, idx) end)
    else
      []
    end
  end

  defp chunk_by_day(lines) do
    lines
    |> Enum.reduce([], fn line, acc ->
      case Regex.run(@day_header, String.trim(line)) do
        [_, day_num, title] ->
          [{day_num, title, []} | acc]

        _ ->
          case acc do
            [{day_num, title, detail_lines} | rest] ->
              [{day_num, title, detail_lines ++ [line]} | rest]

            [] ->
              acc
          end
      end
    end)
    |> Enum.reverse()
  end

  defp parse_day_picks({day_num, title, lines}) do
    day_int = String.to_integer(day_num)
    day_date = Date.new!(@base_year, @base_month, @base_start_day + day_int - 1)
    day_label = "Day #{day_num}: #{title}"

    lines
    |> Enum.map(&String.trim/1)
    |> Enum.filter(fn l -> String.starts_with?(l, "* **") end)
    |> Enum.reject(fn l -> Regex.match?(~r/^\*\s+\*\*原因\*\*/, l) end)
    |> Enum.map(fn line ->
      {priority, restaurant_name, note} = parse_pick_line(line)

      %{
        day_label: day_label,
        day_date: day_date,
        restaurant_name: restaurant_name,
        priority: priority,
        note: note
      }
    end)
    |> Enum.reject(fn p -> p.restaurant_name == "" end)
  end

  defp parse_pick_line(line) do
    # Pattern: * **甜點主選**: `HIGASHIYA GINZA`
    # Pattern: * **主餐優先**: `しんぱち食堂 新宿` 或 `麺屋翔 本店`
    case Regex.run(~r/^\*\s+\*\*(.+?)\*\*:\s*(.+)/, line) do
      [_, label, rest] ->
        priority = if String.contains?(label, "備選"), do: "備選", else: "主選"

        # Extract restaurant names from backticks
        names =
          Regex.scan(~r/`([^`]+)`/, rest)
          |> Enum.map(fn [_, name] -> name end)

        restaurant_name = Enum.join(names, " / ")
        note = clean_markdown(rest)

        {priority, restaurant_name, note}

      _ ->
        {"主選", clean_markdown(line), nil}
    end
  end
end
