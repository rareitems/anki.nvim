---@mod anki.configuration Configuration
---@brief [[
--- See |Config|
---@brief ]]

---@mod anki.Usage Usage
---@brief [[
--- Setup your config. See |anki.Config|
--- Launch your anki
--- Enter a filename with '.anki' extension
--- Create a form using ':Anki <your notetype>' command
--- Fill it with information you want to remember.
--- Send it to anki directly using ':AnkiSend' or send it to 'Add' GUI using ':AnkiSendGui' if you want to add picture
---@brief ]]

---@mod anki.Context Context
---@brief [[
--- Context can be used to prefill certain `field`s or `tag` during the creation of the buffer form using |anki.anki|
--- This can be used to mimic the idea of sticky fields from anki's 'Add' menu but with more control.
---
--- Context can be set either setting global variable |vim.g.anki_context| or using |:AnkiSetContext| command.
--->
--- vim.g.anki_context = { tags = "Rust ComputerScience", fields = { Context = "Rust" } }
--- vim.g.anki_context = "nvim"
---<
--- If context is a `string` your config's `contexts` subtable will be checked for corresponding value.
--- Contexts can be specified in your config like so
--->
--- contexts = {
---   nvim = {
---     tags = "shortcuts::nvim nvim",
---     fields = {
---       Context = "nvim",
---     },
---   },
--- },
---<
---@brief ]]

---@mod anki.Highlights Highlights
---@brief [[
---There are following highlights with their default values
--->
--- vim.api.nvim_set_hl(0, "ankiHtmlItalic", { italic = true })
--- vim.api.nvim_set_hl(0, "ankiHtmlBold", { bold = true })
--- vim.api.nvim_set_hl(0, "ankiDeckname", { link = "Special" })
--- vim.api.nvim_set_hl(0, "ankiModelname", { link = "Special" })
--- vim.api.nvim_set_hl(0, "ankiTags", { link = "Special" })
--- vim.api.nvim_set_hl(0, "ankiField", { link = "@namespace" })
---<
---@brief ]]

---@mod anki.TexSupport TexSupport
---@brief [[
---With this enabled files with '.anki' extension will be set to filetype `anki.tex` instead of simply `anki`
---And it also will add
--->
--- \documentclass[11pt, a4paper]{article}
--- \usepackage{amsmath}
--- \usepackage{amssymb}
--- \begin{document}
---   <rest of the form>
--- \end{document}
---<
---To the buffer while when |anki.anki| is run
---This allows you for usage of vimtex, tex snippets etc. while creating anki cards.
---@brief ]]

---@mod anki.Clozes Clozes
---@brief [[
---If you are using luasnip you can use something like this to create clozes more easily.
--->
--- local function cloze_same_line(_, _, _, _)
---   local a = vim.g.anki_cloze or 1
---   local t0 = t({ "{{c" .. a .. "::#" })
---   local t1 = i(1)
---   local t2 = t({ "}}" })
---   local t3 = i(0)
---   vim.g.anki_cloze = a + 1
---   return sn(nil, { t0, t1, t2, t3 })
---
---   s("CT", {
---     d(1, cloze_same_line, {}, {}),
---   }),
--- end
---<
---@brief ]]

local anki = {}

local has_loaded = false
local should_delete_command = false

local function notify_error(content)
  vim.api.nvim_notify("anki.nvim: " .. content, vim.log.levels.ERROR, {})
end

local function notify_info(content)
  vim.api.nvim_notify("anki.nvim: " .. content, vim.log.levels.INFO, {})
end

---@class Config
---@field tex_support boolean Basic support for latex inside the 'anki' filetype. See |anki.TexSupport|.
---@field models table Table of name of notetypes (keys) to name of decks (values). Which notetype should be send to which deck
---@field contexts table Table of context names as keys with value of table with `tags` and `fields`. See |anki.Context|.

---@type Config
local Config = {
  tex_support = false,
  models = {},
  contexts = {},
}

local function get_context(arg)
  if not arg then
    error("Context was neither given nor is vim.g.anki_context defined")
  end

  if type(arg) == "string" then
    if Config.contexts and Config.contexts[arg] then
      return Config.contexts[arg]
    else
      error("Supplied a string to context. But said context is not defined in the config or config is wronly defined")
    end
  end

  if type(arg) == "table" then
    return arg
  end

  error("Supplied or global config is neither a 'table' or 'string'")
end

--created in setup
local models_to_decknames = {}
local model_names = {}

--- Given `arg` a name of a notetype. Fills the current buffer with a form which later can be send to anki using `send` or `sendgui`.
---
--- Name of the fields on the form depend on the `arg`
--- Name of the deck depends on `arg` and user's config
---@param arg string
anki.anki = function(arg)
  local api = require("anki.api")
  local buffer = require("anki.buffer")

  if vim.bo.modified then
    notify_error("There are unsaved changes in the buffer")
    return
  end

  local status, fields = pcall(api.modelFieldNames, arg)
  if not status then
    error(fields)
  end

  local cont = buffer.create(fields, models_to_decknames[arg], arg, nil, Config.tex_support)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, cont)
end

--- The same thing as |anki.anki| but it will prefill 'fields' and 'tags' specified in the context
---@param arg string
---@param context string | table
anki.ankiWithContext = function(arg, context)
  local api = require("anki.api")
  local buffer = require("anki.buffer")

  if vim.bo.modified then
    notify_error("There are unsaved in the buffer")
    return
  end

  local status, fields = pcall(api.modelFieldNames, arg)
  if not status then
    error(fields)
  end

  context = get_context(context or vim.g.anki_context)
  if not context then
    return
  end

  local cont = buffer.create(fields, models_to_decknames[arg], arg, context, Config.tex_support)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, cont)
