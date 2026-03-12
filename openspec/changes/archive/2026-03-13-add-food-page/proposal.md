## Why

使用者需要在旅行行程 app 中查看美食推薦，目前美食資訊只存在 markdown 檔案中，無法在手機上方便瀏覽。需要一個獨立的美食頁面，支援按天篩選和按分類瀏覽，並能一鍵導航到餐廳。

## What Changes

- 新增 `FoodParser` 模組，解析美食推薦 markdown 為結構化資料
- 新增 `food_restaurants` 與 `food_daily_picks` 兩張資料表
- 新增 `/food` 獨立路由與 `FoodLive` LiveView 頁面
- 頁面支援水平日期篩選列（全部 + 每日 tab）與按分類分組
- 餐廳卡片顯示店名、分類、區域、金額、營業時間、推薦理由，並帶 Google Maps 導航
- 共用導航新增第 4 個「美食」tab

## Capabilities

### New Capabilities

- `food-parsing`: 解析美食推薦 markdown 檔案為結構化餐廳與每日推薦資料
- `food-display`: 獨立美食頁面，含日期篩選、分類分組、餐廳卡片與 Google Maps 導航

### Modified Capabilities

（無）

## Impact

- 新增檔案: `lib/jacalendar/food_parser.ex`, `lib/jacalendar_web/live/food_live.ex`
- 新增 schema: `lib/jacalendar/food/restaurant.ex`, `lib/jacalendar/food/daily_pick.ex`
- 新增 migration: `food_restaurants`, `food_daily_picks`
- 修改: `lib/jacalendar_web/router.ex`（新增 `/food` 路由）
- 修改: `lib/jacalendar_web/components/core_components.ex`（新增美食 tab）
