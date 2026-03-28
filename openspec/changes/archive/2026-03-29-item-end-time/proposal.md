## Why

目前 Item 只有開始時間（`time_value`），結束時間是靠下一個 item 推算或預設 1 小時。這導致事件方塊的高度不精確，編輯時也無法指定事件的持續時間。需要加入可選的 `end_time` 欄位，讓使用者能明確設定事件的時間範圍。

## What Changes

- DB migration：在 `items` 表新增 `end_time` 欄位（`:time` 型別，nullable）
- Item schema 加入 `end_time` 欄位，changeset 允許此欄位
- Trip view 事件方塊高度計算邏輯改為：有 `end_time` 就用 `end_time`，沒有就用下一個 item 的開始時間，若都沒有則預設 1 小時
- Trip view 編輯模式加入結束時間 input（type=time）
- 建立新 item 時，預設 `end_time` 為開始時間 + 1 小時
- Markdown import 的 item 不會有 `end_time`（維持 nil，向後相容）

## Non-Goals

- 不做拖拉調整時間範圍（用 input 就好）
- 不改 ScheduleLive 的顯示邏輯（它會被 Trip view 取代）

## Capabilities

### New Capabilities

- `item-end-time`: Item 的可選結束時間欄位，影響事件方塊高度計算與編輯 UI

### Modified Capabilities

（無）

## Impact

- 新增檔案：`priv/repo/migrations/*_add_end_time_to_items.exs`（migration）
- 修改檔案：`lib/jacalendar/itineraries/item.ex`（schema + changeset）
- 修改檔案：`lib/jacalendar_web/live/trip_live.ex`（顯示邏輯 + 編輯 UI）
- 修改檔案：`lib/jacalendar/itineraries.ex`（`create_item/2` 預設 end_time）
