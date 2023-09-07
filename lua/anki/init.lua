---@mod anki.introduction Introduction
---@brief [[
---This plugin allows to create (and edit in future) Anki card from from Neovim
---@brief ]]

---@mod anki.configuration Configuration
---@brief [[
--- See |anki.config|
---@brief ]]

---@mod anki.usage Usage
---@brief [[
--- Setup your config. See |anki.config|
--- Launch your anki
--- Enter a filename with `.anki` extension
--- Create a form using `:Anki <your notetype>` command
--- Fill it with information you want to remember.
--- Send it to anki directly using `:AnkiSend` or send it to `Add` GUI using `:AnkiSendGui` if you want to add picture
---@brief ]]

---@mod anki.linter Linter
---@brief [[
---Allows of "statically" checking cards before you sending them to Anki.
---See |anki.Linter|
---
---You can define a bunch of function which given fields from the buffer can report various errors (spellchecking, too long lines, etc.) which will show up in `nvim` diagnostics.
---Kind of like "LSP" for your Anki cards.
---
---Can be set in either the configuration |anki.config| or in buffer (`vim.b.anki.linters`) or global (`vim.b.anki.linters`) variables
---
---Example:
---Show errors if any of the lines or fields are too long
--->lua
--- {
---        linter = function(fields, form)
---            local ret = {}
---            for field, lines in pairs(fields) do
---                local counter = 0
---                for ln, line in ipairs(lines) do
---                    if #line >= line_size then
---                        table.insert(ret, {
---                            message = "this line is too long " .. #line,
---                            lnum = lines.line_number + ln,
---                            col = 0,
---                        })
---                    end
---                    counter = counter + #line
---                end
---                if counter >= field_size then
---                    table.insert(ret, {
---                        message = "this field has way too much characters" .. counter,
---                        lnum = lines.line_number,
---                        col = 0,
---                    })
---                end
---            end
---            return ret
---        end,
---        name = "size",
--- }
---<
---@brief ]]

