## Why

Markdown 行程中包含「必訪景點清單」段落，列出咖啡廳、唱片行、美術館等必去地點。目前解析時忽略此段落，使用者無法在 app 中追蹤哪些景點已造訪、哪些尚未完成。新增 checklist 功能讓使用者可以勾選追蹤進度。

## What Changes

- 解析 markdown 中 `## 📍 必訪景點清單` 段落，提取每個項目的名稱、地點、備註（如「需預約」「每日任務」）
- 新建 `checklist_items` 資料表儲存清單項目，包含 `checked` 欄位支援勾選狀態
- 新增 `/itineraries/:id/checklist` route，由獨立的 `ChecklistLive` 處理
- 在行程表頁面上方加入 tab 切換（行程表 / 清單）

## Capabilities

### New Capabilities

- `checklist`: 必訪景點清單的解析、儲存、顯示與勾選互動

### Modified Capabilities

- `markdown-parsing`: 新增解析「必訪景點清單」段落的能力
- `data-persistence`: 新增 `checklist_items` 資料表與相關 CRUD 操作

## Impact

- 受影響程式碼：
  - `lib/jacalendar/markdown_parser.ex` — 新增 `parse_checklist/1`
  - `lib/jacalendar/itinerary.ex` — 新增 checklist 欄位
  - `lib/jacalendar/itineraries.ex` — 新增 checklist items 的 serialize/CRUD
  - `lib/jacalendar_web/router.ex` — 新增 route
  - `lib/jacalendar_web/live/checklist_live.ex` — 新建 LiveView
  - `lib/jacalendar_web/live/schedule_live.ex` — 加入 tab 導覽
  - `priv/repo/migrations/` — 新增 migration
