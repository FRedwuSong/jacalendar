## Context

目前行程資料以純 Elixir struct（`Itinerary`, `Day`, `Item`）存在 LiveView assigns 中，頁面重整就消失。Phoenix 專案已包含 `Jacalendar.Repo`（PostgreSQL），但尚無任何 migration 或 Ecto schema。

現有的資料結構：
- `Itinerary` — title, date_range, metadata, days[]
- `Day` — date, weekday, title, items[]
- `Item` — time (tagged tuple), description, sub_items (string list)

## Goals / Non-Goals

**Goals:**

- 將行程資料持久化到 PostgreSQL
- Parse 後自動存入 DB
- 所有 inline 編輯（時間、描述、sub-items CRUD）直接寫入 DB
- 新增行程列表頁，讓使用者選擇已儲存的行程
- 頁面重整後資料不遺失

**Non-Goals:**

- 不做使用者認證（目前單一使用者）
- 不做 metadata（航班、住宿）的獨立 table，暫以 JSON 欄位存放
- 不做資料匯出功能

## Decisions

### 使用三層 Ecto schema 對應既有結構

```
itineraries (1) ──▶ days (N) ──▶ items (N)
```

- `itineraries` — title:string, date_range_start:date, date_range_end:date, metadata:map (JSONB)
- `days` — date:date, weekday:string, title:string, position:integer, itinerary_id:references
- `items` — time_type:string, time_value:time (nullable), description:string, sub_items:{:array, :string}, position:integer, day_id:references

Time 的 tagged tuple `{:exact, ~T[17:15:00]}` / `{:fuzzy, :morning}` / `:pending` 拆為兩欄：
- `time_type` — "exact" / "fuzzy_morning" / "fuzzy_afternoon" / "fuzzy_evening" / "pending"
- `time_value` — Time（僅 exact 有值，其餘為 nil）

sub_items 使用 PostgreSQL array 欄位，不另開 table，保持簡單。

### 使用 Phoenix context module 封裝 DB 操作

新增 `Jacalendar.Itineraries` context module，提供：
- `create_itinerary(attrs)` — 從 parsed struct 建立完整行程（含 days、items）
- `list_itineraries()` — 列出所有行程（僅 title、date_range）
- `get_itinerary!(id)` — 載入完整行程（preload days → items）
- `update_item(item_id, attrs)` — 更新單一 item（時間、描述）
- `update_sub_items(item_id, sub_items)` — 更新 sub_items 陣列
- `delete_itinerary(id)` — 刪除整個行程

### LiveView 改為 DB 驅動

ScheduleLive 改為接收 itinerary_id 參數：
- 路由：`live "/", ScheduleLive`（行程列表）和 `live "/itineraries/:id", ScheduleLive`（單一行程）
- Parse 成功後呼叫 context 存入 DB，redirect 到 `/itineraries/:id`
- 所有編輯 event handler 改為呼叫 context module 更新 DB，再重新 assign

### 保留原始 struct 作為 parser 輸出格式

`Jacalendar.MarkdownParser` 仍然輸出 `%Itinerary{}` struct，由 context module 負責轉換為 Ecto changeset 存入 DB。Parser 不依賴 Ecto。

## Risks / Trade-offs

- **[N+1 查詢]** 載入行程需要 preload days 和 items → 使用 `Repo.preload` 一次載入，行程數量小不會有效能問題
- **[sub_items 用 array 欄位]** 無法對單一 sub_item 做 DB 層級操作 → 目前需求只需整組更新，可接受
- **[metadata 用 JSONB]** 航班/住宿結構鬆散 → 目前不需查詢 metadata，JSON 足夠，未來需要再拆 table
- **[time tagged tuple 轉換]** Ecto schema 和 parser struct 之間需要轉換邏輯 → 集中在 context module 處理
