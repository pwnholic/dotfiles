local buf_conf = {
	retirement_age_mins = 5, -- minutes after which an inactive buffer is closed
	ignored_filetypes = { "lazy", "mason", "oil" }, -- list of filetypes to never close
	notification_on_autoclose = true, -- list of filetypes to never close
	ignore_alt_file = true, -- whether the alternate file is also going to be ignored
	ignore_unsaved_changes_bufs = true, -- when false, will automatically write and then close buffers with unsaved changes
	ignore_special_buf_types = true, -- ignore non-empty buftypes, e.g. terminal buffers
	ignore_visible_bufs = true, -- ignore visible buffers (buffers open in a window, "a" in `:buffers`)
	ignore_unloaded_bufs = false, -- session plugins often add buffers without unloading them
	minimum_buffer_num = 1, -- minimum number of open buffers for auto-closing to become active
	ignore_filename_pattern = "", -- ignore files matches this lua pattern (string.find)
}

vim.uv.new_timer():start(
	buf_conf.retirement_age_mins * 60000,
	30 * 1000, --sec
	-- schedule_wrap required for timers
	vim.schedule_wrap(function()
		local open_buffers = vim.fn.getbufinfo({ buflisted = 1 }) -- https://neovim.io/doc/user/builtin.html#getbufinfo
		if #open_buffers < buf_conf.minimum_buffer_num then
			return
		end

		for _, buf in pairs(open_buffers) do
			-- check all the conditions
			local used_secs_ago = os.time() - buf.lastused -- always 0 for current buffer, therefore it's never closed
			local recently_used = used_secs_ago < buf_conf.retirement_age_mins * 60
			local buf_ft = vim.api.nvim_get_option_value("filetype", { buf = buf.bufnr })
			local is_ignored_ft = vim.tbl_contains(buf_conf.ignored_filetypes, buf_ft)
			local is_modified = vim.api.nvim_get_option_value("modified", { buf = buf.bufnr })
			local is_ignored_unsaved_buf = is_modified and buf_conf.ignore_unsaved_changes_bufs

			local is_ignored_special_buffer = vim.api.nvim_get_option_value("buftype", { buf = buf.bufnr }) ~= ""
				and buf_conf.ignore_special_buf_types
			local is_ignored_alt_file = (buf.name == vim.fn.expand("#:p")) and buf_conf.ignore_alt_file
			local is_ignored_visible_buf = buf.hidden == 0 and buf.loaded == 1 and buf_conf.ignore_visible_bufs
			local is_ignored_unloaded_buf = buf.loaded == 0 and buf_conf.ignore_unloaded_bufs
			local is_ignored_filename = buf_conf.ignore_filename_pattern ~= ""
				and buf.name:find(buf_conf.ignore_filename_pattern)
			local is_set, set_true = pcall(vim.api.nvim_buf_get_var, buf.bufnr, "buffer_closer")
			local is_manually_ignored = is_set and set_true

			-- GUARD against any of the conditions
			if
				recently_used
				or is_ignored_ft
				or is_ignored_special_buffer
				or is_ignored_alt_file
				or is_ignored_unsaved_buf
				or is_ignored_visible_buf
				or is_ignored_unloaded_buf
				or is_ignored_filename
				or is_manually_ignored
			then
				goto continue
			end

			-- close buffer
			if buf_conf.notification_on_autoclose then
				local filename = vim.fs.basename(buf.name)
				vim.notify(("Auto Closing %q"):format(filename), vim.log.levels.INFO, { title = "Buffer" })
			end

			if is_modified and not buf_conf.ignore_unsaved_changes_bufs then
				vim.api.nvim_buf_call(buf.bufnr, vim.cmd.write)
			end

			require("mini.bufremove").delete(buf.bufnr, true)
			::continue::
		end
	end)
)
