## Context

Jacalendar 是一個 Phoenix 1.8 應用，目標是讓使用者上傳旅行行程 Markdown，解析後在 Web UI 上調整時間，最終匯出到 Apple 行事曆。

目前是全新專案，沒有既有的解析邏輯。參考的 Markdown 格式來自實際的東京旅行行程檔案，結構為巢狀 bullet list，含 `### Day N: YYYY/MM/DD` 標題。

## Goals / Non-Goals

**Goals:**

- 將旅行行程 Markdown 解析為結構化 Elixir 資料
- 支援明確時間（`**HH:MM**:`）、模糊時段（早上/下午/晚上）、無時間三種狀態
- 解析每日標題中的日期、星期、主題
- 解析航班與住宿等 metadata
- 輸出易於後續 Web UI 與行事曆匯出使用的資料結構

**Non-Goals:**

- 不處理 UI 顯示邏輯（屬於下一個 change）
- 不處理 Apple 行事曆匯出（屬於第三個 change）
- 不支援任意格式的 Markdown，僅支援旅行行程的特定格式
- 不做 Markdown 編輯或回寫

## Decisions

### 使用純 Elixir 正則表達式解析，不引入外部 Markdown parser

旅行行程 Markdown 的結構是固定的巢狀 bullet list，不需要完整的 Markdown AST。用 `Regex` + `String` 模組逐行解析即可，避免不必要的依賴。

### 資料結構設計

```elixir
# 整份行程
%Jacalendar.Itinerary{
  title: "東京 6 天 5 夜咖啡與美食之旅",
  date_range: {~D[2026-04-16], ~D[2026-04-21]},
  metadata: %{flights: [...], hotel: %{...}},
  days: [%Day{}, ...]
}

# 單日
%Jacalendar.Itinerary.Day{
  date: ~D[2026-04-16],
  weekday: "四",
  title: "抵達與新宿之夜",
  items: [%Item{}, ...]
}

# 單一行程項目
%Jacalendar.Itinerary.Item{
  time: {:exact, ~T[17:15:00]} | {:fuzzy, :morning} | :pending,
  description: "抵達成田機場 (NRT)",
  sub_items: [...]
}
```

時間狀態用 tagged tuple 表示：
- `{:exact, Time}` — 有明確 HH:MM
- `{:fuzzy, atom}` — 模糊時段（`:morning`, `:afternoon`, `:evening`）
- `:pending` — 無時間資訊

### 解析策略：逐行 + 狀態機

以行為單位讀取，用目前的縮排層級和標題層級追蹤解析狀態：
1. `## ` 開頭 → metadata 區塊（航班、住宿）或行程表開始
2. `### Day N:` → 新的一天
3. `*   **HH:MM**:` → 有時間的行程項目
4. `*   **模糊時段**:` → 模糊時間項目
5. `*   **文字**:` → 無時間項目
6. 縮排的 `*` → sub-item

## Risks / Trade-offs

- **[格式耦合]** 解析器與特定 Markdown 格式緊密耦合 → 可接受，因為目標是解析使用者自己的行程格式，不是通用 Markdown parser
- **[模糊時段辨識]** 「早上」「上午」「下午」「傍晚」等中文時段詞彙需要窮舉 → 先支援常見詞彙，不匹配的歸類為 `:pending`
