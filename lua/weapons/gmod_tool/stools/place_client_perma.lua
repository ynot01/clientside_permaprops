TOOL.Category = "Clientside Permaprops"
TOOL.Name = "#tool.place_client_perma.name"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
    language.Add("tool.place_client_perma.name", "Clientside Permaprop")
    language.Add("tool.place_client_perma.desc", "Left click to turn a prop, or right click to remove a clientside permaprop. Reload to refresh.")
    function TOOL:Think()
        language.Add("tool.place_client_perma.0", "Permissions check: " .. tostring(self:GetOwner():IsAdmin()) .. " - There are currently " .. tostring(#ents.FindByClass("clientside_permaprop")) .. " clientside permaprops loaded.")
    end
end

local next_prop_time = 0
local function send_prop(pos, ang, mdl, prop_skin, mat, rowid, ply)
    if next_prop_time < CurTime() then
        next_prop_time = CurTime() + 0.02
    else
        next_prop_time = next_prop_time + 0.02
    end
    timer.Simple(next_prop_time - CurTime(), function()
        if !IsValid(ply) and ply != nil then return end
        net.Start("ClientPerma:AddSingleProp", true)
            net.WriteVector(pos)
            net.WriteAngle(ang)
            net.WriteString(mdl)
            net.WriteUInt(prop_skin, 8)
            net.WriteString(mat)
            net.WriteUInt(rowid, 32)
        if ply == nil then
            net.Broadcast()
        else
            net.Send(ply)
        end
    end)
end

if CLIENT then
    local white = Color(255,255,255)
    local red = Color(255,0,0)
    local black = Color(0,0,0)
    surface.CreateFont("ClientPerma:Font", {
        font = "Roboto",
        size = 12
    })
    function TOOL:DrawHUD()
        for k,v in ipairs(ents.FindByClass("clientside_permaprop")) do
            if LocalPlayer():GetPos():DistToSqr(v:GetPos()) > 10000000 then
                continue
            end
            cam.Start3D()
                local screenpos = v:GetPos():ToScreen()
            cam.End3D()
            if !screenpos.visible then continue end
            if v:GetPos():DistToSqr(LocalPlayer():EyePos() + LocalPlayer():GetAimVector() * 100) < 1000 then
                draw.SimpleTextOutlined(v.rowid .. ": " .. v:GetModel(), "ClientPerma:Font", screenpos.x, screenpos.y, red, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, black)
            else
                draw.SimpleTextOutlined(v.rowid .. ": " .. v:GetModel(), "ClientPerma:Font", screenpos.x, screenpos.y, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, black)
            end
        end
    end
end
--self:GetClientInfo("class", "")
function TOOL:LeftClick( tr )
    if !self:GetOwner():IsAdmin() then return false end
    if SERVER and tr.Entity and tr.Entity:GetModel() then
        local ent = tr.Entity
        local mdl = ent:GetModel()
        if !isstring(mdl) then
            -- self:GetOwner():ChatPrint(tostring(ent:GetModel()) .. " is not a string!")
            return true
        end
        if !string.EndsWith(mdl, ".mdl") then
            -- self:GetOwner():ChatPrint(tostring(ent:GetModel()) .. " is not a .mdl!")
            return true
        end
        local pos = ent:GetPos()
        local ang = ent:GetAngles()
        local prop_skin = ent:GetSkin()
        local mat = ent:GetMaterial()
        ent:Remove()
        local query = "INSERT INTO clientside_permaprops( posx , posy , posz , angx , angy , angz , mdl , prop_skin , mat ) VALUES( "
        query = query .. tostring(pos.x) .. " , "
        query = query .. tostring(pos.y) .. " , "
        query = query .. tostring(pos.z) .. " , "
        query = query .. tostring(ang.x) .. " , "
        query = query .. tostring(ang.y) .. " , "
        query = query .. tostring(ang.z) .. " , "
        query = query .. SQLStr(mdl) .. " , "
        query = query .. tostring(prop_skin) .. " , "
        query = query .. SQLStr(mat) .. " ) "
        sql.Query(query)
        local last_row = sql.Query("select last_insert_rowid()")[1]["last_insert_rowid()"]
        send_prop(pos, ang, mdl, prop_skin, mat, last_row)
        print("[Clientside Permaprops] " .. self:GetOwner():Nick() .. " [" .. self:GetOwner():SteamID() .. "] Created prop: " .. tostring(mdl) .. " ROWID: " .. tostring(last_row))
    end
    return true
end

function TOOL:RightClick( tr )
    if !self:GetOwner():IsAdmin() then return false end
    if IsFirstTimePredicted() and CLIENT then
        for k,v in ipairs(ents.FindByClass("clientside_permaprop")) do
            if v:GetPos():DistToSqr(LocalPlayer():EyePos() + LocalPlayer():GetAimVector() * 100) < 1000 then
                net.Start("ClientPerma:RemoveProp")
                    net.WriteUInt(v.rowid, 32)
                net.SendToServer()
            end
        end
    end
    return true
end

local last_reload = 0
local reload_cd = 300
function TOOL:Reload( tr )
    if !self:GetOwner():IsAdmin() then return false end
    if last_reload > CurTime() - reload_cd then
        if SERVER then
            self:GetOwner():ChatPrint("You can reload clientside permaprops again in " .. tostring(math.Round(last_reload - (CurTime() - reload_cd))) .. " seconds.")
        end
        return false
    end
    last_reload = CurTime()
    if SERVER then
        print("[Clientside Permaprops] " .. self:GetOwner():Nick() .. " [" .. self:GetOwner():SteamID() .. "] Triggered prop refresh.")
        for k,v in player.Iterator() do
            v:ChatPrint("Reloading clientside permaprops!")
        end
        net.Start("ClientPerma:ClearAll")
        net.Broadcast()
        local perma_table = sql.Query("SELECT ROWID, * FROM clientside_permaprops ")
        if !istable(perma_table) or #perma_table <= 0 then return end
        for _,proptable in ipairs(perma_table) do
            local posx = proptable["posx"] or 0
            local posy = proptable["posy"] or 0
            local posz = proptable["posz"] or 0
            local angx = proptable["angx"] or 0
            local angy = proptable["angy"] or 0
            local angz = proptable["angz"] or 0
            local pos = Vector(posx, posy, posz)
            local ang = Angle(angx, angy, angz)
            local mdl = proptable["mdl"] or "models/error.mdl"
            local prop_skin = proptable["prop_skin"] or 0
            local mat = proptable["mat"] or ""
            local rowid = proptable["rowid"] or 0
            send_prop(pos, ang, mdl, prop_skin, mat, rowid)
        end
    end
    return true
end


function TOOL.BuildCPanel( CPanel )

    -- local ClassSelect = {Label = "Entity", MenuButton = 0, Options={}, CVars = {}}
    -- for k,v in ipairs(scripted_ents.GetSpawnable()) do
    --     ClassSelect["Options"][v.ClassName]			= { place_client_perma_class = v.ClassName }
    -- end

    -- CPanel:AddControl("Header", {
    --     Description = "(SUPERADMIN ONLY) Creates a persistent (or not) vehicle that traverses through set points repeatedly"
    -- })

    -- CPanel:AddControl("ComboBox", ClassSelect )

    CPanel:AddControl("Label", {
        Text = "Test"
    })

    -- CPanel:AddControl( "Slider",  { Label	= "Seconds",
    -- 								Type	= "Float",
    -- 								Min		= 0.1,
    -- 								Max		= 60.0,
    -- 								Command = "place_client_perma_delay" }	 )

    -- CPanel:AddControl( "Checkbox", { Label	= "LFS: Landing gear up?",
    -- Command = "place_client_perma_lfsgear" }	 )


    -- CPanel:AddControl("Button", {
    --     Label = "Create cinematic",
    --     Command = "makecinematic"
    -- })

    -- CPanel:AddControl("Button", {
    --     Label = "Save cinematic to server",
    --     Command = "savecinematic"
    -- })

    -- CPanel:AddControl("Label", {
    --     Text = "Press R to bring up the remove points menu"
    -- })

    -- CPanel:AddControl("Label", {
    --     Text = "Right click to bring up the adjust points menu"
    -- })

    -- CPanel:AddControl("Label", {
    --     Text = "The menus do not pop up, so you must press F3 to unlock your cursor"
    -- })

end

-- concommand.Add("makecinematic", function( ply, cmd, args )
--     net.Start("CreateCinVehi")
--     net.WriteBool(false)
--     net.WriteString(GetConVar("place_client_perma_class"):GetString())
--     net.WriteTable(setpoints)
--     net.SendToServer()
-- end)

-- concommand.Add("savecinematic", function( ply, cmd, args )
--     net.Start("CreateCinVehi")
--     net.WriteBool(true)
--     net.WriteString(GetConVar("place_client_perma_class"):GetString())
--     net.WriteTable(setpoints)
--     net.SendToServer()
-- end)