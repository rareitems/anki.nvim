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
        local t = require("anki.buffer").parse(data, true)
        assert.are.equal("Super Basic", t.modelName)
    end)

    it("deckname", function()
        local t = require("anki.buffer").parse(data, true)
        assert.are.equal("Parent::Child", t.deckName)
    end)

    it("tags", function()
        local t = require("anki.buffer").parse(data, true)
        assert.are.same({ "TAG0", "TAG1", "TAG::TAG", "TAG::TAG::TAG" }, t.tags)
    end)

    it("field0", function()
        local x, y = require("anki.buffer").parse(data, true)
        assert.are.same({ "Field0 information", line_number = 4 }, x.fields.Field0)
    end)

    it("field1", function()
        local t = require("anki.buffer").parse(data, false)
        assert.are.same(
            [[Field1<br>
Field1<br>
Field1<br>
Field1<br>
Field1<br>
Field1]],
            require("anki.buffer").concat_lines(t.fields["Field1"])
        )
    end)

    it("field1WithNumberas", function()
        local x, y = require("anki.buffer").parse(data, true)

        for _, v in ipairs(x.fields["Field1"]) do
            assert.are.same(v, "Field1")
        end

        assert.are.same({
            "Field1",
            "Field1",
            "Field1",
            "Field1",
            "Field1",
            "Field1",
            line_number = 7,
        }, x.fields["Field1"])
    end)

    it("field2", function()
        local x, y = require("anki.buffer").parse(data, true)
        assert.are.same({ "", line_number = 15 }, x.fields["Field2"])
    end)

    it("field8", function()
        local x, y = require("anki.buffer").parse(data, true)
        assert.are.same({ line_number = 36 }, x.fields["Field8"])
    end)
end)
