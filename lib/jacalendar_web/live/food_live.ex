defmodule JacalendarWeb.FoodLive do
  use JacalendarWeb, :live_view

  alias Jacalendar.Food
  alias Jacalendar.FoodParser
  alias Jacalendar.Itineraries

  @impl true
  def mount(_params, _session, socket) do
    restaurants = Food.list_restaurants()
    daily_picks = Food.list_daily_picks()
    has_data = Food.has_data?()

    # Find the most recent itinerary for tab navigation and header
    itinerary = Itineraries.list_itineraries() |> List.first()

    # Build unique days from daily_picks for the filter bar
    days =
      daily_picks
      |> Enum.map(fn p -> %{date: p.day_date, label: p.day_label} end)
      |> Enum.uniq_by(& &1.date)
      |> Enum.sort_by(& &1.date, Date)

    # Group restaurants by category
    categories =
      restaurants
      |> Enum.group_by(& &1.category)
      |> Enum.sort_by(fn {cat, _} ->
        Enum.find_index(["甜點", "烤魚定食", "鰻魚", "拉麵"], &(&1 == cat)) || 99
      end)

    {:ok,
     socket
     |> assign(:has_data, has_data)
     |> assign(:restaurants, restaurants)
     |> assign(:daily_picks, daily_picks)
     |> assign(:days, days)
     |> assign(:categories, categories)
     |> assign(:selected_day, nil)
     |> assign(:import_mode, false)
     |> assign(:import_error, nil)
     |> assign(:itinerary, itinerary)
     |> assign(:itinerary_id, itinerary && itinerary.id)
     |> allow_upload(:markdown_file, accept: ~w(.md .txt .markdown), max_entries: 1)}
  end

  @impl true
  def handle_event("select_day", %{"day" => "all"}, socket) do
    {:noreply, assign(socket, :selected_day, nil)}
  end

  @impl true
  def handle_event("select_day", %{"day" => date_str}, socket) do
    date = Date.from_iso8601!(date_str)
    {:noreply, assign(socket, :selected_day, date)}
  end

  @impl true
  def handle_event("show_import", _, socket) do
    {:noreply, assign(socket, :import_mode, true)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("import", _params, socket) do
    markdown =
      consume_uploaded_entries(socket, :markdown_file, fn %{path: path}, _entry ->
        {:ok, File.read!(path)}
      end)
      |> List.first()

    if markdown do
      do_import(socket, markdown)
    else
      {:noreply, assign(socket, :import_error, "請選擇一個 Markdown 檔案")}
    end
  end

  defp do_import(socket, markdown) do
    case FoodParser.parse(markdown) do
      {:ok, data} ->
        {:ok, _} = Food.import_food(data)

        restaurants = Food.list_restaurants()
        daily_picks = Food.list_daily_picks()

        days =
          daily_picks
          |> Enum.map(fn p -> %{date: p.day_date, label: p.day_label} end)
          |> Enum.uniq_by(& &1.date)
          |> Enum.sort_by(& &1.date, Date)

        categories =
          restaurants
          |> Enum.group_by(& &1.category)
          |> Enum.sort_by(fn {cat, _} ->
            Enum.find_index(["甜點", "烤魚定食", "鰻魚", "拉麵"], &(&1 == cat)) || 99
          end)

        {:noreply,
         socket
         |> assign(:has_data, true)
         |> assign(:restaurants, restaurants)
         |> assign(:daily_picks, daily_picks)
         |> assign(:days, days)
         |> assign(:categories, categories)
         |> assign(:import_mode, false)
         |> assign(:import_error, nil)}

      {:error, reason} ->
        {:noreply, assign(socket, :import_error, reason)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-3xl mx-auto space-y-6">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold tracking-tight">{if @itinerary, do: @itinerary.title, else: "美食推薦"}</h1>
            <p :if={@itinerary && @itinerary.date_range_start} class="text-base-content/60 text-sm mt-1">
              {@itinerary.date_range_start} ~ {@itinerary.date_range_end}
            </p>
          </div>
          <.link navigate="/" class="btn btn-ghost btn-sm">
            <.icon name="hero-arrow-left" class="size-4" /> 返回列表
          </.link>
        </div>

        <.itinerary_tabs :if={@itinerary_id} itinerary_id={@itinerary_id} active={:food} />

        <%= if @has_data do %>
          <%!-- Day filter bar --%>
          <div class="flex gap-2 overflow-x-auto pb-2 scrollbar-none">
            <button
              phx-click="select_day"
              phx-value-day="all"
              class={[
                "btn btn-sm shrink-0",
                if(@selected_day == nil, do: "btn-active btn-primary", else: "btn-ghost")
              ]}
            >
              全部
            </button>
            <button
              :for={day <- @days}
              phx-click="select_day"
              phx-value-day={Date.to_iso8601(day.date)}
              class={[
                "btn btn-sm shrink-0 flex flex-col items-center leading-tight h-auto py-1.5",
                if(@selected_day == day.date, do: "btn-active btn-primary", else: "btn-ghost")
              ]}
            >
              <span class="text-xs font-mono">{Calendar.strftime(day.date, "%m/%d")}</span>
            </button>
          </div>

          <%= if @selected_day == nil do %>
            <%!-- All view: grouped by category --%>
            <div :for={{category, restaurants} <- @categories} class="space-y-3">
              <h2 class="text-lg font-semibold flex items-center gap-2">
                <span class="badge badge-primary badge-sm">{category}</span>
                <span class="text-base-content/40 text-sm">{length(restaurants)} 間</span>
              </h2>
              <div class="space-y-3">
                <.restaurant_card :for={r <- restaurants} restaurant={r} />
              </div>
            </div>
          <% else %>
            <%!-- Per-day view --%>
            <% day_picks = Enum.filter(@daily_picks, & &1.day_date == @selected_day) %>
            <% day_label = Enum.find_value(@days, fn d -> if d.date == @selected_day, do: d.label end) %>
            <h2 :if={day_label} class="text-base font-medium text-base-content/70">{day_label}</h2>
            <%= if day_picks == [] do %>
              <div class="text-center py-8 text-base-content/40">
                <p>這天沒有特別推薦的餐廳</p>
              </div>
            <% else %>
              <div class="space-y-3">
                <div :for={pick <- day_picks} class="space-y-1">
                  <div class="flex items-center gap-2">
                    <span class={[
                      "badge badge-sm",
                      if(pick.priority == "主選", do: "badge-primary", else: "badge-ghost")
                    ]}>
                      {pick.priority}
                    </span>
                    <span class="text-sm font-medium">{pick.restaurant_name}</span>
                  </div>
                  <% matched = Enum.find(@restaurants, & &1.name == pick.restaurant_name) %>
                  <.restaurant_card :if={matched} restaurant={matched} />
                  <%!-- For picks with multiple restaurants (e.g. "A / B"), try matching each --%>
                  <%= if matched == nil and String.contains?(pick.restaurant_name, " / ") do %>
                    <% names = String.split(pick.restaurant_name, " / ") %>
                    <% matched_list = Enum.filter(@restaurants, fn r -> r.name in names end) %>
                    <.restaurant_card :for={r <- matched_list} restaurant={r} />
                  <% end %>
                </div>
              </div>
            <% end %>
          <% end %>

          <%!-- Re-import button --%>
          <div class="text-center pt-4">
            <button phx-click="show_import" class="btn btn-ghost btn-sm text-base-content/40">
              <.icon name="hero-arrow-path" class="size-4" /> 重新匯入美食資訊
            </button>
          </div>

          <%= if @import_mode do %>
            <div class="card bg-base-200 p-6">
              <.import_form upload={@uploads.markdown_file} import_error={@import_error} />
            </div>
          <% end %>
        <% else %>
          <%!-- Empty state --%>
          <%= if @import_mode do %>
            <.import_form upload={@uploads.markdown_file} import_error={@import_error} />
          <% else %>
            <div class="text-center py-12 text-base-content/40">
              <.icon name="hero-cake" class="size-12 mx-auto mb-3" />
              <p class="mb-4">尚未匯入美食推薦</p>
              <button phx-click="show_import" class="btn btn-primary btn-sm">
                匯入美食 Markdown
              </button>
            </div>
          <% end %>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  attr :restaurant, :map, required: true

  defp restaurant_card(assigns) do
    ~H"""
    <a
      href={"https://www.google.com/maps/dir/?api=1&destination=#{URI.encode(@restaurant.address)}"}
      target="_blank"
      class="card bg-base-200/50 p-4 space-y-1.5 hover:bg-base-200 transition-colors block"
    >
      <div class="flex items-start justify-between gap-2">
        <div>
          <p class="font-semibold text-sm">{@restaurant.name}</p>
          <div class="flex items-center gap-2 mt-0.5">
            <span class="badge badge-outline badge-xs">{@restaurant.category}</span>
            <span :if={@restaurant.area} class="text-xs text-base-content/60">{@restaurant.area}</span>
          </div>
        </div>
        <span class="text-primary shrink-0">
          <.icon name="hero-map-pin" class="size-4" />
        </span>
      </div>
      <p :if={@restaurant.price_range} class="text-xs text-warning">{@restaurant.price_range}</p>
      <p :if={@restaurant.hours} class="text-xs text-base-content/60">{@restaurant.hours}</p>
      <p :if={@restaurant.reason} class="text-xs text-base-content/50 italic">{@restaurant.reason}</p>
    </a>
    """
  end

  attr :upload, :any, required: true
  attr :import_error, :string, default: nil

  defp import_form(assigns) do
    ~H"""
    <form phx-submit="import" phx-change="validate" class="space-y-4">
      <div>
        <label class="label text-sm font-medium">上傳美食推薦 Markdown 檔案</label>
        <div class="flex items-center gap-3">
          <.live_file_input upload={@upload} class="file-input file-input-bordered file-input-sm w-full" />
        </div>
        <div :for={entry <- @upload.entries} class="text-sm text-base-content/60 mt-2">
          {entry.client_name}
          <span :if={entry.progress > 0} class="text-xs">({entry.progress}%)</span>
        </div>
        <div :for={err <- upload_errors(@upload)} class="text-error text-sm mt-1">
          {upload_error_message(err)}
        </div>
      </div>
      <p :if={@import_error} class="text-error text-sm">{@import_error}</p>
      <button type="submit" class="btn btn-primary btn-sm" disabled={@upload.entries == []}>
        匯入
      </button>
    </form>
    """
  end

  defp upload_error_message(:too_large), do: "檔案太大"
  defp upload_error_message(:too_many_files), do: "只能上傳一個檔案"
  defp upload_error_message(:not_accepted), do: "僅接受 .md / .txt 檔案"
  defp upload_error_message(_), do: "上傳錯誤"
end
