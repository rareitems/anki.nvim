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

local function notify(msg, level)
    vim.notify("anki: " .. msg, level or vim.log.levels.INFO, {
        title = "anki.nvim",
        icon = "󰘸",
    })
end

---@class anki.Config
---@field tex_support boolean Basic support for latex inside the 'anki' filetype. See |anki.TexSupport|.
---@field models table Table of name of notetypes (keys) to name of decks (values). Which notetype should be send to which deck
---@field contexts table Table of context names as keys with value of table with `tags` and `fields`. See |anki.Context|.
---@field move_cursor_after_creation boolean If `true` it will move the cursor the position of the first field
---@field xclip_path string Path to the 'xclip' binary
---@field base64_path string Path to the 'base64' binary

---@type anki.Config
local Config = {
    tex_support = false,
    models = {},
    contexts = {},
    move_cursor_after_creation = true,

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

--- Given `arg` a name of a notetype. Fills the current buffer with a form which later can be send to anki using `send` or `sendgui`.
---
--- Name of the fields on the form depend on the `arg`
--- Name of the deck depends on `arg` and user's config
---@param arg string
anki.anki = function(arg)
    if lock:is_locked() then
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
    lock:lock()

    vim.api.nvim_buf_set_lines(0, 0, -1, false, anki_table.form)

    if Config.move_cursor_after_creation then
        vim.api.nvim_win_set_cursor(0, { anki_table.pos_first_field, 0 })
    end
end

--- Sends the current buffer (which can be created using |anki.anki|) to the 'Add' GUI inside Anki.
--- '<br>' is going to be appended to the end of separate lines to get newlines inside Anki.
--- It will select the specified inside the buffer note type and deck.
--- This will always replace the content inside 'Add' and won't do any checks about it.
anki.sendgui = function()
    if vim.bo.modified then
        notify("There are unsaved changes in the buffer", vim.log.levels.ERROR)
        return
    end

    local api = require("anki.api")
    local buffer = require("anki.buffer")

    local cur_buf = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local parsed = buffer.parse(cur_buf)
    local is_success, data = pcall(api.guiAddCards, parsed)

    if is_success then
        notify("Card was sent to GUI Add Card")
        lock:unlock()
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
    local parsed = buffer.parse(cur_buf)

    local is_success, data = pcall(api.addNote, parsed, false)

    if is_success then
        notify("Card was added")
        lock:unlock()
        fields_of_last_note = parsed.note.fields
        return
    else
        if string.find(data, "duplicate") then
            if allow_duplicate then
                -- adding again because there is no API for just checking for duplicates in AnkiConnect
                local is_success, data = pcall(api.addNote, parsed, true)
                if is_success then
                    notify("Card was added. Card you added was a duplicate.")
                    lock:unlock()
                    fields_of_last_note = parsed.note.fields
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
        lock:unlock()
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

---Add an image from clipboard to anki's media and inserts a link to it on current cursor
---position
---Accepted data from clipboard can be raw png, jpg or gif data or path to an image.
---Requires 'xclip' and 'base64'
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

        local base64_out = vim.system({ base64 }, { stdin = xclip_out.stdout }):wait()

        if base64_out.code ~= 0 then
            notify("Error from base64", vim.log.levels.ERROR)
            notify(base64_out.stderr, vim.log.levels.ERROR)
            return
        end

        local status, data = pcall(require("anki.api").storeMediaFile, {
            filename = "from_neovim." .. ft,
            data = base64_out.stdout,
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
            notify("Added image from clipboard")
            return
        else
            notify(data, vim.log.levels.ERROR)
            return
        end
    end
end

return anki
