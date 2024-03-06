local H = {}

---@param msg string
---@param level any
H.notify =  function(msg, level)
    vim.notify("anki: " .. msg, level, {
        title = "anki.nvim",
        icon = "󰘸",
    })
end

---@param msg string
H.notify_info =  function(msg)
    vim.notify("anki: " .. msg, vim.log.levels.INFO, {
        title = "anki.nvim",
        icon = "󰘸",
    })
end

---@param msg string
H.notify_error =  function(msg)
    vim.notify("anki: " .. msg, vim.log.levels.ERROR, {
        title = "anki.nvim",
        icon = "󰘸",
    })
end

return H
