## Why

Markdown 解析器已完成，但使用者還無法在瀏覽器中查看和操作行程。需要一個 Web UI 讓使用者上傳/貼上 Markdown、檢視解析後的行程表、以當下時間為分隔線區分過去/未來行程、並手動補上或調整缺少時間的項目。

## What Changes

- 新增 LiveView 頁面，提供 Markdown 文字輸入區
- 顯示解析後的每日行程表，以時間軸方式呈現
- 以當下時間 HH:MM 為分隔線，區分已過/未來行程
- 時間狀態為 fuzzy 或 pending 的項目，提供時間編輯功能
- 將首頁改為行程表頁面

## Capabilities

### New Capabilities

- `schedule-display`: Web UI 行程表顯示與互動功能（上傳 Markdown、時間軸顯示、時間分隔線、時間編輯）

### Modified Capabilities

（無）

## Impact

- 新增檔案：`lib/jacalendar_web/live/schedule_live.ex`
- 修改檔案：`lib/jacalendar_web/router.ex`（新增 LiveView route）
- 可能修改：`assets/css/app.css`（行程表樣式）
