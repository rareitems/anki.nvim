local curl = require("plenary.curl")

local URL = "localhost:8765"

local function request(res)
  local decoded = vim.json.decode(res.body)

  if decoded.error == vim.NIL then
    return decoded.result
  else
    error("anki.nvim: AnkiConnect Error " .. decoded.error)
  end
end

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
    return request(res)
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

API.addNote = function(params)
  params.note.options = {
    allowDuplicate = false,
    duplicateScope = "deck",
    duplicateScopeOptions = {
      deckName = nil,
      checkChildren = false,
      checkAllModels = false,
    },
  }
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

return API
