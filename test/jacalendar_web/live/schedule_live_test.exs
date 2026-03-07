defmodule JacalendarWeb.ScheduleLiveTest do
  use JacalendarWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Jacalendar.Itineraries

  @valid_markdown """
  # 東京之旅 (2026/04/16 - 04/21)

  ## ✈️ 航班資訊
  *   **去程**: 2026/04/16 (四) **JL 8664**
      *   TPE 桃園 12:45 -> **NRT 成田 17:15**

  ## 🏨 住宿資訊
  *   **飯店**: 新宿華盛頓飯店
  *   **地址**: 東京都新宿区西新宿3-2-9

  ## 🗓️ 詳細行程表

  ### Day 1: 2026/04/16 (四) - 抵達
  *   **17:15**: 抵達成田機場
  *   **交通**: 搭巴士
      *   利木津巴士直達新宿
  *   **早上**: 前往 coffee swamp
  *   **晚餐**: 吃拉麵
  """

  defp create_itinerary(_context) do
    {:ok, parsed} = Jacalendar.MarkdownParser.parse(@valid_markdown)
    {:ok, id} = Itineraries.create_itinerary(parsed)
    %{itinerary_id: id}
  end

  describe "input mode" do
    test "renders markdown input form", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      assert has_element?(view, "#markdown-form")
      assert has_element?(view, "#markdown-input")
      assert has_element?(view, "#parse-btn")
    end

    test "parses valid markdown, saves to DB, and redirects", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> form("#markdown-form", %{markdown: @valid_markdown})
      |> render_submit()

      {path, _flash} = assert_redirect(view)
      assert path =~ ~r"/itineraries/\d+"
    end

    test "shows error for invalid markdown", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> form("#markdown-form", %{markdown: ""})
      |> render_submit()

      assert has_element?(view, "#parse-error")
    end
  end

  describe "itinerary list" do
    setup :create_itinerary

    test "shows saved itineraries on root page", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "東京之旅"
      assert html =~ "已儲存的行程"
    end

    test "no itinerary list when empty", %{conn: conn} do
      # Delete all itineraries first
      for it <- Itineraries.list_itineraries() do
        Itineraries.delete_itinerary(it)
      end

      {:ok, _view, html} = live(conn, "/")
      refute html =~ "已儲存的行程"
    end
  end

  describe "schedule display" do
    setup :create_itinerary

    test "displays day header", %{conn: conn, itinerary_id: id} do
      {:ok, _view, html} = live(conn, "/itineraries/#{id}")
      assert html =~ "04/16"
      assert html =~ "抵達"
    end

    test "displays exact time items", %{conn: conn, itinerary_id: id} do
      {:ok, _view, html} = live(conn, "/itineraries/#{id}")
      assert html =~ "17:15"
      assert html =~ "抵達成田機場"
    end

    test "displays pending time items with badge", %{conn: conn, itinerary_id: id} do
      {:ok, _view, html} = live(conn, "/itineraries/#{id}")
      assert html =~ "待定"
    end

    test "displays fuzzy time items", %{conn: conn, itinerary_id: id} do
      {:ok, _view, html} = live(conn, "/itineraries/#{id}")
      assert html =~ "早上"
    end

    test "displays sub-items", %{conn: conn, itinerary_id: id} do
      {:ok, _view, html} = live(conn, "/itineraries/#{id}")
      assert html =~ "利木津巴士直達新宿"
    end

    test "displays flight metadata", %{conn: conn, itinerary_id: id} do
      {:ok, _view, html} = live(conn, "/itineraries/#{id}")
      assert html =~ "JL8664"
    end

    test "displays hotel metadata", %{conn: conn, itinerary_id: id} do
      {:ok, _view, html} = live(conn, "/itineraries/#{id}")
      assert html =~ "新宿華盛頓飯店"
    end

    test "back to list link works", %{conn: conn, itinerary_id: id} do
      {:ok, view, _html} = live(conn, "/itineraries/#{id}")
      view |> element("a", "返回列表") |> render_click()
      {path, _flash} = assert_redirect(view)
      assert path == "/"
    end
  end

  describe "time editing" do
    setup :create_itinerary

    test "clicking pending time shows time input", %{conn: conn, itinerary_id: id} do
      {:ok, view, _html} = live(conn, "/itineraries/#{id}")
      view |> element("button", "待定") |> render_click()
      assert has_element?(view, "input[type=time]")
    end

    test "saving time updates the item in DB", %{conn: conn, itinerary_id: id} do
      {:ok, view, _html} = live(conn, "/itineraries/#{id}")
      view |> element("button", "待定") |> render_click()

      view
      |> form("form[id^=time-form]", %{time: "14:30"})
      |> render_submit()

      html = render(view)
      assert html =~ "14:30"
    end
  end

  describe "description editing" do
    setup :create_itinerary

    test "clicking description shows text input", %{conn: conn, itinerary_id: id} do
      {:ok, view, _html} = live(conn, "/itineraries/#{id}")
      view |> element("p", "抵達成田機場") |> render_click()
      assert has_element?(view, "input[id^=desc-input]")
    end

    test "submitting edit updates description in DB", %{conn: conn, itinerary_id: id} do
      {:ok, view, _html} = live(conn, "/itineraries/#{id}")
      view |> element("p", "抵達成田機場") |> render_click()

      view
      |> form("form[id^=desc-form]", %{value: "抵達羽田機場"})
      |> render_submit()

      html = render(view)
      assert html =~ "抵達羽田機場"

      # Verify it's in DB
      itinerary = Itineraries.get_itinerary!(id)
      item = hd(hd(itinerary.days).items)
      assert item.description == "抵達羽田機場"
    end
  end

  describe "sub-item editing" do
    setup :create_itinerary

    test "clicking sub-item shows text input", %{conn: conn, itinerary_id: id} do
      {:ok, view, _html} = live(conn, "/itineraries/#{id}")
      view |> element("p", "利木津巴士直達新宿") |> render_click()
      assert has_element?(view, "input[id^=sub-input]")
    end
  end

  describe "sub-item deletion" do
    setup :create_itinerary

    test "clicking delete removes sub-item from DB", %{conn: conn, itinerary_id: id} do
      {:ok, view, _html} = live(conn, "/itineraries/#{id}")
      assert render(view) =~ "利木津巴士直達新宿"

      view
      |> element("button[phx-click=delete_sub_item]")
      |> render_click()

      refute render(view) =~ "利木津巴士直達新宿"
    end
  end

  describe "sub-item addition" do
    setup :create_itinerary

    test "adding new sub-item saves to DB", %{conn: conn, itinerary_id: id} do
      {:ok, view, _html} = live(conn, "/itineraries/#{id}")

      # Get first item's add button
      itinerary = Itineraries.get_itinerary!(id)
      first_item = hd(hd(itinerary.days).items)

      view
      |> element(~s|button[phx-click=add_sub_item][phx-value-item-id="#{first_item.id}"]|)
      |> render_click()

      assert has_element?(view, "input[id=new-sub-input-#{first_item.id}]")

      view
      |> form("#new-sub-form-#{first_item.id}", %{value: "記得帶護照"})
      |> render_submit()

      assert render(view) =~ "記得帶護照"
    end
  end

  describe "itinerary deletion" do
    setup :create_itinerary

    test "deleting itinerary redirects to root", %{conn: conn, itinerary_id: id} do
      {:ok, view, _html} = live(conn, "/itineraries/#{id}")

      view
      |> element("button[phx-click=delete_itinerary]")
      |> render_click()

      {path, _flash} = assert_redirect(view)
      assert path == "/"
    end
  end
end
