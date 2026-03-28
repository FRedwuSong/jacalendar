## Why

目前行程資料只能透過 `/itineraries/:id` 查看，日期切換是同一路由內的狀態切換，無法直接分享某天的連結或加入書籤。需要一組獨立的 URL 結構（`/trip/:id/all` 與 `/trip/:id/:day`），以 Google Calendar 週視圖風格呈現行程，讓每天都有自己的永久連結。

## What Changes

- 新增 `/trip/:id/all` 路由：6 欄並排週視圖，左側 07:00~24:00 時間軸，垂直捲動
- 新增 `/trip/:id/:day` 路由：單日單欄視圖，同樣時間軸，手機全寬顯示
- 行程項目以事件方塊（event block）依據時間佔據對應的格子高度，類似 Google Calendar
- 使用現有 Itinerary/Day/Item 資料模型，不新增 schema
- 頁面載入時預設捲動至合理位置（約中午附近）

## Capabilities

### New Capabilities

- `trip-calendar-view`: Google Calendar 風格的行程週視圖與單日視圖，支援獨立 URL 路由

### Modified Capabilities

（無）

## Impact

- 新增檔案：`lib/jacalendar_web/live/trip_live.ex`（新 LiveView）
- 修改檔案：`lib/jacalendar_web/router.ex`（新增路由）
- 依賴：現有 `Jacalendar.Itineraries` context、daisyUI + Tailwind CSS
