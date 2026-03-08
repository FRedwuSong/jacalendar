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

  defp timeline_range([]), do: {0, 23}

  defp timeline_range(scheduled_items) do
    times = Enum.map(scheduled_items, & &1.time_value)
    min_h = times |> Enum.map(& &1.hour) |> Enum.min() |> then(&max(&1 - 1, 0))
    max_h = times |> Enum.map(& &1.hour) |> Enum.max() |> then(&min(&1 + 2, 24))
    {min_h, max_h}
  end

  defp item_grid_row(item, start_hour) do
    h = item.time_value.hour
    m = item.time_value.minute
    row = (h - start_hour) * 2 + if(m >= 30, do: 2, else: 1)
    row
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
                <span class="text-xs">{day.title}</span>
              </button>
            </div>

            <%!-- Metadata --%>
            <% meta = @itinerary.metadata || %{} %>
            <% flights = meta["flights"] || [] %>
            <% hotel = meta["hotel"] %>
            <div
              :if={flights != [] || hotel}
              id="metadata-section"
              class="grid grid-cols-1 sm:grid-cols-2 gap-3"
            >
              <div
                :if={flights != []}
                class="card card-compact bg-base-200 shadow-sm"
              >
                <div class="card-body">
                  <h3 class="card-title text-sm">
                    <.icon name="hero-paper-airplane" class="size-4" /> 航班
                  </h3>
                  <div :for={flight <- flights} class="text-sm space-y-0.5">
                    <div>
                      <span class="font-medium">
                        {if flight["direction"] == "outbound", do: "去程", else: "回程"}
                      </span>
                      <span class="text-base-content/70">
                        {flight["flight_number"]} · {flight["date"]}
                      </span>
                    </div>
                    <div
                      :if={flight["departure"] && flight["arrival"]}
                      class="text-xs text-base-content/60 font-mono pl-2"
                    >
                      <% dep = flight["departure"] %>
                      <% arr = flight["arrival"] %>
                      {dep["code"]} {dep["name"]} {dep["time"]} → {arr["code"]} {arr["name"]} {arr["time"]}
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
                </div>
              </div>
            </div>

            <%!-- Days --%>
            <%= if @selected_day do %>
              <%!-- Single day: Timeline view --%>
              <% [day] = Enum.filter(@itinerary.days, & &1.id == @selected_day) %>
              <% {scheduled_items, unscheduled_items} = split_items_by_schedule(day.items) %>

              <%!-- Day header --%>
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
              <%= if scheduled_items != [] do %>
                <% {start_hour, end_hour} = timeline_range(scheduled_items) %>
                <% total_rows = (end_hour - start_hour) * 2 %>
                <div
                  class="grid relative"
                  style={"grid-template-columns: 3.5rem 1fr; grid-template-rows: repeat(#{total_rows}, 1.75rem);"}
                >
                  <%!-- Hour labels and grid lines --%>
                  <%= for h <- start_hour..(end_hour - 1) do %>
                    <div
                      class="text-xs text-base-content/40 font-mono text-right pr-3 leading-none"
                      style={"grid-row: #{(h - start_hour) * 2 + 1}; grid-column: 1;"}
                    >
                      {format_hour(h)}
                    </div>
                    <div
                      class="border-t border-base-300/50"
                      style={"grid-row: #{(h - start_hour) * 2 + 1}; grid-column: 2;"}
                    />
                  <% end %>

                  <%!-- Scheduled items --%>
                  <%= for item <- scheduled_items do %>
                    <div
                      id={"timeline-item-#{item.id}"}
                      class={[
                        "rounded-lg bg-primary/10 border-l-3 border-primary px-3 text-sm transition-colors",
                        if(@editing == {:description, item.id},
                          do: "relative z-10 py-2 bg-base-300 shadow-lg",
                          else: "py-1.5 hover:bg-primary/20"
                        )
                      ]}
                      style={"grid-row: #{item_grid_row(item, start_hour)} / span 2; grid-column: 2;"}
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
                    </div>
                  <% end %>
                </div>
              <% end %>
            <% else %>
              <%!-- All days: List view --%>
              <% filtered_days = @itinerary.days %>
              <div :for={day <- filtered_days} class="space-y-2">
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
