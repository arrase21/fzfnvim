local helpers = require("fzf.helpers")

local has_icons = pcall(require, "mini.icons")

describe("helpers", function()
  describe("file_icon", function()
    it("returns the mini.icons icon for known extension", function()
      if not has_icons then return end
      local icon, hl = helpers.file_icon("test.lua")
      local expected = require("mini.icons").get("file", "test.lua")
      assert.equals(expected, icon)
      assert.is_not_nil(hl)
    end)

    it("returns default icon for unknown extension", function()
      if not has_icons then return end
      local icon, hl = helpers.file_icon("test.xyz")
      assert.is_true(icon ~= "")
      assert.is_not_nil(hl)
    end)

    it("matches by basename for extensionless files", function()
      if not has_icons then return end
      local icon = helpers.file_icon("Makefile")
      local expected = require("mini.icons").get("file", "Makefile")
      assert.equals(expected, icon)
    end)

    it("returns empty icon without mini.icons", function()
      local icon = helpers.file_icon("")
      assert.equals("", icon)
    end)
  end)

  describe("dir_icon", function()
    it("returns the mini.icons directory icon", function()
      if not has_icons then return end
      local icon, hl = helpers.dir_icon("Downloads")
      local expected = require("mini.icons").get("directory", "Downloads")
      assert.equals(expected, icon)
      assert.is_not_nil(hl)
    end)

    it("handles a trailing slash", function()
      if not has_icons then return end
      local icon = helpers.dir_icon("src/")
      local expected = require("mini.icons").get("directory", "src")
      assert.equals(expected, icon)
    end)

    it("returns empty icon without a name", function()
      local icon = helpers.dir_icon("")
      assert.equals("", icon)
    end)
  end)

  describe("strip_icon", function()
    it("strips icon and separator from line", function()
      local result = helpers.strip_icon("\ttest.lua")
      assert.equals("test.lua", result)
    end)
  end)

  describe("join_path", function()
    it("joins root and file", function()
      assert.equals("/root/file", helpers.join_path("/root", "file"))
    end)

    it("handles trailing slash in root", function()
      assert.equals("/root/file", helpers.join_path("/root/", "file"))
    end)

    it("handles leading slash in file", function()
      assert.equals("/root/file", helpers.join_path("/root", "/file"))
    end)
  end)

  describe("add_file_icons", function()
    it("adds icons to a list of files", function()
      local result = helpers.add_file_icons({ "test.lua", "test.md" })
      assert.equals(2, #result)
      assert.is_not_nil(result[1]:match("^."))
    end)
  end)

  describe("git_mark", function()
    it("returns a blank mark without status", function()
      assert.equals(" ", helpers.git_mark(nil))
      assert.equals(" ", helpers.git_mark(""))
    end)

    it("maps status codes to git icons", function()
      local function mark(xy)
        return (helpers.git_mark(xy):gsub("\27%[[%d;]*m", ""))
      end
      assert.equals(vim.fn.nr2char(0xF467), mark(" M")) -- unstaged
      assert.equals(vim.fn.nr2char(0xF14B), mark("M ")) -- modified
      assert.equals(vim.fn.nr2char(0xF467), mark("MM")) -- unstaged
      assert.equals(vim.fn.nr2char(0xF128), mark("??")) -- untracked
      assert.equals(vim.fn.nr2char(0xF0FE), mark("A ")) -- added
      assert.equals(vim.fn.nr2char(0xF146), mark("D ")) -- deleted
      assert.equals(vim.fn.nr2char(0x2794), mark("R ")) -- renamed
      assert.equals(vim.fn.nr2char(0x26A0), mark("UU")) -- conflict
      assert.equals(vim.fn.nr2char(0xF165D), mark("!!")) -- hidden
    end)
  end)

  describe("git_status", function()
    it("returns empty status outside a git repository", function()
      local st = helpers.git_status(vim.fn.tempname())
      assert.is_nil(st.top)
      assert.equals(0, #st.list)
    end)

    it("reads modified files in a git repository", function()
      if vim.fn.executable("git") ~= 1 then return end
      local dir = vim.fn.tempname()
      vim.fn.mkdir(dir, "p")
      vim.system({ "git", "-C", dir, "init" }):wait()
      local file = dir .. "/dirty.txt"
      vim.fn.writefile({ "old" }, file)
      vim.system({ "git", "-C", dir, "add", "." }):wait()
      vim.system({ "git", "-C", dir, "-c", "user.email=t@t", "-c", "user.name=t", "commit", "-m", "i" })
        :wait()
      vim.fn.writefile({ "new" }, file)

      local st = helpers.git_status(dir)
      assert.equals(vim.uv.fs_realpath(dir) or dir, st.top)
      assert.equals(" M", st.files[st.top .. "/dirty.txt"])
      assert.equals(" M", helpers.git_status_of(st, file))
    end)
  end)

  describe("build_fzf_opts", function()
    it("converts opts table to string", function()
      local result = helpers.build_fzf_opts({ ["--exact"] = "", ["--no-sort"] = "" })
      assert.is_not_nil(result:match("%-%-exact"))
      assert.is_not_nil(result:match("%-%-no%-sort"))
    end)

    it("handles key-value opts", function()
      local result = helpers.build_fzf_opts({ ["--prompt"] = "> " })
      assert.is_not_nil(result:match(">"), "should include value")
    end)
  end)
end)
