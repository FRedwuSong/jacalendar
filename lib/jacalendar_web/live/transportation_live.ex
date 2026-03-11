defmodule JacalendarWeb.TransportationLive do
  use JacalendarWeb, :live_view

  alias Jacalendar.Itineraries
  alias Jacalendar.TransportParser

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    itinerary = Itineraries.get_itinerary!(id)

    {:ok,
     socket
     |> assign(:itinerary, itinerary)
     |> assign(:has_transport_data, has_transport_data?(itinerary))
     |> assign(:import_mode, false)
     |> assign(:import_error, nil)
     |> assign(:expanded, MapSet.new())
     |> allow_upload(:markdown_file, accept: ~w(.md .txt .markdown), max_entries: 1)}
  end

  defp has_transport_data?(itinerary) do
    itinerary.transport_sections != [] or
      itinerary.transport_routes != [] or
      itinerary.taxi_address_cards != []
  end

  @impl true
  def handle_event("show_import", _, socket) do
    {:noreply, assign(socket, :import_mode, true)}
  end

  @impl true
  def handle_event("import", _params, socket) do
    # Read uploaded file content
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
    case TransportParser.parse(markdown) do
      {:ok, data} ->
        {:ok, _} = Itineraries.import_transportation(socket.assigns.itinerary.id, data)
        itinerary = Itineraries.get_itinerary!(socket.assigns.itinerary.id)

        {:noreply,
         socket
         |> assign(:itinerary, itinerary)
         |> assign(:has_transport_data, true)
         |> assign(:import_mode, false)
         |> assign(:import_error, nil)}

      {:error, reason} ->
        {:noreply, assign(socket, :import_error, reason)}
    end
  end

  @impl true
  def handle_event("toggle_section", %{"id" => id}, socket) do
    expanded = socket.assigns.expanded

    expanded =
      if MapSet.member?(expanded, id) do
        MapSet.delete(expanded, id)
      else
        MapSet.put(expanded, id)
      end

    {:noreply, assign(socket, :expanded, expanded)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-3xl mx-auto space-y-6">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold tracking-tight">{@itinerary.title}</h1>
            <p :if={@itinerary.date_range_start} class="text-base-content/60 text-sm mt-1">
              {@itinerary.date_range_start} ~ {@itinerary.date_range_end}
            </p>
          </div>
          <.link navigate="/" class="btn btn-ghost btn-sm">
            <.icon name="hero-arrow-left" class="size-4" /> 返回列表
          </.link>
        </div>

        <.itinerary_tabs itinerary_id={@itinerary.id} active={:transportation} />

        <%= if @has_transport_data do %>
          <%!-- Transport Sections --%>
          <div :if={@itinerary.transport_sections != []} class="space-y-2">
            <div :for={section <- @itinerary.transport_sections} class="collapse collapse-arrow bg-base-200/50 rounded-lg">
              <input
                type="checkbox"
                checked={MapSet.member?(@expanded, "section-#{section.id}")}
                phx-click="toggle_section"
                phx-value-id={"section-#{section.id}"}
              />
              <div class="collapse-title font-medium flex items-center gap-2">
                {section_emoji(section.section_type)} {section.title}
              </div>
              <div class="collapse-content">
                <div class="text-sm text-base-content/80 space-y-1">
                  {render_markdown(section.content)}
                </div>
              </div>
            </div>
          </div>

          <%!-- Daily Routes --%>
          <div :if={@itinerary.transport_routes != []} class="space-y-2">
            <h2 class="text-lg font-semibold">每日交通路線</h2>
            <div :for={route <- @itinerary.transport_routes} class="collapse collapse-arrow bg-base-200/50 rounded-lg">
              <input
                type="checkbox"
                checked={MapSet.member?(@expanded, "route-#{route.id}")}
                phx-click="toggle_section"
                phx-value-id={"route-#{route.id}"}
              />
              <div class="collapse-title font-medium">
                <span class="badge badge-primary badge-sm mr-2">{format_route_date(route)}</span>
                {route.title}
              </div>
              <div class="collapse-content">
                <div class="space-y-4 pt-1">
                  <div
                    :for={seg <- route.segments}
                    class="flex gap-3 items-start pl-3 border-l-2 border-primary/30"
                  >
                    <div class={"badge badge-sm badge-outline shrink-0 mt-0.5 " <> method_badge_class(seg["method"])}>
                      {method_label(seg["method"])}
                    </div>
                    <div class="flex-1 min-w-0">
                      <p class="font-medium text-sm">
                        {seg["from"]}
                        <span :if={seg["to"] != ""} class="text-base-content/40"> → </span>
                        <span :if={seg["to"] != ""}>{seg["to"]}</span>
                      </p>
                      <p :if={seg["cost"]} class="text-xs text-warning mt-0.5">{seg["cost"]}</p>
                      <div class="text-xs text-base-content/60 mt-1 space-y-0.5">
                        {render_markdown(seg["details"])}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <%!-- Address Cards --%>
          <div :if={@itinerary.taxi_address_cards != []} class="space-y-2">
            <h2 class="text-lg font-semibold">地址卡</h2>
            <p class="text-sm text-base-content/50">點擊導航，從目前位置出發</p>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <a
                :for={card <- @itinerary.taxi_address_cards}
                href={"https://www.google.com/maps/dir/?api=1&destination=#{URI.encode(card.address)}"}
                target="_blank"
                class="card bg-base-200/50 p-4 space-y-1.5 hover:bg-base-200 transition-colors"
              >
                <div class="flex items-start justify-between gap-2">
                  <p class="font-semibold text-sm">{card.name}</p>
                  <span class="text-primary shrink-0">
                    <.icon name="hero-map-pin" class="size-4" />
                  </span>
                </div>
                <p :if={card.name_ja} class="text-sm text-base-content/70">{card.name_ja}</p>
                <p class="text-sm font-mono text-base-content/60">{card.address}</p>
                <p :if={card.note} class="text-xs text-base-content/40 italic">{card.note}</p>
              </a>
            </div>
          </div>

          <%!-- Re-import button --%>
          <div class="text-center pt-4">
            <button phx-click="show_import" class="btn btn-ghost btn-sm text-base-content/40">
              <.icon name="hero-arrow-path" class="size-4" /> 重新匯入交通資訊
            </button>
          </div>

          <%!-- Re-import form --%>
          <%= if @import_mode do %>
            <div class="card bg-base-200 p-6">
              <.import_form upload={@uploads.markdown_file} import_error={@import_error} />
            </div>
          <% end %>
        <% else %>
          <%!-- Empty state or import mode --%>
          <%= if @import_mode do %>
            <.import_form upload={@uploads.markdown_file} import_error={@import_error} />
          <% else %>
            <div class="text-center py-12 text-base-content/40">
              <.icon name="hero-map" class="size-12 mx-auto mb-3" />
              <p class="mb-4">此行程尚未匯入交通資訊</p>
              <button phx-click="show_import" class="btn btn-primary btn-sm">
                匯入交通 Markdown
              </button>
            </div>
          <% end %>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  attr :upload, :any, required: true
  attr :import_error, :string, default: nil

  defp import_form(assigns) do
    ~H"""
    <form phx-submit="import" phx-change="validate" class="space-y-4">
      <div>
        <label class="label text-sm font-medium">上傳交通 Markdown 檔案</label>
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

  defp format_route_date(%{day_date: %Date{} = date}),
    do: "#{date.day}"

  defp format_route_date(route), do: route.day_label

  defp section_emoji("tools"), do: "📱"
  defp section_emoji("hotel_transport"), do: "🏨"
  defp section_emoji("daily_task"), do: "☕"
  defp section_emoji("tips"), do: "💡"
  defp section_emoji(_), do: ""

  defp method_label("metro"), do: "地鐵"
  defp method_label("taxi"), do: "計程車"
  defp method_label("walk"), do: "步行"
  defp method_label(_), do: "其他"

  defp method_badge_class("metro"), do: "badge-info"
  defp method_badge_class("taxi"), do: "badge-warning"
  defp method_badge_class("walk"), do: "badge-success"
  defp method_badge_class(_), do: ""

  # Simple markdown to Phoenix-safe HTML rendering
  defp render_markdown(nil), do: ""

  defp render_markdown(text) do
    text
    |> String.split("\n")
    |> Enum.map(&String.trim_trailing/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&render_line/1)
    |> Phoenix.HTML.raw()
  end

  defp render_line(line) do
    trimmed = String.trim(line)

    cond do
      # Sub-heading ###
      String.starts_with?(trimmed, "### ") ->
        text = String.trim_leading(trimmed, "### ") |> clean_inline()
        "<p class=\"font-semibold text-sm mt-3 mb-1\">#{text}</p>"

      # Numbered list item
      Regex.match?(~r/^\d+\.\s+/, trimmed) ->
        text = Regex.replace(~r/^\d+\.\s+/, trimmed, "") |> clean_inline()
        "<div class=\"flex gap-2 items-start py-0.5\"><span class=\"text-base-content/40 shrink-0\">•</span><span>#{text}</span></div>"

      # Deep nested bullet (8+ spaces or 2 tabs)
      Regex.match?(~r/^(\s{8,}|\t{2,})\*\s+/, line) ->
        text = Regex.replace(~r/^\s+\*\s+/, line, "") |> clean_inline()
        "<div class=\"flex gap-2 items-start py-0.5 pl-8\"><span class=\"text-base-content/30 shrink-0\">‣</span><span>#{text}</span></div>"

      # Nested bullet (4+ spaces or tab)
      Regex.match?(~r/^(\s{4,}|\t)\*\s+/, line) ->
        text = Regex.replace(~r/^\s+\*\s+/, line, "") |> clean_inline()
        "<div class=\"flex gap-2 items-start py-0.5 pl-4\"><span class=\"text-base-content/30 shrink-0\">‣</span><span>#{text}</span></div>"

      # Top-level bullet
      String.starts_with?(trimmed, "* ") ->
        text = String.trim_leading(trimmed, "* ") |> clean_inline()
        "<div class=\"flex gap-2 items-start py-0.5\"><span class=\"text-base-content/40 shrink-0\">•</span><span>#{text}</span></div>"

      true ->
        "<p class=\"py-0.5\">#{clean_inline(trimmed)}</p>"
    end
  end

  defp clean_inline(text) do
    text
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
    |> String.replace(~r/\*\*(.+?)\*\*/, "<strong>\\1</strong>")
    |> String.replace(~r/\*([^*]+)\*/, "<em>\\1</em>")
  end
end
