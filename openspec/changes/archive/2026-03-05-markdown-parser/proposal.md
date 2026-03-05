## Why

使用者有既存的旅行行程 Markdown 檔案（含日期、時間、地點、描述），需要一個解析器將其轉換為結構化資料，作為後續 Web UI 顯示與 Apple 行事曆匯出的基礎。

## What Changes

- 新增 Markdown 行程解析模組，支援解析旅行行程格式
- 解析每日行程標題（日期、星期、主題）
- 解析行程項目：明確時間（HH:MM）、模糊時段（早上/下午/晚上）、無時間
- 無明確時間的項目標記為「待補」（pending）
- 解析航班、住宿等 metadata 區塊
- 輸出結構化的 Elixir 資料結構，供後續功能使用

## Capabilities

### New Capabilities

- `markdown-parsing`: 解析旅行行程 Markdown 檔案，將巢狀 bullet list 格式轉換為結構化行程資料（日期、時間、地點、描述、時間狀態）

### Modified Capabilities

（無）

## Impact

- 新增檔案：`lib/jacalendar/markdown_parser.ex`
- 新增檔案：`test/jacalendar/markdown_parser_test.exs`
- 無既有程式碼受影響，這是全新功能
