local map = vim.keymap.set
map("n", "<leader>ge", "<cmd> BlameToggle <CR>", { desc = "Toggle git blame" })
map(
  "n",
  "<leader>o1",
  "<cmd> Octo pr create draft <CR>",
  { desc = "Create new PR" }
)
map(
  "n",
  "<leader>o2",
  "<cmd> Octo pr list <CR>",
  { desc = "List PRs for this repo" }
)
map("n", "<leader>o3", "<cmd> Octo pr search <CR>", { desc = "Search for PR" })
map("n", "<leader>gl", function()
  Snacks.lazygit.open()
end, { desc = "Open lazygit" })
map("n", "<leader>dvv", function()
  if next(require("diffview.lib").views) == nil then
    vim.cmd "DiffviewOpen"
  else
    vim.cmd "DiffviewClose"
  end
end, { desc = "Toggle Diffview" })

-- Octo mapping
vim.api.nvim_create_autocmd("FileType", {
  pattern = "octo",
  callback = function()
    vim.keymap.set(
      "i",
      "@",
      "@<C-x><C-o>",
      { noremap = true, silent = true, buffer = true }
    )
    vim.keymap.set(
      "i",
      "#",
      "#<C-x><C-o>",
      { noremap = true, silent = true, buffer = true }
    )
  end,
})

vim.treesitter.language.register("markdown", "octo")
return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      on_attach = function(bufnr)
        local gitsigns = require "gitsigns"
        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal { "]c", bang = true }
          else
            gitsigns.nav_hunk "next"
          end
        end)

        map("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal { "[c", bang = true }
          else
            gitsigns.nav_hunk "prev"
          end
        end)

        -- Actions
        map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "Git stage hunk" })
        map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "Git reset hunk" })
        map("v", "<leader>hs", function()
          gitsigns.stage_hunk { vim.fn.line ".", vim.fn.line "v" }
        end, { desc = "Stage visuall selected Hunk" })
        map("v", "<leader>hr", function()
          gitsigns.reset_hunk { vim.fn.line ".", vim.fn.line "v" }
        end, { desc = "Rest visually selected hunk" })
        map(
          "n",
          "<leader>hS",
          gitsigns.stage_buffer,
          { desc = "Git state buffer" }
        )
        map(
          "n",
          "<leader>hu",
          gitsigns.undo_stage_hunk,
          { desc = "Git undo stage hunk" }
        )
        map(
          "n",
          "<leader>hR",
          gitsigns.reset_buffer,
          { desc = "Git reset buffer" }
        )
        map(
          "n",
          "<leader>hp",
          gitsigns.preview_hunk,
          { desc = "Git preview hunk" }
        )
        map(
          "n",
          "<leader>hb",
          gitsigns.toggle_current_line_blame,
          { desc = "Git toggle current line blame" }
        )
        map("n", "<leader>hd", gitsigns.diffthis, { desc = "Git diff this" })
        map("n", "<leader>hD", function()
          gitsigns.diffthis "~"
        end, { desc = "Git diff this" })
        -- Text object
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>")
      end,
    },
    event = "UIEnter",
  },
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      enable_builtin = true,
      default_to_projects_v2 = false,
      ui = {
        use_signcolumn = true,
        use_signstatus = true,
      },
      colors = {
        white = "#ffffff",
        grey = "#2A354C",
        black = "#000000",
        red = "#fdb8c0",
        dark_red = "#da3633",
        green = "#acf2bd",
        dark_green = "#238636",
        yellow = "#d3c846",
        dark_yellow = "#735c0f",
        blue = "#58A6FF",
        dark_blue = "#0366d6",
        purple = "#6f42c1",
      },
    },
  },
  {
    {
      "Rawnly/gist.nvim",
      cmd = { "GistCreate", "GistCreateFromFile", "GistsList" },
      opts = {},
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
      "DiffviewFileHistory",
    },
    opts = {
      view = {
        merge_tool = {
          layout = "diff3_mixed",
        },
      },
    },
  },
  {
    "FabijanZulj/blame.nvim",
    cmd = { "BlameToggle" },
    opts = {},
  },
}
