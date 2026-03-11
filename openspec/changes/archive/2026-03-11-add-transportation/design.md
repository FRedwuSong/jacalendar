## Context

Jacalendar 目前有兩個頁籤：行程表（ScheduleLive）和清單（ChecklistLive）。使用者另外有一份 `tokyo_trip_transportation.md` 交通攻略，包含必備工具/App、飯店交通、每日路線詳解、交通 Tips、以及計程車地址卡。需要新增第三個「交通」頁籤來整合這些資訊。

交通 markdown 的結構與行程 markdown 不同，它是一份獨立文件，不含 Day header 格式，而是用 `## ` 和 `### ` 區分各區塊。

## Goals / Non-Goals

**Goals:**

- 解析交通 markdown 並結構化儲存至 DB
- 提供交通頁籤 UI，含每日路線展開/收合、地址卡可複製功能
- 在三個頁籤間統一導航（行程表 / 清單 / 交通）

**Non-Goals:**

- 不做即時路線查詢或外部 API 串接（Google Maps 等）
- 不做交通 markdown 的線上編輯功能
- 不合併交通資料到行程表 timeline 中

## Decisions

### 獨立的交通解析器

建立 `Jacalendar.TransportParser` 作為獨立模組，與現有 `MarkdownParser` 分開。理由：

- 交通 markdown 格式完全不同（無 Day header、無時間前綴）
- 職責分離，避免現有解析器過於複雜
- 由 ScheduleLive 的匯入頁面觸發，上傳交通 markdown 時呼叫此解析器

替代方案：擴充 MarkdownParser 加入交通格式判斷 → 否決，因為兩種格式差異太大。

### 三張表的資料模型

1. **`transport_sections`** — 儲存通用區塊（必備工具、飯店交通、每日任務、Tips）
   - `itinerary_id`, `section_type` (enum: tools, hotel_transport, daily_task, tips), `title`, `content` (text, 保留 markdown 格式), `position`

2. **`transport_routes`** — 儲存每日重點交通路線段
   - `itinerary_id`, `day_label` (e.g., "Day 2"), `day_date` (date), `title` (路線摘要), `position`
   - 每條 route 有多個 `segments` 以 JSON array 存在同一欄位
   - segment 結構: `{order, from, to, method, details, cost, duration}`

3. **`taxi_address_cards`** — 儲存計程車/導航用地址卡
   - `itinerary_id`, `name` (場所名), `name_ja` (日文名), `address` (日文地址), `note`, `position`

替代方案：把所有資料存成單一 JSON blob → 否決，因為地址卡需要獨立查詢和排序。

### TransportationLive UI 結構

- 頂部：與行程表/清單相同的頁籤導航
- 區塊一：通用資訊（必備工具、飯店交通、Tips）— 以 accordion 收合呈現
- 區塊二：每日路線詳解 — 按 Day 分組的 accordion，展開顯示各段路線
- 區塊三：計程車地址卡 — grid 卡片排列，每張卡片有「複製地址」按鈕
- 地址卡的複製功能使用 JS hook + `navigator.clipboard.writeText()`

### 匯入流程

在現有的 markdown 匯入頁面（ScheduleLive index view）新增第二個文字區域，用於貼上交通 markdown。或是在匯入成功後，顯示「上傳交通資訊」按鈕。

選擇方案：在行程詳情頁新增一個「匯入交通資訊」按鈕，點擊後出現 modal 讓使用者貼上交通 markdown。這樣不影響現有匯入流程。

### 頁籤導航抽取

目前頁籤 HTML 在 ScheduleLive 和 ChecklistLive 中各自重複。新增第三個頁籤後，應將頁籤導航抽成共用 function component，避免三處重複。

## Risks / Trade-offs

- [交通 markdown 格式變化] → 解析器使用寬鬆的 regex 匹配，非嚴格格式依賴
- [transport_routes segments 用 JSON 欄位] → 犧牲 SQL 查詢能力換取 schema 簡潔；此資料不需要跨 route 查詢
- [地址卡複製依賴 clipboard API] → 需要 HTTPS 環境；Gigalixir 部署已是 HTTPS
