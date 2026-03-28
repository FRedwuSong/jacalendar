## 1. Context 層

- [x] 1.1 在 `Itineraries` context 新增 weekday derivation 輔助函數，將日期轉為中文星期（一~日）
- [x] 1.2 實作 create day via context function `create_day/2`：接收 itinerary，計算 `date_range_end + 1` 作為新日期、`max(position) + 1` 作為 position、呼叫 weekday derivation 取得星期，在 transaction 中建立 Day 並更新 itinerary 的 `date_range_end`

## 2. Trip View UI

- [x] 2.1 在 trip view header 加入 add day button in trip view：day pills 最後方的「+」按鈕
- [x] 2.2 實作 `handle_event("add_day", ...)` 事件：呼叫 `create_day/2`，重新載入 itinerary，navigate 到新建的 day 頁面
