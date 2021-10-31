let g:scrollview_winblend = 0
hi ScrollView ctermbg=242 guibg=#424242

map z/ <Plug>(incsearch-fuzzy-/)
map z? <Plug>(incsearch-fuzzy-?)
map zg/ <Plug>(incsearch-fuzzy-stay)

" map /  <Plug>(incsearch-forward)
" map ?  <Plug>(incsearch-backward)
" map g/ <Plug>(incsearch-stay)

nnoremap gpd <cmd>lua require('goto-preview').goto_preview_definition()<CR>
nnoremap gpi <cmd>lua require('goto-preview').goto_preview_implementation()<CR>
nnoremap gP <cmd>lua require('goto-preview').close_all_win()<CR>
nnoremap gpr <cmd>lua require('goto-preview').goto_preview_references()<CR>


let g:diagnostic_virtual_text_prefix = ''
let g:diagnostic_enable_virtual_text = 1

let g:completion_matching_strategy_list = ['exact', 'substring', 'fuzzy']
let g:completion_enable_snippet = 'UltiSnips'
let g:completion_matching_smart_case = 1
let g:completion_trigger_on_delete = 1

" Errors in Red
hi LspDiagnosticsVirtualTextError guifg=Red ctermfg=Red

" Warnings in Yellow
hi LspDiagnosticsVirtualTextWarning guifg=Yellow ctermfg=Yellow

" Info and Hints in White
hi LspDiagnosticsVirtualTextInformation guifg=White ctermfg=White
hi LspDiagnosticsVirtualTextHint guifg=White ctermfg=White

" Underline the offending code
hi LspDiagnosticsUnderlineError guifg=NONE ctermfg=NONE cterm=underline gui=underline
hi LspDiagnosticsUnderlineWarning guifg=NONE ctermfg=NONE cterm=underline gui=underline
hi LspDiagnosticsUnderlineInformation guifg=NONE ctermfg=NONE cterm=underline gui=underline
hi LspDiagnosticsUnderlineHint guifg=NONE ctermfg=NONE cterm=underline gui=underline

" Set completeopt to have a better completion experience
set completeopt=menuone,noinsert,noselect

" Avoid showing message extra message when using completion
set shortmess+=c

let scrollview_mode='flexible'
let scrollview_winblend=0

" let g:rooter_manual_only = 1

" Fugitive {{{
nnoremap <silent> <leader>f :diffget //2<CR>
nnoremap <silent> <leader>j :diffget //3<CR>
" }}}

