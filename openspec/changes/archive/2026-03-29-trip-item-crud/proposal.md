## Why

Trip view 目前是 read-only，無法新增、編輯或刪除行程項目。使用者需要回到 ScheduleLive 或重新匯入 markdown 才能修改內容。需要讓 trip view 成為主要的編輯介面，支援完整的 Item CRUD。

## What Changes

- 在 `Itineraries` context 新增 `create_item/2`（接收 day_id 和 attrs）和 `delete_item/1` 函數
- 點擊 trip view 的空白時間格新增 item：以點擊位置的小時作為預設時間，建立一個新的 exact time item
- 點擊事件方塊展開 inline 編輯面板：可修改時間、描述、sub_items
- 事件方塊上顯示刪除按鈕，點擊後刪除該 item
- 編輯完成後即時更新畫面（LiveView 重新載入 itinerary）

## Non-Goals

- 不做拖拉移動事件方塊（改用點擊編輯時間）
- 不做跨天移動 item
- 不做批次編輯

## Capabilities

### New Capabilities

- `trip-item-crud`: 在 trip view 上新增、編輯、刪除 Item 的完整 CRUD 功能

### Modified Capabilities

（無）

## Impact

- 修改檔案：`lib/jacalendar/itineraries.ex`（新增 `create_item/2`、`delete_item/1`）
- 修改檔案：`lib/jacalendar_web/live/trip_live.ex`（新增事件處理、編輯 UI）
