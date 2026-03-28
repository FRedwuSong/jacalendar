## Why

目前 Day 只能透過 markdown import 建立，無法在 trip view 上直接新增。當使用者想延長旅程或補一天行程時，必須重新編輯 markdown 再匯入，流程不直覺。需要在 trip view 提供「新增一天」的能力，讓使用者可以直接在 calendar 介面操作。

## What Changes

- 在 `Itineraries` context 新增 `create_day/2` 函數，接收 itinerary 和 attrs，自動計算下一天的日期（`date_range_end + 1`）和 position（現有最大 position + 1），同時更新 itinerary 的 `date_range_end`
- 在 Trip view 的 header 區域加入「+」按鈕，點擊後新增一天
- 新增的 Day 會立即出現在 day pills 導航列和週視圖中
- 新增的 Day 沒有任何 item，是空白的一天

## Non-Goals

- 不做刪除 Day 功能
- 不做編輯 Day 屬性（日期、標題）的功能
- 不做 Item CRUD（另一個 change 處理）

## Capabilities

### New Capabilities

- `trip-day-crud`: 在 trip view 上新增 Day，包含 context 函數與 UI 互動

### Modified Capabilities

（無）

## Impact

- 修改檔案：`lib/jacalendar/itineraries.ex`（新增 `create_day/2`）
- 修改檔案：`lib/jacalendar_web/live/trip_live.ex`（新增按鈕與事件處理）
- 修改檔案：`lib/jacalendar/itineraries/itinerary.ex`（更新 `date_range_end` changeset 如需要）
