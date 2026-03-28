## 1. Context 層

- [x] 1.1 在 `Itineraries` context 新增 create item via context function `create_item/2`：接收 day_id 和 attrs map，建立 exact time item，position 為 max + 1
- [x] 1.2 在 `Itineraries` context 新增 delete item via context function `delete_item/1`：接收 Item struct 並刪除

## 2. Trip View — 新增 Item

- [x] 2.1 實作 create item via time grid click：在 trip view 的時間格空白區域加入 `phx-click` 事件，根據點擊位置計算對應小時，呼叫 `create_item/2` 建立空白 item
- [x] 2.2 新增 item 後自動進入 edit mode，讓使用者可以立即輸入描述

## 3. Trip View — edit item inline

- [x] 3.1 實作 edit item inline 基礎：在 trip_live.ex 新增 `editing` assign 追蹤目前正在編輯的 item_id
- [x] 3.2 點擊事件方塊觸發 `edit_item` 事件，切換該 item 為編輯模式：顯示時間 input（type=time）和描述 textarea
- [x] 3.3 實作 `save_item` 事件：收集表單資料，呼叫 `update_item/2` 更新時間與描述，退出編輯模式並重新載入 itinerary
- [x] 3.4 實作 `cancel_edit` 事件：按 Escape 時退出編輯模式，不儲存變更

## 4. Trip View — 刪除 Item (delete item via UI)

- [x] 4.1 在事件方塊上顯示 delete item via UI 按鈕（編輯模式中顯示刪除按鈕）
- [x] 4.2 實作 `delete_item` 事件：呼叫 `delete_item/1` 刪除 item，重新載入 itinerary
