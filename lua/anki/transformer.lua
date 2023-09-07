local M = {}

local function name(name)
    if not name or #name == 0 then
        return "In Transformation:\n"
    else
        return "In Transformation '" .. name .. "'\n"
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

---@param form Form
---@param transformers Transformer[]
---@return Form
M.try_to_tranform_with = function(form, transformers)
    if not transformers or #transformers == 0 then
        return form
    end

    local keys = vim.tbl_keys(form.fields)

    local pass_in_form = vim.deepcopy(form)
    local fields = vim.deepcopy(form.fields)

    for i, v in ipairs(transformers) do
        if eval_cond(v, form) then
            local success, result = pcall(v.transformation, fields, pass_in_form)
            if not success then
                error(name(v.name) .. result)
            end
            if result then
                for k, v in pairs(result) do
                    if not vim.tbl_contains(keys, k) then
                        error(
                            name(v.name)
                                .. "doesn't appear in original fields: "
                                .. vim.inspect(result)
                        )
                    end
                    fields[k] = v
                end
            end
        end
    end

    form.fields = fields
    return form
end

return M
