local M = {}


--------------------------------------
-- TABLE

M.backticks_table = function(cmd)
    local tab = {}
    local pipe = assert(
        io.popen(cmd),
        "backticks_table(" .. cmd .. ") failed."
    )
    local line = pipe:read("*line")
    while line do
        table.insert(tab, line)
        line = pipe:read("*line")
    end
    return tab
end


--------------------------------------
-- LIST

---Join a list of strings into a single string, separated by delimiter
---@param delimiter string
---@param list table<string>
---@return string
M.implode = function(delimiter, list)
    local len = #list
    if len == 0 then
        return ""
    end
    local string = list[1]
    for i = 2, len do
        string = string .. delimiter .. list[i]
    end
    return string
end


--------------------------------------
-- STRING

---Split a string by a delimiter
---@param s string
---@param delimiter string
---@return table<string>
M.string_split = function(s, delimiter)
    local result = {}

    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, M.all_trim(match))
    end

    return result
end

M.all_trim = function(s)
    return s:match( "^%s*(.-)%s*$" )
end

M.is_empty = function(s)
    return s == nil or s == ''
end


--------------------------------------
-- FILE

---Check if a file exists relative to cwd.
---@param filename string
---@return boolean
M.file_exists = function(filename)
    local stat = vim.loop.fs_stat(vim.loop.cwd() .. '/' ..filename)
    return stat and stat.type == 'file'
end

M.close_handle = function(handle)
	if not handle:is_closing() then
        handle:close()
    end
end


--------------------------------------
-- PATH

---Pop a directory off the end of a path.
---/usr/local/bin becomes /usr/local
---@param path string
---@return string
M.pop_dir = function(path)
    local split = M.string_split(path, '/')
    table.remove(split, #split)
    return M.implode('/', split)
end

---Extract the file extension from a file path.
---@param path string
---@return string
M.get_file_extension = function(path)
    local split = M.string_split(path, '.')
    return split[#split]
end


--------------------------------------
-- BUFFER

M.current_buffer_path = function()
    local bufname = vim.api.nvim_buf_get_name(0)
    return bufname
end


--------------------------------------
-- NOTIFYING

local use_notify = true
if vim.notify == nil then
    use_notify = false
end
local plugin_name = "PHPCS"

---Show the user a message.
---Uses vim.notify under the hood if available.
---@param s string
---@param level string|nil
M.notify = function(s, level)
    if level == nil then
        level = "info"
    end

    if use_notify then
        vim.notify(
            s,
            level,
            {
                title = plugin_name,
            }
        )
    else
        print(s)
    end
end


--------------------------------------
-- DETECTION

---Detect a phpcs.xml file relative to the current buffer.
---Crawls up the filesystem until one is found.
---Defaults to PSR2 if none is found.
---@param fallback string
---@return string A fully qualified path to the closest phpcs.xml file or the fallback.
M.detect_phpcs_xml = function(fallback)
    local cwd = vim.fn.getcwd()
    local possible_paths = M.prepare_possible_phpcs_xml_paths(cwd)

    for _, possible_path in pairs(possible_paths) do
        if vim.fn.filereadable(possible_path) then
            return possible_path
        end
    end

    return fallback
end

---Convert a path into a list of possible paths for a phpcs.xml file.
---@param basepath string A fully qualified path to a directory.
---@return table<string> A list of possible paths for a phpcs.xml file.
M.prepare_possible_phpcs_xml_paths = function(basepath)
    local paths = {}
    local split = M.string_split(basepath, '/')
    local current = basepath

    for i=1,#split do
        local the_path = current .. "/phpcs.xml"
        table.insert(paths, the_path)
        current = M.pop_dir(current)
    end

    return paths
end

return M
