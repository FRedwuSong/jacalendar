## Context

目前 app 有行程表、清單、交通三個 tab。美食推薦存在獨立 markdown 檔案中，結構為「分類推薦」（甜點/烤魚/鰻魚/拉麵，每間有區域/金額/地址/時間/理由）和「按天安插建議」（Day 1-6 推薦）。需要解析此 markdown 並以手機友善的 UI 呈現。

## Goals / Non-Goals

**Goals:**

- 解析美食推薦 markdown 為結構化資料（餐廳 + 每日推薦）
- 建立 `/food` 獨立頁面，支援水平日期篩選與按分類瀏覽
- 餐廳卡片帶 Google Maps 導航連結
- 共用導航新增「美食」tab

**Non-Goals:**

- 不與 itinerary 綁定（獨立路由 `/food`）
- 不支援使用者新增/編輯餐廳
- 不支援即時營業狀態查詢

## Decisions

### 資料模型：兩張表分離餐廳與每日推薦

- `food_restaurants`：存餐廳基本資料（name, category, area, price_range, address, hours, reason, position）
- `food_daily_picks`：存每日推薦關聯（day_date, day_label, restaurant_id, priority, note）
- 理由：一間餐廳可能被推薦在多天，用關聯表避免重複資料
- 替代方案：單表用 JSON 存每日推薦 → 查詢不方便，放棄

### 獨立路由不綁 itinerary

- URL 為 `/food`，不帶 itinerary id
- 理由：目前只有一個行程，綁 id 沒有實際好處
- 導航 tab 中「美食」直接連到 `/food`

### Parser 模組獨立

- 建立 `Jacalendar.FoodParser`，與 `TransportParser` 和 `MarkdownParser` 完全獨立
- 理由：三份 markdown 格式完全不同，共用解析器反而增加複雜度

### UI 使用水平日期篩選

- 複用行程表頁的水平滑動日期 bar 模式
- 「全部」按鈕顯示按分類分組的所有餐廳
- 選擇特定日期只顯示當天推薦
- 餐廳卡片點擊開 Google Maps 導航（與地址卡相同模式）

## Risks / Trade-offs

- [風險] Markdown 格式變動導致解析失敗 → 與 TransportParser 相同策略，缺欄位的餐廳跳過不匯入
- [風險] `/food` 獨立路由使 tab 導航不一致（其他 tab 在 `/itineraries/:id/` 下） → 可接受，美食 tab 連結直接寫死 `/food`
