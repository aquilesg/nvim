local map = vim.keymap.set
function _G.set_terminal_keymaps()
  map("t", "<C-[>", [[<C-\><C-n>]], { buffer = 0, desc = "Exit Terminal mode" })
  map("t", "<esc>", [[<C-\><C-n>]], { buffer = 0, desc = "Exit Terminal mode" })
  map(
    "t",
    "<C-h>",
    [[<Cmd>wincmd h<CR>]],
    { buffer = 0, desc = "Move to left buffer" }
  )
  map(
    "t",
    "<C-j>",
    [[<Cmd>wincmd j<CR>]],
    { buffer = 0, desc = "Move to buffer below" }
  )
  map(
    "t",
    "<C-k>",
    [[<Cmd>wincmd k<CR>]],
    { buffer = 0, desc = "Move to buffer above" }
  )
  map(
    "t",
    "<C-l>",
    [[<Cmd>wincmd l<CR>]],
    { buffer = 0, desc = "Move to right buffer" }
  )
  map(
    "t",
    "<C-w>",
    [[<C-\><C-n><C-w>]],
    { buffer = 0, desc = "Move to buffer" }
  )
  map(
    "t",
    "<F13>",
    "<Cmd>BufferClose<CR>",
    { buffer = 0, desc = "Move to buffer" }
  )
end

vim.cmd "autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()"

return {
  {
    "akinsho/toggleterm.nvim",
    opts = {
      direction = "horizontal",
      winbar = {
        enabled = true,
      },
    },
    keys = {
      -- Toggle term selection
      {
        "<leader>tt",
        "<cmd> ToggleTerm <CR>",
        desc = "Toggle terminal",
      },
      {
        "<C-t>",
        "<cmd> ToggleTerm <CR>",
        desc = "Toggle terminal",
        mode = "t",
      },
      {
        "<leader>ta",
        "<cmd> ToggleTermToggleAll <CR>",
        desc = "Toggle all terminals",
      },
      {
        "<leader>ts",
        "<cmd> TermSelect <CR>",
        { desc = "Open terminal select" },
      },
      {
        "<leader>tS",
        "<cmd> ToggleTermSetName <CR>",
        { desc = "Open terminal select" },
      },
      -- Work Specific things
      {
        "<leader>tT",
        '<cmd> TermExec cmd="make test" name="Testing" <CR>',
        desc = "Run Make test",
      },
      {
        "<leader>ti",
        '<cmd> TermExec cmd="aws-environment integration3 platform" name="Integration3 East Terminal" <CR>',
        desc = "Toggle Integration3 terminal in East Region",
      },
      {
        "<leader>tI",
        '<cmd> TermExec cmd="aws-environment integration3 platform --region us-west-2" name="Integration3 West Terminal" <CR>',
        desc = "Toggle Integration3 terminal in West Region",
      },
      {
        "<leader>tu",
        '<cmd> TermExec cmd="aws-environment uat platform" name="UAT East Terminal"  <CR>',
        desc = "Toggle UAT terminal in East Region",
      },
      {
        "<leader>tU",
        '<cmd> TermExec cmd="aws-environment uat platform --region us-west-2" name="UAT West Terminal"  <CR>',
        desc = "Toggle UAT terminal in West Region",
      },
      {
        "<leader>tp",
        '<cmd> TermExec cmd="aws-environment production platform" name="Production East Terminal" <CR>',
        desc = "Toggle Production terminal in East Region",
      },
      {
        "<leader>tP",
        '<cmd> TermExec cmd="aws-environment production platform --region us-west-2" name="Production West Terminal" <CR>',
        desc = "Toggle Production terminal in West Region",
      },
    },
  },
}
