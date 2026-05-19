local config = require("fzf.config")

describe("config", function()
  it("has default options", function()
    assert.is_not_nil(config.options)
    assert.is_not_nil(config.options.ui)
    assert.is_not_nil(config.options.fzf)
  end)

  it("setup merges user opts without mutating defaults", function()
    local ui_before = config.options.ui.width
    config.setup({ ui = { width = 0.5 } })
    assert.equals(0.5, config.options.ui.width)
    config.setup({})
    assert.equals(ui_before, config.options.ui.width)
  end)

  it("has layout presets", function()
    assert.is_not_nil(config.layout_presets.center)
    assert.is_not_nil(config.layout_presets.fullscreen)
    assert.is_not_nil(config.layout_presets.horizontal)
    assert.is_not_nil(config.layout_presets.vertical)
  end)
end)
