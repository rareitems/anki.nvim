local curl = require("plenary.curl")

local URL = "localhost:8765"

---API for AnkiConnect
---See 'https://foosoft.net/projects/anki-connect/' for more information
---@class API
local API = {}

---Makes a request to AnkiConnect endpoint
---@param body table
API.request = function(body)
    local status, res = pcall(curl.get, URL, {
        body = vim.json.encode(body),
        timeout = 1000,
    })

    if status then
        local decoded = vim.json.decode(res.body)
        if decoded.error == vim.NIL then
            return decoded.result
        else
            error("anki.nvim: AnkiConnect Error " .. decoded.error)
        end
    else
        error(res)
    end
end

API.deckNames = function()
    local status, res = pcall(API.request, {
        action = "deckNames",
        version = 6,
    })

    if status then
        return res
    else
        error(res)
    end
end

API.deckNamesAndIds = function()
    local status, res = pcall(API.request, {
        action = "deckNamesAndIds",
        version = 6,
    })

    if status then
        return res
    else
        error(res)
    end
end

API.modelNames = function()
    local status, res = pcall(API.request, {
        action = "modelNames",
        version = 6,
    })

    if status then
        return res
    else
        error(res)
    end
end

API.modelNamesAndIds = function()
    local status, res = pcall(API.request, {
        action = "modelNamesAndIds",
        version = 6,
    })

    if status then
        return res
    else
        error(res)
    end
end

API.modelFieldNames = function(name)
    local status, res = pcall(API.request, {
        action = "modelFieldNames",
        version = 6,
        params = {
            modelName = name,
        },
    })

    if status then
        return res
    else
        error(res)
    end
end

API.guiAddCards = function(params)
    -- vim.print([[[lua/anki/api.lua:97] params: ]] .. vim.inspect(params))
    -- local status, res = pcall(API.request, )

    return API.request({
        action = "guiAddCards",
        version = 6,
        params = params,
    })
end

API.addNote = function(params, allow_duplicate)
    if allow_duplicate then
        params.note.options = {
            allowDuplicate = allow_duplicate,
        }
    else
        params.note.options = {
            allowDuplicate = allow_duplicate,
            duplicateScope = "deck",
            duplicateScopeOptions = {
                deckName = vim.NIL,
                checkChildren = false,
                checkAllModels = false,
            },
        }
    end

    local status, res = pcall(API.request, {
        action = "addNote",
        version = 6,
        params = params,
    })

    if status then
        return res
    else
        error(res)
    end
end

API.storeMediaFile = function(params)
    local status, res = pcall(API.request, {
        action = "storeMediaFile",
        version = 6,
        params = params,
    })

    if status then
        return res
    else
        error(res)
    end
end

---Makes a request to AnkiConnect endpoint
---@param body table
---@return boolean, table
API.request2 = function(body)
    local status, res = pcall(curl.get, URL, {
        body = vim.json.encode(body),
        timeout = 2000,
    })

    if status then
        local decoded = vim.json.decode(res.body)
        if decoded.error == vim.NIL then
            return true, decoded.result
        else
            return false, decoded.error
        end
    else
        return false, res
    end
end

---@param params { query: string }
---@return boolean, table
API.findNotes = function(params)
    return API.request2({
        action = "findNotes",
        version = 6,
        params = params,
    })
end

---Returns a list of objects containing for each note ID the note fields, tags, note type and the cards belonging to the note.
---@param params { notes: table<integer> }
---@return boolean, table
API.notesInfo = function(params)
    return API.request2({
        action = "notesInfo",
        version = 6,
        params = params,
    })
end

---@param cardId number
---@return string
API.getDeckName = function(cardId)
    local a, b = API.request2({
        action = "cardsInfo",
        version = 6,
        params = { cards = { cardId } },
    })
    assert(a)
    return b[1].deckName
end

---@param query string
---@return boolean, table
API.guiBrowse = function(query)
    return API.request2({
        action = "guiBrowse",
        version = 6,
        params = { query = query },
    })
end

API.invalidateGuiBrowser = function()
    local a, b = API.guiBrowse("nid:1")
    if not a then
        vim.print(vim.inspect(b))
    end
end

---@class UpdateNote
---@field id number
---@field fields table<table<string, string>>
---@field tags table<string>

---@param note UpdateNote
---@return boolean, table
API.updateNote = function(note)
    return API.request2({
        action = "updateNote",
        version = 6,
        params = { note = note },
    })
end

---@param noteId number
---@return boolean, table
API.guiSelectNote = function(noteId)
    return API.request2({
        action = "guiSelectNote",
        version = 6,
        params = { note = noteId },
    })
end

-- ---@class UpdateNoteFields
-- ---@field id number
-- ---@field fields table<table<string, string>>
-- ---@param note UpdateNote 
-- ---@return boolean, table
-- API.updateNoteFields = function(note)
--     return API.request2({
--         action = "updateNote",
--         version = 6,
--         params = { note = note },
--     })
-- end

return API
