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
---To the buffer when |anki.anki| is run
---This allows usage of vimtex, tex snippets etc. while creating anki cards.
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

---@private
---@class Lock
---@field is_locked boolean
local lock = { locked = false }

function lock:lock()
    self.locked = true
end

function lock:unlock()
    self.locked = false
end

function lock:is_locked()
    return self.locked
end

local fields_of_last_note = nil

local function notify_error(content)
    vim.api.nvim_notify("anki.nvim: " .. content, vim.log.levels.ERROR, {})
end

local function notify_info(content)
    vim.api.nvim_notify("anki.nvim: " .. content, vim.log.levels.INFO, {})
end

---@class anki.Config
---@field tex_support boolean Basic support for latex inside the 'anki' filetype. See |anki.TexSupport|.
---@field models table Table of name of notetypes (keys) to name of decks (values). Which notetype should be send to which deck
---@field contexts table Table of context names as keys with value of table with `tags` and `fields`. See |anki.Context|.
---@field move_cursor_after_creation boolean If `true` it will move the cursor the position of the first field

---@type anki.Config
local Config = {
    tex_support = false,
    models = {},
    contexts = {},
    move_cursor_after_creation = true,
}

local function get_context(arg)
    if not arg then
        error("Context was neither given nor is vim.g.anki_context defined")
    end

    if type(arg) == "string" then
        if Config.contexts and Config.contexts[arg] then
            return Config.contexts[arg]
        else
            error(
                "Supplied a string '"
                .. arg
                .. "' to context. But said context is not defined in the config or config is incorrectly defined"
            )
        end
    end

    if type(arg) == "table" then
        return arg
    end

    error("Supplied or global 'vim.g.context' is neither a 'table' nor 'string'")
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
    if lock:is_locked() then
        notify_error(
            "You have not send the current buffer to Anki.\nIf you are sure you want to overwrite the current buffer unlock it with ':AnkiUnlock'"
        )
        return
    end

    local api = require("anki.api")
    local buffer = require("anki.buffer")

    local status, fields = pcall(api.modelFieldNames, arg)
    if not status then
        error(fields)
    end

    local anki_table =
        buffer.create(fields, models_to_decknames[arg], arg, nil, Config.tex_support)
    lock:lock()

    vim.api.nvim_buf_set_lines(0, 0, -1, false, anki_table.form)
    if Config.move_cursor_after_creation then
        vim.api.nvim_win_set_cursor(0, { anki_table.pos_first_field, 0 })
    end
end

--- Fills the current buffer with a form which later can be send to anki using `send` or `sendgui`.
--- Deck to which the card will be sent is specified by 'deckname'
--- Fields are that of the 'notetype'
---
--- It will prefill 'fields' and 'tags' specified in the 'context'. See |anki.Context|
--- If 'context' is of a type 'string' it checks user's config. See |anki.Config|
--- If 'context' is of a type 'table' it uses that table directly.
---@param deckname string Name of Anki's deck
---@param notetype string Name of Anki' note type
---@param context string | table | nil
anki.ankiWithDeck = function(deckname, notetype, context)
    if lock:is_locked() then
        notify_error(
            "You have not send the current buffer to Anki.\nIf you are sure you want to overwrite the current buffer unlock it with ':AnkiUnlock'"
        )
        return
    end

    local api = require("anki.api")
    local buffer = require("anki.buffer")

    local cxt = nil
    if context then
        local status, res = pcall(get_context, context)
        if status then
            cxt = res
        else
            notify_error(res)
            return
        end
    end

    local status, fields = pcall(api.modelFieldNames, notetype)
    if not status then
        notify_error(fields)
        return
    end

    local s1, decknames = pcall(api.deckNames)
    if not s1 then
        notify_error(decknames)
        return
    end

    local has_found_deck = false
    for _, v in ipairs(decknames) do
        if v == deckname then
            has_found_deck = true
            break
        end
    end
    if not has_found_deck then
        notify_error(
            "Given deck '" .. deckname .. "' does not exist in your Anki collection"
        )
        return
    end

    local anki_table = buffer.create(fields, deckname, notetype, cxt, Config.tex_support)
    lock:lock()

    vim.api.nvim_buf_set_lines(0, 0, -1, false, anki_table.form)
    if Config.move_cursor_after_creation then
        vim.api.nvim_win_set_cursor(0, { anki_table.pos_first_field, 0 })
    end
end

