## 1. 資料庫 Schema 與 Migration（三張表的資料模型）

- [x] 1.1 建立 `transport_sections` migration 與 Ecto schema（transport section persistence）
- [x] 1.2 建立 `transport_routes` migration 與 Ecto schema，含 segments JSON 欄位（transport route persistence）
- [x] 1.3 建立 `taxi_address_cards` migration 與 Ecto schema（taxi address card persistence）
- [x] 1.4 在 Itinerary schema 新增 has_many 關聯，並設定 cascade delete

## 2. 獨立的交通解析器（TransportParser）

- [x] 2.1 建立 `Jacalendar.TransportParser` 模組，實作 `parse/1` 入口（parse complete transportation document、separate transport parser module）
- [x] 2.2 實作 parse transport sections：解析必備工具、飯店交通、每日任務、Tips 區塊
- [x] 2.3 實作 parse daily transport routes：解析每日重點交通詳解的 Day 分組與路線段
- [x] 2.4 實作 parse taxi address cards：解析計程車/導航用地址卡

## 3. 資料持久化（Itineraries Context）

- [x] 3.1 在 `Itineraries` context 新增 `import_transportation/2` 函式，處理交通資料寫入 DB
- [x] 3.2 更新 `get_itinerary!/1` preload 交通相關關聯

## 4. TransportationLive UI 結構（transportation-display）

- [x] 4.1 抽取頁籤導航為共用 function component（頁籤導航抽取），含三個 tab：行程表/清單/交通（transportation tab navigation）
- [x] 4.2 新增 `/itineraries/:id/transportation` 路由與 `TransportationLive` mount
- [x] 4.3 實作 empty state 與匯入交通 markdown 功能（import transportation markdown、empty state）
- [x] 4.4 實作 display transport sections（accordion 收合展開）
- [x] 4.5 實作 display daily transport routes（按 Day 分組 accordion）
- [x] 4.6 實作 display taxi address cards（grid 卡片 + copy address to clipboard + copy confirmation feedback）

## 5. 整合與匯入流程

- [x] 5.1 更新 ScheduleLive 和 ChecklistLive 使用共用頁籤 component
- [x] 5.2 確認 itinerary 刪除時 cascade delete 交通資料（cascade delete transport sections、cascade delete transport routes、cascade delete address cards）
