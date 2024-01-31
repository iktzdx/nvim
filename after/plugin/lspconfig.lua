vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'LSP actions',
    callback = function(event)
        -- Create your keybindings here...
        local opts = { buffer = event.buf, remap = false }
        vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
        vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
        vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
        vim.keymap.set('n', '<C-h>', vim.lsp.buf.signature_help, opts)
        vim.keymap.set('n', '<leader>vws', function()
            vim.lsp.buf.workspace_symbol()
        end, opts)
        vim.keymap.set('n', '<leader>vrn', vim.lsp.buf.rename, opts)
        vim.keymap.set({ 'n', 'v' }, '<leader>vca', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', '<leader>vrr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', '<leader>vfm', function()
            vim.lsp.buf.format { async = true }
        end, opts)
    end
})

require('mason').setup()
require('mason-lspconfig').setup({
    ensure_installed = {
        -- Replace these with whatever servers you want to install
        'bashls',
        'gopls',
        'intelephense',
        'lua_ls',
        'tsserver',
        'yamlls',
    }
})

-- luasnip setup
local luasnip = require('luasnip')

-- nvim-cmp setup
local cmp = require('cmp')
local cmp_select = { behavior = cmp.ConfirmBehavior.Select }
local cmp_replace = { behavior = cmp.ConfirmBehavior.Replace }

local has_words_before = function()
    unpack = unpack or table.unpack
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

-- For more information read https://github.com/hrsh7th/nvim-cmp/blob/main/doc/cmp.txt#L429
cmp.setup({
    -- Specify a snippet engine (required)
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    completion = {
        completeopt = "menu,menuone,preview,noselect",
    },

    window = {
        -- completion = cmp.config.window.bordered(),
        -- documentation = cmp.config.window.bordered(),
    },

    mapping = cmp.mapping.preset.insert({
        ['<C-u>'] = cmp.mapping.scroll_docs(-4), -- Up
        ['<C-d>'] = cmp.mapping.scroll_docs(4),  -- Down
        ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
        ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
        ['<C-y>'] = cmp.mapping.confirm { cmp_replace, select = true },
        ['<C-Space>'] = cmp.mapping.complete(),
        ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
                luasnip.expand_or_jump()
            elseif has_words_before() then
                cmp.complete()
            else
                fallback()
            end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, { "i", "s" }),
    }),

    sources = cmp.config.sources({
        { name = "nvim_lsp", priority = 10 },
        { name = "luasnip",  priority = 7 },
        { name = "path",     priority = 5 },
        { name = "buffer",   priority = 5 },
        { name = "nvim_lua", priority = 3 },
    }),
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
        { name = 'buffer' }
    }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
        { name = 'path' }
    }, {
        { name = 'cmdline' }
    })
})

-- Add additional capabilities supported by nvim-cmp
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

local lspconfig = require('lspconfig')

-- Setup Lua LSP
lspconfig.lua_ls.setup {
    capabilities = capabilities,
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    log_level = 2,
    root_dir = lspconfig.util.root_pattern(".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua.toml", "stylua.toml",
        "selene.toml", "selene.yml", ".git"),
    single_file_support = true,
    settings = {
        Lua = {
            telemetry = {
                enable = false
            }
        }
    },
}

-- Golang LSP setup
lspconfig.gopls.setup {
    capabilities = capabilities,

    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_dir = lspconfig.util.root_pattern("go.work", "go.mod", ".git"),
    single_file_support = true,
    settings = {
        gopls = {
            completeUnimported = true,
            usePlaceholders = true,
            analyses = {
                unusedparams = true,
                fillstruct = true,
            },
            staticcheck = true,
        },
    },
}

-- TypeScript setup
lspconfig.tsserver.setup {
    capabilities = capabilities,

    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
    init_options = {
        hostInfo = "neovim"
    },
    root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git"),
    single_file_support = true,
}

-- Bash setup
lspconfig.bashls.setup {
    capabilities = capabilities,
    cmd = { "bash-language-server", "start" },
    filetypes = { "sh" },
    settings = {
        bashIde = {
            globPattern = "*@(.sh|.inc|.bash|.command)"
        }
    },
    single_file_support = true,
}

-- PHP setup
lspconfig.intelephense.setup {
    capabilities = capabilities,
    init_options = {
        globalStoragePath = os.getenv('HOME') .. '/.local/share/intelephense'
    },
    cmd = { "intelephense", "--stdio" },
    filetypes = { "php" },
    root_dir = lspconfig.util.root_pattern("composer.json", ".git"),
}

-- YAML setup
lspconfig.yamlls.setup {
    -- other configuration for setup {}
    cmd = { "yaml-language-server", "--stdio" },
    filetypes = { "yaml", "yaml.docker-compose" },
    root_dir = lspconfig.util.find_git_ancestor,
    single_file_support = true,
    settings = {
        yaml = {
            -- other settings. note this overrides the lspconfig defaults.
            schemas = {
                ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
                ["../path/relative/to/file.yml"] = "/.github/workflows/*",
                ["/path/from/root/of/project"] = "/.github/workflows/*",
            },
        },
        redhat = {
            telemetry = {
                enabled = false
            },
        }
    }
}

require('mason-lspconfig').setup_handlers({
    function(server_name)
        lspconfig[server_name].setup({
            capabilities = capabilities
        })
    end,
})
