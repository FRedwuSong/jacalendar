## Why

目前行程 app 只有「行程表」和「清單」兩個頁籤。使用者另外有一份獨立的交通攻略 markdown（`tokyo_trip_transportation.md`），包含每日交通路線、地鐵/計程車/步行方案、以及計程車地址卡等重要資訊。旅行時需要在不同 app 或文件之間切換查看交通資訊很不方便，應該整合到同一個 app 中。

## What Changes

- 新增交通 markdown 解析器，解析以下區塊：必備工具 & App、飯店交通、每日任務路線、每日重點交通詳解（Day-based）、交通小撇步、計程車地址卡
- 新增資料庫表格儲存結構化交通資料：`transport_sections`（通用區塊）、`transport_routes`（每日路線段）、`taxi_address_cards`（地址卡）
- 新增 `/itineraries/:id/transportation` 路由與 `TransportationLive` LiveView
- 在現有頁籤列新增「交通」頁籤（行程表 / 清單 / 交通）
- UI 功能：可展開/收合的每日路線區塊、可複製的計程車地址卡（方便出示給司機）、Tips 顯示

## Capabilities

### New Capabilities

- `transportation-parsing`: 解析交通攻略 markdown，提取必備工具、飯店交通、每日路線、Tips、計程車地址卡等結構化資料
- `transportation-display`: 交通頁籤 UI，包含每日路線展開/收合、地址卡複製、Tips 顯示

### Modified Capabilities

- `data-persistence`: 新增 transport_sections、transport_routes、taxi_address_cards 三張表的持久化
- `markdown-parsing`: 擴充解析器以支援交通 markdown 格式

## Impact

- 新增檔案：`lib/jacalendar/transport_parser.ex`、`lib/jacalendar_web/live/transportation_live.ex`
- 新增 migration：transport_sections、transport_routes、taxi_address_cards
- 新增 schema：`lib/jacalendar/itineraries/transport_section.ex`、`transport_route.ex`、`taxi_address_card.ex`
- 修改：`lib/jacalendar/itineraries.ex`（新增交通資料 CRUD）
- 修改：`lib/jacalendar_web/router.ex`（新增路由）
- 修改：`lib/jacalendar_web/live/schedule_live.ex`、`checklist_live.ex`（頁籤導航更新）
