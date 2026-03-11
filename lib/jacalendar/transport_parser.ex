defmodule Jacalendar.TransportParser do
  @moduledoc """
  Parses transportation markdown into structured data.
  """

  @section_patterns [
    {"tools", ~r/^## 📱\s*必備交通工具與 App/},
    {"hotel_transport", ~r/^## 🏨\s*飯店交通/},
    {"daily_task", ~r/^## ☕\s*每日任務/},
    {"tips", ~r/^## 💡\s*交通小撇步/}
  ]

  @routes_header ~r/^## 🗓️\s*重點行程交通詳解/
  @address_cards_header ~r/^## 📍\s*計程車/
  @day_header ~r/^### Day (\d+) \((\d+)\/(\d+) .+?\):\s*(.+)/

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
    # Find the routes section
    route_lines =
      lines
      |> Enum.drop_while(&(not Regex.match?(@routes_header, &1)))
      |> Enum.drop(1)
      |> Enum.take_while(fn line ->
        not (String.starts_with?(line, "## ") and not String.starts_with?(line, "### "))
      end)

    # Split into day groups
    route_lines
    |> Enum.reduce({[], nil, []}, fn line, {results, current_day, current_lines} ->
      case Regex.run(@day_header, line) do
        [_, day_num, month, day, title] ->
          results =
            if current_day do
              [build_route(current_day, Enum.reverse(current_lines)) | results]
            else
              results
            end

          day_info = %{
            day_label: "Day #{day_num}",
            day_date: parse_date(month, day),
            title: String.trim(title)
          }

          {results, day_info, []}

        _ ->
          {results, current_day, [line | current_lines]}
      end
    end)
    |> then(fn {results, current_day, current_lines} ->
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

  defp parse_date(month, day) do
    m = String.to_integer(month)
    d = String.to_integer(day)
    case Date.new(2026, m, d) do
      {:ok, date} -> date
      _ -> nil
    end
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
    # Filter out non-segment lines
    lines = Enum.reject(lines, fn line ->
      trimmed = String.trim(line)
      trimmed == "" or trimmed == "---"
    end)

    # Split by numbered items (1. **from -> to**)
    lines
    |> Enum.reduce({[], [], false}, fn line, {segments, current, started} ->
      if Regex.match?(~r/^\d+\.\s+\*\*/, line) do
        segments =
          if current != [] and started do
            [build_segment(Enum.reverse(current)) | segments]
          else
            segments
          end

        {segments, [line], true}
      else
        if started do
          {segments, [line | current], true}
        else
          {segments, current, false}
        end
      end
    end)
    |> then(fn {segments, current, started} ->
      if current != [] and started do
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
    # Extract from -> to from header like "1.  **飯店 -> Leaves Coffee Roasters (墨田區本所)**"
    route_text =
      case Regex.run(~r/\d+\.\s+\*\*(.+?)\*\*/, header) do
        [_, text] -> text
        _ -> String.replace(header, ~r/^\d+\.\s+/, "")
      end

    {from, to} =
      case String.split(route_text, ~r/\s*->\s*/, parts: 2) do
        [f, t] -> {String.trim(f), String.trim(t)}
        _ -> {route_text, ""}
      end

    details = detail_lines |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == "" or &1 == "---")) |> Enum.join("\n")

    # Try to extract method
    method =
      cond do
        String.contains?(details, "地鐵") or String.contains?(details, "搭乘") -> "metro"
        String.contains?(details, "計程車") -> "taxi"
        String.contains?(details, "步行") -> "walk"
        true -> "other"
      end

    # Try to extract cost
    cost =
      case Regex.run(~r/約\s*([\d,]+)\s*(?:-\s*[\d,]+\s*)?日圓/, details) do
        [match, _] -> match
        _ -> nil
      end

    %{
      "from" => from,
      "to" => to,
      "method" => method,
      "details" => details,
      "cost" => cost
    }
  end

  defp build_segment([]), do: %{"from" => "", "to" => "", "method" => "other", "details" => "", "cost" => nil}

  # --- Address Cards ---

  defp parse_address_cards(lines) do
    card_lines =
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

    # Split by ### headers
    card_lines
    |> Enum.reduce({[], []}, fn line, {cards, current} ->
      if String.starts_with?(line, "### ") do
        cards =
          if current != [] do
            [build_address_card(Enum.reverse(current)) | cards]
          else
            cards
          end

        {cards, [line]}
      else
        {cards, [line | current]}
      end
    end)
    |> then(fn {cards, current} ->
      if current != [] do
        [build_address_card(Enum.reverse(current)) | cards]
      else
        cards
      end
    end)
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.map(fn {card, idx} -> Map.put(card, :position, idx) end)
  end

  defp build_address_card([header | detail_lines]) do
    # Extract name from header like "### 1. 住宿：新宿華盛頓飯店 (本館)"
    name =
      header
      |> String.replace(~r/^### \d+\.\s*/, "")
      |> String.replace(~r/^住宿：/, "")
      |> String.trim()

    details = Enum.join(detail_lines, "\n")

    name_ja =
      case Regex.run(~r/\*\*日文\*\*:\s*(.+)/, details) do
        [_, n] -> String.trim(n)
        _ -> nil
      end

    address =
      case Regex.run(~r/\*\*地址\*\*:\s*(.+)/, details) do
        [_, a] -> String.trim(a)
        _ -> ""
      end

    note =
      case Regex.run(~r/\*\*備註\*\*:\s*(.+)/, details) do
        [_, n] -> String.trim(n)
        _ -> nil
      end

    %{name: name, name_ja: name_ja, address: address, note: note}
  end

  defp build_address_card([]), do: %{name: "", name_ja: nil, address: "", note: nil}
end
