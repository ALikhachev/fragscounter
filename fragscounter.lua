PLUGIN.Title = "Frags Counter"
PLUGIN.Description = "Count kills while people alive and shows some messages like doublekill, multikill."
PLUGIN.Author = "MisterFix"
PLUGIN.Version = "0.2"

function PLUGIN:Init()
    print("Frags Counter plugin loading.")
    self:LoadConfig()
    self.frags = {}
end

function PLUGIN:LoadConfig()
    local b, res = config.Read("fragscounter")
    self.Config = res or {}
    if (not b) then
        self:LoadDefaultConfig()
        if (res) then config.Save("fragscounter") end
    end
end

function PLUGIN:LoadDefaultConfig()
    self.Config.doublekill_message = "Player %s did doublekill!"
    self.Config.rampage_message = "Player %s is on rampage!! Try to stop him?"
    self.Config.ultrakill_message = "Player %s scored an ultrakill!"
    self.Config.triplekill_message = "Player %s killed three players in a row!"
    self.Config.stop_message = "Player %s1 stopped %s2 who was on rampage!"
end

function PLUGIN:BroadcastNotice(msg)
    local netUsers = rust.GetAllNetUsers()

    for k,netUser in pairs(netUsers)
    do
        rust.Notice( netUser, msg)
    end
end

function PLUGIN:OnKilled (takedamage, dmg)
    if (dmg.attacker.client and dmg.victim.client) then
        local player = dmg.attacker.client.netUser
        local playerID = rust.GetUserID( player )
        local targetuser = dmg.victim.client.netUser
        local targetID = rust.GetUserID( targetuser )
        local msg
        if (self.frags[targetID] ~= nil) then
            if (self.frags[targetID] >= 5) then
                msg = string.gsub(self.Config.stop_messages, "%%s1", util.QuoteSafe( player.displayName ) )
                msg = string.gsub(msg, "%%s2", util.QuoteSafe( targetuser.displayName ) )
                self:BroadcastNotice( msg )
            end
            msg = nil
            self.frags[targetID] = 0
        end
        if (self.frags[playerID] == nil) then
            self.frags[playerID] = 0
        end
        self.frags[playerID] = self.frags[playerID] + 1
        local fragsc = self.frags[playerID]
        if (fragsc >= 5) then
            msg = self.Config.rampage_message
        else 
            if (fragsc == 4) then
                msg = self.Config.ultrakill_message
            else
                if (fragsc == 3) then
                    msg = self.Config.triplekill_message
                else
                    if (fragsc == 2) then
                        msg = self.Config.doublekill_message
                    end
                end
            end
        end
        if (msg ~= nil) then
            msg = string.gsub(msg, "%%s", util.QuoteSafe( player.displayName ) )
            self:BroadcastNotice( msg )
        end
    end
end

function PLUGIN:OnUserDisconnect( netuser )
    local playerID = rust.GetUserID( netuser )
    self.frags[playerID] = nil
end

