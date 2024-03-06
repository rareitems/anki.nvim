local M = {}
local UTIL = require("anki.utils")

--TODO: add noteID

---@class TableAnki
---@field form table
---@field pos_first_field 1-indexed position of the first field

---Creates a table of lines according to given inputs
---@param fields table Table of field names
---@param deckname string | nil Name of the deck
---@param modelname string Name of the model (note type)
---@param context table | nil Table of tags and fields to prefill
---@param latex_support boolean If true insert lines for tex support inside a buffer
---@param noteId number | nil If true insert lines for tex support inside a buffer
---@return TableAnki
M.create = function(fields, deckname, modelname, context, latex_support, noteId)
    local b = {}

    local pos = {
        has_seen_first_field = false,
        pos = 1,
    }

    if latex_support then
        table.insert(b, [[\documentclass[11pt, a4paper]{article}]])
        table.insert(b, [[\usepackage{amsmath}]])
        table.insert(b, [[\usepackage{amssymb}]])
        table.insert(b, [[\begin{document}]])
        pos.pos = pos.pos + 4
    end


    if noteId then
        table.insert(b, "%%NOTEID " .. noteId)
        pos.pos = pos.pos + 1
    else
        table.insert(b, "%%MODELNAME " .. modelname)
        pos.pos = pos.pos + 1

        if deckname then
            table.insert(b, "%%DECKNAME " .. deckname)
            pos.pos = pos.pos + 1
        end
    end

    if context and context.tags then
        table.insert(b, "%%TAGS" .. " " .. context.tags)
    else
        table.insert(b, "%%TAGS")
    end
    pos.pos = pos.pos + 1

    for _, e in ipairs(fields) do
        if not pos.has_seen_first_field then
            pos.pos = pos.pos + 1
            pos.has_seen_first_field = true
        end

        local field = "%" .. e

        table.insert(b, field)
        if context and context.fields and context.fields[e] then
            local t = type(context.fields[e])

            if t == "string" then
                local split_by_n = vim.split(context.fields[e], "\n")
                for _, k in ipairs(split_by_n) do
                    table.insert(b, k)
                end
            elseif t == "table"  then
                for _, k in ipairs(context.fields[e]) do
                    table.insert(b, k)
                end
            end
        else
            table.insert(b, "")
        end
        table.insert(b, field)
    end

    if latex_support then
        table.insert(b, [[\end{document}]])
    end

    return {
        form = b,
        pos_first_field = pos.pos,
    }
end

---Parses an input into a table with 'note' subtable which can be send AnkiConnect
---@return Form, table?
M.parse = function(input)
    local result = { fields = {} }

    local lines
    if type(input) == "string" then
        lines = vim.split(input, "\n", {})
    else
        lines = input
    end

    local is_inside_field = { is = false, name = "", content = {}, line_number = -1 }

    for line_counter, line in ipairs(lines) do
        if line:sub(1, 2) == [[%%]] then
            local line_by_space = vim.split(line, " ", {})

            if line_by_space[1] == "%%TAGS" then
                table.remove(line_by_space, 1)
                result.tags = line_by_space
                goto continue
            end


            if line_by_space[1] == "%%MODELNAME" then
                table.remove(line_by_space, 1)
                result.modelName = table.concat(line_by_space, " ")
                goto continue
            end

            if line_by_space[1] == "%%NOTEID" then
                table.remove(line_by_space, 1)
                result.noteId = table.concat(line_by_space, " ")
                goto continue
            end

            if line_by_space[1] == "%%DECKNAME" then
                table.remove(line_by_space, 1)
                result.deckName = table.concat(line_by_space, " ")
                goto continue
            end
        end

        if line:sub(1, 1) == [[%]] then
            if is_inside_field.is then
                if result.fields[is_inside_field.name] == nil then
                    result.fields[is_inside_field.name] = is_inside_field.content
                    result.fields[is_inside_field.name].line_number = is_inside_field.line_number
                        - 1
                else
                    UTIL.notify_info("Field with name '" .. is_inside_field.name .. "' appears twice. Overwrote the data")
                end

                is_inside_field.is = false
            else
                is_inside_field = {
                    is = true,
                    name = line:sub(2, -1),
                    content = {},
                    line_number = line_counter,
                }
            end

            goto continue
        end

        if is_inside_field.is then
            table.insert(is_inside_field.content, line)
        end

        ::continue::
    end

    return result
end

---@class Field
---@field value string
---@field order number

---@class AnkiNote
---@field modelName string
---@field noteId number
---@field tags table<string>
---@field fields table<Field>

---@param ankiNote AnkiNote
---@return {fields_names: table<string>, fields_values: table<string>, modelname: string, context: table, noteId: number, tags: string}
M.parse_form_from_anki = function(ankiNote)
    local fields_names = {}
    local field_values = {}

    for k, v in pairs(ankiNote.fields) do
        fields_names[v.order + 1] = k

        local f = string.gsub(v.value, "[\n\r]", "")
        local split = vim.fn.split(f, "<br>")

        if #split ~= 0 then
            field_values[k] = split
        else
            field_values[k] = { "" }
        end
    end

    return {
        fields_names = fields_names,
        fields_values = field_values,
        modelname = ankiNote.modelName,
        noteId = ankiNote.noteId,
        tags = vim.fn.join(ankiNote.tags, " "),
    }
end

M.concat_lines = function(lines)
    return table.concat(lines, "<br>\n")
end

M.transform = function(form, transformers)
    local t = require("anki.transformer")

    -- stylua: ignore
    local result = t.try_to_tranform_with(form, transformers)
    -- stylua: ignore
    result = t.try_to_tranform_with(result, require("anki.helpers").global_variable("transformers"))
    -- stylua: ignore
    result = t.try_to_tranform_with(result, require("anki.helpers").buffer_variable("transformers"))

    return result
end

M.all = function(cur_buf, transformers)
    local form = M.parse(cur_buf)
    form = M.transform(form, transformers)

    -- TODO: add tagger

    for k, v in pairs(form.fields) do
        form.fields[k] = M.concat_lines(v)
    end

    return { note = form }
end

return M
