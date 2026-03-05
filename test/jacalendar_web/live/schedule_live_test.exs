defmodule JacalendarWeb.ScheduleLiveTest do
  use JacalendarWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

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

  describe "input mode" do
    test "renders markdown input form", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      assert has_element?(view, "#markdown-form")
      assert has_element?(view, "#markdown-input")
      assert has_element?(view, "#parse-btn")
    end

    test "parses valid markdown and shows schedule", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> form("#markdown-form", %{markdown: @valid_markdown})
      |> render_submit()

      assert has_element?(view, "#schedule-mode")
      assert has_element?(view, "#metadata-section")
      assert has_element?(view, "#day-0")
    end

    test "shows error for invalid markdown", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> form("#markdown-form", %{markdown: ""})
      |> render_submit()

      assert has_element?(view, "#parse-error")
    end
  end

  describe "schedule display" do
    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> form("#markdown-form", %{markdown: @valid_markdown})
      |> render_submit()

      %{view: view}
    end

    test "displays day header", %{view: view} do
      html = render(view)
      assert html =~ "04/16"
      assert html =~ "抵達"
    end

    test "displays exact time items", %{view: view} do
      assert has_element?(view, "#item-0-0")
      html = render(view)
      assert html =~ "17:15"
      assert html =~ "抵達成田機場"
    end

    test "displays pending time items with badge", %{view: view} do
      html = render(view)
      assert html =~ "待定"
    end

    test "displays fuzzy time items", %{view: view} do
      html = render(view)
      assert html =~ "早上"
    end

    test "displays sub-items", %{view: view} do
      html = render(view)
      assert html =~ "利木津巴士直達新宿"
    end

    test "displays flight metadata", %{view: view} do
      html = render(view)
      assert html =~ "JL8664"
    end

    test "displays hotel metadata", %{view: view} do
      html = render(view)
      assert html =~ "新宿華盛頓飯店"
    end

    test "back to input button works", %{view: view} do
      view |> element("button", "重新輸入") |> render_click()
      assert has_element?(view, "#input-mode")
    end
  end

  describe "time editing" do
    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> form("#markdown-form", %{markdown: @valid_markdown})
      |> render_submit()

      %{view: view}
    end

    test "clicking pending time shows time input", %{view: view} do
      view |> element("button", "待定") |> render_click()
      assert has_element?(view, "input[type=time]")
    end

    test "saving time updates the item", %{view: view} do
      view |> element("button", "待定") |> render_click()

      view
      |> form("form[id^=time-form]", %{time: "14:30"})
      |> render_submit()

      html = render(view)
      assert html =~ "14:30"
    end
  end

  describe "description editing" do
    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> form("#markdown-form", %{markdown: @valid_markdown})
      |> render_submit()

      %{view: view}
    end

    test "clicking description shows text input", %{view: view} do
      # item-0-0 is "抵達成田機場" (first item, day 0)
      view |> element("#item-0-0 p", "抵達成田機場") |> render_click()
      assert has_element?(view, "#desc-input-0-0")
    end

    test "submitting edit updates description", %{view: view} do
      view |> element("#item-0-0 p", "抵達成田機場") |> render_click()

      view
      |> form("#desc-form-0-0", %{value: "抵達羽田機場"})
      |> render_submit()

      html = render(view)
      assert html =~ "抵達羽田機場"
      refute has_element?(view, "#desc-input-0-0")
    end

    test "pressing Escape cancels description edit", %{view: view} do
      view |> element("#item-0-0 p", "抵達成田機場") |> render_click()
      assert has_element?(view, "#desc-input-0-0")

      render_keydown(view, "cancel_edit", %{"key" => "Escape"})
      refute has_element?(view, "#desc-input-0-0")
      assert render(view) =~ "抵達成田機場"
    end

    test "empty description is allowed", %{view: view} do
      view |> element("#item-0-0 p", "抵達成田機場") |> render_click()

      view
      |> form("#desc-form-0-0", %{value: ""})
      |> render_submit()

      refute has_element?(view, "#desc-input-0-0")
    end
  end

  describe "sub-item editing" do
    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> form("#markdown-form", %{markdown: @valid_markdown})
      |> render_submit()

      %{view: view}
    end

    test "clicking sub-item shows text input", %{view: view} do
      # item-0-1 is "搭巴士" which has sub-item "利木津巴士直達新宿"
      view |> element("#item-0-1 p", "利木津巴士直達新宿") |> render_click()
      assert has_element?(view, "#sub-input-0-1-0")
    end

    test "submitting edit updates sub-item", %{view: view} do
      view |> element("#item-0-1 p", "利木津巴士直達新宿") |> render_click()

      view
      |> form("#sub-form-0-1-0", %{value: "搭 N'EX 到新宿"})
      |> render_submit()

      html = render(view)
      assert html =~ "搭 N&#39;EX 到新宿"
      refute has_element?(view, "#sub-input-0-1-0")
    end

    test "pressing Escape cancels sub-item edit", %{view: view} do
      view |> element("#item-0-1 p", "利木津巴士直達新宿") |> render_click()
      assert has_element?(view, "#sub-input-0-1-0")

      render_keydown(view, "cancel_edit", %{"key" => "Escape"})
      refute has_element?(view, "#sub-input-0-1-0")
      assert render(view) =~ "利木津巴士直達新宿"
    end
  end

  describe "sub-item deletion" do
    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> form("#markdown-form", %{markdown: @valid_markdown})
      |> render_submit()

      %{view: view}
    end

    test "clicking delete removes sub-item", %{view: view} do
      html = render(view)
      assert html =~ "利木津巴士直達新宿"

      view
      |> element("#item-0-1 button[phx-click=delete_sub_item]")
      |> render_click()

      html = render(view)
      refute html =~ "利木津巴士直達新宿"
    end
  end

  describe "sub-item addition" do
    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> form("#markdown-form", %{markdown: @valid_markdown})
      |> render_submit()

      %{view: view}
    end

    test "clicking add button shows text input", %{view: view} do
      view
      |> element("#item-0-0 button[phx-click=add_sub_item]")
      |> render_click()

      assert has_element?(view, "#new-sub-input-0-0")
    end

    test "submitting new sub-item adds it to list", %{view: view} do
      view
      |> element("#item-0-0 button[phx-click=add_sub_item]")
      |> render_click()

      view
      |> form("#new-sub-form-0-0", %{value: "記得帶護照"})
      |> render_submit()

      html = render(view)
      assert html =~ "記得帶護照"
      refute has_element?(view, "#new-sub-input-0-0")
    end

    test "pressing Escape cancels new sub-item", %{view: view} do
      view
      |> element("#item-0-0 button[phx-click=add_sub_item]")
      |> render_click()

      assert has_element?(view, "#new-sub-input-0-0")

      render_keydown(view, "cancel_edit", %{"key" => "Escape"})
      refute has_element?(view, "#new-sub-input-0-0")
    end
  end
end
