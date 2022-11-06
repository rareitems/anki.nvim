<h1 align='center'>anki.nvim</h1>

Create anki cards directly from your neovim.

![anki](https://user-images.githubusercontent.com/83038443/200166900-42f2be8c-15f3-4929-9a36-147ed8fc7720.gif)

## Requirements

- Neovim >= 0.8.0
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [AnkiConnect](https://ankiweb.net/shared/info/2055492159)
- curl

## Installation and Setup

- With [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use({
  "rareitems/anki.nvim",
  config = function()
    require("anki").setup({
      -- this function will add support for associating '.anki' extension with 'anki' filetype.
      tex_support = false,
      models = {
        -- Here you specify which notetype should be associated with which deck
        Notetype = "Deck Path",
        ["Super Basic"] = "Deck::ChildDeck",
      },
    })
  end,
})
```


See more details under Config section in [help file](doc/anki.txt).

## Usage

1. Setup neovim plugin.
2. Launch your anki
3. Make sure AnkiConnect works. Try going to (localhost:8765) and see if anything is shown. If you have any problems check AnkiConnect page (https://foosoft.net/projects/anki-connect/)
4. Enter a filename with '.anki' extension. If it loads _very_ slowly it probably cannot make a connection to AnkiConnect.
5. Fill the current buffer with anki card form using ':Anki <your notetype>' command
6. Fill the space between field name with information you want to remember and you want to be inside this field. This is will be send as raw HTML. So for example if you want a newline put '\<br\>'.
7. Send it to anki directly using ':AnkiSend' or send it to anki's GUI 'Add' using ':AnkiSendGui' if you want to add picture
