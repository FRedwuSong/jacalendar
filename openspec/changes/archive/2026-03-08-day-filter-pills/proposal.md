## Why

目前行程表頁面一次顯示所有天數的明細，旅程天數多時畫面冗長，使用者難以快速定位到特定日期。需要按天篩選功能，讓使用者能快速切換查看單日行程。

## What Changes

- 在行程表頂部新增日期 pill 按鈕列，包含「全部」及每日按鈕
- 每個 pill 兩行顯示：上方日期（MM/DD）、下方標題
- 按鈕列支援橫向捲動，適配手機螢幕
- 選中某天時，只顯示該天的行程項目
- 選「全部」時恢復顯示所有天數

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `schedule-display`: 新增按天篩選的 UI 互動功能，從「一次顯示全部天數」擴展為「可選擇顯示單日或全部」

## Impact

- 受影響的 spec：`schedule-display`
- 受影響的程式碼：
  - `lib/jacalendar_web/live/schedule_live.ex` — 新增 `selected_day` assign 與篩選邏輯、pill UI 元件
