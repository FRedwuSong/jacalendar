## 1. 篩選狀態管理

- [x] 1.1 在 `mount/3` 新增 `selected_day` assign（使用 LiveView assign 管理篩選狀態），初始值為 `nil`
- [x] 1.2 新增 `handle_event("select_day", ...)` 事件處理，按天 ID 而非日期篩選，更新 `selected_day`

## 2. Day filter pills UI

- [x] 2.1 在 render 的行程標題下方新增 day filter pills 按鈕列（pill 按鈕列放在行程標題下方），包含「全部」按鈕及每日 pill
- [x] 2.2 每個 pill 兩行顯示日期（MM/DD）與標題，使用 DaisyUI btn 元件與 btn-active 表示選中狀態
- [x] 2.3 按鈕列加上 `overflow-x-auto` 支援橫向捲動

## 3. 篩選邏輯

- [x] 3.1 render 時根據 `selected_day` 過濾 `@itinerary.days`，`nil` 顯示全部，有值則只顯示該天
