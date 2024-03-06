<h1 align='center'>anki.nvim</h1>

Create and add anki cards directly from your neovim.

![anki](https://user-images.githubusercontent.com/83038443/200166900-42f2be8c-15f3-4929-9a36-147ed8fc7720.gif)

## Features
- Create new cards directly from Neovim
- Edit cards directly from anki in Neovim
- Transform and lint your cards as you add them from Neovim

## Requirements

- Neovim >= 0.8.0
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [AnkiConnect](https://ankiweb.net/shared/info/2055492159)
- curl
- (optional) [xclip](https://github.com/astrand/xclip) and base64 for directly adding images from clipboard

## Installation and Setup

- with [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use({
  "rareitems/anki.nvim",
  config = function()
    require("anki").setup({
      -- this function will add support for associating '.anki' extension with both 'anki' and 'tex' filetype.
      tex_support = false,
      models = {
        -- Here you specify which notetype should be associated with which deck
        NoteType = "PathToDeck",
        ["Basic"] = "Deck",
        ["Super Basic"] = "Deck::ChildDeck",
      },
      -- linters = require("anki.linters").default_linters();
    })
  end,
})
```

- with [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "rareitems/anki.nvim",
  -- lazy -- don't lazy it, it tries to be as lazy possible and it needs to add a filetype association
  opts = {
    {
      -- this function will add support for associating '.anki' extension with both 'anki' and 'tex' filetype.
      tex_support = false,
      models = {
        -- Here you specify which notetype should be associated with which deck
        NoteType = "PathToDeck",
        ["Basic"] = "Deck",
        ["Super Basic"] = "Deck::ChildDeck",
      },
    }
  }
}
```

See more details under Config section in [help file](doc/anki.nvim.txt).

## Usage

1. Setup neovim plugin.
2. Launch your anki
3. Make sure AnkiConnect works. Try going to (localhost:8765) and see if anything is shown. If you have any problems check AnkiConnect page (https://foosoft.net/projects/anki-connect/)
4. Enter a filename with '.anki' extension. If it loads _very_ slowly it probably cannot make a connection to AnkiConnect.
5. Fill the current buffer with anki card form using ':Anki <your notetype>' command
6. Fill the space between field name with information you want to remember and you want to be inside this field. This is will be send as raw HTML.
7. Send it to anki directly using ':AnkiSend' or send it to anki's GUI 'Add' using ':AnkiSendGui' if you want to add picture

## Configuration

```lua
{
  models = --(table<string,string>) Table of names of notetypes to name of decks. Which notetype should be send to which deck
    {
      NoteType = "PathToDeck",
      ["Basic"] = "Deck",
      ["Super Basic"] = "Deck::ChildDeck",
    }
  contexts = nil --(table | nil) Optional Table of context names as keys with value of table with `tags` and `fields`. See `:h anki.context`.
  move_cursor_after_creation = true --(boolean) If `true` it will move the cursor the position of the first field
  linters = require("anki.linters").default_linters() --(Linter[] | nil) Your linters see `:h anki.linter`
  transformers = nil --(Transformer[] | nil) Your transformers `:h anki.transformer`
  tex_support = false --(boolean) Basic support for latex inside the `anki` filetype. See |anki.texSupport|.
  xclip_path = "xclip" --(string | nil) Path to the `xclip` binary
  base64_path = "base64" --(string | nil) Path to the `base64` binary
}
```
