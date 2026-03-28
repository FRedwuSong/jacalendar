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
        row_end = time_to_row(next.time_value)
        %{item: current, row_start: row_start, row_end: max(row_end, row_start + @rows_per_hour)}

      [current] ->
        row_start = time_to_row(current.time_value)
        %{item: current, row_start: row_start, row_end: row_start + @rows_per_hour}
    end)
  end

  defp format_time(%Time{} = t), do: Calendar.strftime(t, "%H:%M")

  defp format_column_header(day) do
    month = day.date.month
    d = day.date.day
    "#{month}/#{d} (#{day.weekday})"
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:hours, hours())
      |> assign(:hour_start, @hour_start)
      |> assign(:rows_per_hour, @rows_per_hour)
      |> assign(:total_rows, (@hour_end - @hour_start) * @rows_per_hour)

    ~H"""
    <div class="flex flex-col h-[calc(100vh-4rem)]">
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
                  <%!-- Hour grid lines --%>
                  <%= for hour <- @hours do %>
                    <div
                      class="border-t border-base-content/20"
                      style={"grid-row: #{(hour - @hour_start) * @rows_per_hour + 1} / span #{@rows_per_hour}"}
                    >
                    </div>
                  <% end %>
                  <%!-- Event blocks --%>
                  <%= for block <- event_blocks(day.items) do %>
                    <div
                      class="absolute inset-x-1 rounded-lg bg-primary/15 border-l-4 border-primary px-2 py-1 overflow-y-auto cursor-default hover:bg-primary/25 transition-colors"
                      style={"top: calc((#{block.row_start} - 1) * 1.5rem); height: calc((#{block.row_end} - #{block.row_start}) * 1.5rem);"}
                    >
                      <div class="flex items-baseline gap-2">
                        <span class="text-xs font-semibold text-primary shrink-0">
                          <%= format_time(block.item.time_value) %>
                        </span>
                        <span class="text-sm font-bold leading-tight">
                          <%= block.item.description %>
                        </span>
                      </div>
                      <%= if block.item.sub_items && block.item.sub_items != [] do %>
                        <div class="mt-1 space-y-0.5 text-xs leading-tight text-base-content/70">
                          <%= for sub <- block.item.sub_items do %>
                            <div class="pl-2">
                              <%= if String.starts_with?(sub, "🖊️") do %>
                                <span class="text-base-content/50 italic">✏ <%= String.trim_leading(sub, "🖊️ ") %></span>
                              <% else %>
                                <%= sub %>
                              <% end %>
                            </div>
                          <% end %>
                        </div>
                      <% end %>
                    </div>
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
end
