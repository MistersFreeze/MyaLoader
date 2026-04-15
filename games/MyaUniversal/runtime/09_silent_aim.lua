local function should_redirect_silent(origin, direction, params)
	if not silent_on or not _G.MYA_UNIVERSAL_LOADED then
		return false
	end
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		return false
	end
	if silent_require_raycast_params and typeof(params) ~= "RaycastParams" then
		return false
	end
	local mag = direction.Magnitude
	if mag < 0.01 or mag > silent_max_ray_distance then
		return false
	end
	local cam = camera
	if not cam or not cam.CFrame then
		return false
	end
	if (origin - cam.CFrame.Position).Magnitude > silent_max_origin_dist then
		return false
	end
	local look = cam.CFrame.LookVector
	local dunit = direction.Unit
	if dunit:Dot(look) < silent_min_look_dot then
		return false
	end
	return true
end

local function apply_silent_redirect(origin, direction, _params)
	local worldPos = cached_silent_aim_world
	if not worldPos then
		return origin, direction
	end
	local mag = direction.Magnitude
	if mag < 1e-4 then
		return origin, direction
	end
	local delta = worldPos - origin
	if delta.Magnitude < 1e-4 then
		return origin, direction
	end
	local newDir = delta.Unit * mag
	return origin, newDir
end

local function install_silent_hooks()
	if typeof(hookfunction) ~= "function" then
		return
	end

	if typeof(getrawmetatable) == "function" and typeof(getnamecallmethod) == "function" then
		local mt = getrawmetatable(game)
		if mt and mt.__namecall and old_namecall == nil then
			local nc = mt.__namecall
			local function namecall_hook(self, ...)
				local method = getnamecallmethod()
				if silent_ray_bypass then
					return old_namecall(self, ...)
				end
				if
					method == "Raycast"
					and (self == Workspace or self == workspace)
					and should_redirect_silent(...)
				then
					local origin, direction, params = ...
					local okR, o2, d2 = pcall(apply_silent_redirect, origin, direction, params)
					if okR and o2 and d2 and (d2 - direction).Magnitude > 1e-4 then
						local okCall, res = pcall(old_namecall, self, o2, d2, params)
						if okCall then
							return res
						end
					end
				end
				return old_namecall(self, ...)
			end
			local replacement = typeof(newcclosure) == "function" and newcclosure(namecall_hook) or namecall_hook
			local ok, res = pcall(hookfunction, nc, replacement)
			if ok and res then
				old_namecall = res
			end
		end
	end

	if old_namecall == nil and old_workspace_raycast == nil and Workspace.Raycast and typeof(Workspace.Raycast) == "function" then
		local ray = Workspace.Raycast
		local function hooked(self, origin, direction, params)
			if silent_ray_bypass then
				return old_workspace_raycast(self, origin, direction, params)
			end
			if self == Workspace and should_redirect_silent(origin, direction, params) then
				local okR, o2, d2 = pcall(apply_silent_redirect, origin, direction, params)
				if okR and o2 and d2 and (d2 - direction).Magnitude > 1e-4 then
					local okCall, res = pcall(old_workspace_raycast, self, o2, d2, params)
					if okCall then
						return res
					end
				end
			end
			return old_workspace_raycast(self, origin, direction, params)
		end
		local replacement = typeof(newcclosure) == "function" and newcclosure(hooked) or hooked
		local ok, res = pcall(hookfunction, ray, replacement)
		if ok and res then
			old_workspace_raycast = res
		end
	end
end

local function uninstall_silent_hooks()
	if typeof(hookfunction) == "function" then
		if old_namecall and typeof(getrawmetatable) == "function" then
			local mt = getrawmetatable(game)
			if mt and mt.__namecall then
				pcall(hookfunction, mt.__namecall, old_namecall)
			end
		end
		old_namecall = nil
		if old_workspace_raycast and Workspace.Raycast then
			pcall(hookfunction, Workspace.Raycast, old_workspace_raycast)
		end
		old_workspace_raycast = nil
	end
end

install_silent_hooks()
