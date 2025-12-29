include( "shared.lua" )

timer.Create("ClientPerma:PingLoop", 3, 0, function()
    net.Start("ClientPerma:Ping")
    net.SendToServer()
end)

net.Receive("ClientPerma:AddSingleProp", function(len)
    timer.Remove("ClientPerma:PingLoop")
    local pos = net.ReadVector()
    local ang = net.ReadAngle()
    local mdl = net.ReadString()
    local prop_skin = net.ReadUInt(8)
    local mat = net.ReadString()
    local rowid = net.ReadUInt(32)
    local prop = ents.CreateClientside("clientside_permaprop")
    prop:SetModel(mdl)
    prop:SetPos(pos)
    prop:SetAngles(ang)
    prop:SetSkin(prop_skin)
    prop:SetMaterial(mat)
    prop.rowid = rowid
end)
net.Receive("ClientPerma:ClearAll", function()
    for k,v in ipairs(ents.FindByClass("clientside_permaprop")) do
        v:Remove()
    end
    -- chat.AddText("Removed all clientside permaprops")
end)
net.Receive("ClientPerma:RemoveProp", function()
    local to_remove_id = net.ReadUInt(32)
    for k,v in ipairs(ents.FindByClass("clientside_permaprop")) do
        if v.rowid == to_remove_id then
            v:Remove()
            return
        end
    end
end)

ENT.rowid = -1
function ENT:Initialize()
end

function ENT:Draw()
    if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 10000000 then
        self:DestroyShadow()
        return
    end
    self:DrawModel()
    self:CreateShadow()
end
