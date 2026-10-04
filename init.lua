-- Neovim config: Tree-sitter syntax highlighting
-- Requires Neovim 0.12+ (uses the built-in vim.pack plugin manager)

-- ---------------------------------------------------------------- truecolor
-- Without this you are limited to a 16-colour palette and every colourscheme
-- looks flat. If your terminal turns out not to support truecolour, set this
-- to false and highlighting still works, just with fewer colours.
vim.o.termguicolors = true
vim.o.background = 'dark'

-- ------------------------------------------------------------------ plugins
-- vim.pack is built in, so there is no bootstrap block to maintain.
-- nvim-treesitter is pinned to 'main': the 'master' branch is frozen and does
-- not support the 0.12 API.
local plugins_ok = pcall(vim.pack.add, {
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  { src = 'https://github.com/catppuccin/nvim', name = 'catppuccin' },
})

-- -------------------------------------------------------------- colourscheme
-- The catppuccin plugin defines the @-prefixed Tree-sitter capture groups
-- (@type, @parameter, @variable.member, ...) with distinct colours. The
-- catppuccin that ships inside Neovim only defines the classic groups, so
-- captures would collapse onto a handful of fallback colours.
local colors_ok = false
if plugins_ok then
  colors_ok = pcall(function()
    require('catppuccin').setup({
      flavour = 'mocha',
      integrations = { treesitter = true },
    })
    vim.cmd.colorscheme('catppuccin')
  end)
end

-- Fall back to a bundled scheme so a failed clone never leaves you on the
-- washed-out default.
if not colors_ok then
  pcall(vim.cmd.colorscheme, 'habamax')
end

-- ------------------------------------------------------------- tree-sitter
-- 'cpp' is the one that matters here; Neovim bundles 'c' but not 'cpp'.
-- The rest are cheap and cover the usual scratch files.
local PARSERS = {
  'cpp', 'c', 'python', 'lua', 'vim', 'vimdoc',
  'markdown', 'markdown_inline', 'json', 'bash',
}

if plugins_ok then
  pcall(function()
    require('nvim-treesitter').install(PARSERS)
  end)
end

-- Turn Tree-sitter highlighting on per buffer. Driven off whether a parser
-- actually exists for the filetype, so this needs no per-language list and
-- silently does nothing for filetypes you have not installed.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter_highlight', { clear = true }),
  callback = function(args)
    local buf = args.buf
    local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
    if not lang then
      return
    end

    -- Fails when the parser is missing or still compiling; that is fine,
    -- the regex syntax stays active as a fallback.
    if not pcall(vim.treesitter.start, buf, lang) then
      return
    end

    -- Tree-sitter-aware indentation.
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

    -- Folding, but opened all the way so files do not land collapsed.
    vim.wo.foldmethod = 'expr'
    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    vim.wo.foldlevel = 99
  end,
})
