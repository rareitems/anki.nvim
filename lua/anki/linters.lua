---@mod anki.linters Linters
---@brief [[
---Collection of linters |anki.linter|
---@brief ]]
local Linters = {}

---Linter which lints based on the size of a single line and total size of all fields.
---
---Reference: https://andymatuschak.org/prompts/#litmus
---
---See |anki.linter| for more information about Linters.
---@return Linter
Linters.size = function(line_size, field_size)
    line_size = line_size or 130
    field_size = field_size or 250
    return {
        linter = function(fields)
            local ret = {}
            for _, lines in pairs(fields) do
                local counter = 0
                for ln, line in ipairs(lines) do
                    if #line > line_size + 10 then
                        table.insert(ret, {
                            severity = vim.diagnostic.severity.ERROR,
                            message = string.format("very long line (length=%s)", #line),
                            lnum = lines.line_number + ln,
                            col = 0,
                        })
                    elseif line_size + 2 < #line or #line > line_size - 2 then
                        table.insert(ret, {
                            severity = vim.diagnostic.severity.WARN,
                            message = string.format("long line (length=%s)", #line),
                            lnum = lines.line_number + ln,
                            col = 0,
                        })
                    end
                    counter = counter + #line
                end

                if counter > field_size + 10 then
                    table.insert(ret, {
                        severity = vim.diagnostic.severity.ERROR,
                        message = string.format("very long field (length=%s)", counter),
                        lnum = lines.line_number,
                        col = 0,
                    })
                elseif field_size + 2 < counter or counter > field_size - 2 then
                    table.insert(ret, {
                        severity = vim.diagnostic.severity.WARN,
                        message = string.format("long field (length=%s)", counter),
                        lnum = lines.line_number,
                        col = 0,
                    })
                end
            end
            return ret
        end,
        name = "size",
    }
end

---Linter which reports badly spelled word in your card.
---
---Essentially `:set spell` but only inside the fields.
---See |anki.linter| for more information about Linters.
---@return Linter
Linters.spellcheck = function()
    return {
        linter = function(fields)
            local ret = {}

            for _, v in pairs(fields) do
                for ln, line in ipairs(v) do
                    for _, err in ipairs(vim.spell.check(line) or {}) do
                        local severity
                        if err[2] == "bad" then
                            severity = vim.diagnostic.severity.ERROR
                        else
                            severity = vim.diagnostic.severity.WARN
                        end
                        table.insert(ret, {
                            severity = severity,
                            message = err[1],
                            lnum = v.line_number + ln,
                            col = err[3] - 1,
                        })
                    end
                end
            end

            return ret
        end,
        name = "spellcheck",
    }
end

---Linter which reports on fields that are only consisted of "yes" or "no"
---
---Reference: https://andymatuschak.org/prompts/#litmus
---
---See |anki.linter| for more information about Linters.
---@return Linter
Linters.avoid_binary_prompts = function()
    return {
        linter = function(fields)
            local ret = {}

            for _, v in pairs(fields) do
                for ln, line in ipairs(v) do
                    local lowercase_line = string.lower(line)
                    if lowercase_line == "yes" or lowercase_line == "no" then
                        table.insert(ret, {
                            severity = vim.diagnostic.severity.ERROR,
                            message = "Avoid binary prompts. Try to rephrased this as more open-ended prompts",
                            lnum = v.line_number + ln,
                            col = 0,
                        })
                    end
                end
            end

            return ret
        end,
        name = "avoid_binary_prompts",
    }
end

---Default linters made out of
---|anki.linters.size|
---|anki.linters.avoid_binary_prompts|
---@return Linter[]
Linters.default_linters = function()
    return {
        Linters.avoid_binary_prompts(),
        Linters.size(),
    }
end

return Linters
