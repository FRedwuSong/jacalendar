## 1. 資料分離

- [x] 1.1 根據 time_type 分離項目為兩組：在 render 中將選中日的 items 分為 `scheduled_items`（exact）和 `unscheduled_items`（fuzzy/pending）

## 2. 附註區 UI

- [x] 2.1 實作未排定項目附註區，顯示在時間軸上方，呈現 fuzzy/pending 項目及其時間標籤（calendar timeline view for single day 的 unscheduled section）

## 3. 時間軸 UI

- [x] 3.1 實作時間軸範圍動態計算：從 scheduled_items 取最早/最晚時間，前後各加 1 小時 padding
- [x] 3.2 使用 CSS Grid 實現時間軸佈局：左欄小時標籤、右欄項目區域，每小時一個 grid row
- [x] 3.3 將 exact-time 項目放入對應的 grid row 位置

## 4. 條件式渲染

- [x] 4.1 條件式渲染兩種視圖：`@selected_day == nil` 時顯示現有清單（all-days view unchanged），有值時顯示時間軸 + 附註區
