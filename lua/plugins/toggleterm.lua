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
        desc = "Open terminal select",
      },
      {
        "<leader>tS",
        "<cmd> ToggleTermSetName <CR>",
        desc = "Open terminal select",
      },
      -- Sending stuff to terminal
      {
        "<leader>tl",
        "<cmd> ToggleTermSendCurrentLine <CR>",
        desc = "Send current line at cursor",
      },
      {
        "<leader>tvl",
        "<cmd> ToggleTermSendVisualLines <CR>",
        desc = "Send current lines in visual selection",
        mode = "v",
      },
      {
        "<leader>tvL",
        "<cmd> ToggleTermSendVisualSelection <CR>",
        desc = "Send currently selected visual section",
        mode = "v",
      },
      -- Backup for Obsidian
      {
        "<leader>tb",
        function()
          local Terminal = require("toggleterm.terminal").Terminal
          local git = Terminal:new {
            display_name = "Obsidian Vault Backup",
            cmd = "git add . && git commit -m \"Back up $(date +'%Y-%d-%m:%H-%M-%S')\" && git push",
            dir = "~/Repos/brain/",
          }
          git:toggle()
        end,
        desc = "Backup Obsidian Repository",
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
      -- Diff files with git-diff
      {
        "<leader>tD",
        function()
          vim.ui.input({
            prompt = "Enter first file path: ",
            completion = "file",
          }, function(input1)
            if not input1 then
              print "No first file selected."
              return
            end
            vim.ui.input({
              prompt = "Enter second file path: ",
              completion = "file",
            }, function(input2)
              if not input2 then
                print "No second file selected."
                return
              end
              local Terminal = require("toggleterm.terminal").Terminal
              local diff_command = Terminal:new {
                cmd = "bash -c "
                  .. vim.fn.shellescape(
                    "delta --side-by-side "
                      .. vim.fn.shellescape(input1)
                      .. " "
                      .. vim.fn.shellescape(input2)
                      .. "; read -n 1 -s -r -p 'Press any key to close...'"
                  ),
                display_name = "Diff View Terminal",
                direction = "float",
                close_on_exit = true,
              }
              diff_command:toggle()
            end)
          end)
        end,
        desc = "Diff two files with git-diff",
      },
      {
        "<leader>tS",
        function()
          local Terminal = require("toggleterm.terminal").Terminal
          local aquariam = Terminal:new {
            cmd = "asciiquarium",
            display_name = "Screensaver",
            direction = "float",
            close_on_exit = true,
          }
          aquariam:toggle()
        end,
        desc = "Screensaver",
      },
      {
        "<leader>tB",
        function()
          local Terminal = require("toggleterm.terminal").Terminal
          local resources = Terminal:new {
            cmd = "btop",
            display_name = "Resource Usage",
            direction = "float",
            close_on_exit = true,
          }
          resources:toggle()
        end,
        desc = "Resource Usage",
      },
    },
  },
}