" " TreeSitter{{{
lua <<EOF
require'nvim-treesitter.configs'.setup {
 ensure_installed = {"toml" ,"html","css","json","go","latex","c","cpp","java","rust","python"},     -- one of "all", "language", or a list of languages
 highlight = {
   enable = true,              -- false will disable the whole extension
 },
}
EOF
" }}}
" ALE {{{
""""""""""
"  ALE  "
""""""""""
let g:ale_linters = {
      \ 'tex': ['lacheck'],
      \ 'python': ['flake8']
      \}

nmap <F2> <Plug>(ale_fix)

let g:ale_fixers = { 'c':['clangtidy'], 'cpp':['clangtidy'] }
" }}}
" LaTeX {{{
"""""""""""
"  LaTeX  "
"""""""""""
autocmd FileType plaintex set ft=tex
" }}}
" Vimtex {{{
""""""""""""
"  Vimtex  "
""""""""""""
let g:vimtex_compiler_progname = 'nvr'
let g:tex_flavor='latex'
let g:vimtex_quickfix_mode=0
" set conceallevel=0
" let g:tex_conceal='abdmg'
set fillchars=fold:\ "
let g:vimtex_fold_enabled = 1
let g:vimtex_view_general_viewer = 'okular'
let g:vimtex_view_general_options = '--unique file:@pdf\#src:@line@tex'
let g:vimtex_view_general_options_latexmk = '--unique'
" }}}
" LanguageClient {{{
nnoremap <silent> <c-]> <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> K     <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent> gD    <cmd>lua vim.lsp.buf.implementation()<CR>
" nnoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
nnoremap <silent> 1gD   <cmd>lua vim.lsp.buf.type_definition()<CR>
nnoremap <silent> gr    <cmd>lua vim.lsp.buf.references()<CR>
nnoremap <silent> g0    <cmd>lua vim.lsp.buf.document_symbol()<CR>
nnoremap <silent> gW    <cmd>lua vim.lsp.buf.workspace_symbol()<CR>
nnoremap <silent> gd    <cmd>lua vim.lsp.buf.declaration()<CR>

" Set completeopt to have a better completion experience
set completeopt=menuone,noinsert,noselect

" }}}
" Close-buffers  {{{
" Open buffer deletion menu
nnoremap <silent> Q     :Bdelete menu<CR>
" }}}
" Quickscope settings{{{
" Trigger a highlight in the appropriate direction when pressing these keys:
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']
let g:qs_lazy_highlight = 1
" }}}
" Codelens {{{
let g:codelens_auto = 1
let g:codelens_fg_colour='#1da374'
" }}}
" Vim Hardtime {{{
" let g:hardtime_default_on = 1
let g:hardtime_showmsg = 1
let g:hardtime_allow_different_key = 1
"}}}
" Indentline {{{
""""""""""""""
" indentLine "
""""""""""""""
let g:indent_blankline_char = '│'
highlight IndentBlanklineChar guifg=#6B7089 gui=nocombine
highlight WhiteSpace guifg=#6B7089 gui=nocombine
set listchars=space:⋅
let g:indent_blankline_space_char_blankline = " "

let g:indentLine_fileTypeExclude = ['tex', 'help', 'json', 'alpha', 'terminal']
let g:indent_blankline_use_treesitter = v:true
" let g:indent_blankline_show_current_context = v:true
let g:indent_blankline_context_highlight_list = ['Error', 'Warning']
" }}}
" Auto Format {{{
"""""""""""""""""
"  Auto_format  "
"""""""""""""""""
au BufWrite * :Autoformat  " Auto reformat files on write
autocmd FileType Dockerfile,template,nasm,taskedit,sql,gitcommit,octave,tex,conf,rofi,asm,mips,scheme,vim,yaml,vimwiki,text,snippets,zsh,term let b:autoformat_autoindent=0 " Except these filetypes
" }}}
" Emmet {{{
"""""""""""
"  Emmet  "
"""""""""""
" let g:user_emmet_install_global = 0                   " Only make Emmet
" autocmd FileType html,css,vue,javascript EmmetInstall " active for HTML/CSS

"Change Emmet.vim leader key
" let g:user_emmet_leader_key='<C-e>'
" }}}
" NERDCommenter {{{
"""""""""""""""""
" NERDCommenter "
"""""""""""""""""
" let NERDSpaceDelims = 1
" }}}
" NERDTree GIT {{{
""""""""""""""""""
"  NERDTree GIT  "
""""""""""""""""""
" let g:NERDTreeIndicatorMapCustom = {
"       \ "Modified"  : "",
"       \ "Staged"    : "",
"       \ "Renamed"   : "➜",
"       \ "Unmerged"  : "",
"       \ "Dirty"     : "",
"       \ "Clean"     : "✓",
"       \ 'Ignored'   : '⊠',
"       \ "Untracked" : "?"
"       \ }
"
" let g:NERDTreeShowIgnoredStatus = 1 " Show ignored files in NERDTree
" }}}
" Lightline {{{
"""""""""""""""
"  LightLine  "
"""""""""""""""
" let g:lightline = {
      " \ 'component': {
      " \   'lineinfo': ' %3l:%-2v',
      " \ },
      " \ 'colorscheme': 'nord',
      " \ 'active': {
      " \   'left': [ [ 'mode', 'paste' ], [ 'fugitive', 'filename'], [ 'gitdiff' ]]
      " \ },
      " \ 'inactive': {
      " \   'left': [ [ 'filename', 'gitversion'  ]  ],
      " \ },
      " \ 'component_expand': {
      " \   'gitdiff': 'lightline#gitdiff#get',
      " \
      " \ },
      " \ 'component_type': {
      " \   'gitdiff': 'middle',
      " \
      " \ },
      " \ 'component_function': {
      " \   'fugitive': 'LightlineFugitive',
      " \   'filename': 'LightlineFilename',
      " \   'readonly': 'LightlineReadonly',
      " \   'scrollstatus': 'ScrollStatus'
      " \ },
      " \ 'separator': { 'left': '', 'right': '' },
      " \ 'subseparator': { 'left': '', 'right': '' }
      " \ }

