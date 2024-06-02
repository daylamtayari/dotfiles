return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    vim.treesitter.language.register("markdown", "mdx")
    -- vim.list_extend(opts.highlight.disable, { "tsx" })
    opts.highlight = { enable = true }
    opts.indent = { enable = true }
    if type(opts.ensure_installed) == "table" then
      vim.list_extend(opts.ensure_installed, {
        -- latex
        "bibtex",
        "latex",
        -- documents
        "markdown",
        "json",
        -- vim
        "vim",
        "vimdoc",
        -- web
        "html",
        "css",
        "javascript",
        "typescript",
        "tsx",
        -- languages
        "lua",
        "go",
        "python",
        "java",
        "c",
        "cpp",
        "rust"
      })
    end
    if type(opts.highlight.disable) == "table" then
      vim.list_extend(opts.highlight.disable, { "latex", "bibtex" })
    else
      opts.highlight.disable = { "latex", "bibtex" }
    end
  end,
}

