local M = {}

M.global_variable = function(s)
    if vim.g["anki"] then
        return vim.g["anki"][s]
    end
    return nil
end

M.buffer_variable = function(s)
    if vim.b["anki"] then
        return vim.b["anki"][s]
    end
    return nil
end

return M