" function! LightlineModified()
  " return &ft =~ 'help\|vimfiler' ? '' : &modified ? '+' : &modifiable ? '' : '-'
" endfunction
" function! LightlineReadonly()
  " return &readonly ? '' : ''
" endfunction
" function! LightlineFilename()
  " return ('' != LightlineReadonly() ? LightlineReadonly() . ' ' : '') .
        " \ (&ft == 'vimfiler' ? vimfiler#get_status_string() :
        " \  &ft == 'unite' ? unite#get_status_string() :
        " \  &ft == 'vimshell' ? vimshell#get_status_string() :
        " \ '' != expand('%:t') ? expand('%:t') : '[No Name]') .
        " \ ('' != LightlineModified() ? ' ' . LightlineModified() : '')
" endfunction
" function! LightlineFugitive()
  " if exists('*FugitiveHead')
    " let branch = FugitiveHead()
    " return branch !=# '' ? ''.branch : ''
  " endif
  " return ''
" endfunction
" }}}
" Easy Align {{{
""""""""""""""""
"  Easy Align  "
""""""""""""""""
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)
" }}}
" Auto Pairs {{{
""""""""""""""""
"  Auto Pairs  "
""""""""""""""""
"let b:AutoPairs = {'(':')', '[':']', '{':'}',"'":"'",'"':'"'}
"let g:AutoPairsMapCR = 1
" }}}
" Fileheader {{{
""""""""""""""""
"  Fileheader  "
""""""""""""""""
nnoremap <leader>a :AddFileHeader<CR>
nnoremap <leader>u :UpdateFileHeader<CR>
let g:fileheader_delimiter_map = {
      \ 'mips': { 'begin': '# ', 'char': '# ', 'end': '# ' }
      \ }
" }}}
" echodoc {{{
"""""""""""
" echodoc "
"""""""""""
" set cmdheight=1
" let g:echodoc#enable_at_startup = 1
" let g:echodoc#type = "floating"
" }}}
" Vimagit {{{
"""""""""""
" vimagit "
"""""""""""
nnoremap <leader>gs :Magit<CR>
" }}}
" gitgutter {{{
"""""""""""""
" gitgutter "
"""""""""""""
let g:gitgutter_override_sign_column_highlight = 1

" Jump between hunks
nmap <Leader>gn <Plug>(GitGutterNextHunk)  " git next
nmap <Leader>gp <Plug>(GitGutterPrevHunk)  " git previ

" Hunk-add and hunk-revert for chunk staging
nmap <Leader>ga <Plug>(GitGutterStageHunk)  " git add (chunk)
nmap <Leader>gu <Plug>(GitGutterUndoHunk) " git undo (chunk)

