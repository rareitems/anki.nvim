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
    local status, res = pcall(API.request, {
        action = "guiAddCards",
        version = 6,
        params = params,
    })

    if status then
        return res
    else
        error(res)
    end
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

return API
