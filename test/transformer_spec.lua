local data = [[
%%MODELNAME Super Basic
%%DECKNAME Parent::Child
%%TAGS TAG0 TAG1 TAG::TAG TAG::TAG::TAG
%Field0
Field0 information
%Field0
%Field1
Field1 Field1 Field1 Field1 Field1 Field1
%Field1
%Field2
Field2 
Field2 
Field2 
Field2 
Field2 
Field2
%Field2
]]

describe("tranformer tests", function()
    it("sanity check", function()
        require("anki.api")
        require("anki.transformer")
    end)

    it("nothing", function()
        local t = require("anki.buffer").all(data, {
            {
                transformation = function(_) end,
            },
        })
        assert.are.same(
            "Field1 Field1 Field1 Field1 Field1 Field1",
            t.note.fields["Field1"]
        )
    end)

    it("simple", function()
        local t = require("anki.buffer").all(data, {
            {
                transformation = function(form)
                    return { Field2 = { "a" } }
                end,
            },
        })
        assert.are.same("a", t.note.fields["Field2"])
    end)
end)
