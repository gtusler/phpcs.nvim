local M = {}

local root = vim.loop.cwd()
local phpcs_path = "$HOME/.config/composer/vendor/bin/phpcs"
local phpcbf_path = "$HOME/.config/composer/vendor/bin/phpcbf"
local phpcs_standard_fallback = "PSR2"
local phpcs_standard = phpcs_standard_fallback
local fix_on_save = false

local util = require('phpcs.util')
local runner = require('phpcs.runner')



--------------------------------------
-- VARIABLES

---Path to the `phpcs` binary.
M.phpcs_path = vim.g.nvim_phpcs_config_phpcs_path or phpcs_path
---Path to the `phpcbf` binary.
M.phpcbf_path = vim.g.nvim_phpcs_config_phpcbf_path or phpcbf_path
---Name of phpcs standard or path to phpcs.xml file.
M.phpcs_standard = vim.g.nvim_phpcs_config_phpcs_standard or phpcs_standard
---A fallback for use when automatically finding a phpcs.xml file fails.
M.phpcs_standard_fallback = vim.g.nvim_phpcs_config_phpcs_standard_fallback or phpcs_standard_fallback
---Whether or not to fix file format on save.
M.fix_on_save = vim.g.nvim_phpcs_config_fix_on_save or fix_on_save
---Whether or not to do any sniffing at all.
M.enabled = true

M.namespace = nil

---Attempt to dynamically set a few values. Currently overrides config.
M.detect_local_paths = function()
    M.namespace = vim.api.nvim_create_namespace('phpcs')

    if util.file_exists('phpcs.xml') then
        M.phpcs_standard = root .. '/phpcs.xml'
    end

    if util.file_exists('vendor/bin/phpcs') then
        M.phpcs_path = root .. '/vendor/bin/phpcs'
    end

    if util.file_exists('vendor/bin/phpcbf') then
        M.phpcbf_path = root .. '/vendor/bin/phpcbf'
    end
end


--------------------------------------
-- SETUP

M.setup = function(opts)
    if opts == nil then
        M.detect_local_paths()
    end

    if opts.phpcs ~= nil then
        M.phpcs_path = opts.phpcs
    end

    if opts.phpcbf ~= nil then
        M.phpcbf_path = opts.phpcbf
    end

    if opts.standard_fallback ~= nil then
        M.phpcs_standard_fallback = opts.standard_fallback
    end

    if opts.standard ~= nil then
        if opts.standard == 'auto' then
            M.phpcs_standard = util.detect_phpcs_xml(M.phpcs_standard_fallback)
        else
            M.phpcs_standard = opts.standard
        end
    end

    if opts.fix_on_save ~= nil then
        M.fix_on_save = opts.fix_on_save
    end
end



--------------------------------------
-- ACTIONS

local function doRunCodeSniffer()
    runner.cs(M.namespace, M.phpcs_path, M.phpcs_standard)
end

local function doRunFormatter()
    runner.cbf(M.phpcbf_path, M.phpcs_standard)
end

local function doListStandards()
    runner.list_standards(M.phpcs_path)
end

local function doLogCurrentStandard()
    util.notify(M.phpcs_standard)
end

local function doSnifferEnable()
    M.enabled = true
end

local function doSnifferDisable()
    M.enabled = false
end

local function doLogFixOnSave()
    local message = "Fix on save is disabled."
    if M.fix_on_save then
        message = "Fix on save is enabled."
    end

    util.notify(message)
end

local function doEnableFixOnSave()
    M.fix_on_save = true
    util.notify('Enabled fix on save')
end

local function doDisableFixOnSave()
    M.fix_on_save = false
    util.notify('Disabled fix on save')
end


--------------------------------------
-- COMMANDS

vim.api.nvim_create_user_command(
    'PhpcsDisable',
    doSnifferDisable,
    {
        desc = 'Dynamically disable sniffing',
    }
)

vim.api.nvim_create_user_command(
    'PhpcsEnable',
    doSnifferEnable,
    {
        desc = 'Dynamically enable sniffing',
    }
)

vim.api.nvim_create_user_command(
    'Phpcs',
    doRunCodeSniffer,
    {
        desc = 'Run phpcs code sniffer on the current buffer.',
    }
)

vim.api.nvim_create_user_command(
    'Phpcbf',
    doRunFormatter,
    {
        desc = 'Run phpcbf formatter on the file in the current buffer.',
    }
)

vim.api.nvim_create_user_command(
    'PhpcsListStandards',
    doListStandards,
    {
        desc = 'List the installed phpcs standards.',
    }
)

vim.api.nvim_create_user_command(
    'PhpcsCurrentStandard',
    doLogCurrentStandard,
    {
        desc = 'Show the standard which is currently in use.',
    }
)

vim.api.nvim_create_user_command(
    'PhpcsFixOnSave',
    doLogFixOnSave,
    {
        desc = "Log whether or not fix on save is enabled.",
    }
)

vim.api.nvim_create_user_command(
    'PhpcsFixOnSaveOn',
    doEnableFixOnSave,
    {
        desc = 'Dynamically enable fix on save.',
    }
)

vim.api.nvim_create_user_command(
    'PhpcsFixOnSaveOff',
    doDisableFixOnSave,
    {
        desc = 'Dynamically disable fix on save.',
    }
)


--------------------------------------
-- AUTO CHECK AND FIX HOOKS
-- https://neovim.io/doc/user/autocmd.html#_5.-events

local autocmd_group = vim.api.nvim_create_augroup('phpcs-bufenter', { clear = true })

vim.api.nvim_create_autocmd(
    {'BufEnter', 'BufModifiedSet'},
    {
        pattern = '*.php',
        group = autocmd_group,
        callback = function(args)
            if not M.enabled then
                return
            end
            doRunCodeSniffer()
        end,
    }
)

vim.api.nvim_create_autocmd(
    'BufWrite',
    {
        pattern = '*.php',
        group = autocmd_group,
        callback = function(args)
            if not M.enabled then
                return
            end
            if M.fix_on_save then
                doRunFormatter()
            else
                doRunCodeSniffer()
            end
        end,
    }
)


--------------------------------------
-- INIT

M.detect_local_paths()

return M
