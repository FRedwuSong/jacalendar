## 1. Route 與 LiveView 基礎（使用單一 LiveView 頁面搭配狀態切換）

- [x] 1.1 建立 `JacalendarWeb.ScheduleLive` LiveView 模組，實作 markdown input 的輸入模式
- [x] 1.2 修改 `router.ex`，將首頁 route 改為 ScheduleLive

## 2. 行程表顯示（行程資料用 stream 管理）

- [x] 2.1 實作 schedule display by day — 解析後以每日為單位顯示行程，包含日期/星期/標題
- [x] 2.2 實作各時間類型的顯示：exact time、fuzzy time display、pending time display
- [x] 2.3 實作 sub-items display — 巢狀顯示子項目
- [x] 2.4 實作 metadata display — 航班與住宿摘要區塊

## 3. 時間分隔線（時間分隔線使用 JS hook 取得客戶端時間）

- [x] 3.1 建立 JS hook 取得客戶端當下時間並 pushEvent 到 LiveView
- [x] 3.2 實作 current time divider — 在當日行程中顯示時間分隔線，non-current day 不顯示

## 4. 時間編輯（時間編輯使用 inline form）

- [x] 4.1 實作 time editing — 點擊 fuzzy/pending 項目的時間區域顯示 time input
- [x] 4.2 實作 confirm time edit — 確認後更新 item 時間並重新排序

## 5. 測試

- [x] 5.1 撰寫 ScheduleLive 的 LiveView 測試（markdown input、invalid markdown、schedule display）
- [x] 5.2 撰寫時間編輯的互動測試（edit pending time、confirm time edit）
