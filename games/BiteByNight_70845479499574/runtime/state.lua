local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer or Players.PlayerAdded:Wait()

local settings = {
	survivor_esp = true,
	killer_esp = true,
	generator_esp = true,
	batteries_esp = true,
}

local runtime_conn = nil
local highlights_folder = Instance.new("Folder")
highlights_folder.Name = "MyaBiteESP"
highlights_folder.Parent = CoreGui

local survivor_highlights = {}
local killer_highlights = {}
local generator_highlights = {}
local battery_highlights = {}

local function get_alive_folder()
	local p = Workspace:FindFirstChild("PLAYERS")
	return p and p:FindFirstChild("ALIVE") or nil
end

local function get_killer_folder()
	local p = Workspace:FindFirstChild("PLAYERS")
	return p and p:FindFirstChild("KILLER") or nil
end

local function get_generators_folder()
	local maps = Workspace:FindFirstChild("MAPS")
	if not maps then
		return nil
	end
	local game_map = maps:FindFirstChild("GAME MAP")
	if not game_map then
		return nil
	end
	return game_map:FindFirstChild("Generators")
end

local function get_batteries_folder()
	local maps = Workspace:FindFirstChild("MAPS")
	if not maps then
		return nil
	end
	local game_map = maps:FindFirstChild("GAME MAP")
	if not game_map then
		return nil
	end
	return game_map:FindFirstChild("Batteries")
end

local function ensure_highlight(dict, key, name, fill)
	local h = dict[key]
	if h then
		return h
	end
	h = Instance.new("Highlight")
	h.Name = name
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.FillColor = fill
	h.OutlineColor = fill
	h.FillTransparency = 0.62
	h.OutlineTransparency = 1
	h.Parent = highlights_folder
	dict[key] = h
	return h
end

local function hide_all(dict)
	for _, h in pairs(dict) do
		if h then
			h.Enabled = false
		end
	end
end

local function cleanup_key(dict, key)
	local h = dict[key]
	if h then
		pcall(function()
			h:Destroy()
		end)
		dict[key] = nil
	end
end

local function cleanup_stale(dict)
	for key in pairs(dict) do
		if not key or not key.Parent or not key:IsDescendantOf(Workspace) then
			cleanup_key(dict, key)
		end
	end
end

