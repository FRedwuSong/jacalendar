## Why

選擇單日時，清單視圖無法直覺呈現行程的時間分佈。需要 Google Calendar 風格的垂直時間軸，讓使用者一眼掌握當天已排定行程的時間配置。

## What Changes

- 選擇單日（pill 按鈕）時，從清單視圖切換為垂直時間軸視圖
- 時間軸只顯示有精確時間（exact time）的項目，按時間定位
- 未排定項目（fuzzy/pending）顯示在時間軸上方的附註區
- 選「全部」時維持現有清單視圖不變
- 時間軸範圍動態計算，只涵蓋有項目的時段

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `schedule-display`: 單日視圖從清單改為時間軸 + 附註區的雙區塊佈局

## Impact

- 受影響的 spec：`schedule-display`
- 受影響的程式碼：
  - `lib/jacalendar_web/live/schedule_live.ex` — render 邏輯大幅調整，新增時間軸 UI 元件
