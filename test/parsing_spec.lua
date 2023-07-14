local data = [[
%%MODELNAME Super Basic
%%DECKNAME Parent::Child
%%TAGS TAG0 TAG1 TAG::TAG TAG::TAG::TAG
%Field0
Field0 information
%Field0
%Field1
Field1
Field1
Field1
Field1
Field1
Field1
%Field1
%Field2

%Field2
%Field3

%Field3
%Field4

%Field4
%Field5

%Field5
%Field6
Field6
Field6
Field6
Field6
%Field6
%Field7

%Field7
%Field8

%Field8
]]

describe("parsing tests", function()
    it("sanity check", function()
        require("anki.api")
    end)

    it("modelname", function()
        local t = require("anki.buffer").parse(data).note
        assert.are.equal("Super Basic", t.modelName)
    end)

    it("deckname", function()
        local t = require("anki.buffer").parse(data).note
        assert.are.equal("Parent::Child", t.deckName)
    end)

    it("tags", function()
        local t = require("anki.buffer").parse(data).note
        assert.are.same({ "TAG0", "TAG1", "TAG::TAG", "TAG::TAG::TAG" }, t.tags)
    end)

    it("field0", function()
        local t = require("anki.buffer").parse(data).note
        assert.are.same("Field0 information", t.fields.Field0)
    end)

    it("field0", function()
        local t = require("anki.buffer").parse(data).note
        assert.are.same(
            [[Field1<br>
Field1<br>
Field1<br>
Field1<br>
Field1<br>
Field1]],
            t.fields["Field1"]
        )
    end)

    it("field0", function()
        local t = require("anki.buffer").parse(data).note
        print("t: " .. vim.inspect(t))
        assert.are.same(t.fields["Field2"], "")
    end)
end)
