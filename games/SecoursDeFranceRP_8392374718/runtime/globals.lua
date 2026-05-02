--[[
    Secours de France RP - Globals & State
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

_G.MYA_SECOURS_RP = {
	ATM_ESP = false,
	HOUSE_ESP = false,
	VENDEUR_ESP = false,

	ATM_TRACERS_ENABLED = false,
	HOUSE_TRACERS_ENABLED = false,
	VENDEUR_TRACERS_ENABLED = false,

	AUTO_ATM = false,
	AUTO_HOUSE = false,
	AUTO_LOCKPICK = false,
	-- Set true while farm_houses runs door minigame so lockpick auto-runs without toggling GUI.
	MYA_FORCE_LOCKPICK = false,
	FARM_DELAY = 1.5,

	ATM_HIGHLIGHTS = {},
	HOUSE_HIGHLIGHTS = {},
	VENDEUR_HIGHLIGHTS = {},
	PLAYER_ESP_LIST = {},

	ATM_TRACERS = {},
	HOUSE_TRACERS = {},
	VENDEUR_TRACERS = {},
	PLAYER_TRACERS = {},

	CONNECTIONS = {},
}

local P = _G.MYA_SECOURS_RP
local cachedInstanceService: any = nil

local function findRemoteFunction(root: Instance, name: string): RemoteFunction?
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("RemoteFunction") and d.Name == name then
			return d
		end
	end
	return nil
end

local function collectRequireStrategies(): { any }
	local list: { any } = {}
	local function push(fn: any)
		if typeof(fn) == "function" then
			table.insert(list, fn)
		end
	end
	if getrenv then
		local r = getrenv()
		if r then
			push(r.require)
		end
	end
	if getfenv then
		local fe = getfenv(0)
		if fe and typeof(fe.require) == "function" then
			push(fe.require)
		end
	end
	local syn = rawget(_G, "syn")
	if syn and typeof(syn.require) == "function" then
		push(syn.require)
	end
	push(require)
	return list
end

local function tryRequireServiceManager(ss: Instance): any
	local sm = ss:FindFirstChild("ServiceManager")
	if not sm or not sm:IsA("ModuleScript") then
		return nil
	end
	for _, req in ipairs(collectRequireStrategies()) do
		local ok, mgr = pcall(req, sm)
		if ok and typeof(mgr) == "table" and typeof(mgr.GetService) == "function" then
			local ok2, inst = pcall(function()
				return mgr:GetService("Instance")
			end)
			if ok2 and inst then
				return inst
			end
		end
	end
	return nil
end

local function resolveInstanceService(): any
	local ss = ReplicatedStorage:FindFirstChild("SharedServices")
	if not ss then
		return nil
	end

	local home = findRemoteFunction(ss, "Home_Function")
	local atm = findRemoteFunction(ss, "ATM_Function")
	if home and atm then
		local tokenRf = findRemoteFunction(ss, "GetToken")
			or findRemoteFunction(ss, "Token")
			or findRemoteFunction(ss, "SecurityToken")
		return {
			WaitForChild = function(_: any, name: string, timeout: number?)
				if name == "Home_Function" then
					return home
				end
				if name == "ATM_Function" then
					return atm
				end
				return nil
			end,
			GetToken = function(_: any)
				if not tokenRf then
					return nil
				end
				local ok, tok = pcall(function()
					return tokenRf:InvokeServer()
				end)
				if ok then
					return tok
				end
				return nil
			end,
		}
	end

	return tryRequireServiceManager(ss)
end

function P.getInstanceService(): any
	if not cachedInstanceService then
		cachedInstanceService = resolveInstanceService()
	end
	return cachedInstanceService
end

function P.getRemote(name: string): Instance?
	local svc = P.getInstanceService()
	if not svc then
		return nil
	end
	return svc:WaitForChild(name, 10)
end

function P.getToken(): any
	local svc = P.getInstanceService()
	if not svc or typeof(svc.GetToken) ~= "function" then
		return nil
	end
	return svc:GetToken()
end

function P.createHighlight(target: Instance, color: Color3, list: { [Instance]: any })
	if list[target] then
		return
	end
	local h = Instance.new("Highlight")
	h.FillColor = color
	h.FillTransparency = 0.5
	h.OutlineTransparency = 1
	h.Adornee = target
	h.Parent = target
	list[target] = h
end

function P.createTracer(target: Instance, color: Color3, list: { [Instance]: any })
	if list[target] then
		return
	end
	local l = Drawing.new("Line")
	l.Visible = false
	l.Color = color
	l.Thickness = 1
	l.Transparency = 1
	list[target] = l
end

function P.clearDrawings(list: { [Instance]: any })
	for _, l in pairs(list) do
		if l then
			l:Remove()
		end
	end
	table.clear(list)
end

function P.clearHighlights(list: { [Instance]: any })
	for _, h in pairs(list) do
		if h then
			h:Destroy()
		end
	end
	table.clear(list)
end

return P
