## Context

目前 `ScheduleLive` 的 render 在 schedule 模式下，根據 `@selected_day` 過濾 days 後，以清單方式顯示所有 items。單日視圖需改為時間軸佈局。

現有資料結構中，每個 item 有 `time_type`（exact/fuzzy_morning/fuzzy_afternoon/fuzzy_evening/pending）和 `time_value`（Time 或 nil）。

## Goals / Non-Goals

**Goals:**

- 單日選中時，以垂直時間軸呈現已排定（exact time）項目
- 未排定項目（fuzzy/pending）顯示在時間軸上方的附註區
- 時間軸範圍動態計算，只顯示有項目的時段（前後各加 1 小時 padding）

**Non-Goals:**

- 不做拖拽調整時間
- 不做項目持續時間（duration）— 每個項目固定高度
- 不改變「全部」視圖的行為
- 不改變資料結構

## Decisions

### 使用 CSS Grid 實現時間軸佈局

使用 CSS Grid 而非絕對定位。左欄為小時標籤，右欄為項目區域。每小時一個 grid row，項目根據時間放入對應 row。

替代方案：absolute positioning — 需要手動計算 pixel 偏移，維護困難。

### 根據 time_type 分離項目為兩組

在 render 時將當天 items 分為：
- `scheduled_items`：`time_type == "exact"` 的項目
- `unscheduled_items`：其他所有項目（fuzzy/pending）

這個分離純粹在 template 層面完成，不需修改 context 或資料邏輯。

### 時間軸範圍動態計算

從 scheduled_items 中取最早和最晚時間，向前/後各取整到小時再各加 1 小時 padding。例如最早 09:15、最晚 17:30 → 顯示 08:00~18:00。

若無 scheduled_items，則不顯示時間軸區塊，只顯示附註區。

### 條件式渲染兩種視圖

在 render 中根據 `@selected_day` 決定渲染哪個視圖：
- `nil` → 現有清單視圖（不動）
- 有值 → 新的時間軸 + 附註區視圖

## Risks / Trade-offs

- [風險] 項目時間很接近時可能重疊 → 固定高度 + 足夠的 row 間距緩解，不做完美重疊處理
- [取捨] 不顯示 duration → 簡化實作，但視覺上無法看出活動長度
