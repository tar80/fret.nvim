PLENARY_PATH ?= $(HOME)/.local/share/nvim-data/lazy/plenary.nvim

.PHONY: test

test:
	@echo "--- Running Plenary.test_harness ---"
	nvim --headless \
		--cmd "set rtp+=$(PLENARY_PATH)" \
		--cmd "lua vim.opt.rtp:append(vim.fn.getcwd())" \
		-c "lua require('plenary.test_harness').test_directory('tests/', {timeout = 3000})" \
		-c "qa!"
