local M = {}

local function name(name)
    if not name or #name == 0 then
        return "In Linter:\n"
    else
        return "In Linter '" .. name .. "'\n"
    end
end

local function eval_cond(v, form)
    local c
    if v.condition then
        c = v.condition(form)
    else
        c = true
    end
    return c
end

---@param form table
---@param linters Linter[]
---@param diagnostics table
M.try_to_lint_with = function(form, linters, diagnostics)
    if not linters or #linters == 0 then
        return false
    end

    for i, v in ipairs(linters) do
        if eval_cond(v, form) then
            local success, diags = pcall(v.linter, form.fields, form)

            if not success then
                error(name(v.name) .. diags)
            end

            if not diags then
                error(name(v.name) .. "did not return anything")
            end

            if type(diags) ~= "table" then
                error(name(v.name) .. "did not return a table")
            end

            for _, diag in ipairs(diags) do
                if not diag.message then
                    error(name(v.name) .. "did not have diag.message field")
                end

                table.insert(diagnostics, diag)
            end
        end
    end
end

local ns = vim.api.nvim_create_namespace("anki")
M.lint = function(cur_buf, linters)
    local buffer = require("anki.buffer")
    local form = buffer.parse(cur_buf)

    -- TODO: add tagger
    local diagnostics = {}
    M.try_to_lint_with(form, linters, diagnostics)
    -- stylua: ignore
    M.try_to_lint_with(form, require("anki.helpers").global_variable("linters"), diagnostics)
    -- stylua: ignore
    M.try_to_lint_with(form, require("anki.helpers").buffer_variable("linters"), diagnostics)

    vim.diagnostic.set(ns, 0, diagnostics)
end

return M
