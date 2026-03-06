## Why

行程資料目前存在 LiveView process 的 assigns 中，頁面重整或 process 結束就會遺失。使用者辛苦匯入並編輯過的行程資料應該被持久化到 PostgreSQL，讓資料可以跨 session 存取。

## What Changes

- 新增 Ecto schema：Itinerary、Day、Item（含 sub_items）
- 新增 context module `Jacalendar.Itineraries` 封裝 CRUD 操作
- 新增 migration 建立 itineraries、days、items 三張 table
- 修改 ScheduleLive：parse 後存入 DB，編輯操作直接寫入 DB，頁面載入時從 DB 讀取
- 新增行程列表頁，讓使用者可以選擇檢視已儲存的行程

## Capabilities

### New Capabilities

- `data-persistence`: Ecto schema 定義、migration、context module 提供行程資料的 CRUD 操作

### Modified Capabilities

- `schedule-display`: 行程資料來源從 in-memory assigns 改為 DB 讀寫，新增行程列表選擇功能

## Impact

- 新增檔案：`lib/jacalendar/itineraries.ex`（context module）
- 新增檔案：`lib/jacalendar/itineraries/itinerary.ex`、`day.ex`、`item.ex`（Ecto schemas）
- 新增檔案：`priv/repo/migrations/` 下的 migration
- 修改檔案：`lib/jacalendar_web/live/schedule_live.ex`（改用 DB 讀寫）
- 修改檔案：`test/jacalendar_web/live/schedule_live_test.exs`（更新測試）
