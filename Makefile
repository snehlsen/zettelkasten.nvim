NVIM := nvim
PLUGIN_DIR := $(shell pwd)

.PHONY: test test-verbose test-file help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

test: ## Run all integration tests
	@$(NVIM) --clean -l test/run_all.lua

test-verbose: ## Run tests with nvim verbose logging
	@$(NVIM) --clean -V1 -l test/run_all.lua

test-file: ## Run a single test file (usage: make test-file FILE=test/test_plugin_load.lua)
	@$(NVIM) --clean --headless \
		--cmd 'set runtimepath+=$(PLUGIN_DIR)' \
		-c "lua package.path = '$(PLUGIN_DIR)/test/?.lua;' .. package.path" \
		-c 'luafile $(FILE)'
