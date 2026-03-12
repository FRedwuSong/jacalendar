## 1. 資料模型：兩張表分離餐廳與每日推薦

- [x] 1.1 建立 `food_restaurants` migration 與 Ecto schema（name, category, area, price_range, address, hours, reason, position）
- [x] 1.2 建立 `food_daily_picks` migration 與 Ecto schema（day_date, day_label, restaurant_name, priority, note, position）
- [x] 1.3 建立 Food context 模組（import_food/1, list_restaurants/0, daily_picks_for_date/1）

## 2. FoodParser：解析美食推薦 markdown

- [x] 2.1 建立 `Jacalendar.FoodParser` 獨立 parser 模組（parser 模組獨立），實作 parse/1 入口（parse food recommendation markdown into structured data）
- [x] 2.2 實作 parse restaurant details：解析分類推薦區塊，extract restaurant details 含 category, area, price_range, address, hours, reason
- [x] 2.3 實作 recognize food categories（甜點/烤魚定食/鰻魚/拉麵）
- [x] 2.4 實作 extract daily pick associations：解析按天安插建議區塊
- [x] 2.5 實作 skip restaurants without address

## 3. 獨立路由不綁 itinerary

- [x] 3.1 新增 `/food` 路由與 `FoodLive` mount（food page accessible at standalone route）
- [x] 3.2 更新共用 navigation tab for food（新增「美食」tab 連結到 `/food`）

## 4. FoodLive UI：水平日期篩選與餐廳卡片

- [x] 4.1 實作 empty state with import prompt 與 import food markdown via file upload
- [x] 4.2 實作 horizontal day filter bar（全部 + 每日 tab，UI 使用水平日期篩選）
- [x] 4.3 實作 category grouping in all-view（全部模式按分類分組顯示）
- [x] 4.4 實作 per-day view（選特定日期只顯示當天推薦）
- [x] 4.5 實作 restaurant card display 含 Google Maps 導航連結
