if vim.g.loaded_mdpaste then
	return
end

vim.g.loaded_mdpaste = 1

vim.api.nvim_create_user_command("MDPaste", function()
	require("mdpaste").paste()
end, { desc = "MDPaste" })
