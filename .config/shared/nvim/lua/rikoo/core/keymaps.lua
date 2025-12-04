vim.g.mapleader = " " -- Set leader key to space

local keymap = vim.keymap -- for conciseness

-- ==================== 基础操作 ====================
keymap.set("i", "jk", "<ESC>", { desc = "退出插入模式 (jk)" })
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "清除搜索高亮 (nh)" })

-- ==================== 数字增减 ====================
keymap.set("n", "<leader>+", "<C-a>", { desc = "数字 +1 (+)" })
keymap.set("n", "<leader>-", "<C-x>", { desc = "数字 -1 (-)" })

-- ==================== 窗口管理 (s = split) ====================
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "垂直分割窗口 (sv)" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "水平分割窗口 (sh)" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "窗口等宽等高 (se)" })
keymap.set("n", "<leader>sx", ":close<CR>", { desc = "关闭当前窗口 (sx)" })

-- ==================== 标签页管理 (t = tab) ====================
keymap.set("n", "<leader>to", ":tabnew<CR>", { desc = "打开新标签页 (to)" })
keymap.set("n", "<leader>tx", ":tabclose<CR>", { desc = "关闭当前标签页 (tx)" })
keymap.set("n", "<leader>tn", ":tabn<CR>", { desc = "下一个标签页 (tn)" })
keymap.set("n", "<leader>tp", ":tabp<CR>", { desc = "上一个标签页 (tp)" })
keymap.set("n", "<leader>tf", ":tabnew %<CR>", { desc = "当前文件新标签打开 (tf)" })