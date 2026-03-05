## 1. 使用統一的 editing state 追蹤所有編輯操作

- [x] 1.1 將 `editing_item_id` assign 替換為統一的 `editing` assign，支援 `{:time, day_idx, item_idx}` 格式，並遷移現有時間編輯邏輯
- [x] 1.2 更新時間編輯相關的 event handlers（`edit_time`, `cancel_edit`, `save_time`）使用新的 editing state
- [x] 1.3 更新 template 中時間編輯的條件判斷，改用新的 `editing` assign

## 2. Description editing — inline 編輯統一使用 text input + Enter 確認

- [x] 2.1 新增 `edit_description` event handler，設定 `editing` 為 `{:description, day_idx, item_idx}`
- [x] 2.2 在 template 中實作 description editing 的 inline 編輯：點擊顯示 text input，支援 Enter/blur 確認、Escape 取消
- [x] 2.3 新增 `save_description` 和 `cancel_edit_description` event handlers，處理空字串描述情境
- [x] 2.4 撰寫 description editing 的測試（點擊編輯、確認、取消、空描述）

## 3. Sub-item editing

- [x] 3.1 新增 `edit_sub_item` event handler，設定 `editing` 為 `{:sub_item, day_idx, item_idx, sub_idx}`
- [x] 3.2 在 template 中實作 sub-item editing 的 inline 編輯：點擊顯示 text input，支援 Enter/blur 確認、Escape 取消
- [x] 3.3 新增 `save_sub_item` 和 `cancel_edit_sub_item` event handlers
- [x] 3.4 撰寫 sub-item editing 的測試

## 4. Sub-item deletion

- [x] 4.1 在每個 sub-item 旁新增刪除按鈕
- [x] 4.2 新增 `delete_sub_item` event handler，實作 sub-item deletion 邏輯
- [x] 4.3 撰寫 sub-item deletion 的測試

## 5. Sub-item addition

- [x] 5.1 在每個 schedule item 下方新增「新增子項目」按鈕
- [x] 5.2 新增 `add_sub_item` event handler，設定 `editing` 為 `{:new_sub_item, day_idx, item_idx}`，實作 sub-item addition 顯示 text input
- [x] 5.3 新增 `save_new_sub_item` event handler，將新 sub-item 附加到 item 的 sub_items 列表
- [x] 5.4 撰寫 sub-item addition 的測試
