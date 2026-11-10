local GroupHandler = {}

--:// Types
type RobloxGroupRole = {
	Id:number,
	Name:string,
	Rank:number
}

type GroupResult = {
	IsMember:boolean,
	Roles:{RobloxGroupRole}
}

type Target = Player | number

--:// Services
local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")

--:// Config
local Default_Group:number = 1

--:// Values
local Cache = {}

--:// Local functions
local function Init()
	Players.PlayerRemoving:Connect(function(Player:Player)
		Cache[Player.UserId] = nil
	end)
end

local function filterUserId(Target:Target)
	if typeof(Target) == "number" then
		return Target
	end
	
	if typeof(Target) == "Instance" and Target.ClassName == "Player" then
		return Target.UserId
	end
end

local function fetchGroupData(UserId:number, Group:number):GroupResult
	if not Cache[UserId] then
		Cache[UserId] = {}
	end
	
	if Cache[UserId][Group] then
		return Cache[UserId][Group]
	end
	
	local success:boolean, data:GroupResult? = pcall(function()
		return GroupService:GetRolesInGroupAsync(UserId, Group)
	end)
	
	if success then
		Cache[UserId][Group] = data
		return data
	else
		warn("[GroupHandler] - Error retrieving group data: " .. data)
	end
end

local function getHighestRoleInGroup(UserId:number, Group:number):RobloxGroupRole
	local Data = fetchGroupData(UserId, Group)

	if not Data or Data.IsMember == false then
		return nil
	end

	if next(Data.Roles) then
		local Roles:{RobloxGroupRole} = table.clone(Data.Roles)

		for Index = #Roles, 1, -1 do
			local Role:RobloxGroupRole = Roles[Index]

			if Role.Name:sub(1,1) == "[" and Role.Name:sub(-1) == "]" then
				table.remove(Roles, Index)
			end
		end

		return Roles[1]
	end
end

function GroupHandler.GetRankInGroup(Target:Target, Group:number):number
	local UserId:number = filterUserId(Target)
	Group = Group or Default_Group
	
	assert(UserId, "[GroupHandler] - Invalid UserId")
	
	local HighestRole:RobloxGroupRole? = getHighestRoleInGroup(UserId, Group)
	
	if not HighestRole then
		return 0
	end
	
	return HighestRole.Rank
end

function GroupHandler.GetHighestRoleInGroup(Target:Target, Group:number):string
	local UserId:number = filterUserId(Target)
	Group = Group or Default_Group

	assert(UserId, "[GroupHandler] - Invalid UserId")

	local HighestRole:RobloxGroupRole? = getHighestRoleInGroup(UserId, Group)

	if not HighestRole then
		return ""
	end

	return HighestRole.Name
end

function GroupHandler.HasRoleInGroup(Target:Target, Group:number, RoleName:string):boolean
	local UserId:number = filterUserId(Target)
	Group = Group or Default_Group

	assert(UserId, "[GroupHandler] - Invalid UserId")
	
	local Data = fetchGroupData(UserId, Group)

	if not Data or Data.IsMember == false then
		return false
	end
	
	for _, Role in pairs(Data.Roles) do
		if Role.Name == RoleName then
			return true
		end
	end
	
	return false
end

--:// Init
Init()

return GroupHandler
