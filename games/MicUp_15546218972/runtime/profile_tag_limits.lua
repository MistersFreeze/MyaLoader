-- Corner (MicUp): game Profile Tags UI caps selection using require(ReplicatedStorage.Assets.Data.Tags).MaxTags.
-- Bump it client-side so the stock prompt allows more than 8. Server may still reject on UpdateProfileTags.
task.spawn(function()
	local okPath, tagsMod = pcall(function()
		return game:GetService("ReplicatedStorage"):WaitForChild("Assets", 30):WaitForChild("Data", 30):WaitForChild(
			"Tags",
			30
		)
	end)
	if not okPath or not tagsMod or not tagsMod:IsA("ModuleScript") then
		return
	end
	local ok, m = pcall(require, tagsMod)
	if ok and type(m) == "table" and type(m.MaxTags) == "number" then
		m.MaxTags = 255
	end
end)
