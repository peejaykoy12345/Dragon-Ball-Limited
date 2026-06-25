local ReplicatedStorage = game:GetService("ReplicatedStorage")

local pooledFolder = ReplicatedStorage:FindFirstChild("PooledFolder") or Instance.new("Folder", ReplicatedStorage)
pooledFolder.Name = "PooledFolder"

local pool: {[Instance]: {Instance}} = {}
local templateDescendantCache: {[Instance]: {Instance}} = {}
local templateLookupCache: {[Instance]: {[string]: Instance}} = {}

local PoolingService = {}

local CLASS_PROPERTIES: {[string]: {string}} = {
    BasePart = {"Transparency"},
    ParticleEmitter = {"Enabled"},
}

--[[local function resetToTemplate(instance: Instance, templateInstance: Instance)
    for class, properties in pairs(CLASS_PROPERTIES) do
        if instance:IsA(class) then
            for _, property in ipairs(properties) do
                instance[property] = templateInstance[property]
            end
            return
        end
    end
end]]

function PoolingService.Register(template: Instance)
	templateDescendantCache[template] = template:GetDescendants()
	pool[template] = {}

	local lookup = {}
	for i, td in ipairs(templateDescendantCache[template]) do
		local key = tostring(i) .. td.ClassName .. td.Name
		if lookup[key] then
			warn(`PoolingService: Duplicate descendant key "{key}" in template "{template.Name}", reset may be unreliable`)
		end
		lookup[key] = td
	end
	templateLookupCache[template] = lookup
end

function PoolingService.GetPooledObject(vfxTemplate: Instance): Instance?
	if vfxTemplate == nil then
		warn("VFX TEMPLATE IS NIL")
		return
	end

	if not templateDescendantCache[vfxTemplate] then
		PoolingService.Register(vfxTemplate)
	end

	local typePool = pool[vfxTemplate]

	if #typePool > 0 then
		return table.remove(typePool) :: Instance
	end

	return vfxTemplate:Clone()
end

function PoolingService.Return(vfx: Instance, template: Instance)
	--[[local templateDescendants = templateDescendantCache[template]
	local vfxDescendants = vfx:GetDescendants()

	resetToTemplate(vfx, template)

	for i, descendant in ipairs(vfxDescendants) do
		local templateDescendant = templateDescendants[i]
		if not templateDescendant then continue end
		if descendant.ClassName ~= templateDescendant.ClassName then
			warn(`PoolingService: Class mismatch at index {i}, "{descendant.ClassName}" vs "{templateDescendant.ClassName}"`)
			continue
		end

		for class in pairs(CLASS_PROPERTIES) do
			if descendant:IsA(class) then
				resetToTemplate(descendant, templateDescendant)
				break
			end
		end
	end]]

	vfx.Parent = pooledFolder
	local typePool = pool[template]
	if not typePool then
		typePool = {}
		pool[template] = typePool
	end
	table.insert(typePool, vfx)
end

return PoolingService