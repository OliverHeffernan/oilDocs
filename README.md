# oilDocs

`oilDocs` shows a directory's Markdown document in a read-only horizontal or
vertical split beside [oil.nvim](https://github.com/stevearc/oil.nvim). For
`/projects/example/`, the default note is `/projects/example/example.md`.

## Requirements

- Neovim 0.10 or newer
- oil.nvim

## Install with lazy.nvim

Add this to your Lazy plugin specifications:

```lua
{
  "OliverHeffernan/oilDocs",
  branch = "main",
  main = "oilDocs",
  lazy = false,
  dependencies = {
    "stevearc/oil.nvim",
  },
  opts = {
    split = "horizontal",
    height = 12,
    width = 48,
    close_when_missing = true,
    create_missing = true,
    keymaps = {
      open = "gN",
      toggle = "gM",
    },
  },
}
```

`branch = "main"` makes the target branch explicit and prevents Lazy from
failing if a local checkout is missing its `origin/HEAD` default-branch
metadata. `lazy = false` ensures oilDocs registers its handler before Oil emits
its first `OilEnter` event.

If Oil already has its own Lazy specification, keeping it in `dependencies`
here is safe: Lazy merges specifications for the same plugin.

For local development from this checkout, use `dir` instead of the GitHub
repository:

```lua
{
  dir = "/Users/oliverheffernan/Documents/aMyDocuments/CDT/2026/oilDocs",
  name = "oilDocs",
  main = "oilDocs",
  lazy = false,
  dependencies = { "stevearc/oil.nvim" },
  opts = {},
}
```

## Configuration

Lazy passes `opts` to `require("oilDocs").setup()`. The complete default-style
configuration is:

```lua
require("oilDocs").setup({
  split = "horizontal", -- "horizontal" below Oil, or "vertical" to its right
  height = 12,
  width = 48,
  filename = function(directory, name)
    return vim.fs.joinpath(directory, name .. ".md")
  end,
  close_when_missing = true,
  create_missing = true,
  keymaps = {
    open = "gN",
    toggle = "gM",
  },
})
```

`height` controls the preview size when `split = "horizontal"`. `width`
controls it when `split = "vertical"`.

`create_missing` controls what happens when `gN` is pressed and the current
directory does not yet have a Markdown document:

- When `true`, oilDocs asks for confirmation, creates the document with a
  `# Directory name` heading, and opens it for editing.
- When `false`, oilDocs displays a notification and does not create or open a
  document.

This option never creates documents automatically while navigating in Oil. It
only applies when explicitly opening a document with `gN`.

When using Lazy, place these same fields inside the `opts` table rather than
calling `setup()` separately.

The preview follows Oil directory navigation, is reused within an Oil window,
and never takes focus. It closes when the note is missing or the Oil window is
left. State is independent for each Oil window.

- `gN` opens the note for editing and offers to create a missing note.
- `gM` or `:OilDocsToggle` hides or shows the preview for the current Oil
  window. A hidden preview stays hidden while navigating between directories,
  until it is toggled on again.
- Saving an open note reloads its preview automatically.

Set a keymap to `false` or `nil` to disable it. Unsupported and remote Oil
adapters are ignored when `oil.get_current_dir()` returns `nil`.
