## Context

目前 `ScheduleLive` 在 schedule 模式下，使用 `<div :for={day <- @itinerary.days}>` 一次渲染所有天數。行程資料從 `Itineraries.get_itinerary!/1` 取得，days 已按 position 排序。

## Goals / Non-Goals

**Goals:**

- 使用者可透過 pill 按鈕列篩選單日行程
- pill 顯示兩行：日期（MM/DD）與標題
- 按鈕列可橫向捲動，適配手機
- 預設顯示全部天數

**Non-Goals:**

- 不改變 URL routing（不做 per-day URL）
- 不改變資料結構或 DB schema
- 不做 swipe 手勢切換

## Decisions

### 使用 LiveView assign 管理篩選狀態

在 `mount/3` 加入 `selected_day` assign，初始值為 `nil`（代表全部）。點擊 pill 時觸發 `select_day` 事件，更新 assign。render 時根據 `selected_day` 過濾 `@itinerary.days`。

不使用 URL query params，因為這是暫時的 UI 狀態，不需要 bookmark 或分享。

### Pill 按鈕列放在行程標題下方

放在標題與 metadata 之間，使用 `overflow-x-auto` 實現橫向捲動。使用 DaisyUI 的 `btn` 元件搭配 `btn-active` 表示選中狀態。

### 按天 ID 而非日期篩選

使用 `day.id` 作為篩選鍵，避免日期格式轉換問題。`nil` 代表全部。

## Risks / Trade-offs

- [風險] 天數很多（>10天）pill 列會很長 → 橫向捲動解決，可接受
- [取捨] 不持久化篩選狀態 → 重新整理會回到「全部」，這是合理的預設行為