--- The same thing as |anki.anki| but it will prefill 'fields' and 'tags' specified in the 'context'.
--- See |anki.Context|
---
--- If 'context' is of a type 'string' it checks user's config. See |anki.Config|
--- If 'context' is of a type 'table' it uses that table directly.
--- If 'context' is 'nil' it uses value from 'vim.g.anki_context' variable.
---@param arg string
---@param context string | table | nil
anki.ankiWithContext = function(arg, context)
    if lock:is_locked() then
        notify_error(
            "You have not send the current buffer to Anki.\nIf you are sure you want to overwrite the current buffer unlock it with ':AnkiUnlock'"
        )
        return
    end

    local api = require("anki.api")
    local buffer = require("anki.buffer")

    local status, fields = pcall(api.modelFieldNames, arg)
    if not status then
        error(fields)
    end

    local cxt = get_context(context or vim.g.anki_context)
    if not cxt then
        return
    end

    local anki_table =
        buffer.create(fields, models_to_decknames[arg], arg, cxt, Config.tex_support)
    lock:lock()

    vim.api.nvim_buf_set_lines(0, 0, -1, false, anki_table.form)

    if Config.move_cursor_after_creation then
        vim.api.nvim_win_set_cursor(0, { anki_table.pos_first_field, 0 })
    end
end

--- Sends the current buffer (which can be created using |anki.anki|) to the 'Add' GUI inside Anki.
--- '<br>' is going to be appended to the end of seperate lines to get newlines inside Anki.
--- It will select the specified inside the buffer note type and deck.
--- This will always replace the content inside 'Add' and won't do any checks about it.
anki.sendgui = function()
    if vim.bo.modified then
        notify_error("There are unsaved changes in the buffer")
        return
    end

    local api = require("anki.api")
    local buffer = require("anki.buffer")

    local cur_buf = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local parsed = buffer.parse(cur_buf)
    local is_success, data = pcall(api.guiAddCards, parsed)

    if is_success then
        notify_info("Card was sent to GUI Add Card")
        lock:unlock()
        fields_of_last_note = parsed.note.fields
        return
    else
        notify_error(data)
    end
end

--- Sends the current buffer (which can be created using |anki.anki|) directly to Anki.
--- '<br>' is going to be appended to the end of seperate lines to get newlines inside Anki.
--- It will send it to the specified inside the buffer deck using specified note type.
--- If duplicate in the specified deck is detected the card won't be created and user will be prompted about it.
---@param opts table|nil optional configuration options:
---  • {allow_duplicate} (boolean) If true card will be created even if it is a duplicate
anki.send = function(opts)
    opts = opts or {}
    local allow_duplicate = opts.allow_duplicate or false

    if vim.bo.modified then
        notify_error("There are unsaved changes in the buffer")
        return
    end

    local api = require("anki.api")
    local buffer = require("anki.buffer")

    local cur_buf = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local parsed = buffer.parse(cur_buf)

    local is_success, data = pcall(api.addNote, parsed, false)

    if is_success then
        notify_info("Card was added")
        lock:unlock()
        fields_of_last_note = parsed.note.fields
        return
    else
        if string.find(data, "duplicate") then
            if allow_duplicate then
                -- adding again because there is no API for just checking for duplicates in AnkiConnect
                local is_success, data = pcall(api.addNote, parsed, true)
                if is_success then
                    notify_info("Card was added. Card you added was a duplicate.")
                    lock:unlock()
                    fields_of_last_note = parsed.note.fields
                else
                    notify_error(data)
                end
            else
                notify_error("Card you are trying to add is a duplicate")
            end
        else
            notify_error(data)
        end
    end
end

--- Replaces the current line with the content of field whose name is nearest to the cursor
--- from the previous sent form
anki.fill_field_from_last_note = function()
    local x = vim.api.nvim_win_get_cursor(0)[1] - 1

    local lines = vim.api.nvim_buf_get_lines(0, x, x + 15, false)

    local field
    for _, line in ipairs(lines) do
        if line:sub(1, 1) == "%" then
            field = line:sub(2, #line)
            break
        end
    end

    if field == nil then
        notify_error("Could not find a field name")
        return
    end

    if fields_of_last_note[field] then
        local replacement =
            vim.split(fields_of_last_note[field], "<br>\n", { plain = true })
        vim.api.nvim_buf_set_lines(0, x, x + 1, false, replacement)
    else
        notify_error("Could not find '" .. field .. "' inside the last note")
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

    vim.api.nvim_create_user_command("AnkiSendAllowDuplicate", function()
        anki.send({ allow_duplicate = true })
    end, {})

    vim.api.nvim_create_user_command("AnkiUnlock", function()
        lock:unlock()
    end, {})

    vim.api.nvim_create_user_command("AnkiShowContext", function()
        notify_info("Context is set to " .. vim.inspect(vim.g.anki_context))
    end, {})

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

    local contexts = {}
    for k, _ in pairs(Config.contexts) do
        table.insert(contexts, k)
    end

    vim.api.nvim_create_user_command("AnkiSetContext", function(opts)
        vim.g.anki_context = opts.args
        notify_info("Set context to " .. vim.inspect(opts.args))
    end, {
        nargs = 1,
        complete = function()
            return contexts
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
            error(
                "Note Type (model) name '"
                .. m
                .. "' from your config was not found in Anki"
            )
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

--- Used to crate association of '.anki' extension to 'anki' filetype (or 'tex.anki' if |anki.TexSupport| is enabled in config) and setup the user's config.
---@param user_cfg anki.Config see |Config|
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
