local buffer = {}

---Creates a table of lines according to given inputs
---@param fields table Table of field names
---@param deckname string Name of the deck
---@param modelname string Name of the model (note type)
---@param context table | nil Table of tags and fields to prefill
---@param latex_support boolean If true insert lines for tex support inside a buffer
---@return table
buffer.create = function(fields, deckname, modelname, context, latex_support)
  local b = {} -- gonna use buf set lines so we build a table with strings

  if latex_support then
    table.insert(b, [[\documentclass[11pt, a4paper]{article}]])
    table.insert(b, [[\usepackage{amsmath}]])
    table.insert(b, [[\usepackage{amssymb}]])
    table.insert(b, [[\begin{document}]])
  end

  table.insert(b, "%%MODELNAME " .. modelname)
  table.insert(b, "%%DECKNAME " .. deckname)

  if context and context.tags then
    table.insert(b, "%%TAGS" .. " " .. context.tags)
  else
    table.insert(b, "%%TAGS")
  end

  for _, e in ipairs(fields) do
    local field = "%" .. e

    table.insert(b, field)
    if context and context.fields and context.fields[e] then
      table.insert(b, context.fields[e])
    else
      table.insert(b, "")
    end
    table.insert(b, field)
  end

  if latex_support then
    table.insert(b, [[\end{document}]])
  end

  return b
end

---Parses an input into a table with 'note' subtable which can be send AnkiConnect
buffer.parse = function(input)
  local result = { fields = {} }

  local lines
  if type(input) == "string" then
    lines = vim.split(input, "\n", {})
  else
    lines = input
  end

  local is_inside_field = { is = false, name = "", content = {} }

  for _, line in ipairs(lines) do
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

      if line_by_space[1] == "%%DECKNAME" then
        table.remove(line_by_space, 1)
        result.deckName = table.concat(line_by_space, " ")
        goto continue
      end
    end

    if line:sub(1, 1) == [[%]] then
      if is_inside_field.is then
        local content = table.concat(is_inside_field.content, "<br>\n")

        if result.fields[is_inside_field.name] == nil then
          result.fields[is_inside_field.name] = content
        else
          vim.notify("Field with name '" .. is_inside_field.name .. "' appears twice. Overwrote the data")
        end

        is_inside_field.is = false
      else
        is_inside_field = { is = true, name = line:sub(2, -1), content = {} }
      end
      goto continue
    end

    if is_inside_field.is then
      table.insert(is_inside_field.content, line)
    end

    ::continue::
  end

  return {
    note = result,
  }
end

return buffer
