## 1. Schema 與 Migration

- [x] 1.1 建立 migration 在 `items` 表新增 item color field `color` 欄位（`:string`，nullable）
- [x] 1.2 修改 Item schema 加入 `color` 欄位，changeset 加入 `:color` 到 cast 列表

## 2. Trip View 顯示

- [x] 2.1 在 trip_live.ex 新增 `color_classes/1` 輔助函數，根據 color 值回傳對應的 Tailwind class map（bg、border、text），實作 event block color rendering

## 3. Trip View 編輯 UI

- [x] 3.1 在編輯模式加入 color picker in edit mode：5 個色塊圓圈（primary/info/success/warning/error），點選時更新 hidden input 的值，選中的色塊顯示 ring 高亮
- [x] 3.2 修改 `save_item` 事件處理：解析 `color` 欄位，nil 或 "primary" 存為 nil，其他存為對應字串
