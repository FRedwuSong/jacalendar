defmodule JacalendarWeb.TripLive do
  use JacalendarWeb, :live_view

  alias Jacalendar.Itineraries

  @hour_start 7
  @hour_end 24
  @rows_per_hour 4

  @impl true
  def mount(%{"id" => id, "day" => day_param}, _session, socket) do
    itinerary = Itineraries.get_itinerary!(id)
    total_days = length(itinerary.days)

    socket = socket |> assign(:editing, nil) |> assign(:confirm_delete, nil)

    case parse_day_param(day_param, total_days) do
      {:ok, :all} ->
        {:ok,
         socket
         |> assign(:itinerary, itinerary)
         |> assign(:view_mode, :week)
         |> assign(:selected_day, nil)
         |> assign(:days, itinerary.days)
         |> assign(:total_days, total_days)}

      {:ok, day_number} ->
        day = Enum.find(itinerary.days, &(&1.position == day_number - 1))

        {:ok,
         socket
         |> assign(:itinerary, itinerary)
         |> assign(:view_mode, :day)
         |> assign(:selected_day, day_number)
         |> assign(:days, [day])
         |> assign(:total_days, total_days)}

      :redirect ->
        {:ok,
         socket
         |> push_navigate(to: ~p"/trip/#{id}/all")}
    end
  end

  defp parse_day_param("all", _total), do: {:ok, :all}

  defp parse_day_param(day_str, total) do
    case Integer.parse(day_str) do
      {day, ""} when day >= 1 and day <= total -> {:ok, day}
      _ -> :redirect
    end
  end

  defp hours, do: @hour_start..(@hour_end - 1)

  defp time_to_row(%Time{} = time) do
    hour = time.hour
    minute = time.minute
    clamped_hour = max(hour, @hour_start)
    (clamped_hour - @hour_start) * @rows_per_hour + div(minute * @rows_per_hour, 60) + 1
  end

  defp event_blocks(items) do
    items
    |> Enum.filter(&(&1.time_type == "exact" && &1.time_value))
    |> Enum.sort_by(& &1.time_value, Time)
    |> Enum.chunk_every(2, 1)
    |> Enum.map(fn
      [current, next] ->
        row_start = time_to_row(current.time_value)
        row_end = item_row_end(current, time_to_row(next.time_value), row_start)
        %{item: current, row_start: row_start, row_end: row_end}

      [current] ->
        row_start = time_to_row(current.time_value)
        row_end = item_row_end(current, nil, row_start)
        %{item: current, row_start: row_start, row_end: row_end}
    end)
  end

  defp item_row_end(item, next_row, row_start) do
    cond do
      item.end_time -> max(time_to_row(item.end_time), row_start + @rows_per_hour)
      next_row -> max(next_row, row_start + @rows_per_hour)
      true -> row_start + @rows_per_hour
    end
  end

  defp format_time(%Time{} = t), do: Calendar.strftime(t, "%H:%M")

  @color_options ["primary", "info", "success", "warning", "error"]

  defp color_classes(nil), do: color_classes("primary")
  defp color_classes("primary"), do: %{bg: "bg-primary/15", bg_edit: "bg-primary/25", border: "border-primary", text: "text-primary", hover: "hover:bg-primary/25", dot: "bg-primary", ring: "ring-primary"}
  defp color_classes("info"), do: %{bg: "bg-info/15", bg_edit: "bg-info/25", border: "border-info", text: "text-info", hover: "hover:bg-info/25", dot: "bg-info", ring: "ring-info"}
  defp color_classes("success"), do: %{bg: "bg-success/15", bg_edit: "bg-success/25", border: "border-success", text: "text-success", hover: "hover:bg-success/25", dot: "bg-success", ring: "ring-success"}
  defp color_classes("warning"), do: %{bg: "bg-warning/15", bg_edit: "bg-warning/25", border: "border-warning", text: "text-warning", hover: "hover:bg-warning/25", dot: "bg-warning", ring: "ring-warning"}
  defp color_classes("error"), do: %{bg: "bg-error/15", bg_edit: "bg-error/25", border: "border-error", text: "text-error", hover: "hover:bg-error/25", dot: "bg-error", ring: "ring-error"}
  defp color_classes(_), do: color_classes("primary")

  defp render_markdown(text) do
    text
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
    |> String.replace(~r/\*\*(.+?)\*\*/, "<strong>\\1</strong>")
    |> String.replace(~r/`(.+?)`/, "<code class=\"text-primary\">\\1</code>")
    |> Phoenix.HTML.raw()
  end

  defp format_column_header(day) do
    month = day.date.month
    d = day.date.day
    "#{month}/#{d} (#{day.weekday})"
  end

  defp reload_itinerary(socket) do
    itinerary = Itineraries.get_itinerary!(socket.assigns.itinerary.id)
    days =
      case socket.assigns.view_mode do
        :week -> itinerary.days
        :day ->
          day = Enum.find(itinerary.days, &(&1.position == socket.assigns.selected_day - 1))
          if day, do: [day], else: []
      end

    socket
    |> assign(:itinerary, itinerary)
    |> assign(:days, days)
    |> assign(:total_days, length(itinerary.days))
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:hours, hours())
      |> assign(:hour_start, @hour_start)
      |> assign(:color_options, @color_options)
      |> assign(:rows_per_hour, @rows_per_hour)
      |> assign(:total_rows, (@hour_end - @hour_start) * @rows_per_hour)

    ~H"""
    <div class="flex flex-col h-[calc(100vh-4rem)]" phx-window-keydown="keydown">
      <%!-- Header --%>
      <div class="flex items-center justify-between px-4 py-2 border-b border-base-300 bg-base-100 shrink-0">
        <h1 class="text-lg font-bold truncate"><%= @itinerary.title %></h1>
        <div class="flex gap-1">
          <.link
            navigate={~p"/trip/#{@itinerary.id}/all"}
            class={"btn btn-sm #{if @view_mode == :week, do: "btn-primary", else: "btn-ghost"}"}
          >
            All
          </.link>
          <%= for day <- @itinerary.days do %>
            <.link
              navigate={~p"/trip/#{@itinerary.id}/#{day.position + 1}"}
              class={"btn btn-sm #{if @selected_day == day.position + 1, do: "btn-primary", else: "btn-ghost"}"}
            >
              <%= format_column_header(day) %>
            </.link>
          <% end %>
          <button phx-click="add_day" class="btn btn-sm btn-ghost text-primary">+</button>
        </div>
      </div>

      <%!-- Calendar grid --%>
      <div id="trip-calendar" phx-hook="TripCalendarScroll" class="flex-1 overflow-auto">
        <div class="flex min-h-0">
          <%!-- Time axis (sticky left) --%>
          <div class="sticky left-0 z-10 bg-base-100 shrink-0 w-14 border-r border-base-300">
            <%!-- Spacer for column headers --%>
            <div class="h-10 border-b border-base-300"></div>
            <%!-- Hour labels --%>
            <div class="grid" style={"grid-template-rows: repeat(#{@total_rows}, 1.5rem)"}>
              <%= for hour <- @hours do %>
                <div
                  class="text-xs text-base-content/50 pr-2 text-right"
                  style={"grid-row: #{(hour - @hour_start) * @rows_per_hour + 1} / span 1"}
                >
                  <%= String.pad_leading("#{hour}", 2, "0") %>:00
                </div>
              <% end %>
            </div>
          </div>

          <%!-- Day columns --%>
          <div class={"flex #{if @view_mode == :day, do: "flex-1", else: ""}"}>
            <%= for day <- @days do %>
              <div class={"flex flex-col #{if @view_mode == :day, do: "flex-1", else: "w-48 shrink-0"}  border-r border-base-300 last:border-r-0"}>
                <%!-- Column header --%>
                <div class="h-10 flex items-center justify-center text-sm font-semibold border-b border-base-300 bg-base-200/50 px-2 text-center whitespace-nowrap">
                  <%= format_column_header(day) %>
                </div>
                <%!-- Events grid --%>
                <div class="relative grid" style={"grid-template-rows: repeat(#{@total_rows}, 1.5rem)"}>
                  <%!-- Hour grid lines (clickable to add item) --%>
                  <%= for hour <- @hours do %>
                    <div
                      class="border-t border-base-content/20 cursor-pointer hover:bg-primary/5"
                      style={"grid-row: #{(hour - @hour_start) * @rows_per_hour + 1} / span #{@rows_per_hour}"}
                      phx-click="add_item"
                      phx-value-hour={hour}
                      phx-value-day_id={day.id}
                    >
                    </div>
                  <% end %>
                  <%!-- Event blocks --%>
                  <%= for block <- event_blocks(day.items) do %>
                    <%= if @editing == block.item.id do %>
                      <%!-- Edit mode --%>
                      <div
                        class={"absolute inset-x-1 rounded-lg #{color_classes(block.item.color).bg_edit} border-l-4 #{color_classes(block.item.color).border} px-2 py-1 overflow-y-auto z-20"}
                        style={"top: calc((#{block.row_start} - 1) * 1.5rem); min-height: calc(#{max(block.row_end - block.row_start, @rows_per_hour * 3)} * 1.5rem);"}
                      >
                        <.form for={%{}} phx-submit="save_item" phx-value-item_id={block.item.id} class="space-y-1">
                          <div class="flex items-center gap-2">
                            <input
                              type="time"
                              name="time"
                              value={format_time(block.item.time_value)}
                              class="input input-xs input-bordered w-24 bg-base-100"
                            />
                            <span class="text-xs text-base-content/50">~</span>
                            <input
                              type="time"
                              name="end_time"
                              value={if block.item.end_time, do: format_time(block.item.end_time), else: ""}
                              class="input input-xs input-bordered w-24 bg-base-100"
                            />
                            <%= if @confirm_delete == block.item.id do %>
                              <button
                                type="button"
                                phx-click="confirm_delete_item"
                                phx-value-item_id={block.item.id}
                                class="btn btn-xs btn-error"
                              >
                                確定刪除？
                              </button>
                            <% else %>
                              <button
                                type="button"
                                phx-click="delete_item"
                                phx-value-item_id={block.item.id}
                                class="btn btn-xs btn-error btn-outline"
                              >
                                ✕
                              </button>
                            <% end %>
                          </div>
                          <div class="flex items-center gap-1.5">
                            <%= for c <- @color_options do %>
                              <label class="cursor-pointer">
                                <input
                                  type="radio"
                                  name="color"
                                  value={c}
                                  checked={c == (block.item.color || "primary")}
                                  class="hidden peer"
                                />
                                <div class={"w-5 h-5 rounded-full #{color_classes(c).dot} peer-checked:ring-2 peer-checked:ring-offset-2 peer-checked:#{color_classes(c).ring} ring-offset-base-100"}></div>
                              </label>
                            <% end %>
                          </div>
                          <input
                            type="text"
                            name="description"
                            value={block.item.description}
                            placeholder="標題"
                            class="input input-xs input-bordered w-full bg-base-100"
                            phx-hook="AutoFocus"
                            id={"edit-desc-#{block.item.id}"}
                          />
                          <textarea
                            name="sub_items"
                            rows="4"
                            placeholder="細項（每行一項）"
                            class="textarea textarea-bordered textarea-xs w-full bg-base-100 font-mono"
                            id={"edit-subs-#{block.item.id}"}
                          ><%= Enum.join(block.item.sub_items || [], "\n") %></textarea>
                          <div class="flex gap-1">
                            <button type="submit" class="btn btn-xs btn-primary">Save</button>
                            <button type="button" phx-click="cancel_edit" class="btn btn-xs btn-ghost">Cancel</button>
                          </div>
                        </.form>
                      </div>
                    <% else %>
                      <%!-- Display mode --%>
                      <div
                        class={"absolute inset-x-1 rounded-lg #{color_classes(block.item.color).bg} border-l-4 #{color_classes(block.item.color).border} px-2 py-1 overflow-y-auto cursor-pointer #{color_classes(block.item.color).hover} transition-colors z-10"}
                        style={"top: calc((#{block.row_start} - 1) * 1.5rem); height: calc((#{block.row_end} - #{block.row_start}) * 1.5rem);"}
                        phx-click="edit_item"
                        phx-value-item_id={block.item.id}
                      >
                        <div class="flex items-baseline gap-2">
                          <span class={"text-xs font-semibold #{color_classes(block.item.color).text} shrink-0"}>
                            <%= format_time(block.item.time_value) %>
                          </span>
                          <span class="text-sm font-bold leading-tight">
                            <%= render_markdown(block.item.description) %>
                          </span>
                        </div>
                        <%= if block.item.sub_items && block.item.sub_items != [] do %>
                          <div class="mt-1 space-y-0.5 text-xs leading-tight text-base-content/70">
                            <%= for sub <- block.item.sub_items do %>
                              <div class="pl-2">
                                <%= if String.starts_with?(sub, "🖊️") do %>
                                  <span class="text-base-content/50 italic">✏ <%= render_markdown(String.trim_leading(sub, "🖊️ ")) %></span>
                                <% else %>
                                  <%= render_markdown(sub) %>
                                <% end %>
                              </div>
                            <% end %>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <%!-- Day navigation (single day only) --%>
      <%= if @view_mode == :day do %>
        <div class="flex items-center justify-between px-4 py-2 border-t border-base-300 bg-base-100 shrink-0">
          <%= if @selected_day > 1 do %>
            <% prev_day = Enum.find(@itinerary.days, &(&1.position == @selected_day - 2)) %>
            <.link navigate={~p"/trip/#{@itinerary.id}/#{@selected_day - 1}"} class="btn btn-sm btn-ghost">
              ← <%= format_column_header(prev_day) %>
            </.link>
          <% else %>
            <div></div>
          <% end %>
          <.link navigate={~p"/trip/#{@itinerary.id}/all"} class="btn btn-sm btn-ghost">
            All
          </.link>
          <%= if @selected_day < @total_days do %>
            <% next_day = Enum.find(@itinerary.days, &(&1.position == @selected_day)) %>
            <.link navigate={~p"/trip/#{@itinerary.id}/#{@selected_day + 1}"} class="btn btn-sm btn-ghost">
              <%= format_column_header(next_day) %> →
            </.link>
          <% else %>
            <div></div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("add_day", _params, socket) do
    itinerary = socket.assigns.itinerary
    {:ok, day} = Itineraries.create_day(itinerary)
    new_day_number = day.position + 1

    {:noreply,
     socket
     |> push_navigate(to: ~p"/trip/#{itinerary.id}/#{new_day_number}")}
  end

  def handle_event("add_item", %{"hour" => hour_str, "day_id" => day_id_str}, socket) do
    hour = String.to_integer(hour_str)
    day_id = String.to_integer(day_id_str)
    time = Time.new!(hour, 0, 0)

    {:ok, item} = Itineraries.create_item(day_id, %{time_value: time, description: ""})

    {:noreply,
     socket
     |> reload_itinerary()
     |> assign(:editing, item.id)}
  end

  def handle_event("edit_item", %{"item_id" => item_id_str}, socket) do
    item_id = String.to_integer(item_id_str)
    {:noreply, socket |> assign(:editing, item_id) |> assign(:confirm_delete, nil)}
  end

  def handle_event("save_item", params, socket) do
    item = Itineraries.get_item!(String.to_integer(params["item_id"]))

    time_value =
      case Time.from_iso8601(params["time"] <> ":00") do
        {:ok, t} -> t
        _ -> item.time_value
      end

    end_time =
      case params["end_time"] do
        "" -> nil
        nil -> nil
        end_str ->
          case Time.from_iso8601(end_str <> ":00") do
            {:ok, t} -> t
            _ -> item.end_time
          end
      end

    sub_items =
      (params["sub_items"] || "")
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    color =
      case params["color"] do
        "primary" -> nil
        c when c in ["info", "success", "warning", "error"] -> c
        _ -> nil
      end

    Itineraries.update_item(item, %{
      time_value: time_value,
      end_time: end_time,
      color: color,
      description: params["description"] || "",
      sub_items: sub_items
    })

    {:noreply,
     socket
     |> reload_itinerary()
     |> assign(:editing, nil)}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, socket |> assign(:editing, nil) |> assign(:confirm_delete, nil)}
  end

  def handle_event("delete_item", %{"item_id" => item_id_str}, socket) do
    {:noreply, assign(socket, :confirm_delete, String.to_integer(item_id_str))}
  end

  def handle_event("confirm_delete_item", %{"item_id" => item_id_str}, socket) do
    item = Itineraries.get_item!(String.to_integer(item_id_str))
    Itineraries.delete_item(item)

    {:noreply,
     socket
     |> reload_itinerary()
     |> assign(:editing, nil)
     |> assign(:confirm_delete, nil)}
  end

  def handle_event("keydown", %{"key" => "Escape"}, socket) do
    {:noreply, assign(socket, :editing, nil)}
  end

  def handle_event("keydown", _params, socket) do
    {:noreply, socket}
  end
end
