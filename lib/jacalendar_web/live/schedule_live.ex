defmodule JacalendarWeb.ScheduleLive do
  use JacalendarWeb, :live_view

  alias Jacalendar.MarkdownParser
  alias Phoenix.LiveView.JS

  @fuzzy_labels %{
    morning: "早上",
    afternoon: "下午",
    evening: "晚上"
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:mode, :input)
     |> assign(:itinerary, nil)
     |> assign(:current_time, nil)
     |> assign(:current_date, nil)
     |> assign(:editing, nil)
     |> assign(:parse_error, nil)
     |> allow_upload(:markdown_file, accept: ~w(.md .txt .markdown), max_entries: 1)}
  end

  @impl true
  def handle_event("parse", %{"markdown" => markdown}, socket) do
    case MarkdownParser.parse(markdown) do
      {:ok, itinerary} ->
        socket =
          socket
          |> assign(:mode, :schedule)
          |> assign(:itinerary, itinerary)
          |> assign(:parse_error, nil)

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, assign(socket, :parse_error, reason)}
    end
  end

  def handle_event("validate_upload", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("load_path", %{"path" => path}, socket) do
    path = String.trim(path)

    case File.read(path) do
      {:ok, content} ->
        case MarkdownParser.parse(content) do
          {:ok, itinerary} ->
            {:noreply,
             socket
             |> assign(:mode, :schedule)
             |> assign(:itinerary, itinerary)
             |> assign(:parse_error, nil)}

          {:error, reason} ->
            {:noreply, assign(socket, :parse_error, reason)}
        end

      {:error, reason} ->
        {:noreply, assign(socket, :parse_error, "無法讀取檔案: #{inspect(reason)}")}
    end
  end

  def handle_event("upload", _params, socket) do
    [markdown] =
      consume_uploaded_entries(socket, :markdown_file, fn %{path: path}, _entry ->
        {:ok, File.read!(path)}
      end)

    case MarkdownParser.parse(markdown) do
      {:ok, itinerary} ->
        {:noreply,
         socket
         |> assign(:mode, :schedule)
         |> assign(:itinerary, itinerary)
         |> assign(:parse_error, nil)}

      {:error, reason} ->
        {:noreply, assign(socket, :parse_error, reason)}
    end
  end

  def handle_event("back_to_input", _params, socket) do
    {:noreply,
     socket
     |> assign(:mode, :input)
     |> assign(:itinerary, nil)
     |> assign(:editing, nil)}
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

  def handle_event("edit_time", %{"day-idx" => day_idx_str, "item-idx" => item_idx_str}, socket) do
    day_idx = String.to_integer(day_idx_str)
    item_idx = String.to_integer(item_idx_str)
    {:noreply, assign(socket, :editing, {:time, day_idx, item_idx})}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, :editing, nil)}
  end

  def handle_event("edit_description", %{"day-idx" => di, "item-idx" => ii}, socket) do
    {:noreply,
     assign(socket, :editing, {:description, String.to_integer(di), String.to_integer(ii)})}
  end

  def handle_event("edit_sub_item", %{"day-idx" => di, "item-idx" => ii, "sub-idx" => si}, socket) do
    {:noreply,
     assign(
       socket,
       :editing,
       {:sub_item, String.to_integer(di), String.to_integer(ii), String.to_integer(si)}
     )}
  end

  def handle_event(
        "save_sub_item",
        %{"day-idx" => di, "item-idx" => ii, "sub-idx" => si, "value" => value},
        socket
      ) do
    day_idx = String.to_integer(di)
    item_idx = String.to_integer(ii)
    sub_idx = String.to_integer(si)

    itinerary = update_sub_item(socket.assigns.itinerary, day_idx, item_idx, sub_idx, value)

    {:noreply,
     socket
     |> assign(:itinerary, itinerary)
     |> assign(:editing, nil)}
  end

  def handle_event("add_sub_item", %{"day-idx" => di, "item-idx" => ii}, socket) do
    {:noreply,
     assign(socket, :editing, {:new_sub_item, String.to_integer(di), String.to_integer(ii)})}
  end

  def handle_event(
        "save_new_sub_item",
        %{"day-idx" => di, "item-idx" => ii, "value" => value},
        socket
      ) do
    day_idx = String.to_integer(di)
    item_idx = String.to_integer(ii)

    if String.trim(value) == "" do
      {:noreply, assign(socket, :editing, nil)}
    else
      itinerary = append_sub_item(socket.assigns.itinerary, day_idx, item_idx, String.trim(value))

      {:noreply,
       socket
       |> assign(:itinerary, itinerary)
       |> assign(:editing, nil)}
    end
  end

  def handle_event(
        "delete_sub_item",
        %{"day-idx" => di, "item-idx" => ii, "sub-idx" => si},
        socket
      ) do
    day_idx = String.to_integer(di)
    item_idx = String.to_integer(ii)
    sub_idx = String.to_integer(si)

    itinerary = delete_sub_item(socket.assigns.itinerary, day_idx, item_idx, sub_idx)

    {:noreply,
     socket
     |> assign(:itinerary, itinerary)
     |> assign(:editing, nil)}
  end

  def handle_event(
        "save_description",
        %{"day-idx" => di, "item-idx" => ii, "value" => value},
        socket
      ) do
    day_idx = String.to_integer(di)
    item_idx = String.to_integer(ii)

    itinerary =
      update_item_field(socket.assigns.itinerary, day_idx, item_idx, :description, value)

    {:noreply,
     socket
     |> assign(:itinerary, itinerary)
     |> assign(:editing, nil)}
  end

  def handle_event(
        "save_time",
        %{"day-idx" => day_idx_str, "item-idx" => item_idx_str, "time" => time_str},
        socket
      ) do
    day_idx = String.to_integer(day_idx_str)
    item_idx = String.to_integer(item_idx_str)

    case parse_time_input(time_str) do
      {:ok, time} ->
        itinerary = update_item_time(socket.assigns.itinerary, day_idx, item_idx, time)

        {:noreply,
         socket
         |> assign(:itinerary, itinerary)
         |> assign(:editing, nil)}

      :error ->
        {:noreply, socket}
    end
  end

  defp append_sub_item(itinerary, day_idx, item_idx, value) do
    days =
      List.update_at(itinerary.days, day_idx, fn day ->
        items =
          List.update_at(day.items, item_idx, fn item ->
            %{item | sub_items: item.sub_items ++ [value]}
          end)

        %{day | items: items}
      end)

    %{itinerary | days: days}
  end

  defp delete_sub_item(itinerary, day_idx, item_idx, sub_idx) do
    days =
      List.update_at(itinerary.days, day_idx, fn day ->
        items =
          List.update_at(day.items, item_idx, fn item ->
            %{item | sub_items: List.delete_at(item.sub_items, sub_idx)}
          end)

        %{day | items: items}
      end)

    %{itinerary | days: days}
  end

  defp update_sub_item(itinerary, day_idx, item_idx, sub_idx, value) do
    days =
      List.update_at(itinerary.days, day_idx, fn day ->
        items =
          List.update_at(day.items, item_idx, fn item ->
            %{item | sub_items: List.replace_at(item.sub_items, sub_idx, value)}
          end)

        %{day | items: items}
      end)

    %{itinerary | days: days}
  end

  defp update_item_field(itinerary, day_idx, item_idx, field, value) do
    days =
      List.update_at(itinerary.days, day_idx, fn day ->
        items = List.update_at(day.items, item_idx, fn item -> Map.put(item, field, value) end)
        %{day | items: items}
      end)

    %{itinerary | days: days}
  end

  defp parse_time_input(time_str) do
    case String.split(time_str, ":") do
      [h, m] ->
        {:ok, Time.new!(String.to_integer(h), String.to_integer(m), 0)}

      _ ->
        :error
    end
  end

  defp update_item_time(itinerary, day_idx, item_idx, time) do
    days =
      itinerary.days
      |> Enum.with_index()
      |> Enum.map(fn {day, di} ->
        if di == day_idx do
          items =
            day.items
            |> Enum.with_index()
            |> Enum.map(fn {item, ii} ->
              if ii == item_idx do
                %{item | time: {:exact, time}}
              else
                item
              end
            end)
            |> Enum.sort_by(fn item ->
              case item.time do
                {:exact, t} -> {0, Time.to_erl(t)}
                {:fuzzy, :morning} -> {1, {6, 0, 0}}
                {:fuzzy, :afternoon} -> {1, {12, 0, 0}}
                {:fuzzy, :evening} -> {1, {18, 0, 0}}
                :pending -> {2, {23, 59, 0}}
              end
            end)

          %{day | items: items}
        else
          day
        end
      end)

    %{itinerary | days: days}
  end

  defp time_display(item) do
    case item.time do
      {:exact, t} -> Calendar.strftime(t, "%H:%M")
      {:fuzzy, period} -> Map.get(@fuzzy_labels, period, "")
      :pending -> nil
    end
  end

  defp editable?(item) do
    case item.time do
      {:exact, _} -> false
      _ -> true
    end
  end

  defp item_before_time?(item, current_time) do
    case item.time do
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
                <p :if={@itinerary.date_range} class="text-base-content/60 text-sm mt-1">
                  {elem(@itinerary.date_range, 0)} ~ {elem(@itinerary.date_range, 1)}
                </p>
              </div>
              <button phx-click="back_to_input" class="btn btn-ghost btn-sm">
                <.icon name="hero-arrow-left" class="size-4" /> 重新輸入
              </button>
            </div>

            <%!-- Metadata --%>
            <div
              :if={@itinerary.metadata}
              id="metadata-section"
              class="grid grid-cols-1 sm:grid-cols-2 gap-3"
            >
              <div
                :if={@itinerary.metadata.flights != []}
                class="card card-compact bg-base-200 shadow-sm"
              >
                <div class="card-body">
                  <h3 class="card-title text-sm">
                    <.icon name="hero-paper-airplane" class="size-4" /> 航班
                  </h3>
                  <div :for={flight <- @itinerary.metadata.flights} class="text-sm">
                    <span class="font-medium">
                      {if flight.direction == :outbound, do: "去程", else: "回程"}
                    </span>
                    <span class="text-base-content/70">
                      {flight.flight_number} · {flight.date}
                    </span>
                  </div>
                </div>
              </div>

              <div
                :if={@itinerary.metadata.hotel && @itinerary.metadata.hotel.name}
                class="card card-compact bg-base-200 shadow-sm"
              >
                <div class="card-body">
                  <h3 class="card-title text-sm">
                    <.icon name="hero-building-office" class="size-4" /> 住宿
                  </h3>
                  <p class="text-sm font-medium">{@itinerary.metadata.hotel.name}</p>
                  <p :if={@itinerary.metadata.hotel.address} class="text-xs text-base-content/60">
                    {@itinerary.metadata.hotel.address}
                  </p>
                </div>
              </div>
            </div>

            <%!-- Days --%>
            <div :for={{day, day_idx} <- Enum.with_index(@itinerary.days)} class="space-y-2">
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

              <div id={"day-#{day_idx}"} class="space-y-1">
                <%= for {item, item_idx} <- Enum.with_index(day.items) do %>
                  <% item_id = "#{day_idx}-#{item_idx}" %>
                  <% next_item = Enum.at(day.items, item_idx + 1) %>

                  <div
                    id={"item-#{item_id}"}
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
                      <%= if @editing == {:time, day_idx, item_idx} do %>
                        <.form
                          for={%{}}
                          id={"time-form-#{item_id}"}
                          phx-submit="save_time"
                          class="flex"
                        >
                          <input type="hidden" name="day-idx" value={day_idx} />
                          <input type="hidden" name="item-idx" value={item_idx} />
                          <input
                            type="time"
                            name="time"
                            id={"time-input-#{item_id}"}
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
                            phx-value-day-idx={day_idx}
                            phx-value-item-idx={item_idx}
                          >
                            {time_display(item)}
                          </span>
                        <% else %>
                          <button
                            class="badge badge-warning badge-sm cursor-pointer hover:badge-primary"
                            phx-click="edit_time"
                            phx-value-day-idx={day_idx}
                            phx-value-item-idx={item_idx}
                          >
                            待定
                          </button>
                        <% end %>
                      <% end %>
                    </div>

                    <%!-- Content column --%>
                    <div class="flex-1 min-w-0">
                      <%= if @editing == {:description, day_idx, item_idx} do %>
                        <.form
                          for={%{}}
                          phx-submit="save_description"
                          id={"desc-form-#{item_id}"}
                        >
                          <input type="hidden" name="day-idx" value={day_idx} />
                          <input type="hidden" name="item-idx" value={item_idx} />
                          <input
                            type="text"
                            name="value"
                            value={item.description}
                            id={"desc-input-#{item_id}"}
                            class="input input-xs input-bordered w-full text-sm"
                            phx-blur={JS.dispatch("submit", to: "#desc-form-#{item_id}")}
                            phx-keydown="cancel_edit"
                            phx-key="Escape"
                            autofocus
                          />
                        </.form>
                      <% else %>
                        <p
                          class="text-sm cursor-pointer hover:text-primary"
                          phx-click="edit_description"
                          phx-value-day-idx={day_idx}
                          phx-value-item-idx={item_idx}
                        >
                          {item.description}
                        </p>
                      <% end %>
                      <div :if={item.sub_items != []} class="mt-1 space-y-0.5">
                        <%= for {sub, sub_idx} <- Enum.with_index(item.sub_items) do %>
                          <div class="flex items-center gap-1 group">
                            <%= if @editing == {:sub_item, day_idx, item_idx, sub_idx} do %>
                              <.form
                                for={%{}}
                                phx-submit="save_sub_item"
                                id={"sub-form-#{item_id}-#{sub_idx}"}
                                class="flex-1"
                              >
                                <input type="hidden" name="day-idx" value={day_idx} />
                                <input type="hidden" name="item-idx" value={item_idx} />
                                <input type="hidden" name="sub-idx" value={sub_idx} />
                                <input
                                  type="text"
                                  name="value"
                                  value={sub}
                                  id={"sub-input-#{item_id}-#{sub_idx}"}
                                  class="input input-xs input-bordered w-full text-xs"
                                  phx-blur={
                                    JS.dispatch("submit", to: "#sub-form-#{item_id}-#{sub_idx}")
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
                                phx-value-day-idx={day_idx}
                                phx-value-item-idx={item_idx}
                                phx-value-sub-idx={sub_idx}
                              >
                                {sub}
                              </p>
                              <button
                                class="btn btn-ghost btn-xs opacity-0 group-hover:opacity-100 text-error"
                                phx-click="delete_sub_item"
                                phx-value-day-idx={day_idx}
                                phx-value-item-idx={item_idx}
                                phx-value-sub-idx={sub_idx}
                              >
                                <.icon name="hero-x-mark" class="size-3" />
                              </button>
                            <% end %>
                          </div>
                        <% end %>
                      </div>
                      <%= if @editing == {:new_sub_item, day_idx, item_idx} do %>
                        <.form
                          for={%{}}
                          phx-submit="save_new_sub_item"
                          id={"new-sub-form-#{item_id}"}
                          class="mt-1"
                        >
                          <input type="hidden" name="day-idx" value={day_idx} />
                          <input type="hidden" name="item-idx" value={item_idx} />
                          <input
                            type="text"
                            name="value"
                            id={"new-sub-input-#{item_id}"}
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
                          phx-value-day-idx={day_idx}
                          phx-value-item-idx={item_idx}
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
