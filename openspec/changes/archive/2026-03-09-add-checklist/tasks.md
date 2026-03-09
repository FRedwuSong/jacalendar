## 1. 資料庫與 Schema（Checklist 資料表設計）

- [x] 1.1 建立 `checklist_items` migration（checklist item persistence，含 on_delete cascade delete）
- [x] 1.2 建立 `ChecklistItem` Ecto schema 與 changeset

## 2. Markdown 解析（Parse checklist section）

- [x] 2.1 在 `MarkdownParser` 新增 `parse_checklist/1`（parse checklist section，Markdown 解析格式）
- [x] 2.2 更新 `%Itinerary{}` struct 加入 `checklist` 欄位（parse complete itinerary）
- [x] 2.3 在 `Itineraries.create_itinerary/1` 中 serialize 並儲存 checklist items

## 3. Checklist LiveView（獨立 ChecklistLive）

- [x] 3.1 新增 `/itineraries/:id/checklist` route
- [x] 3.2 建立 `ChecklistLive`，載入並 display checklist 項目
- [x] 3.3 實作 toggle checklist item 勾選/取消事件

## 4. Tab 導覽

- [x] 4.1 在 `ScheduleLive` 加入 tab navigation between schedule and checklist
- [x] 4.2 在 `ChecklistLive` 加入 tab navigation between schedule and checklist