" Use fontawesome icons as signs
let g:gitgutter_sign_added = ''
let g:gitgutter_sign_modified = ''
let g:gitgutter_sign_removed = ''
let g:gitgutter_sign_removed_first_line = ''
let g:gitgutter_sign_modified_removed = ''
" }}}
" vim-fugitive {{{
""""""""""""""""
" vim-fugitive "
""""""""""""""""
nnoremap <Leader>gB :Gblame<CR>   " git blame
nnoremap <Leader>gb :.Gbrowse<CR> " Open current line in the browser
vnoremap <Leader>gb :Gbrowse<CR>  " Open visual selection in the browser
nnoremap <Leader>gaf :Gw<CR>      " git add file
" }}}
"Python Mode {{{
"""""""""""""""
" Python Mode "
"""""""""""""""
let g:pymode_options_colorcolumn = 0 " Turn off colorcolumn
let g:pymode_lint = 0                " We use ALE for linting
"}}}
" Rainbow Parenthesis {{{
"""""""""""""""""""""""
" Rainbow Parenthesis "
"""""""""""""""""""""""
" let g:rainbow#max_level = 16
" let g:rainbow#pairs = [['(', ')'], ['[', ']'], ['{', '}']]
" let g:rainbow_active = 1 "set to 0 if you want to enable it later via :RainbowToggle
" }}}
" Hexokinase {{{
""""""""""""""
" Hexokinase "
""""""""""""""
let g:Hexokinase_ftAutoload = ['css']                            " Autoload for CSS files
let g:Hexokinase_refreshEvents = ['TextChanged', 'TextChangedI'] " Update colors on text change
let g:Hexokinase_highlighters = [ 'backgroundfull' ]
" }}}
" git-messenger {{{
"""""""""""""""""
" git-messenger "
"""""""""""""""""
nmap <Leader>gm :GitMessenger<CR>
" }}}
" javascript-syntax-libraries {{{
"""""""""""""""""""""""""""""""
" javascript-syntax-libraries "
"""""""""""""""""""""""""""""""
" let g:used_javascript_libs = 'angularjs'
" }}}
" vim-floaterm {{{
""""""""""""""""
" vim-floaterm "
""""""""""""""""
noremap    <Leader>r :FloatermNew ranger<CR>
nnoremap   <silent>   <F7>    :FloatermNew<CR>
tnoremap   <silent>   <F7>    <C-\><C-n>:FloatermNew<CR>
nnoremap   <silent>   <F8>    :FloatermPrev<CR>
tnoremap   <silent>   <F8>    <C-\><C-n>:FloatermPrev<CR>
nnoremap   <silent>   <F9>    :FloatermNext<CR>
tnoremap   <silent>   <F9>    <C-\><C-n>:FloatermNext<CR>
nnoremap   <silent>   <F12>   :FloatermToggle<CR>
tnoremap   <silent>   <F12>   <C-\><C-n>:FloatermToggle<CR>
let g:floaterm_position = 'center'
let g:floaterm_winblend = 30
let g:floaterm_height   = 0.7
let g:floaterm_width    = 0.7
let g:floaterm_opener   = 'edit'
autocmd User Startified setlocal buflisted
" }}}
" Startify {{{
""""""""""""
" Startify "
""""""""""""
" let g:startify_fortune_use_unicode = 1
" }}}
" Lens.vim {{{
""""""""""""
" Lens.vim "
""""""""""""
let g:lens#disabled_filetypes = ['nerdtree', 'fzf','', 'scratch', '__vista__', 'Scratch']
let g:lens#animate = 0
let g:lens#width_resize_min = float2nr(&columns * 0.2)
let g:lens#width_resize_max = float2nr(&columns * 0.8)
let g:lens#height_resize_min= float2nr(&lines * 0.2)
let g:lens#height_resize_max = float2nr(&lines * 0.8)
" }}}
" FZF {{{
"""""""
" FZF "
"""""""
nnoremap <C-p> :Files<CR>
nnoremap <C-y> :Windows<CR>
nnoremap <C-b> :Buffers<CR>

" Configure FZF to use a floating window configuration
" let $FZF_DEFAULT_OPTS = '--layout=reverse --multi'
let g:fzf_colors =
      \ { 'fg':      ['fg', 'Normal'],
      \   'bg':      ['bg', 'Normal'],
      \   'hl':      ['fg', 'Comment'],
      \   'fg+':     ['fg', 'CursorLine'],
      \   'bg+':     ['bg', 'Normal'],
      \   'hl+':     ['fg', 'Statement'],
      \   'info':    ['fg', 'PreProc'],
      \   'border':  ['fg', 'CursorLine'],
      \   'prompt':  ['fg', 'Conditional'],
      \   'pointer': ['fg', 'Exception'],
      \   'marker':  ['fg', 'Keyword'],
      \   'spinner': ['fg', 'Label'],
      \   'header':  ['fg', 'Comment'] }

let g:fzf_layout = { 'window': 'call CreateCenteredFloatingWindow()' }

function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --column --no-ignore --line-number --no-heading --color=always --smart-case -- %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction

command! -nargs=* -bang Rg call RipgrepFzf(<q-args>, <bang>0)

nnoremap <C-s> :Rg<CR>
" }}}
" TMUXLine {{{
""""""""""""
" TMUXLine "
""""""""""""
" let g:tmuxline_preset = {
"       \'a'    : '#S',
"       \'win'  : ['#I', '#W'],
"       \'cwin' : ['#I', '#W', '#F'],
"       \'y'    : ['#{prefix_highlight}', '%R', '%a', '%Y'],
"       \'z'    : '#{prefix_highlight}'}
"
" let g:tmuxline_theme = 'vim_statusline_3'
" }}}
" LazyGit {{{
"""""""""""
" LazyGit "
"""""""""""
" Open lazygit
nnoremap <silent> <Leader>' :call ToggleLazyGit()<CR>
" }}}
