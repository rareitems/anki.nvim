syntax match C contained "%" conceal cchar= 
syntax match Cnothing contained "%" conceal cchar=-

syntax match ankiDeckname /^%%DECKNAME/ contains=C
syntax match ankiModelname /^%%MODELNAME/ contains=C
syntax match ankiTags /^%%TAGS/ contains=C
syntax match ankiNoteId /^%%NOTEID/ contains=C

syntax match ankiField /^%\(\w\|\s\)*$/ contains=Cnothing

syn region ankiHtmlItalic start="<i>" end="</i>"
syn region ankiHtmlBold start="<b>" end="</b>"
