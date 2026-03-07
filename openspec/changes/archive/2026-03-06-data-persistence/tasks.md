## 1. 使用三層 Ecto schema 對應既有結構

- [x] 1.1 建立 migration：itineraries table（title, date_range_start, date_range_end, metadata:map）
- [x] 1.2 建立 migration：days table（date, weekday, title, position, itinerary_id）
- [x] 1.3 建立 migration：items table（time_type, time_value, description, sub_items:array, position, day_id）
- [x] 1.4 建立 Ecto schema `Jacalendar.Itineraries.Itinerary`、`Day`、`Item`，包含 associations 和 changeset

## 2. 使用 Phoenix context module 封裝 DB 操作

- [x] 2.1 建立 `Jacalendar.Itineraries` context module，實作 itinerary persistence：`create_itinerary/1` 從 parsed struct 建立完整行程
- [x] 2.2 實作 itinerary retrieval：`get_itinerary!/1` preload days → items，以及 itinerary listing：`list_itineraries/0`
- [x] 2.3 實作 `update_item/2` 更新時間和描述，`update_sub_items/2` 更新 sub_items 陣列
- [x] 2.4 實作 itinerary deletion：`delete_itinerary/1`
- [x] 2.5 撰寫 context module 的測試

## 3. LiveView 改為 DB 驅動

- [x] 3.1 修改路由，新增 `live "/itineraries/:id", ScheduleLive`，保留原始 struct 作為 parser 輸出格式
- [x] 3.2 修改 markdown input 流程：parse 成功後存入 DB 並 redirect 到 `/itineraries/:id`
- [x] 3.3 修改 mount：依據 params 決定顯示 itinerary list view 或載入指定行程
- [x] 3.4 修改所有編輯 event handlers（時間、描述、sub-items）改為呼叫 context module 更新 DB
- [x] 3.5 新增 itinerary list view 的 template（顯示已儲存行程列表）
- [x] 3.6 新增 itinerary deletion 的 event handler 和 UI
- [x] 3.7 更新 ScheduleLive 測試，涵蓋 DB 讀寫與行程列表功能
