## Context

Jacalendar 已有 `Jacalendar.MarkdownParser` 能將旅行行程 Markdown 解析為 `%Itinerary{}` struct。現在需要 Web UI 讓使用者在瀏覽器中操作這些資料。

目前的 router 只有一個預設的 `PageController :home`，需要替換為 LiveView。

## Goals / Non-Goals

**Goals:**

- 提供 Markdown 文字輸入區，貼上後即時解析並顯示行程
- 以每日為單位、時間軸方式顯示行程項目
- 以當下時間為分隔線，視覺上區分已過/未來行程
- 讓使用者能對 fuzzy/pending 時間的項目設定明確時間

**Non-Goals:**

- 不處理 Apple 行事曆匯出（第三個 change）
- 不做使用者帳號/登入
- 不做 Markdown 檔案儲存到資料庫（目前純 in-memory）
- 不做多人協作

## Decisions

### 使用單一 LiveView 頁面搭配狀態切換

兩個狀態：
1. **輸入模式** — 顯示 textarea，使用者貼上 Markdown
2. **行程模式** — 顯示解析後的行程表

用 LiveView assign 切換，不需要多個頁面或 route。

### 時間分隔線使用 JS hook 取得客戶端時間

伺服器不知道使用者的當地時間。用 `phx-hook` 在 mount 時從瀏覽器取得當下時間，再 `pushEvent` 回 LiveView 更新 assign。每分鐘自動更新一次。

### 時間編輯使用 inline form

對於 fuzzy/pending 時間的項目，點擊時間區域會顯示 `<.input type="time">` 讓使用者設定。確認後更新對應 item 的 time 為 `{:exact, Time}`。

### 行程資料用 stream 管理

每日的行程項目使用 LiveView stream，避免整頁重新渲染。更新單一 item 時間時只需 `stream_insert` 該項目。

## Risks / Trade-offs

- **[時區問題]** 使用客戶端時間避免了時區處理，但如果使用者跨時區查看行程，分隔線位置可能不符預期 → 可接受，目前不需要處理
- **[資料不持久]** 行程資料只存在 LiveView process 中，頁面重整就消失 → 可接受，目前需求是查看與調整，不是長期儲存
