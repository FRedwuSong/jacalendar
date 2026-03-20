defmodule Jacalendar.TransportParser do
  @moduledoc """
  Parses transportation markdown into structured data.
  """

  @section_patterns [
    {"tools", ~r/^## 📱/},
    {"hotel_transport", ~r/^## 🏨/},
    {"airport", ~r/^## ✈️/},
    {"daily_task", ~r/^## ☕/},
    {"tips", ~r/^## 💡/}
  ]

  @address_cards_header ~r/^## 📍/
  @day_header ~r/^## Day (\d+)\s+交通/

  def parse(nil), do: {:error, "input is nil"}
  def parse(""), do: {:error, "input is empty"}

  def parse(markdown) when is_binary(markdown) do
    lines = String.split(markdown, "\n")

    sections = parse_sections(lines)
    routes = parse_routes(lines)
    address_cards = parse_address_cards(lines)

    {:ok, %{sections: sections, routes: routes, address_cards: address_cards}}
  end

  def parse(_), do: {:error, "input must be a string"}

  # --- Sections ---

  defp parse_sections(lines) do
    @section_patterns
    |> Enum.with_index()
    |> Enum.map(fn {{type, pattern}, pos} ->
      content = extract_section_content(lines, pattern)

      if content != "" do
        title = extract_section_title(lines, pattern)
        %{section_type: type, title: title, content: content, position: pos}
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp extract_section_title(lines, pattern) do
    case Enum.find(lines, &Regex.match?(pattern, &1)) do
      nil -> ""
      line -> line |> String.replace(~r/^## [^\s]+\s*/, "") |> String.trim()
    end
  end

  defp extract_section_content(lines, pattern) do
    lines
    |> Enum.drop_while(&(not Regex.match?(pattern, &1)))
    |> Enum.drop(1)
    |> Enum.take_while(fn line ->
      not (String.starts_with?(line, "## ") or line == "---")
    end)
    |> Enum.join("\n")
    |> String.trim()
  end

  # --- Routes ---

  defp parse_routes(lines) do
    # Find all "## Day N 交通" sections
    lines
    |> Enum.with_index()
    |> Enum.reduce({[], nil, nil, []}, fn {line, _idx}, {results, current_day, _day_num, current_lines} ->
      case Regex.run(@day_header, line) do
        [_, day_num] ->
          results =
            if current_day do
              [build_route(current_day, Enum.reverse(current_lines)) | results]
            else
              results
            end

          day_info = %{
            day_label: "Day #{day_num}",
            day_date: nil,
            title: "Day #{day_num} 交通"
          }

          {results, day_info, day_num, []}

        _ ->
          if current_day do
            # Stop collecting if we hit another ## that's not a ### subsection
            if String.starts_with?(line, "## ") and not String.starts_with?(line, "### ") do
              results = [build_route(current_day, Enum.reverse(current_lines)) | results]
              {results, nil, nil, []}
            else
              {results, current_day, nil, [line | current_lines]}
            end
          else
            {results, nil, nil, []}
          end
      end
    end)
    |> then(fn {results, current_day, _, current_lines} ->
      if current_day do
        [build_route(current_day, Enum.reverse(current_lines)) | results]
      else
        results
      end
    end)
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.map(fn {route, idx} -> Map.put(route, :position, idx) end)
  end

  defp build_route(day_info, lines) do
    segments = parse_segments(lines)

    %{
      day_label: day_info.day_label,
      day_date: day_info.day_date,
      title: day_info.title,
      segments: segments
    }
  end

  defp parse_segments(lines) do
    # Split by ### headers (e.g., "### coffee swamp -> Leaves Coffee Roasters")
    lines
    |> Enum.reduce({[], []}, fn line, {segments, current} ->
      if String.starts_with?(line, "### ") do
        segments =
          if current != [] do
            [build_segment(Enum.reverse(current)) | segments]
          else
            segments
          end

        {segments, [line]}
      else
        if current != [] do
          {segments, [line | current]}
        else
          {segments, current}
        end
      end
    end)
    |> then(fn {segments, current} ->
      if current != [] do
        [build_segment(Enum.reverse(current)) | segments]
      else
        segments
      end
    end)
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.map(fn {seg, idx} -> Map.put(seg, "order", idx) end)
  end

  defp build_segment([header | detail_lines]) do
    # Extract from -> to from header like "### coffee swamp -> Leaves Coffee Roasters"
    route_text = String.replace(header, ~r/^###\s+/, "") |> String.trim()

    {from, to} =
      case String.split(route_text, ~r/\s*->\s*/, parts: 2) do
        [f, t] -> {clean_backticks(String.trim(f)), clean_backticks(String.trim(t))}
        _ -> {clean_backticks(route_text), ""}
      end

    details = detail_lines |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == "")) |> Enum.join("\n")

    # Try to extract method from details and route text
    all_text = from <> " " <> to <> " " <> details
    method =
      cond do
        String.contains?(all_text, "步行") -> "walk"
        String.contains?(all_text, "計程車") -> "taxi"
        String.contains?(all_text, "地鐵") or String.contains?(all_text, "線") or
          String.contains?(all_text, "JR") or String.contains?(all_text, "利木津") -> "metro"
        true -> "other"
      end

    %{
      "from" => from,
      "to" => to,
      "method" => method,
      "details" => details,
      "cost" => nil
    }
  end

  defp build_segment([]), do: %{"from" => "", "to" => "", "method" => "other", "details" => "", "cost" => nil}

  defp clean_backticks(text), do: String.replace(text, "`", "")

  # --- Address Cards ---

  defp parse_address_cards(lines) do
    lines
    |> Enum.drop_while(&(not Regex.match?(@address_cards_header, &1)))
    |> Enum.drop(1)
    |> Enum.take_while(fn line ->
      not (String.starts_with?(line, "## ") and not String.starts_with?(line, "### "))
    end)
    |> Enum.reject(fn line ->
      trimmed = String.trim(line)
      String.starts_with?(trimmed, ">") or trimmed == ""
    end)
    |> Enum.map(fn line ->
      # Parse "* **name**: address" format
      case Regex.run(~r/^\*\s+\*\*(.+?)\*\*:\s*(.+)/, String.trim(line)) do
        [_, name, address] ->
          %{name: String.trim(name), name_ja: nil, address: String.trim(address), note: nil}
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(fn card -> card.address == "" end)
    |> Enum.with_index()
    |> Enum.map(fn {card, idx} -> Map.put(card, :position, idx) end)
  end
end
