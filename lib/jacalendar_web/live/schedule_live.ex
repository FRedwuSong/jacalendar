defmodule JacalendarWeb.ScheduleLive do
  use JacalendarWeb, :live_view

  alias Jacalendar.MarkdownParser
  alias Jacalendar.Itineraries
  alias Phoenix.LiveView.JS

  @fuzzy_labels %{
    morning: "早上",
    afternoon: "下午",
    evening: "晚上"
  }

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(:current_time, nil)
      |> assign(:current_date, nil)
      |> assign(:editing, nil)
      |> assign(:parse_error, nil)
      |> assign(:selected_day, nil)
      |> assign(:show_metadata, true)

    case params do
      %{"id" => id} ->
        itinerary = Itineraries.get_itinerary!(id)

        {:ok,
         socket
         |> assign(:mode, :schedule)
         |> assign(:itinerary, itinerary)
         |> assign(:itineraries, [])}

      _ ->
        itineraries = Itineraries.list_itineraries()

        {:ok,
         socket
         |> assign(:mode, :input)
         |> assign(:itinerary, nil)
         |> assign(:itineraries, itineraries)
         |> allow_upload(:markdown_file, accept: ~w(.md .txt .markdown), max_entries: 1)}
    end
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("parse", %{"markdown" => markdown}, socket) do
    parse_and_save(markdown, socket)
  end

  def handle_event("validate_upload", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("load_path", %{"path" => path}, socket) do
    path = String.trim(path)

    case File.read(path) do
      {:ok, content} -> parse_and_save(content, socket)
      {:error, reason} -> {:noreply, assign(socket, :parse_error, "無法讀取檔案: #{inspect(reason)}")}
    end
  end

  def handle_event("upload", _params, socket) do
    [markdown] =
      consume_uploaded_entries(socket, :markdown_file, fn %{path: path}, _entry ->
        {:ok, File.read!(path)}
      end)

    parse_and_save(markdown, socket)
  end

  def handle_event("back_to_input", _params, socket) do
    {:noreply, push_navigate(socket, to: "/")}
  end

  def handle_event("delete_itinerary", %{"id" => id}, socket) do
    itinerary = Itineraries.get_itinerary!(id)
    {:ok, _} = Itineraries.delete_itinerary(itinerary)
    {:noreply, push_navigate(socket, to: "/")}
  end

  def handle_event("toggle_metadata", _, socket) do
    {:noreply, assign(socket, :show_metadata, !socket.assigns.show_metadata)}
  end

  def handle_event("select_day", %{"day-id" => "all"}, socket) do
    {:noreply, assign(socket, :selected_day, nil)}
  end

  def handle_event("select_day", %{"day-id" => day_id}, socket) do
    {:noreply, assign(socket, :selected_day, String.to_integer(day_id))}
  end

  def handle_event("client_time", %{"time" => time_str, "date" => date_str}, socket) do
    [h, m] = String.split(time_str, ":")
    current_time = Time.new!(String.to_integer(h), String.to_integer(m), 0)

    current_date =
      case Date.from_iso8601(date_str) do
        {:ok, d} -> d
        _ -> nil
      end

    {:noreply,
     socket
     |> assign(:current_time, current_time)
     |> assign(:current_date, current_date)}
  end

  def handle_event("edit_time", %{"item-id" => item_id_str}, socket) do
    {:noreply, assign(socket, :editing, {:time, String.to_integer(item_id_str)})}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, :editing, nil)}
  end

  def handle_event("save_time", %{"item-id" => item_id_str, "time" => time_str}, socket) do
    item_id = String.to_integer(item_id_str)

    case parse_time_input(time_str) do
      {:ok, time} ->
        item = Itineraries.get_item!(item_id)
        {:ok, _} = Itineraries.update_item(item, %{time_type: "exact", time_value: time})
        {:noreply, reload_itinerary(socket)}

      :error ->
        {:noreply, socket}
    end
  end

  def handle_event("edit_description", %{"item-id" => item_id_str}, socket) do
    {:noreply, assign(socket, :editing, {:description, String.to_integer(item_id_str)})}
  end

  def handle_event("save_description", %{"item-id" => item_id_str, "value" => value}, socket) do
    item_id = String.to_integer(item_id_str)
    item = Itineraries.get_item!(item_id)
    {:ok, _} = Itineraries.update_item(item, %{description: value})
    {:noreply, reload_itinerary(socket)}
  end

  def handle_event("edit_sub_item", %{"item-id" => item_id_str, "sub-idx" => si}, socket) do
    {:noreply,
     assign(socket, :editing, {:sub_item, String.to_integer(item_id_str), String.to_integer(si)})}
  end

  def handle_event(
        "save_sub_item",
        %{"item-id" => item_id_str, "sub-idx" => si, "value" => value},
        socket
      ) do
    item_id = String.to_integer(item_id_str)
    sub_idx = String.to_integer(si)
    item = Itineraries.get_item!(item_id)
    new_subs = List.replace_at(item.sub_items, sub_idx, value)
    {:ok, _} = Itineraries.update_sub_items(item, new_subs)
    {:noreply, reload_itinerary(socket)}
  end

  def handle_event("add_sub_item", %{"item-id" => item_id_str}, socket) do
    {:noreply, assign(socket, :editing, {:new_sub_item, String.to_integer(item_id_str)})}
  end

  def handle_event("save_new_sub_item", %{"item-id" => item_id_str, "value" => value}, socket) do
    item_id = String.to_integer(item_id_str)

    if String.trim(value) == "" do
      {:noreply, assign(socket, :editing, nil)}
    else
      item = Itineraries.get_item!(item_id)
      {:ok, _} = Itineraries.update_sub_items(item, item.sub_items ++ [String.trim(value)])
      {:noreply, reload_itinerary(socket)}
    end
  end

  def handle_event("delete_sub_item", %{"item-id" => item_id_str, "sub-idx" => si}, socket) do
    item_id = String.to_integer(item_id_str)
    sub_idx = String.to_integer(si)
    item = Itineraries.get_item!(item_id)
    new_subs = List.delete_at(item.sub_items, sub_idx)
    {:ok, _} = Itineraries.update_sub_items(item, new_subs)
    {:noreply, reload_itinerary(socket)}
  end

  defp parse_and_save(markdown, socket) do
    case MarkdownParser.parse(markdown) do
      {:ok, parsed} ->
        case Itineraries.create_itinerary(parsed) do
          {:ok, id} ->
            {:noreply, push_navigate(socket, to: "/itineraries/#{id}")}

          {:error, _} ->
            {:noreply, assign(socket, :parse_error, "儲存失敗")}
        end

      {:error, reason} ->
        {:noreply, assign(socket, :parse_error, reason)}
    end
  end

  defp reload_itinerary(socket) do
    itinerary = Itineraries.get_itinerary!(socket.assigns.itinerary.id)

    socket
    |> assign(:itinerary, itinerary)
    |> assign(:editing, nil)
  end

  defp parse_time_input(time_str) do
    case String.split(time_str, ":") do
      [h, m] ->
        {:ok, Time.new!(String.to_integer(h), String.to_integer(m), 0)}

      _ ->
        :error
    end
  end

  defp time_display(item) do
    time = Itineraries.deserialize_time(item.time_type, item.time_value)

    case time do
      {:exact, t} -> Calendar.strftime(t, "%H:%M")
      {:fuzzy, period} -> Map.get(@fuzzy_labels, period, "")
      :pending -> nil
    end
  end

  defp editable?(item) do
    item.time_type != "exact"
  end

  defp item_before_time?(item, current_time) do
    time = Itineraries.deserialize_time(item.time_type, item.time_value)

    case time do
      {:exact, t} -> Time.compare(t, current_time) == :lt
      {:fuzzy, :morning} -> Time.compare(current_time, ~T[12:00:00]) != :lt
      {:fuzzy, :afternoon} -> Time.compare(current_time, ~T[18:00:00]) != :lt
      {:fuzzy, :evening} -> Time.compare(current_time, ~T[23:00:00]) != :lt
      :pending -> false
    end
  end

  defp should_show_divider_after?(item, next_item, current_time) do
    item_before_time?(item, current_time) and
      (next_item == nil or not item_before_time?(next_item, current_time))
  end

  defp split_items_by_schedule(items) do
    {scheduled, unscheduled} = Enum.split_with(items, &(&1.time_type == "exact"))
    {Enum.sort_by(scheduled, & &1.time_value), unscheduled}
  end

  defp flight_events_for_day(metadata, day_date, _scheduled_items) do
    flights = (metadata || %{})["flights"] || []

    Enum.flat_map(flights, fn flight ->
      flight_date =
        case flight["date"] do
          %Date{} = d -> d
          s when is_binary(s) -> Date.from_iso8601!(s)
          _ -> nil
        end

      if flight_date == day_date do
        dep = flight["departure"]
        arr = flight["arrival"]
        flight_num = flight["flight_number"] || ""
        if dep && dep["time"] && arr && arr["time"] do
          [dh, dm] = String.split(dep["time"], ":")
          dep_time = Time.new!(String.to_integer(dh), String.to_integer(dm), 0)

          [ah, am] = String.split(arr["time"], ":")
          arr_time = Time.new!(String.to_integer(ah), String.to_integer(am), 0)

          checkin_time = Time.add(dep_time, -3 * 3600)

          dep_terminal = dep["terminal"] || flight["terminal"]
          dep_t_suffix = if dep_terminal, do: " · T#{dep_terminal}", else: ""

          [
            %{type: :flight, time_value: checkin_time, end_time: dep_time,
              label: "抵達 #{dep["code"]} #{dep["name"]}機場#{dep_t_suffix}"},
            %{type: :flight, time_value: dep_time, end_time: arr_time,
              label: "#{flight_num} #{dep["code"]} → #{arr["code"]} #{arr["name"]}"}
          ]
        else
          []
        end
      else
        []
      end
    end)
  end


  defp filter_flight_overlaps(scheduled_items, []), do: scheduled_items

  defp filter_flight_overlaps(scheduled_items, flight_events) do
    Enum.reject(scheduled_items, fn item ->
      Enum.any?(flight_events, fn fe ->
        buffer_start = Time.add(fe.time_value, -30 * 60)

        Time.compare(item.time_value, buffer_start) != :lt and
          Time.compare(item.time_value, fe.end_time) != :gt
      end)
    end)
  end

  defp timeline_range([]), do: {0, 23}

  defp timeline_range(scheduled_items) do
    times = Enum.map(scheduled_items, & &1.time_value)
    min_h = times |> Enum.map(& &1.hour) |> Enum.min() |> then(&max(&1 - 1, 0))
    max_h = times |> Enum.map(& &1.hour) |> Enum.max() |> then(&min(&1 + 2, 24))
    {min_h, max_h}
  end

  # Timeline grid: 10 minutes per row, 6 rows per hour
  @minutes_per_row 10
  @rows_per_hour 6
  @row_height_rem 0.583

  defp flight_grid_span(flight_event) do
    start_minutes = flight_event.time_value.hour * 60 + flight_event.time_value.minute
    end_minutes = flight_event.end_time.hour * 60 + flight_event.end_time.minute
    duration_minutes = end_minutes - start_minutes
    rows = div(duration_minutes, @minutes_per_row) + if(rem(duration_minutes, @minutes_per_row) > 0, do: 1, else: 0)
    max(rows, 3)
  end

  defp item_grid_row(item, start_hour) do
    h = item.time_value.hour
    m = item.time_value.minute
    (h - start_hour) * @rows_per_hour + div(m, @minutes_per_row) + 1
  end

  defp item_grid_span(current, next_entry, start_hour) do
    if next_entry do
      # Use grid row difference to guarantee no overlap
      current_row = item_grid_row(current, start_hour)
      next_row = item_grid_row(next_entry, start_hour)
      max(next_row - current_row, 1)
    else
      # Last item: size based on content
      sub_count = length(current.data.sub_items || [])
      max(6, 6 + sub_count * 2)
    end
  end

  defp sub_item_offset_rem(text, item_time) do
    case Regex.run(~r/^(\d{1,2}):(\d{2})/, String.trim(text)) do
      [_, h, m] ->
        item_min = item_time.hour * 60 + item_time.minute
        sub_min = String.to_integer(h) * 60 + String.to_integer(m)
        diff = sub_min - item_min

        if diff > 0 do
          # @row_height_rem per 10 min, offset by 1.5rem for title row
          1.5 + diff * @row_height_rem / @minutes_per_row
        else
          nil
        end

      _ ->
        nil
    end
  end

  defp sun_times_for_date(metadata, date) do
    sun_times = (metadata || %{})["sun_times"] || []
    Enum.find(sun_times, fn st ->
      st_date = case st["date"] do
        %Date{} = d -> d
        s when is_binary(s) -> Date.from_iso8601!(s)
        _ -> nil
      end
      st_date == date
    end)
  end

  defp format_hour(h) when h < 12, do: "#{String.pad_leading(to_string(h), 2, "0")}:00"
  defp format_hour(12), do: "12:00"
  defp format_hour(h), do: "#{String.pad_leading(to_string(h), 2, "0")}:00"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="schedule-container" phx-hook=".ClientTime" class="max-w-3xl mx-auto">
        <%= if @mode == :input do %>
          <div id="input-mode" class="space-y-6">
            <div class="text-center space-y-2">
              <h1 class="text-3xl font-bold tracking-tight">Jacalendar</h1>
              <p class="text-base-content/60">
                貼上你的旅行行程 Markdown，即時轉換為互動式行程表
              </p>
            </div>

            <%!-- Saved itineraries list --%>
            <div :if={@itineraries != []} id="itinerary-list" class="space-y-2">
              <h2 class="text-lg font-semibold">已儲存的行程</h2>
              <div :for={it <- @itineraries} class="card card-compact bg-base-200 shadow-sm">
                <div class="card-body flex-row items-center justify-between">
                  <.link navigate={"/itineraries/#{it.id}"} class="flex-1 hover:text-primary">
                    <p class="font-medium">{it.title}</p>
                    <p :if={it.date_range_start} class="text-xs text-base-content/60">
                      {it.date_range_start} ~ {it.date_range_end}
                    </p>
                  </.link>
                  <button
                    phx-click="delete_itinerary"
                    phx-value-id={it.id}
                    class="btn btn-ghost btn-xs text-error"
                  >
                    <.icon name="hero-trash" class="size-4" />
                  </button>
                </div>
              </div>

              <div class="divider text-base-content/40 text-xs">或新增行程</div>
            </div>

            <%!-- File upload --%>
            <.form
              for={%{}}
              id="upload-form"
              phx-submit="upload"
              phx-change="validate_upload"
              class="space-y-3"
            >
              <div
                class="border-2 border-dashed border-base-300 rounded-lg p-6 text-center hover:border-primary transition-colors cursor-pointer"
                phx-drop-target={@uploads.markdown_file.ref}
              >
                <.live_file_input upload={@uploads.markdown_file} class="hidden" />
                <div class="space-y-2">
                  <.icon name="hero-arrow-up-tray" class="size-8 mx-auto text-base-content/40" />
                  <p class="text-sm text-base-content/60">
                    拖放 .md 檔案到這裡，或
                    <label
                      for={@uploads.markdown_file.ref}
                      class="text-primary cursor-pointer hover:underline"
                    >
                      點擊選擇檔案
                    </label>
                  </p>
                </div>
                <div :for={entry <- @uploads.markdown_file.entries} class="mt-3">
                  <span class="badge badge-info gap-1">
                    <.icon name="hero-document-text" class="size-3" />
                    {entry.client_name}
                  </span>
                </div>
              </div>
              <div :if={@uploads.markdown_file.entries != []} class="flex justify-end">
                <button type="submit" id="upload-btn" class="btn btn-primary btn-sm">
                  <.icon name="hero-calendar-days" class="size-4" /> 上傳並解析
                </button>
              </div>
            </.form>

            <div class="divider text-base-content/40 text-xs">或輸入檔案路徑</div>

            <%!-- File path input --%>
            <.form for={%{}} id="path-form" phx-submit="load_path" class="flex gap-2">
              <input
                type="text"
                name="path"
                id="path-input"
                class="input input-bordered flex-1 font-mono text-sm"
                placeholder="/Users/you/trip/itinerary.md"
                required
              />
              <button type="submit" id="path-btn" class="btn btn-primary btn-sm">
                <.icon name="hero-folder-open" class="size-4" /> 載入
              </button>
            </.form>

            <div class="divider text-base-content/40 text-xs">或直接貼上內容</div>

            <%!-- Textarea paste --%>
            <.form for={%{}} id="markdown-form" phx-submit="parse" class="space-y-4">
              <textarea
                name="markdown"
                id="markdown-input"
                rows="8"
                class="textarea textarea-bordered w-full font-mono text-sm leading-relaxed"
                placeholder="# 東京 6 天 5 夜之旅 (2026/04/16 - 04/21)&#10;&#10;### Day 1: 2026/04/16 (四) - 抵達&#10;*   **17:15**: 抵達成田機場..."
                required
              ></textarea>

              <div class="flex justify-end">
                <button type="submit" id="parse-btn" class="btn btn-primary btn-sm">
                  <.icon name="hero-calendar-days" class="size-4" /> 解析行程
                </button>
              </div>
            </.form>

            <div :if={@parse_error} id="parse-error" class="alert alert-error">
              <.icon name="hero-exclamation-circle" class="size-5" />
              <span>解析失敗：{@parse_error}</span>
            </div>
          </div>
        <% else %>
          <div id="schedule-mode" class="space-y-6">
            <div class="flex items-center justify-between">
              <div>
                <h1 class="text-2xl font-bold tracking-tight">{@itinerary.title}</h1>
                <p :if={@itinerary.date_range_start} class="text-base-content/60 text-sm mt-1">
                  {@itinerary.date_range_start} ~ {@itinerary.date_range_end}
                </p>
              </div>
              <div class="flex gap-2">
                <button
                  phx-click="delete_itinerary"
                  phx-value-id={@itinerary.id}
                  class="btn btn-ghost btn-sm text-error"
                >
                  <.icon name="hero-trash" class="size-4" />
                </button>
                <.link navigate="/" class="btn btn-ghost btn-sm">
                  <.icon name="hero-arrow-left" class="size-4" /> 返回列表
                </.link>
              </div>
            </div>

            <.itinerary_tabs itinerary_id={@itinerary.id} active={:schedule} />

            <%!-- Day filter pills --%>
            <div class="flex gap-2 overflow-x-auto pb-2 scrollbar-none">
              <button
                phx-click="select_day"
                phx-value-day-id="all"
                class={[
                  "btn btn-sm shrink-0",
                  if(@selected_day == nil, do: "btn-active btn-primary", else: "btn-ghost")
                ]}
              >
                全部
              </button>
              <button
                :for={day <- @itinerary.days}
                phx-click="select_day"
                phx-value-day-id={day.id}
                class={[
                  "btn btn-sm shrink-0 flex flex-col items-center leading-tight h-auto py-1.5",
                  if(@selected_day == day.id, do: "btn-active btn-primary", else: "btn-ghost")
                ]}
              >
                <span class="text-xs font-mono">{Calendar.strftime(day.date, "%m/%d")}</span>
              </button>
            </div>

            <%!-- Metadata --%>
            <% meta = @itinerary.metadata || %{} %>
            <% flights = meta["flights"] || [] %>
            <% hotel = meta["hotel"] %>
            <div :if={!@selected_day && (flights != [] || hotel)} id="metadata-section">
              <button
                phx-click="toggle_metadata"
                class="flex items-center gap-1 text-xs text-base-content/40 hover:text-base-content/60 transition-colors mb-2"
              >
                <.icon name={if @show_metadata, do: "hero-chevron-down-mini", else: "hero-chevron-right-mini"} class="size-4" />
                {if @show_metadata, do: "隱藏旅行資訊", else: "顯示旅行資訊"}
              </button>
            <div
              :if={@show_metadata}
              class="grid grid-cols-1 sm:grid-cols-2 gap-3"
            >
              <div
                :if={flights != [] && !@selected_day}
                class="card card-compact bg-base-200 shadow-sm"
              >
                <div class="card-body">
                  <h3 class="card-title text-sm">
                    <.icon name="hero-paper-airplane" class="size-4" /> 航班
                  </h3>
                  <div :for={flight <- flights} class="text-sm">
                    <div class="flex items-center gap-2">
                      <span class="font-medium">
                        {if flight["direction"] == "outbound", do: "去程", else: "回程"}
                      </span>
                      <span class="text-base-content/70">
                        {flight["flight_number"]} · {flight["date"]}
                      </span>
                    </div>
                    <div
                      :if={flight["departure"] && flight["arrival"]}
                      class="flex items-center gap-3 mt-1 pl-2"
                    >
                      <% dep = flight["departure"] %>
                      <% arr = flight["arrival"] %>
                      <div class="text-center">
                        <div class="font-mono text-sm font-semibold">{dep["time"]}</div>
                        <div class="text-xs text-base-content/60">{dep["code"]} {dep["name"]}</div>
                        <div :if={dep["terminal"]} class="text-[10px] text-base-content/40">T{dep["terminal"]}</div>
                      </div>
                      <div class="flex-1 flex items-center">
                        <div class="flex-1 border-t border-base-content/20" />
                        <.icon name="hero-arrow-right-mini" class="size-4 text-base-content/40" />
                      </div>
                      <div class="text-center">
                        <div class="font-mono text-sm font-semibold">{arr["time"]}</div>
                        <div class="text-xs text-base-content/60">{arr["code"]} {arr["name"]}</div>
                        <div :if={arr["terminal"]} class="text-[10px] text-base-content/40">T{arr["terminal"]}</div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div
                :if={hotel && hotel["name"]}
                class="card card-compact bg-base-200 shadow-sm"
              >
                <div class="card-body">
                  <h3 class="card-title text-sm">
                    <.icon name="hero-building-office" class="size-4" /> 住宿
                  </h3>
                  <p class="text-sm font-medium">{hotel["name"]}</p>
                  <p :if={hotel["address"]} class="text-xs text-base-content/60">
                    {hotel["address"]}
                  </p>
                  <p :if={hotel["phone"]} class="text-xs text-base-content/60">
                    <.icon name="hero-phone" class="size-3 inline" /> {hotel["phone"]}
                  </p>
                </div>
              </div>
              </div>
            </div>

            <%!-- Days --%>
            <%= if @selected_day do %>
              <%!-- Single day: Timeline view --%>
              <% [day] = Enum.filter(@itinerary.days, & &1.id == @selected_day) %>
              <% {scheduled_items, unscheduled_items} = split_items_by_schedule(day.items) %>
              <% flight_events = flight_events_for_day(@itinerary.metadata, day.date, scheduled_items) %>
              <% filtered_scheduled = filter_flight_overlaps(scheduled_items, flight_events) %>
              <% all_timeline_items = Enum.sort_by(
                Enum.map(filtered_scheduled, &%{type: :item, data: &1, time_value: &1.time_value}) ++
                Enum.map(flight_events, &%{type: :flight, data: &1, time_value: &1.time_value}),
                & &1.time_value
              ) %>

              <%!-- Day header --%>
              <% sun = sun_times_for_date(@itinerary.metadata, day.date) %>
              <div class={[
                "flex items-baseline gap-3 py-2 border-b-2",
                if(@current_date && day.date == @current_date,
                  do: "border-primary",
                  else: "border-base-300"
                )
              ]}>
                <span class="text-lg font-bold">{Calendar.strftime(day.date, "%m/%d")}</span>
                <span class="badge badge-ghost badge-sm">{day.weekday}</span>
                <span class="text-base-content/70">{day.title}</span>
                <span :if={sun} class="ml-auto text-xs text-base-content/40 font-mono whitespace-nowrap">
                  ☀ {sun["sunrise"]} — {sun["sunset"]}
                </span>
              </div>

              <%!-- Unscheduled items section --%>
              <div :if={unscheduled_items != []} class="card card-compact bg-base-200/50 shadow-sm overflow-hidden">
                <div class="card-body py-3">
                  <h3 class="text-xs font-semibold text-base-content/50 uppercase tracking-wider">
                    未排定項目
                  </h3>
                  <div class="space-y-1.5">
                    <div :for={item <- unscheduled_items} id={"unscheduled-#{item.id}"} class="flex gap-2 items-start text-sm">
                      <span class="w-12 shrink-0 text-right text-xs text-base-content/50 pt-0.5">
                        <%= if @editing == {:time, item.id} do %>
                          <.form for={%{}} id={"time-form-#{item.id}"} phx-submit="save_time" class="flex">
                            <input type="hidden" name="item-id" value={item.id} />
                            <input type="time" name="time" id={"time-input-#{item.id}"} class="input input-xs input-bordered w-full" required />
                          </.form>
                        <% else %>
                          <%= if time_display(item) do %>
                            <span class="cursor-pointer hover:text-primary" phx-click="edit_time" phx-value-item-id={item.id}>
                              {time_display(item)}
                            </span>
                          <% else %>
                            <button class="badge badge-warning badge-xs cursor-pointer hover:badge-primary" phx-click="edit_time" phx-value-item-id={item.id}>
                              待定
                            </button>
                          <% end %>
                        <% end %>
                      </span>
                      <div class="flex-1 min-w-0">
                        <%= if @editing == {:description, item.id} do %>
                          <.form for={%{}} phx-submit="save_description" id={"desc-form-#{item.id}"}>
                            <input type="hidden" name="item-id" value={item.id} />
                            <textarea name="value" id={"desc-input-#{item.id}"} class="textarea textarea-bordered textarea-xs w-full text-sm leading-snug" rows="2" phx-blur={JS.dispatch("submit", to: "#desc-form-#{item.id}")} phx-keydown="cancel_edit" phx-key="Escape" autofocus>{item.description}</textarea>
                          </.form>
                        <% else %>
                          <span class="text-base-content/70 cursor-pointer hover:text-primary" phx-click="edit_description" phx-value-item-id={item.id}>
                            {item.description}
                          </span>
                        <% end %>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <%!-- Timeline grid --%>
              <%= if all_timeline_items != [] do %>
                <% {start_hour, end_hour} = timeline_range(all_timeline_items) %>
                <% rows_per_hour = 6 %>
                <% row_height_rem = 1.0 %>
                <% total_rows = (end_hour - start_hour) * rows_per_hour %>
                <div
                  class="grid relative"
                  style={"grid-template-columns: 3.5rem 1fr; grid-template-rows: repeat(#{total_rows}, #{row_height_rem}rem);"}
                >
                  <%!-- Hour labels and grid lines --%>
                  <%= for h <- start_hour..(end_hour - 1) do %>
                    <div
                      class="text-xs text-base-content/40 font-mono text-right pr-3 leading-none"
                      style={"grid-row: #{(h - start_hour) * rows_per_hour + 1}; grid-column: 1;"}
                    >
                      {format_hour(h)}
                    </div>
                    <div
                      class="border-t border-base-300/50"
                      style={"grid-row: #{(h - start_hour) * rows_per_hour + 1}; grid-column: 2;"}
                    />
                  <% end %>

                  <%!-- Timeline items (scheduled + flights) --%>
                  <%= for {entry, idx} <- Enum.with_index(all_timeline_items) do %>
                    <% next_entry = Enum.at(all_timeline_items, idx + 1) %>
                    <%= if entry.type == :flight do %>
                      <% flight_span = flight_grid_span(entry.data) %>
                      <div
                        class="rounded-lg bg-warning/10 border-l-3 border-warning px-3 py-2 text-sm flex flex-col justify-between"
                        style={"grid-row: #{item_grid_row(entry, start_hour)} / span #{flight_span}; grid-column: 2;"}
                      >
                        <div>
                          <span class="font-mono text-xs text-warning font-semibold">
                            {Calendar.strftime(entry.time_value, "%H:%M")}
                          </span>
                          <span class="ml-2">{entry.data.label}</span>
                        </div>
                        <div class="text-right text-xs text-warning/60 font-mono">
                          {Calendar.strftime(entry.data.end_time, "%H:%M")}
                        </div>
                      </div>
                    <% else %>
                      <% item = entry.data %>
                      <% span = item_grid_span(entry, next_entry, start_hour) %>
                      <div
                        id={"timeline-item-#{item.id}"}
                        class={[
                          "rounded-lg border-l-3 border-primary px-3 text-sm transition-all relative group",
                          if(@editing == {:description, item.id},
                            do: "z-20 py-2 bg-base-300 shadow-lg overflow-visible",
                            else: "py-1.5 bg-primary/10 overflow-hidden hover:overflow-visible hover:z-10 hover:bg-base-200 hover:shadow-lg hover:rounded-lg"
                          )
                        ]}
                        style={"grid-row: #{item_grid_row(entry, start_hour)} / span #{span}; grid-column: 2;"}
                      >
                        <span class="font-mono text-xs text-primary font-semibold">
                          {Calendar.strftime(item.time_value, "%H:%M")}
                        </span>
                        <%= if @editing == {:description, item.id} do %>
                          <.form for={%{}} phx-submit="save_description" id={"desc-form-#{item.id}"} class="mt-1">
                            <input type="hidden" name="item-id" value={item.id} />
                            <textarea name="value" id={"desc-input-#{item.id}"} class="textarea textarea-bordered textarea-sm w-full text-sm leading-snug" rows="2" phx-blur={JS.dispatch("submit", to: "#desc-form-#{item.id}")} phx-keydown="cancel_edit" phx-key="Escape" autofocus>{item.description}</textarea>
                          </.form>
                        <% else %>
                          <span class="ml-2 cursor-pointer hover:text-primary" phx-click="edit_description" phx-value-item-id={item.id}>
                            {item.description}
                          </span>
                        <% end %>
                        <%= for sub <- (item.sub_items || []) do %>
                          <% offset = sub_item_offset_rem(sub, item.time_value) %>
                          <%= if offset do %>
                            <p
                              class="absolute left-3 right-3 text-xs text-base-content/60 pl-3 border-l-2 border-base-300"
                              style={"top: #{offset}rem;"}
                            >
                              {sub}
                            </p>
                          <% else %>
                            <p class="text-xs text-base-content/60 pl-3 border-l-2 border-base-300">
                              {sub}
                            </p>
                          <% end %>
                        <% end %>
                      </div>
                    <% end %>
                  <% end %>

                  <%!-- Current time indicator --%>
                  <%= if @current_date && @current_time && day.date == @current_date do %>
                    <% ct_row = (@current_time.hour - start_hour) * rows_per_hour + div(@current_time.minute, 10) + 1 %>
                    <% ct_offset = rem(@current_time.minute, 10) / 10 * 100 %>
                    <%= if ct_row >= 1 and ct_row <= total_rows do %>
                      <div
                        class="text-xs text-error font-mono font-bold text-right pr-2"
                        style={"grid-row: #{ct_row}; grid-column: 1; align-self: start; margin-top: #{ct_offset}%;"}
                      >
                        {Calendar.strftime(@current_time, "%H:%M")}
                      </div>
                      <div
                        class="border-t-2 border-error relative"
                        style={"grid-row: #{ct_row}; grid-column: 2; align-self: start; margin-top: #{ct_offset}%; z-index: 20;"}
                      >
                        <div class="absolute -left-1.5 -top-1.5 size-3 rounded-full bg-error" />
                      </div>
                    <% end %>
                  <% end %>
                </div>
              <% end %>
            <% else %>
              <%!-- All days: List view --%>
              <% filtered_days = @itinerary.days %>
              <div :for={day <- filtered_days} class="space-y-2">
              <% sun = sun_times_for_date(@itinerary.metadata, day.date) %>
              <div class={[
                "flex items-baseline gap-3 py-2 border-b-2",
                if(@current_date && day.date == @current_date,
                  do: "border-primary",
                  else: "border-base-300"
                )
              ]}>
                <span class="text-lg font-bold">{Calendar.strftime(day.date, "%m/%d")}</span>
                <span class="badge badge-ghost badge-sm">{day.weekday}</span>
                <span class="text-base-content/70">{day.title}</span>
                <span :if={sun} class="ml-auto text-xs text-base-content/40 font-mono whitespace-nowrap">
                  ☀ {sun["sunrise"]} — {sun["sunset"]}
                </span>
              </div>

              <div id={"day-#{day.id}"} class="space-y-1">
                <%= for {item, item_idx} <- Enum.with_index(day.items) do %>
                  <% next_item = Enum.at(day.items, item_idx + 1) %>

                  <div
                    id={"item-#{item.id}"}
                    class={[
                      "flex gap-3 py-2 px-3 rounded-lg transition-colors",
                      if(
                        @current_date && day.date == @current_date && @current_time &&
                          item_before_time?(item, @current_time),
                        do: "opacity-50",
                        else: "hover:bg-base-200"
                      )
                    ]}
                  >
                    <%!-- Time column --%>
                    <div class="w-16 shrink-0 text-right">
                      <%= if @editing == {:time, item.id} do %>
                        <.form
                          for={%{}}
                          id={"time-form-#{item.id}"}
                          phx-submit="save_time"
                          class="flex"
                        >
                          <input type="hidden" name="item-id" value={item.id} />
                          <input
                            type="time"
                            name="time"
                            id={"time-input-#{item.id}"}
                            class="input input-xs input-bordered w-full"
                            required
                          />
                        </.form>
                      <% else %>
                        <%= if time_display(item) do %>
                          <span
                            class={[
                              "text-sm font-mono",
                              if(editable?(item), do: "cursor-pointer hover:text-primary", else: "")
                            ]}
                            phx-click={if(editable?(item), do: "edit_time")}
                            phx-value-item-id={item.id}
                          >
                            {time_display(item)}
                          </span>
                        <% else %>
                          <button
                            class="badge badge-warning badge-sm cursor-pointer hover:badge-primary"
                            phx-click="edit_time"
                            phx-value-item-id={item.id}
                          >
                            待定
                          </button>
                        <% end %>
                      <% end %>
                    </div>

                    <%!-- Content column --%>
                    <div class="flex-1 min-w-0">
                      <%= if @editing == {:description, item.id} do %>
                        <.form
                          for={%{}}
                          phx-submit="save_description"
                          id={"desc-form-#{item.id}"}
                        >
                          <input type="hidden" name="item-id" value={item.id} />
                          <input
                            type="text"
                            name="value"
                            value={item.description}
                            id={"desc-input-#{item.id}"}
                            class="input input-xs input-bordered w-full text-sm"
                            phx-blur={JS.dispatch("submit", to: "#desc-form-#{item.id}")}
                            phx-keydown="cancel_edit"
                            phx-key="Escape"
                            autofocus
                          />
                        </.form>
                      <% else %>
                        <p
                          class="text-sm cursor-pointer hover:text-primary"
                          phx-click="edit_description"
                          phx-value-item-id={item.id}
                        >
                          {item.description}
                        </p>
                      <% end %>
                      <div :if={item.sub_items != []} class="mt-1 space-y-0.5">
                        <%= for {sub, sub_idx} <- Enum.with_index(item.sub_items) do %>
                          <div class="flex items-center gap-1 group">
                            <%= if @editing == {:sub_item, item.id, sub_idx} do %>
                              <.form
                                for={%{}}
                                phx-submit="save_sub_item"
                                id={"sub-form-#{item.id}-#{sub_idx}"}
                                class="flex-1"
                              >
                                <input type="hidden" name="item-id" value={item.id} />
                                <input type="hidden" name="sub-idx" value={sub_idx} />
                                <input
                                  type="text"
                                  name="value"
                                  value={sub}
                                  id={"sub-input-#{item.id}-#{sub_idx}"}
                                  class="input input-xs input-bordered w-full text-xs"
                                  phx-blur={
                                    JS.dispatch("submit", to: "#sub-form-#{item.id}-#{sub_idx}")
                                  }
                                  phx-keydown="cancel_edit"
                                  phx-key="Escape"
                                  autofocus
                                />
                              </.form>
                            <% else %>
                              <p
                                class="text-xs text-base-content/60 pl-3 border-l-2 border-base-300 flex-1 cursor-pointer hover:text-primary"
                                phx-click="edit_sub_item"
                                phx-value-item-id={item.id}
                                phx-value-sub-idx={sub_idx}
                              >
                                {sub}
                              </p>
                              <button
                                class="btn btn-ghost btn-xs opacity-0 group-hover:opacity-100 text-error"
                                phx-click="delete_sub_item"
                                phx-value-item-id={item.id}
                                phx-value-sub-idx={sub_idx}
                              >
                                <.icon name="hero-x-mark" class="size-3" />
                              </button>
                            <% end %>
                          </div>
                        <% end %>
                      </div>
                      <%= if @editing == {:new_sub_item, item.id} do %>
                        <.form
                          for={%{}}
                          phx-submit="save_new_sub_item"
                          id={"new-sub-form-#{item.id}"}
                          class="mt-1"
                        >
                          <input type="hidden" name="item-id" value={item.id} />
                          <input
                            type="text"
                            name="value"
                            id={"new-sub-input-#{item.id}"}
                            class="input input-xs input-bordered w-full text-xs"
                            placeholder="輸入子項目內容..."
                            phx-keydown="cancel_edit"
                            phx-key="Escape"
                            autofocus
                          />
                        </.form>
                      <% else %>
                        <button
                          class="btn btn-ghost btn-xs text-base-content/40 hover:text-primary mt-1"
                          phx-click="add_sub_item"
                          phx-value-item-id={item.id}
                        >
                          <.icon name="hero-plus" class="size-3" /> 子項目
                        </button>
                      <% end %>
                    </div>
                  </div>

                  <%!-- Time divider --%>
                  <div
                    :if={
                      @current_date && day.date == @current_date && @current_time &&
                        should_show_divider_after?(item, next_item, @current_time)
                    }
                    id="current-time-divider"
                    class="flex items-center gap-2 py-1"
                  >
                    <div class="w-16 text-right">
                      <span class="text-xs font-mono text-primary font-bold">
                        {Calendar.strftime(@current_time, "%H:%M")}
                      </span>
                    </div>
                    <div class="flex-1 border-t-2 border-primary border-dashed"></div>
                    <span class="text-xs text-primary font-medium">現在</span>
                  </div>
                <% end %>
              </div>
            </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".ClientTime">
        export default {
          mounted() {
            this.sendTime()
            this.timer = setInterval(() => this.sendTime(), 60000)
          },
          sendTime() {
            const now = new Date()
            const time = now.getHours().toString().padStart(2, '0') + ':' + now.getMinutes().toString().padStart(2, '0')
            const date = now.getFullYear() + '-' + (now.getMonth() + 1).toString().padStart(2, '0') + '-' + now.getDate().toString().padStart(2, '0')
            this.pushEvent("client_time", {time, date})
          },
          destroyed() {
            if (this.timer) clearInterval(this.timer)
          }
        }
      </script>
    </Layouts.app>
    """
  end
end
