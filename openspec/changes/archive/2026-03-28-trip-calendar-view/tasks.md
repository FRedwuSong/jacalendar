## 1. 路由與 LiveView 骨架

- [x] 1.1 在 `router.ex` 新增 week view route `/trip/:id/all` 與 single day view route `/trip/:id/:day`，指向 `TripLive`
- [x] 1.2 建立 `lib/jacalendar_web/live/trip_live.ex` LiveView，mount 時載入 itinerary 並根據 `:day` 參數決定顯示模式（week view 或 single day view）
- [x] 1.3 處理 invalid itinerary ID（404）與 day number out of range（redirect 到 `/trip/:id/all`）

## 2. 時間軸佈局（Time axis layout）

- [x] 2.1 實作 time axis layout：左側固定時間軸，標示 07:00 ~ 24:00 每小時標籤
- [x] 2.2 使用 CSS Grid 建立時間格線，每小時為一個 row，內容區域可垂直捲動
- [x] 2.3 實作 auto-scroll on page load，頁面載入後自動捲動到約 08:00 位置（使用 JS hook）

## 3. 事件方塊渲染（Event block rendering）

- [x] 3.1 實作 event block rendering：將每個 exact time item 定位到對應的時間格，計算 grid-row-start 與 grid-row-end
- [x] 3.2 實作 duration calculation from next item：下一個 item 的時間為結束點，最後一個 item 預設 1 小時
- [x] 3.3 設計事件方塊的視覺樣式（背景色、圓角、文字截斷），使用 daisyUI 主題色

## 4. 週視圖（Week view column layout）

- [x] 4.1 實作 week view column layout：`/trip/:id/all` 的多欄並排佈局，每個 day 一欄
- [x] 4.2 渲染 column headers，顯示 day number、日期與星期（如 "Day 1 · 4/16 (四)"）
- [x] 4.3 處理 mobile horizontal scroll：時間軸固定左側，day 欄位可水平捲動

## 5. 單日視圖（Single day full-width layout）

- [x] 5.1 實作 `/trip/:id/:day` 的 single day full-width layout，事件欄位佔滿寬度
- [x] 5.2 加入 day navigation 控制列：上一天、下一天、回到 all 視圖的連結
