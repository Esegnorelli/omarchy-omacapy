-- Optional nvim hook: tell OmaCapy which language is in the current buffer.
--
--   luafile /path/to/omarchy-omacapy/nvim/omacapy.lua
--
-- or copy this file into ~/.config/nvim/plugin/omacapy.lua

local state = vim.fn.expand("~/.local/state/omarchy/omacapy-lang")

local function write_lang()
  vim.fn.mkdir(vim.fn.fnamemodify(state, ":h"), "p")
  local ft = vim.bo.filetype or ""
  local name = vim.fn.expand("%:t")
  local line = ft ~= "" and ft or name
  if line == "" then
    return
  end
  local ok, err = pcall(function()
    local f = assert(io.open(state, "w"))
    f:write(line .. "\n")
    f:close()
  end)
  if not ok then
    vim.notify("omacapy: " .. tostring(err), vim.log.levels.DEBUG)
  end
end

vim.o.title = true
vim.o.titlestring = "%t"

vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
  group = vim.api.nvim_create_augroup("OmaCapyLang", { clear = true }),
  callback = write_lang,
})
