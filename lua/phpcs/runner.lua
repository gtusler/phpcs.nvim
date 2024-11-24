---@class Runner
local Runner = {}

local Job = require('plenary.job')
local util = require('phpcs.util')


---Run `phpcs` on the current buffer
---@param namespace integer
---@param phpcs_path string
---@param phpcs_standard string
Runner.cs = function(namespace, phpcs_path, phpcs_standard)
    local bufnr = vim.api.nvim_get_current_buf()
    local report_file = os.tmpname()

    local opts = {
        command = phpcs_path,
        args = {
            '--stdin-path=' .. vim.api.nvim_buf_get_name(bufnr),
            '--report=json',
            '--report-file=' .. report_file,
            '--standard=' .. phpcs_standard,
            '-',
        },
        writer = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true),
        on_exit = vim.schedule_wrap(function()
            local file = io.open(report_file, 'r')
            if file ~= nil then
                local content = file:read('*a')
                Runner.publish_diagnostic(namespace, content, bufnr)
            end
        end),
    }

    Job:new(opts):start()
end

---Publish diagnostic results to the given buffer.
---@param namespace integer
---@param results string
---@param bufnr integer
Runner.publish_diagnostic = function(namespace, results, bufnr)
    local diagnostics = Runner.parse_json(results, bufnr)
    vim.diagnostic.set(namespace, bufnr, diagnostics)
end

---Parse phpcs json output into nvim diagnostics format.
---@param encoded any
---@param bufnr any
---@return table
Runner.parse_json = function(encoded, bufnr)
    local decoded = vim.json.decode(encoded)
    local diagnostics = {}
    local uri = vim.fn.bufname(bufnr)

    local error_codes = {
        ['error'] = vim.lsp.protocol.DiagnosticSeverity.Error,
        warning = vim.lsp.protocol.DiagnosticSeverity.Warning,
    }

    if not decoded.files[uri] then
        return diagnostics
    end

    for _, message in ipairs(decoded.files[uri].messages) do
        table.insert(
            diagnostics,
            {
                severity = error_codes[string.lower(message.type)],
                lnum = tonumber(message.line) - 1,
                col = tonumber(message.column) - 1,
                message = message.message,
            }
        )
    end

    return diagnostics
end


---Run `phpcbf` on the file in the current buffer.
---@param phpcbf_path string
---@param phpcs_standard string
---@param new_opts table|nil
--[[
--  new_opts = {
        bufnr = 0, -- Buffer no. defaults to current
        force = false, -- Ignore file size
        timeout = 1000, -- Timeout in ms for the job. Default 1000ms
    }
]]
Runner.cbf = function(phpcbf_path, phpcs_standard, new_opts)
    new_opts = new_opts or {}
    new_opts.bufnr = new_opts.bufnr or vim.api.nvim_get_current_buf()

    if not new_opts.force then
        if vim.api.nvim_buf_line_count(new_opts.bufnr) > 1000 then
            util.notify('File too large. Ignoring code beautifier.', 'error')
            return
        end
    end

    local opts = {
        command = phpcbf_path,
        args = {
            '--standard=' .. phpcs_standard,
            vim.api.nvim_buf_get_name(new_opts.bufnr),
        },
        on_exit = vim.schedule_wrap(function(j)
            if j.code ~= 0 then
                vim.cmd('e')
            end
        end),
        cwd = vim.fn.getcwd(),
    }

    Job:new(opts):start()
end

---Print a list of valid phpcs standards strings
---@param phpcs_path string
Runner.list_standards = function(phpcs_path)
    local opts = {
        command = phpcs_path,
        args = {
            '-i',
        },
        on_exit = vim.schedule_wrap(function(j, return_val)
            util.notify(j:result())
        end),
    }

    Job:new(opts):start()
end

return Runner
