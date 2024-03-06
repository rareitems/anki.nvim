local DATA = {
    {
        cards = { 1708177970425 },
        fields = {
            Back = {
                order = 2,
                value = "Back<br>Back",
            },
            Front = {
                order = 0,
                value = "Front<br>Front",
            },
            Test = {
                order = 1,
                value = "Test<br>Test",
            },
            Empty = {
                order = 3,
                value = "",
            },
        },
        modelName = "BasicCopy",
        noteId = 1708177970425,
        tags = { "Tag0::Tag1::Tag2", "Tag3", "Tag4::Tag5" },
    },
}

describe("parsing from anki", function()
    it("sanity check", function()
        require("anki.buffer")
    end)

    it("t0", function()
        local f = require("anki.buffer")
        local ret = f.parse_form_from_anki(DATA[1])
        assert.are.same(ret.deckname, nil)
        assert.are.same(ret.noteId, 1708177970425)
        assert.are.same(ret.tags, "Tag0::Tag1::Tag2 Tag3 Tag4::Tag5")
        assert.are.same(ret.fields_names, { "Front", "Test", "Back", "Empty" })
        assert.are.same(ret.fields_values, { Front = { "Front", "Front" }, Test = { "Test", "Test" }, Back = { "Back", "Back" }, Empty = { "" } })
    end)
end)
