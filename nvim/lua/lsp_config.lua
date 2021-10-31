vim.api.nvim_command [[ hi def link LspReferenceText  CursorLine ]]
vim.api.nvim_command [[ hi def link LspReferenceWrite CursorLine ]]
vim.api.nvim_command [[ hi def link LspReferenceRead  CursorLine ]]

-- Change diagnostic symbols in the gutter
local signs = { Error = " ", Warning = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "LspDiagnosticsSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- Use a loop to conveniently both setup defined servers
-- and map buffer local keybindings when the language server attaches
local servers = {"rust_analyzer"}

--[[local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)]]

vim.cmd [[autocmd CursorHoldI * lua vim.lsp.diagnostic.show_line_diagnostics({focusable=false})]]

local nvim_lsp = require('lspconfig')
local util = require("util")

for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup {
    on_attach = util.on_attach,
    capabilities = util.capabilities,
    update_in_insert = true,
  }
end
