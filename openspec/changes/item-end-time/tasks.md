## 1. Schema 與 Migration

- [x] 1.1 建立 migration 在 `items` 表新增 `end_time` 欄位（`:time`，nullable），實作 item end_time field
- [x] 1.2 修改 Item schema 加入 `end_time` 欄位，changeset 加入 `:end_time` 到 cast 列表

## 2. Context 層

- [x] 2.1 修改 `create_item/2` 實作 default end_time on item creation：當沒有傳入 `end_time` 時，預設為 `time_value + 1 小時`

## 3. Trip View 顯示邏輯

- [x] 3.1 修改 `event_blocks/1` 函數實作 event block height with end_time：有 `end_time` 用 `end_time` 計算 `row_end`，沒有就沿用原邏輯（下一個 item 的開始時間或預設 1 小時）

## 4. Trip View 編輯 UI

- [x] 4.1 在編輯模式加入 edit end_time in trip view：在 `time_value` input 旁加入 `end_time` input（type=time），標示為「~」分隔開始與結束
- [x] 4.2 修改 `save_item` 事件處理：解析 `end_time` 欄位，空值時存為 `nil`，有值時存為 Time
