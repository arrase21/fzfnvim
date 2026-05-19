local storage = require("fzf.storage")

describe("storage", function()
  local tmp_harpoon

  before_each(function()
    tmp_harpoon = vim.fn.tempname()
    storage.harpoon_file = tmp_harpoon
  end)

  after_each(function()
    pcall(os.remove, tmp_harpoon)
  end)

  it("sessions_dir is set", function()
    assert.is_not_nil(storage.sessions_dir)
    assert.is_true(storage.sessions_dir:match("sessions$") ~= nil)
  end)

  it("ensure_sessions_dir creates directory", function()
    storage.ensure_sessions_dir()
    assert.is_true(vim.fn.isdirectory(storage.sessions_dir) == 1)
  end)

  it("harpoon_load returns empty table when no file", function()
    local data = storage.harpoon_load()
    assert.is_same(type(data), "table")
  end)

  it("harpoon save and load roundtrip", function()
    local test_data = { ["/test"] = { "a.lua", "b.lua" } }
    storage.harpoon_save(test_data)
    local loaded = storage.harpoon_load()
    assert.is_same(test_data, loaded)
  end)
end)
