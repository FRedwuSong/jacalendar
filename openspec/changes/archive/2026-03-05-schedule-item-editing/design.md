## Context

ScheduleLive 已有時間 inline 編輯功能（點擊 → time input → 確認），使用 `editing_item_id` assign 追蹤正在編輯的項目。行程資料目前存在 LiveView process 的 `itinerary` assign 中，以 index 定位 day/item。

## Goals / Non-Goals

**Goals:**

- 描述欄位支援 inline 編輯（點擊 → text input → 確認/取消）
- Sub-items 支援逐筆編輯、刪除、新增
- 與既有的時間編輯共用一致的互動模式

**Non-Goals:**

- 不做整個行程項目的刪除
- 不做拖放排序
- 不做資料持久化（仍為 in-memory）

## Decisions

### 使用統一的 editing state 追蹤所有編輯操作

將 `editing_item_id` 擴展為更通用的 `editing` assign，格式為 `{type, day_idx, item_idx, sub_idx}`：
- `{:description, day_idx, item_idx}` — 編輯描述
- `{:sub_item, day_idx, item_idx, sub_idx}` — 編輯 sub-item
- `{:new_sub_item, day_idx, item_idx}` — 新增 sub-item
- `{:time, day_idx, item_idx}` — 時間編輯（取代原本的 `editing_item_id`）

這樣同一時間只會有一個編輯框，避免 UI 混亂。

### Inline 編輯統一使用 text input + Enter 確認

所有文字編輯（描述、sub-item）都用相同的互動模式：點擊文字 → 變成 input → Enter 或 blur 確認 → Escape 取消。保持一致性。

## Risks / Trade-offs

- **[單一編輯限制]** 同一時間只能編輯一個欄位 → 可接受，避免複雜度，使用者很少需要同時編輯多個欄位
- **[Index-based 定位]** 用 index 定位 item/sub-item，如果排序改變可能錯位 → 目前只有時間編輯會觸發排序，編輯描述和 sub-items 不會，所以安全
