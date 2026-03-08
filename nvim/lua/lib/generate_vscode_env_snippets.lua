#!/usr/bin/env lua
local home = os.getenv("HOME")
local custom_path = home .. "/.config/nvim/lua/lib/?.lua"
package.path = package.path .. ";" .. custom_path

local utils = require("utils")
utils.generate_snippets("vscode")
