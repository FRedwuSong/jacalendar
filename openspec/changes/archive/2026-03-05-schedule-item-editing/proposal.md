## Why

行程表目前只有 Read 和時間編輯，使用者無法修改描述或管理 sub-items。從 Markdown 匯入後如果需要微調行程內容（例如更新餐廳名稱、新增備註、刪除不需要的子項目），只能重新編輯 Markdown 再重新匯入，非常不方便。

## What Changes

- 行程項目的描述支援 inline 編輯
- Sub-items 支援逐筆 CRUD：編輯單筆、刪除單筆、新增一筆
- 描述清空時保留項目（不等於刪除項目）
- 不新增整個行程項目的刪除功能

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `schedule-display`: 新增行程項目描述編輯、sub-items 逐筆 CRUD 功能

## Impact

- 修改檔案：`lib/jacalendar_web/live/schedule_live.ex`（新增 event handlers 和 template）
- 修改檔案：`test/jacalendar_web/live/schedule_live_test.exs`（新增編輯測試）
