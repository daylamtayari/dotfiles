"Remap the arrow keys
"Move a line up
nnoremap <A-k> ddkP
"Move a line down
nnoremap <A-j> ddp
"Move a character left in normal mode
nnoremap <A-h> xhP
"Move a character right in normal mode
nnoremap <A-l> xp

"Disable all arrows in insert mode
inoremap <Up> <Nop>
inoremap <Down> <Nop>
inoremap <Left> <Nop>
inoremap <Right> <Nop>

"Allows easier navigation on lines that are broken
noremap j gj
noremap k gk

"Clear search highlights
nnoremap <C-c> :nohlsearch<CR>

"Close the quickfix window
nnoremap <leader>q :cclose<CR>

"Open $MYVIMRC in a vsplit
nnoremap <leader>ev :vsplit $MYVIMRC<cr>

"Source $MYVIMRC
nnoremap <leader>sv :source $MYVIMRC<cr>

" Window navigation
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
nnoremap <C-Q> <C-W><C-Q>
nnoremap <C-W>t :tabnew<CR>
nnoremap <C-W><C-t> :tabnew<CR>

" Shift-L clears screen since we remapped Ctrl-L
nnoremap L :mode<CR>

nnoremap <Tab> gt
nnoremap <S-Tab> gT
