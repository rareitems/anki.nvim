

" syntax keyword Deckname %%DECKNAME
" syntax keyword Deckname
"
"
syntax match C contained "%" conceal cchar= 
syntax match Cnothing contained "%" conceal cchar=-

syntax match ankiDeckname /^%%DECKNAME/ contains=C
syntax match ankiModelname /^%%MODELNAME/ contains=C
syntax match ankiTags /^%%TAGS/ contains=C

syntax match ankiField /^%\(\w\|\s\)*$/ contains=Cnothing





syn region ankiHtmlItalic start="<i>" end="</i>"
syn region ankiHtmlBold start="<b>" end="</b>"

" hi def ankiHtmlItalic   term=italic cterm=italic gui=italic
" hi def ankiHtmlBold   term=bold cterm=bold gui=bold

" hi def Deckname term=bold cterm=bold gui=bold
" hi def Modelname term=bold cterm=bold gui=bold
" hi def Tags term=bold cterm=bold gui=bold
" hi def Field term=bold cterm=bold gui=bold

" hi def Items term=italic cterm=italic gui=italic

" syntax match 
"
