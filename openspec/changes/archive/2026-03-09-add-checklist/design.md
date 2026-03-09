## Context

目前 Jacalendar 解析 markdown 時會處理航班、住宿、每日行程，但忽略「必訪景點清單」段落。使用者希望在 app 中追蹤哪些景點已造訪。

現有架構：
- `MarkdownParser` 解析 markdown → `%Itinerary{}` struct
- `Itineraries` context 負責 DB 存取
- `ScheduleLive` 單一 LiveView 處理所有頁面

## Goals / Non-Goals

**Goals:**

- 解析 markdown 中的必訪景點清單段落
- 獨立 table 儲存清單項目，支援勾選狀態
- 獨立 LiveView 顯示清單，可勾選/取消
- 行程表與清單之間可 tab 切換

**Non-Goals:**

- 不做景點與每日行程的關聯（哪天去哪個景點）
- 不做地圖或路線規劃
- 不做清單項目的編輯（名稱、地點等）— 只做勾選

## Decisions

### Checklist 資料表設計

使用獨立的 `checklist_items` table，欄位：

| 欄位 | 型態 | 說明 |
|------|------|------|
| id | bigint (PK) | 自動產生 |
| name | string | 景點名稱（如 "GLITCH TOKYO"） |
| location | string | 地點（如 "日本橋"） |
| note | string, nullable | 備註（如 "需預約"、"每日任務"） |
| checked | boolean, default false | 勾選狀態 |
| position | integer | 排序 |
| itinerary_id | references | 關聯到 itineraries |

選擇獨立 table 而非 metadata JSON，因為勾選是頻繁的寫入操作。

### Markdown 解析格式

目標段落格式：
```
## 📍 必訪景點清單 (更新)
1.  **GLITCH TOKYO** (日本橋)
2.  **KOFFEE MAMEYA Kakeru** (清澄白河) - **需預約**
```

解析規則：
- 匹配 `## ` 開頭含「必訪景點清單」的 section header
- 每行匹配 `\d+\.\s+\*\*(.+?)\*\*\s*\((.+?)\)(?:\s*-\s*\*\*(.+?)\*\*)?`
- 提取：name (bold text)、location (括號內)、note (dash 後的 bold text，可選)

### 獨立 ChecklistLive

新建 `ChecklistLive` 而非擴展 `ScheduleLive`，因為後者已 800+ 行。路由 `/itineraries/:id/checklist`。

### Tab 導覽

在 `ScheduleLive` 和 `ChecklistLive` 頁面上方加入共用的 tab bar，使用 `<.link navigate={...}>` 切換。不用 shared component，直接在兩個 LiveView 各自 render tab。

## Risks / Trade-offs

- [風險] 清單段落格式不統一 → 緩解：regex 設計寬鬆一些，允許有無 emoji、有無「更新」等字樣
- [風險] 刪除 itinerary 時需 cascade 刪除 checklist_items → 緩解：migration 中設定 `on_delete: :delete_all`
