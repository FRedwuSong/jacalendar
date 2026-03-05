## 1. 資料結構定義

- [x] 1.1 建立 `Jacalendar.Itinerary` struct（title, date_range, metadata, days），對應 design 中的資料結構設計
- [x] 1.2 建立 `Jacalendar.Itinerary.Day` struct（date, weekday, title, items）
- [x] 1.3 建立 `Jacalendar.Itinerary.Item` struct（time, description, sub_items）

## 2. 核心解析邏輯（使用純 Elixir 正則表達式解析，不引入外部 Markdown parser）

- [x] 2.1 實作 parse day headers — 解析 `### Day N: YYYY/MM/DD (weekday) - title` 格式
- [x] 2.2 實作 parse exact time items — 解析 `**HH:MM**:` 與時間範圍格式
- [x] 2.3 實作 parse fuzzy time items — 辨識中文模糊時段（早上/上午/下午/傍晚/晚餐/晚上）
- [x] 2.4 實作 parse pending time items — 無法辨識時間的項目標記為 `:pending`
- [x] 2.5 實作 parse sub-items — 解析縮排的巢狀 bullet 項目

## 3. Metadata 解析

- [x] 3.1 實作 parse itinerary metadata — 航班資訊（flight information）區塊解析
- [x] 3.2 實作 parse itinerary metadata — 住宿資訊（hotel information）區塊解析

## 4. 整合與入口（解析策略：逐行 + 狀態機）

- [x] 4.1 實作 `Jacalendar.MarkdownParser.parse/1` 入口函式，整合所有解析邏輯，回傳 parse complete itinerary 結果
- [x] 4.2 處理 invalid or empty input 的錯誤回傳

## 5. 測試

- [x] 5.1 用實際行程 Markdown 範例撰寫整合測試，驗證 parse complete itinerary
- [x] 5.2 撰寫各解析功能的單元測試（day headers, exact time, fuzzy time, pending time, sub-items, metadata）