---Linter type
---@class Linter
---@field condition (fun(form : Form) : boolean) | nil If `condition` is a function and it returs `true` run this linter, if `false` do not run it. If `condition` is assigned to `nil` run it always
---@field linter fun(fields : table<string, string[]>, form : Form) : table Function that returns table of diagnostics (with structure that of |diagnostic-structure|(see `:h diagnostic-structure`) for the given fields. Each field is a table from name of that field to array of strings (content inside that field) it also has `line_number` field which indicates the line at which the field at starts (it lets you set `lnum` inside the returned diagnostic table, `line_number + 1` would indicate the first line in that field etc.)
---@field name string Name for error purposes

---Form type
---@class Form
---@field modelName string Name of the note (model)
---@field deckName string Name of the deck
---@field tags string[] Table of tags
---@field fields table Table of name of a Field to array of strings of content inside that field

---@mod anki.transformer Transformer
---@brief [[
---Allows of programatically transforming your cards before sending them to Anki.
---See |anki.Transformer|
---
---You can define a bunch of function which given fields from the buffer can transform fields
---of your cards (correct misspells, capitlize certain fields etc.).
---
---Can be set in either the configuration |anki.config| or in buffer (`vim.b.anki.transformers`) or global (`vim.b.anki.transformers`) variables
---
---Example:
---Runs `titlecase`(https://github.com/wezm/titlecase) binary on specific content from
---a specific field, which automitacally capitlizes the content inside that field.
---
--->lua
--- {
---    condition = function(note)
---        return note.modelName == "Definition"
---    end,
---
---    transformation = function(fields)
---        local stdout = vim.system({ "titlecase" }, { stdin = fields["Concept"] }):wait().stdout or ""
---        fields["Concept"] = vim.split(stdout:sub(1, #stdout - 1), "\n")
---        return fields
---    end,
---
---    name = "uppercase-Concept-Field",
--- },
---<
---@brief ]]

---Transformer type
---@class Transformer
---@field condition (fun(form : Form) : boolean) | nil If `condition` is a function and it returs `true` run this linter, if `false` do not run it. If `condition` is assigned to `nil` run it always
---@field transformation fun(fields : table<string, string[]>, form : Form) : table<string, string[]> Function which does the transformation on the fields and then returns it
---@field name string Name for error reporting purposes

---@mod anki.context Context
---@brief [[
--- Context can be used to prefill certain `field`s or `tag` during the creation of the buffer form using |anki.anki|
--- This can be used to mimic the idea of sticky fields from anki's 'Add' menu but with more control.
---
--- Context can be set either setting global variable |vim.g.anki_context| or using |:AnkiSetContext| command.
--->lua
--- vim.g.anki_context = { tags = "Rust ComputerScience", fields = { Context = "Rust" } }
--- vim.g.anki_context = "nvim"
---<
--- If context is a `string` your config's `contexts` subtable will be checked for corresponding value.
--- Contexts can be specified in your config like so
--->lua
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

---@mod anki.highlights Highlights
---@brief [[
---There are following highlights with their default values
--->lua
--- vim.api.nvim_set_hl(0, "ankiHtmlItalic", { italic = true })
--- vim.api.nvim_set_hl(0, "ankiHtmlBold", { bold = true })
--- vim.api.nvim_set_hl(0, "ankiDeckname", { link = "Special" })
--- vim.api.nvim_set_hl(0, "ankiModelname", { link = "Special" })
--- vim.api.nvim_set_hl(0, "ankiTags", { link = "Special" })
--- vim.api.nvim_set_hl(0, "ankiField", { link = "@namespace" })
---<
---@brief ]]

---@mod anki.texSupport TexSupport
---@brief [[
---With this enabled files with `.anki` extension will be set to filetype `anki.tex` instead of simply `anki`
---And it also will add
--->lua
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

---@mod anki.clozes Clozes
---@brief [[
---If you are using luasnip you can use something like this to create clozes more easily.
--->lua
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

local function lock()
    vim.b.anki_lock = true
end

local function unlock()
    vim.b.anki_lock = false
end

local function is_locked()
    return vim.b.anki_lock or false
end

local fields_of_last_note = nil

local function notify(msg, level)
    vim.notify("anki: " .. msg, level or vim.log.levels.INFO, {
        title = "anki.nvim",
        icon = "󰘸",
    })
end

---@class anki.config
---@field tex_support boolean Basic support for latex inside the `anki` filetype. See |anki.texSupport|.
---@field models table<string, string> Table of name of notetypes (keys) to name of decks (values). Which notetype should be send to which deck
---@field contexts table Table of context names as keys with value of table with `tags` and `fields`. See |anki.context|.
---@field move_cursor_after_creation boolean If `true` it will move the cursor the position of the first field
---@field linters Linter[] Your linters see |anki.linter|
---@field transformers Transformer[] Your transformers |anki.transformer|
---@field xclip_path string Path to the `xclip` binary
---@field base64_path string Path to the `base64` binary

---@type anki.config
local Config = {
    tex_support = false,
    models = {},
    contexts = {},
    move_cursor_after_creation = true,

    transformers = {},
    linters = {},

    xclip_path = "xclip",
    base64_path = "base64",
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

---@mod anki.API API

--- Given `arg` a name of a notetype. Fills the current buffer with a form which later can be send to anki using `send` or `sendgui`.
---
--- Name of the fields on the form depend on the `arg`
--- Name of the deck depends on `arg` and user's config
---@param arg string
anki.anki = function(arg)
    if is_locked() then
        notify(
            "You have not send the current buffer to Anki.\nIf you are sure you want to overwrite the current buffer unlock it with ':AnkiUnlock'",
            vim.log.levels.ERROR
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
    lock()

    vim.api.nvim_buf_set_lines(0, 0, -1, false, anki_table.form)
    if Config.move_cursor_after_creation then
        vim.api.nvim_win_set_cursor(0, { anki_table.pos_first_field, 0 })
    end
end

--- Fills the current buffer with a form which later can be send to anki using `send` or `sendgui`.
--- Deck to which the card will be sent is specified by `deckname`
--- Fields are that of the `notetype`
---
--- It will prefill `fields` and `tags` specified in the `context`. See |anki.context|
--- If `context` is of a type `string` it checks user's config. See |anki.config|
--- If `context` is of a type `table` it uses that table directly.
---@param deckname string Name of Anki's deck
---@param notetype string Name of Anki' note type
---@param context string | table | nil
anki.ankiWithDeck = function(deckname, notetype, context)
    if is_locked() then
        notify(
            "You have not send the current buffer to Anki.\nIf you are sure you want to overwrite the current buffer unlock it with ':AnkiUnlock'",
            vim.log.levels.ERROR
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
            notify(res, vim.log.levels.ERROR)
            return
        end
    end

    local status, fields = pcall(api.modelFieldNames, notetype)
    if not status then
        notify(fields, vim.log.levels.ERROR)
        return
    end

    local s1, decknames = pcall(api.deckNames)
    if not s1 then
        notify(decknames, vim.log.levels.ERROR)
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
        notify(
            "Given deck '" .. deckname .. "' does not exist in your Anki collection",
            vim.log.levels.ERROR
        )
        return
    end

    local anki_table = buffer.create(fields, deckname, notetype, cxt, Config.tex_support)
    lock()

    vim.api.nvim_buf_set_lines(0, 0, -1, false, anki_table.form)
    if Config.move_cursor_after_creation then
        vim.api.nvim_win_set_cursor(0, { anki_table.pos_first_field, 0 })
    end
end

--- The same thing as |anki.anki| but it will prefill `fields` and `tags` specified in the `context`.
--- See |anki.context|
---
--- If `context` is of a type `string` it checks user's config. See |anki.config|
--- If `context` is of a type `table` it uses that table directly.
--- If `context` is `nil` it uses value from `vim.g.anki_context` variable.
---@param arg string
---@param context string | table | nil
anki.ankiWithContext = function(arg, context)
    if is_locked() then
        notify(
            "You have not send the current buffer to Anki.\nIf you are sure you want to overwrite the current buffer unlock it with ':AnkiUnlock'",
            vim.log.levels.ERROR
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
    lock()

    vim.api.nvim_buf_set_lines(0, 0, -1, false, anki_table.form)

    if Config.move_cursor_after_creation then
        vim.api.nvim_win_set_cursor(0, { anki_table.pos_first_field, 0 })
    end
end

--- Sends the current buffer (which can be created using |anki.anki|) to the `Add` GUI inside Anki.
--- `<br>` is going to be appended to the end of separate lines to get newlines inside Anki.
--- It will select the specified inside the buffer note type and deck.
--- This will always replace the content inside `Add` and won't do any checks about it.
anki.sendgui = function()
    if vim.bo.modified then
        notify("There are unsaved changes in the buffer", vim.log.levels.ERROR)
        return
    end

    local api = require("anki.api")
    local buffer = require("anki.buffer")

    local cur_buf = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local parsed = buffer.all(cur_buf, Config.transformers)
    local is_success, data = pcall(api.guiAddCards, parsed)

    if is_success then
        notify("Card was sent to GUI Add Card")
        unlock()
        fields_of_last_note = parsed.note.fields
        return
    else
        notify(data, vim.log.levels.ERROR)
    end
end

--- Sends the current buffer (which can be created using |anki.anki|) directly to Anki.
--- '<br>' is going to be appended to the end of separate lines to get newlines inside Anki.
--- It will send it to the specified inside the buffer deck using specified note type.
--- If duplicate in the specified deck is detected the card won't be created and user will be prompted about it.
---@param opts table|nil optional configuration options:
---  • {allow_duplicate} (boolean) If true card will be created even if it is a duplicate
anki.send = function(opts)
    opts = opts or {}
    local allow_duplicate = opts.allow_duplicate or false

    if vim.bo.modified then
        notify("There are unsaved changes in the buffer", vim.log.levels.ERROR)
        return
    end

    local api = require("anki.api")
    local buffer = require("anki.buffer")

    local cur_buf = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local result = buffer.all(cur_buf, Config.transformers)
    local is_success, data = pcall(api.addNote, result, false)

    if is_success then
        notify("Card was added")
        unlock()
        fields_of_last_note = result.note.fields
        return
    else
        if string.find(data, "duplicate") then
            if allow_duplicate then
                -- adding again because there is no API for just checking for duplicates in AnkiConnect
                is_success, data = pcall(api.addNote, result, true)
                if is_success then
                    notify("Card was added. Card you added was a duplicate.")
                    unlock()
                    fields_of_last_note = result.note.fields
                    return
                else
                    notify(data, vim.log.levels.ERROR)
                end
            else
                notify("Card you are trying to add is a duplicate", vim.log.levels.ERROR)
            end
        else
            notify(data, vim.log.levels.ERROR)
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
        notify("Could not find a field name", vim.log.levels.ERROR)
        return
    end

    if fields_of_last_note[field] then
        local replacement =
            vim.split(fields_of_last_note[field], "<br>\n", { plain = true })
        vim.api.nvim_buf_set_lines(0, x, x + 1, false, replacement)
    else
        notify(
            "Could not find '" .. field .. "' inside the last note",
            vim.log.levels.ERROR
        )
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
        unlock()
    end, {})

    vim.api.nvim_create_user_command("AnkiShowContext", function()
        notify("Context is set to " .. vim.inspect(vim.g.anki_context))
    end, {})

    vim.api.nvim_create_user_command("AnkiWithContext", function(opts)
        if vim.g.anki_context then
            local args = opts.args
            anki.ankiWithContext(args, vim.g.anki_context)
        else
            notify("vim.g.anki_context is not defined")
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
        notify("Set context to " .. vim.inspect(opts.args))
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
            error("Deck with name '" .. d .. "' from your config was not found in Anki")
        end

        if not models[m] then
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

        vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave", "TextYankPost" }, {
            pattern = "*.anki",
            callback = function()
                require("anki.linter").lint(
                    vim.api.nvim_buf_get_lines(0, 0, -1, false),
                    Config.linters
                )
            end,
        })

        create_commands()
        has_loaded = true
    end
end

--- Used to crate association of '.anki' extension to 'anki' filetype (or 'tex.anki' if |anki.TexSupport| is enabled in config) and setup the user's config.
---@param user_cfg anki.config see |anki.config|
anki.setup = function(user_cfg)
    Config.linters = require("anki.linters").default_linters()
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
                        notify(res, vim.log.levels.ERROR)
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
                        notify(res, vim.log.levels.ERROR)
                    end)
                end
            end,
        })
    end
end

local Target = {
    png = 1,
    jpg = 2,
    jpeg = 3,
    gif = 4,
    not_image = 5,
}

Target.is_image = function(target)
    if target == Target.png then
        return "png"
    elseif target == Target.jpeg then
        return "jpeg"
    elseif target == Target.jpg then
        return "jpg"
    elseif target == Target.gif then
        return "gif"
    end
    return nil
end

--- Add an image from clipboard to anki's media and inserts a link to it on current cursor position
--- Accepted data from clipboard can be raw png, jpg or gif data or path to an image.
--- If data is from the clipboard is too big a temporary file (via 'vim.fn.tempname') in 'tempdir' will created.
--- Requires 'xclip' and 'base64'
anki.add_image_from_clipboard = function()
    local xclip = Config.xclip_path
    local base64 = Config.base64_path

    if vim.fn.executable(xclip) == 0 then
        notify("xclip not found", vim.log.levels.ERROR)
        return
    end

    if vim.fn.executable(base64) == 0 then
        notify("base64 not found", vim.log.levels.ERROR)
        return
    end

    local targets = vim.system(
        { xclip, "-o", "-t", "TARGETS", "-selection", "clipboard" },
        { text = true }
    ):wait()

    if targets.code ~= 0 then
        notify("Error from xclip", vim.log.levels.ERROR)
        notify(targets.stderr, vim.log.levels.ERROR)
        return
    end

    local targets_split = vim.split(targets.stdout, "\n")
    local target = nil
    for _, v in ipairs(targets_split) do
        if v == "STRING" then
            target = Target.not_image
            break
        end

        if v == "image/png" then
            target = Target.png
            break
        end

        if v == "image/jpeg" then
            target = Target.jpeg
            break
        end

        if v == "image/jpg" then
            target = Target.jpg
            break
        end

        if v == "image/gif" then
            target = Target.gif
            break
        end
    end
    assert(target)

    if target == Target.not_image then
        local xclip_out = vim.system({
            xclip,
            "-o",
            "-selection",
            "clipboard",
        }, { text = true }):wait()

        if xclip_out.code ~= 0 then
            notify("Error from xclip", vim.log.levels.ERROR)
            notify(xclip_out.stderr, vim.log.levels.ERROR)
            return
        end

        local path = vim.fs.normalize(vim.trim(xclip_out.stdout))

        if vim.fn.filereadable(path) == 0 then
            notify(path .. "is not file or not readable", vim.log.levels.ERROR)
            return
        end

        local filename = vim.fs.basename(path)
        if not filename then
            notify("Could not extract basename from path: " .. path, vim.log.levels.ERROR)
            return
        end

        local ft = filename:match(".(%a+)$")
        if not ft then
            notify(
                "Could not extract filetype from filename: " .. filename,
                vim.log.levels.ERROR
            )
            return
        end

        local status, data = pcall(require("anki.api").storeMediaFile, {
            filename = filename,
            path = path,
            deleteExisting = false,
        })

        if status then
            local index = vim.api.nvim_win_get_cursor(0)
            vim.api.nvim_buf_set_text(
                0,
                index[1] - 1,
                index[2],
                index[1] - 1,
                index[2],
                { string.format([[<img src=%s>]], data) }
            )
            notify("Added image from " .. path)
            return
        else
            notify(data, vim.log.levels.ERROR)
            return
        end
    elseif Target.is_image(target) then
        local ft = Target.is_image(target)

        local xclip_out = vim.system({
            xclip,
            "-o",
            "-t",
            "image/" .. ft,
            "-selection",
            "clipboard",
        }):wait()

        if xclip_out.code ~= 0 then
            notify("Error from xclip", vim.log.levels.ERROR)
            notify(xclip_out.stderr, vim.log.levels.ERROR)
            return
        end

        local status, data
        -- curl doesn't like getting big arguments
        if #xclip_out.stdout > 10000 then
            local tempfile = vim.fn.tempname()
            if vim.fn.writefile(xclip_out.stdout, tempfile) ~= 0 then
                notify("Could not write to tempfile", vim.log.levels.ERROR)
                return
            end
            status, data = pcall(require("anki.api").storeMediaFile, {
                filename = "from_neovim." .. ft,
                path = tempfile,
                deleteExisting = false,
            })
            -- assuming tmpfile will be cleared by OS so we don't have to it
        else
            local base64_out = vim.system({ base64 }, { stdin = xclip_out.stdout }):wait()
            if base64_out.code ~= 0 then
                notify("Error from base64", vim.log.levels.ERROR)
                notify(base64_out.stderr, vim.log.levels.ERROR)
                return
            end
            status, data = pcall(require("anki.api").storeMediaFile, {
                filename = "from_neovim." .. ft,
                data = base64_out.stdout,
                deleteExisting = false,
            })
        end

        if status then
            local index = vim.api.nvim_win_get_cursor(0)
            vim.api.nvim_buf_set_text(
                0,
                index[1] - 1,
                index[2],
                index[1] - 1,
                index[2],
                { string.format([[<img src=%s>]], data) }
            )
            notify("Added image from clipboard")
            return
        else
            notify(data, vim.log.levels.ERROR)
            return
        end
    end
end

---Returns 'true' after buffer was made but has not been yet sent, false otherwise.
---
---Can be used in thing like lualine as an a visual indicator whatever or card has been sent to anki.
---@return boolean
anki.is_locked = function()
    return is_locked()
end

return anki
