local lspkind = require('lspkind')
local cmp = require("cmp")

cmp.setup({
  mapping = {
    ['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
    ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
    ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
    ['<C-e>'] = cmp.mapping.close(),
    ['<TAB>'] = cmp.mapping({
      c = cmp.mapping.confirm({ select = false }),
    }),
    ['<CR>'] = cmp.mapping({
      i = cmp.mapping.confirm({ select = true }),
    })
  },
  completion = {
    completeopt = 'menu,menuone,noinsert',
  },
  snippet = {
    expand = function(args)
      require'luasnip'.lsp_expand(args.body)
    end
  },
  formatting = {
    format = lspkind.cmp_format({with_text = true, maxwidth = 50})
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'nvim_lua' },
    { name = 'crates' },
    { name = 'buffer' },
    { name = 'orgmode' },
    { name = 'path' },
    { name = 'omni' },
    { name = 'calc' },
    { name = 'luasnip' },
    { name = 'vim-dadbod-completion' },
  },
  experimental = {
    ghost_text = true
  }
})
cmp.setup.cmdline(':', {
  sources = {
    { name = 'cmdline', keyword_length = 2 },
    { name = 'path' },
  }
})
-- Use buffer source for `/`.
cmp.setup.cmdline('/', {
  sources = {
    { name = 'buffer' },
  }
})
cmp.setup.cmdline('?', {
  sources = {
    { name = 'buffer' },
  }
})
