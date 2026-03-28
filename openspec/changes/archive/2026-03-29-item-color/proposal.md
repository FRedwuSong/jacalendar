## Why

目前所有事件方塊都是同一個顏色（primary 紫藍），無法在視覺上區分不同類型的活動（交通、餐飲、購物、景點等）。加入可選顏色讓使用者能快速辨識事件類型。

## What Changes

- DB migration：在 `items` 表新增 `color` 欄位（`:string`，nullable，預設 `nil` 代表 primary）
- Item schema 加入 `color` 欄位，changeset 允許此欄位
- Trip view 事件方塊根據 `color` 值套用對應的 daisyUI 背景色和左邊框色
- Trip view 編輯模式加入顏色選擇器：5 個色塊（primary/info/success/warning/error）供點選
- 5 色在 light 和 dark 主題下都使用 daisyUI 語意色，自動適配

## Non-Goals

- 不做自訂顏色（只用 daisyUI 內建 5 色）
- 不做分類標籤（顏色只是視覺標記，不綁定語意）

## Capabilities

### New Capabilities

- `item-color`: Item 的可選顏色欄位，支援 5 種 daisyUI 語意色，影響事件方塊視覺與編輯 UI

### Modified Capabilities

（無）

## Impact

- 新增檔案：`priv/repo/migrations/*_add_color_to_items.exs`
- 修改檔案：`lib/jacalendar/itineraries/item.ex`（schema + changeset）
- 修改檔案：`lib/jacalendar_web/live/trip_live.ex`（顯示邏輯 + 顏色選擇器 UI）
