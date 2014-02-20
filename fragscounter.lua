PLUGIN.Title = "Frags Counter"
PLUGIN.Description = "Count kills while people alive and shows some messages like doublekill, multikill."
PLUGIN.Author = "MisterFix"
PLUGIN.Version = "0.3"

function PLUGIN:Init()
    print("Frags Counter plugin loading.")
    if (not api.Exists( "economy" )) then print("Basic Economy not found!") end
    economy = plugins.Find("econ")
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
    self.Config.send_chat = false
    self.Config.send_notice = true
    self.Config.send_to_killer = true
    self.Config.economy_enabled = true
    self.Config.money_for_kill_base = 100
end

function PLUGIN:Broadcast(msg, exceptuser)
    local netUsers = rust.GetAllNetUsers()

    for k,netUser in pairs(netUsers)
    do
        if (self.Config.send_to_killer or exceptuser ~= netUser) then
            -- for possibility to send notice and chat at one time
            if (self.Config.send_notice) then
                rust.Notice( netUser, msg )
            end
            if (self.Config.send_notice) then
                rust.SendChatToUser( netUser, msg )
            end
        end
    end
end

function PLUGIN:OnKilled (takedamage, dmg)
    if (dmg.attacker.client and dmg.victim.client and takedamage:GetComponent("HumanController") and dmg.attacker.client ~= dmg.victim.client) then
        local player = dmg.attacker.client.netUser
        local playerID = rust.GetUserID( player )
        local target = dmg.victim.client.netUser
        local targetID = rust.GetUserID( target )
        local msg
        local money
        if (self.frags[targetID]) then
            if (self.frags[targetID] >= 5) then
                msg = string.gsub(self.Config.stop_messages, "%%s1", util.QuoteSafe( player.displayName ) )
                msg = string.gsub(msg, "%%s2", util.QuoteSafe( target.displayName ) )
                self:BroadcastNotice( msg )
                money = self.Config.money_for_kill_base * 2
                economy:giveMoneyTo(target, money)
                rust.SendChatToUser(target, "You got " .. money .. " dollars for rampage.")
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
        if (self.Config.economy_enabled) then
            money = self.Config.money_for_kill_base + self.Config.money_for_kill_base * fragsc * 0.05
            economy:giveMoneyTo(player, money)
            rust.SendChatToUser(player, "You got " .. money .. " dollars.")
            economy:takeMoneyFrom(target, money * 0.3)
            rust.SendChatToUser(target, "You lost " .. money * 0.3 .. " dollars.")
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

