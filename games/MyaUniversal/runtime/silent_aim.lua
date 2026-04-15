local function vector3_dot(a, b)
	if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then
		return nil
	end
	return a.X * b.X + a.Y * b.Y + a.Z * b.Z
end

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
	if typeof(look) ~= "Vector3" then
		return false
	end
	local dunit = direction.Unit
	if typeof(dunit) ~= "Vector3" then
		return false
	end
	local dot = vector3_dot(dunit, look)
	if dot == nil then
		return false
	end
	if dot < silent_min_look_dot then
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

local function run_raycast_redirect(self, origin, direction, params)
	if not should_redirect_silent(origin, direction, params) then
		return nil
	end
	local okR, o2, d2 = pcall(apply_silent_redirect, origin, direction, params)
	if not okR or not o2 or not d2 then
		return nil
	end
	if (d2 - direction).Magnitude <= 1e-4 then
		return nil
	end
	return o2, d2
end

local function install_silent_hooks()
	if typeof(hookfunction) ~= "function" then
		return
	end

	-- Prefer Workspace.Raycast hook: avoids routing all of game.__namecall (debug utilities, etc.).
	if old_workspace_raycast == nil and Workspace.Raycast and typeof(Workspace.Raycast) == "function" then
		local ray = Workspace.Raycast
		local function hooked(self, origin, direction, params)
			if silent_ray_bypass then
				return old_workspace_raycast(self, origin, direction, params)
			end
			if self ~= Workspace and self ~= workspace then
				return old_workspace_raycast(self, origin, direction, params)
			end
			local o2, d2 = run_raycast_redirect(self, origin, direction, params)
			if o2 and d2 then
				local okCall, res = pcall(old_workspace_raycast, self, o2, d2, params)
				if okCall then
					return res
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

	-- Fallback: game.__namecall (only if Raycast hook could not be installed).
	if old_workspace_raycast == nil and typeof(getrawmetatable) == "function" and typeof(getnamecallmethod) == "function" then
		local mt = getrawmetatable(game)
		if mt and mt.__namecall and old_namecall == nil then
			local nc = mt.__namecall
			local function namecall_hook(self, ...)
				if silent_ray_bypass then
					return old_namecall(self, ...)
				end
				local method = getnamecallmethod()
				if method ~= "Raycast" then
					return old_namecall(self, ...)
				end
				if self ~= Workspace and self ~= workspace then
					return old_namecall(self, ...)
				end
				local origin, direction, params = ...
				local o2, d2 = run_raycast_redirect(self, origin, direction, params)
				if o2 and d2 then
					local okCall, res = pcall(old_namecall, self, o2, d2, params)
					if okCall then
						return res
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
end

local function uninstall_silent_hooks()
	if typeof(hookfunction) ~= "function" then
		return
	end
	if old_workspace_raycast and Workspace.Raycast then
		pcall(hookfunction, Workspace.Raycast, old_workspace_raycast)
	end
	old_workspace_raycast = nil
	if old_namecall and typeof(getrawmetatable) == "function" then
		local mt = getrawmetatable(game)
		if mt and mt.__namecall then
			pcall(hookfunction, mt.__namecall, old_namecall)
		end
	end
	old_namecall = nil
end

install_silent_hooks()
