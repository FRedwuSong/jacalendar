defmodule JacalendarWeb.ChecklistLive do
  use JacalendarWeb, :live_view

  alias Jacalendar.Itineraries

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    itinerary = Itineraries.get_itinerary!(id)

    {:ok,
     socket
     |> assign(:itinerary, itinerary)
     |> assign(:checklist_items, itinerary.checklist_items)}
  end

  @impl true
  def handle_event("toggle", %{"id" => id_str}, socket) do
    item = Itineraries.get_checklist_item!(String.to_integer(id_str))
    {:ok, _} = Itineraries.toggle_checklist_item(item)
    {:noreply, reload_checklist(socket)}
  end

  @impl true
  def handle_event("reorder", %{"ids" => ids}, socket) do
    Itineraries.reorder_checklist_items(ids)
    {:noreply, reload_checklist(socket)}
  end

  defp reload_checklist(socket) do
    itinerary = Itineraries.get_itinerary!(socket.assigns.itinerary.id)

    socket
    |> assign(:itinerary, itinerary)
    |> assign(:checklist_items, itinerary.checklist_items)
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

        <.itinerary_tabs itinerary_id={@itinerary.id} active={:checklist} />

        <%!-- Checklist --%>
        <%= if @checklist_items == [] do %>
          <div class="text-center py-12 text-base-content/40">
            <.icon name="hero-clipboard-document-list" class="size-12 mx-auto mb-3" />
            <p>此行程沒有景點清單</p>
          </div>
        <% else %>
          <% checked_count = Enum.count(@checklist_items, & &1.checked) %>
          <div class="text-sm text-base-content/60 mb-2">
            已完成 {checked_count}/{length(@checklist_items)}
          </div>
          <div id="checklist-container" phx-hook="Sortable" class="space-y-1">
            <div
              :for={item <- @checklist_items}
              id={"checklist-#{item.id}"}
              data-id={item.id}
              class={[
                "flex items-center gap-3 px-4 py-3 rounded-lg transition-colors",
                if(item.checked, do: "bg-base-200/50 opacity-60", else: "hover:bg-base-200")
              ]}
            >
              <div class="drag-handle cursor-grab active:cursor-grabbing shrink-0 text-base-content/30 hover:text-base-content/60 touch-none">
                <.icon name="hero-bars-3" class="size-5" />
              </div>
              <div
                class="cursor-pointer shrink-0"
                phx-click="toggle"
                phx-value-id={item.id}
              >
                <div class={[
                  "size-5 rounded border-2 flex items-center justify-center transition-colors",
                  if(item.checked, do: "bg-primary border-primary", else: "border-base-content/30")
                ]}>
                  <.icon :if={item.checked} name="hero-check" class="size-3 text-primary-content" />
                </div>
              </div>
              <div class="flex-1 min-w-0 cursor-pointer" phx-click="toggle" phx-value-id={item.id}>
                <p class={["font-medium", if(item.checked, do: "line-through text-base-content/50")]}>
                  {item.name}
                </p>
                <p :if={item.location} class="text-xs text-base-content/50">
                  {item.location}
                </p>
              </div>
              <span :if={item.note} class="badge badge-ghost badge-sm shrink-0">
                {item.note}
              </span>
            </div>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
