 -- Handle the island command
function CommandIsland(a_Split, a_Player)
    if (#a_Split == 1) then
        return true
    end
    
    local pi = GetPlayerInfo(a_Player)
    local ii = GetIslandInfo(pi.islandNumber)
    if (ii == nil) then
        a_Player:SendMessageInfo("You have no island. Type /skyblock play first.")
        return true
    end
    
    if (a_Split[2] == "home") then    
        if (#a_Split == 3) then
            if (a_Split[3] == "set") then                
                if (a_Player:GetWorld():GetName() ~= WORLD_NAME) then
                    a_Player:SendMessageInfo("You can use this command only in world " + WORLD_NAME)
                    return true
                end
                
                local x = a_Player:GetPosX()
                local y = a_Player:GetPosY()
                local z = a_Player:GetPosZ()
                local yaw = a_Player:GetHeadYaw()
                local pitch = a_Player:GetPitch()
                
                -- Checkf if player is in his island area
                local islandNumber = GetIslandNumber(x, z)
                if (pi.islandNumber ~= islandNumber) then
                    a_Player:SendMessageInfo("You can use this command only on your own island.")
                    return true
                end
                
                ii.homeLocation = { [1] = x, [2] = y, [3] = z, [4] = yaw, [5] = pitch }
                ii:Save()
                a_Player:SendMessageSuccess("Island home location changed.")
                return true
            end
            
            a_Player:SendMessageFailure("Unknown argument.")
            return true
        end
    
        if (a_Player:GetWorld():GetName() ~= WORLD_NAME) then
            if (a_Player:MoveToWorld(WORLD_NAME) == false) then
                -- Didn't find the world
                a_Player:SendMessageFailure("Command failed. Couldn't find the world " .. WORLD_NAME .. ".")
                return true
            end
        end
            
        -- Send player home, check home location
        if (ii.homeLocation == nil) then
            local posX, posZ
            posX, posZ = GetIslandPosition(pi.islandNumber)
            a_Player:TeleportToCoords(posX, 151, posZ)
        else
            local x = ii.homeLocation[1]
            local y = ii.homeLocation[2]
            local z = ii.homeLocation[3]
            local yaw = ii.homeLocation[4]
            local pitch = ii.homeLocation[5]
        
            a_Player:TeleportToCoords(x, y, z)
            a_Player:SetYaw(yaw)
            a_Player:SetPitch(pitch)
        end
        a_Player:SendMessageSuccess("Welcome back " .. a_Player:GetName())
        return true
    end
    
    if (a_Split[2] == "obsidian") then
        if (a_Player:GetWorld():GetName() ~= WORLD_NAME) then
            a_Player:SendMessageInfo("You can use this command only in " .. WORLD_NAME .. ".")
            return true
        end
        -- Reset obsidian
        local pi = GetPlayerInfo(a_Player)
        pi.resetObsidian = true
        a_Player:SendMessageInfo("Make now an right-click on the obsidian block without any items")
        return true
    end
    
    if (a_Split[2] == "add") then
        -- Add player
        if (#a_Split == 2) then
            a_Player:SendMessageInfo("/island add <player>")
            return true
        end
        
        local toAdd = a_Split[3]
        a_Player:GetWorld():DoWithPlayer(toAdd,
            function (a_FoundPlayer)
                ii:AddFriend(a_FoundPlayer)
                ii:Save()
                
                -- Add Entry to inFriendList
                local pi_Added = GetPlayerInfo(a_FoundPlayer)
                pi_Added:AddEntry(ii.islandNumber, a_Player)
                
                -- Check if player has no island, if yes set first added as default
                if (pi_Added.islandNumber == -1) then
                    pi_Added.islandNumber = ii.islandNumber
                end
                pi_Added:Save()
                
                a_Player:SendMessageSuccess("Added player " .. a_FoundPlayer:GetName() .. " to your island.")
                return true
            end);
        
        if (ii:ContainsFriend(toAdd) == false) then
            a_Player:SendMessageInfo("There is no player with that name.")
            return true
        end
        
        return true
    end
    
    if (a_Split[2] == "remove") then
        -- Remove player
        if (#a_Split == 2) then
            a_Player:SendMessageInfo("/island remove <player>")
            return true
        end
        
        if (ii:RemoveFriend(a_Split[3]) == false) then
            a_Player:SendMessageInfo("There is no player with that name.")
        else
            ii:Save()
            a_Player:SendMessageSuccess("Removed player from friend list.")
        end
        
        return true
    end
    
    if (a_Split[2] == "join") then
        -- Join island
        if (#a_Split == 2) then
            a_Player:SendMessageInfo("/island join <player>")
            return true
        end
        
        local toJoin = a_Split[3]
        if (pi.inFriendList[toJoin:lower()] == nil) then
            a_Player:SendMessageInfo("You are not in his friend list.")
            return true
        end
        
        local iiFriend = GetIslandInfo(pi.inFriendList[toJoin:lower()][2])
        if (iiFriend.friends[a_Player:GetUUID()] == nil) then
            a_Player:SendMessageInfo("You have been removed from his friend list.")
            return true
        end
        
        if (iiFriend.homeLocation == nil) then
            local posX, posZ
            posX, posZ = GetIslandPosition(iiFriend.islandNumber)
            a_Player:TeleportToCoords(posX, 151, posZ)
        else
            local x = iiFriend.homeLocation[1]
            local y = iiFriend.homeLocation[2]
            local z = iiFriend.homeLocation[3]
            local yaw = iiFriend.homeLocation[4]
            local pitch = iiFriend.homeLocation[5]
        
            a_Player:TeleportToCoords(x, y, z)
            a_Player:SetYaw(yaw)
            a_Player:SetPitch(pitch)
        end
        
        a_Player:SendMessageSuccess("Teleported you to the island.")
        return true
    end
    
    if (a_Split[2] == "list") then
        -- List friends from island and islands who player can access
        local hasFriends = "Your friends: "
        local amount = GetAmount(ii.friends)
        local counter = 0
        for uuid, playerName in pairs(ii.friends) do
            hasFriends = hasFriends .. playerName
            counter = counter + 1
            if (counter ~= amount) then
                hasFriends = hasFriends .. ", "
            end
        end
        
        local canJoin = "Islands you can enter: "
        amount = GetAmount(pi.inFriendList)
        counter = 0
        for playerName, info in pairs(pi.inFriendList) do
            canJoin = canJoin .. playerName
            counter = counter + 1
            if (counter ~= amount) then
                canJoin = canJoin .. ", "
            end
        end
        
        a_Player:SendMessageInfo(hasFriends)
        a_Player:SendMessageInfo(canJoin)
        return true
    end
    
    if (a_Split[2] == "restart") then
        -- Restart island
        if (a_Player:GetWorld():GetName() ~= WORLD_NAME) then
            a_Player:SendMessageFailure("This command works only in the world " + WORLD_NAME)
            return true
        end
        
        if (pi.islandNumber == -1) then
            a_Player:SendMessageFailure("You have no island.")
            return true
        end
        
        if (pi.isRestarting ~= nil and pi.isRestarting) then -- Avoid running the command multiple
            a_Player:SendMessageInfo("This command is running. Please wait...")
            return true
        end
        
        -- Check if player is the real owner
        if (ii.ownerUUID ~= a_Player:GetUUID() and pi.isRestarting ~= nil) then
            a_Player:SendMessageInfo("Restart not possible, you are not the real owner of this island. If you want to start an own one, type again /island restart.")
            pi.isRestarting = nil -- Player wants to start an own island.
            return true
        end
        
        if (pi.isRestarting == nil) then
            pi.isRestarting = false
            local islandNumber = -1
            local posX = 0
            local posZ = 0
            
            islandNumber, posX, posZ = CreateIsland(a_Player, -1)
            pi.islandNumber = islandNumber
            
            local ii = cIslandInfo.new(islandNumber)
            ii:SetOwner(a_Player)
            ii:Save()
            
            if (a_Player:GetWorld():GetName() ~= WORLD_NAME) then
                a_Player:MoveToWorld(WORLD_NAME)
            end
            
            a_Player:TeleportToCoords(posX, 151, posZ)
            a_Player:SendMessageSuccess("Welcome to your island. Do not fall and make no obsidian :-)")
            pi:Save()
            return true
        end
        
        pi.isRestarting = true
        a_Player:TeleportToCoords(0, 170, 0) -- spawn platform
        
        local posX = 0
        local posZ = 0
        
        posX, posZ = GetIslandPosition(pi.islandNumber)
        RemoveIsland(posX, posZ) -- Recreates all chunks in the area of the island

        a_Player:SendMessageInfo("Please wait 10s...");
        local playerName = a_Player:GetName()
        
        local Callback = function (a_World)
            a_World:DoWithPlayer(playerName, 
                function(a_FoundPlayer)                
                    a_FoundPlayer:GetInventory():Clear()
                    
                    local pi = GetPlayerInfo(a_Player)
                    local islandNumber = -1
                    local posX = 0
                    local posZ = 0
                
                    islandNumber, posX, posZ = CreateIsland(a_FoundPlayer, pi.islandNumber);
                    a_FoundPlayer:TeleportToCoords(posX, 151, posZ);
                    a_FoundPlayer:SetFoodLevel(20)
                    a_FoundPlayer:SetHealth(a_FoundPlayer:GetMaxHealth())
                    a_FoundPlayer:SendMessageSuccess("Good luck with your new island.")
                    
                    pi.isRestarting  = false
                    pi.isLevel = LEVELS[1].levelName
                    pi.completedChallenges = {}
                    pi.completedChallenges[pi.isLevel] = {}
                    pi:Save()
                end)
            end
        
        a_Player:GetWorld():ScheduleTask(200, Callback)
        return true
    end
    
    a_Player:SendMessageFailure("Unknown argument.")
    return true
end