return {
	{
		"williamboman/mason.nvim",
		lazy = false,
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		lazy = false,
		dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = { "lua_ls", "ts_ls", "yamlls", "jdtls", "gitlab_ci_ls" }, -- Removed duplicate yaml-language-server
				automatic_installation = true,
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			local lspconfig = require("lspconfig")

			-- Common on_attach function for keybindings
			local on_attach = function(client, bufnr)
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false
				if client.name == "ts_ls" then
					vim.keymap.set("n", "<leader>oi", function()
						vim.lsp.buf.code_action({
							context = { only = { "source.removeUnused.ts" } },
							apply = true,
						})
						vim.lsp.buf.code_action({
							context = { only = { "source.organizeImports.ts" } },
							apply = true,
						})
					end, { buffer = bufnr, desc = "Organize imports and remove unused" })
				end
			end

			-- Lua
			lspconfig.lua_ls.setup({
				on_attach = on_attach,
			})

			-- TypeScript/JavaScript
			lspconfig.ts_ls.setup({
				on_attach = on_attach,
				root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git")
					or vim.fn.getcwd(),
				single_file_support = true,
			})

			-- Java
			lspconfig.jdtls.setup({
				on_attach = on_attach,
				cmd = {
					vim.fn.stdpath("data") .. "/mason/bin/jdtls",
					"--jvm-arg=-Xmx2G",
					"-data",
					vim.fn.expand("~/.cache/jdtls/workspace") .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t"),
				},
				root_dir = lspconfig.util.root_pattern("pom.xml", "build.gradle", ".git") or vim.fn.getcwd(),
				settings = {
					java = {
						configuration = {
							runtimes = {
								{
									name = "JavaSE-17",
									path = "/home/john/.jbang/currentjdk/",
								},
							},
						},
					},
				},
			})

			lspconfig.yamlls.setup({
				on_attach = on_attach,
				settings = {
					yaml = {
						schemas = {
							["https://json.schemastore.org/gitlab-ci.json"] = ".gitlab-ci.yml",
							["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.32.1-standalone-strict/all.json"] = "*.yaml", -- Specific Kubernetes schema
						},
						schemaStore = { enable = true },
						completion = true, -- Explicitly enable completion
						hover = true, -- Enable hover for diagnostics
						validate = true, -- Ensure validation
					},
				},
				filetypes = { "yaml" },
				capabilities = {
					textDocument = {
						completion = {
							completionItem = {
								snippetSupport = true, -- Enable snippet support
							},
						},
					},
				},
				flags = {
					debounce_text_changes = 150, -- Improve responsiveness
				},
			})

			-- GitLab CI (specific override for .gitlab-ci.yml)
			lspconfig.gitlab_ci_ls.setup({
				on_attach = on_attach,
				root_dir = lspconfig.util.root_pattern(".gitlab-ci.yml", ".git") or vim.fn.getcwd(),
				filetypes = { "yaml.gitlab" },
			})
		end,
	},
}