end

--- Sends the current buffer (which can be created using |anki.anki|) to the 'Add' GUI inside Anki.
--- '<br>' is going to be append to the end of seperate lines to get newlines inside Anki.
--- It will select the specified inside the buffer note type and deck.
--- This will always replace the content inside 'Add' and won't do any checks about it.
anki.sendgui = function()
  local api = require("anki.api")
  local buffer = require("anki.buffer")

  local cur_buf = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local parsed = buffer.parse(cur_buf)
  local a, b = pcall(api.guiAddCards, parsed)

  if a then
    notify_info("Card was sent to GUI Add Card")
    return
  else
    notify_error(b)
  end
end

--- Sends the current buffer (which can be created using |anki.anki|) directly to Anki.
--- '<br>' is going to be append to the end of seperate lines to get newlines inside Anki.
--- It will send it to the specified inside the buffer deck using specified note type.
--- If duplicate in the specified deck is detected the card won't be created and user will be prompted about it.
anki.send = function()
  local api = require("anki.api")
  local buffer = require("anki.buffer")

  local cur_buf = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local parsed = buffer.parse(cur_buf)
  local a, b = pcall(api.addNote, parsed)

  if a then
    notify_info("Card was added")
    return
  else
    if string.find(b, "duplicate") then
      notify_error("Card you are trying to add is a duplicate")
    else
      notify_error(b)
    end
  end
end

local function create_commands()
  vim.api.nvim_create_user_command("Anki", function(opts)
    local args = opts.args
    anki.anki(args)
  end, {
    nargs = 1,
    complete = function()
      return model_names
    end,
  })

  vim.api.nvim_create_user_command("AnkiSendGui", function()
    anki.sendgui()
  end, {})

  vim.api.nvim_create_user_command("AnkiSend", function()
    anki.send()
  end, {})

  vim.api.nvim_create_user_command("AnkiSetContext", function(opts)
    vim.g.anki_context = opts.args
    notify_info("Set context to " .. vim.inspect(opts.args))
  end, {
    nargs = 1,
  })

  vim.api.nvim_create_user_command("AnkiShowContext", function()
    notify_info("Context is set to " .. vim.inspect(vim.g.anki_context))
  end, {})

  local contexts = {}
  for k, _ in pairs(Config.contexts) do
    table.insert(contexts, k)
  end

  vim.api.nvim_create_user_command("AnkiWithContext", function(opts)
    if vim.g.anki_context then
      local args = opts.args
      anki.ankiWithContext(args, vim.g.anki_context)
    else
      notify_error("vim.g.anki_context is not defined")
      return
    end
  end, {
    nargs = 1,
    complete = function()
      return model_names
    end,
  })
end

local function load()
  local api = require("anki.api")

  local s0, decknames = pcall(api.deckNamesAndIds)
  if not s0 then
    error(decknames)
  end

  local s1, models = pcall(api.modelNamesAndIds)
  if not s1 then
    error(models)
  end

  local config_models = Config.models
  for m, d in pairs(config_models) do
    if not decknames[d] then
      -- notify_error("Deck with name '" .. d .. "' from your config was not found in Anki")
      error("Deck with name '" .. d .. "' from your config was not found in Anki")
    end

    if not models[m] then
      -- notify_error("Note Type (model) name '" .. m .. "' from your config was not found in Anki")
      error("Note Type (model) name '" .. m .. "' from your config was not found in Anki")
    end
    models_to_decknames[m] = d
    table.insert(model_names, m)
  end

  vim.api.nvim_set_hl(0, "ankiHtmlItalic", { italic = true })
  vim.api.nvim_set_hl(0, "ankiHtmlBold", { bold = true })
  vim.api.nvim_set_hl(0, "ankiDeckname", { link = "Special" })
  vim.api.nvim_set_hl(0, "ankiModelname", { link = "Special" })
  vim.api.nvim_set_hl(0, "ankiTags", { link = "Special" })
  vim.api.nvim_set_hl(0, "ankiField", { link = "@namespace" })
end

local function launch()
  if not has_loaded then
    local status, res = pcall(load)
    if not status then
      vim.api.nvim_create_user_command("Anki", function()
        launch()
      end, {})
      should_delete_command = true
      error(res .. " You can try again with :Anki")
    end

    if should_delete_command then
      vim.api.nvim_del_user_command("Anki")
      should_delete_command = false
    end

    create_commands()
    has_loaded = true
  end
end

--- Used to crate association of '.anki' extension to 'anki' filetype ('tex.anki' if |anki.TexSupport| is enabled in config) and setup the user's config.
---@param user_cfg Config see |Config|
anki.setup = function(user_cfg)
  user_cfg = user_cfg or {}
  Config = vim.tbl_deep_extend("force", Config, user_cfg)

  if Config.tex_support then
    vim.filetype.add({
      extension = {
        anki = "tex.anki",
      },
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "tex.anki",
      callback = function()
        local status, res = pcall(launch)
        if not status then
          vim.schedule(function()
            notify_error(res)
          end)
        end
      end,
    })
  else
    vim.filetype.add({
      extension = {
        anki = "anki",
      },
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "anki",
      callback = function()
        local status, res = pcall(launch)
        if not status then
          vim.schedule(function()
            notify_error(res)
          end)
        end
      end,
    })
  end
end

return anki
