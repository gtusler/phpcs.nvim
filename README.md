# What is phpcs.nvim

`phpcs.nvim` is a simple nvim plugin which wraps the command line `phpcs` and `phpcbf` binaries.

## Installation

lazy.nvim

```lua
{
    'gtusler/phpcs.nvim',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope.nvim',
        'rcarriga/nvim-notify', -- optional
    },
    config = function()
        -- see configuration section
    end,
}
```

## Configuration

```lua
require('phpcs').setup({
    -- Path to the `phpcs` binary.
    phpcs = "$HOME/.config/composer/vendor/bin/phpcs",

    -- Path to the `phpcbf` binary.
    phpcbf = "$HOME/.config/composer/vendor/bin/phpcbf",

    -- Could be the name of a phpcs standard.
    -- Could be the path to a phpcs.xml file.
    -- Could be 'auto', where we crawl up from cwd checking for ./phpcs.xml and the closest value is used.
    standard = "auto",

    -- Set a standard to use when auto-detection doesn't find a phpcs.xml file.
    standard_fallback = "PSR2",

    -- Whether or not to automatically fix any issues on save.
    fix_on_save = false,
})
```

## Usage

`phpcs` attaches to any open buffer which has the `.php` file extension.

If configured to automatically fix on save:
- In an open buffer, `phpcbf` is run on save.

If configured not to automatically fix on save:
- In an open buffer, `phpcs` is run on save.
- To automatically fix the issues highlighted by `phpcs`, you can run `:Phpcbf`.

### Commands

There are commands available, try typing `:Php`, hitting `tab` and seeing what's there.

- `:Phpcs` Run the code sniffer.
- `:Phpcbf` Run the code formatter.
- `:PhpcsCurrentStandard` Print the standard which is currently in use.
- `:PhpcsListStandards` Print standards which are installed and accessible via a string in config.
- `:PhpcsFixOnSave` Print the current status of fix on save.
- `:PhpcsFixOnSaveOff` Dynamically disable fix on save.
- `:PhpcsFixOnSaveOn` Dinamically enable fix on save.
