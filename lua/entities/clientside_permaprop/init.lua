AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

-- This entity does not exist server-side!

util.AddNetworkString("ClientPerma:AddSingleProp")
util.AddNetworkString("ClientPerma:ClearAll")
util.AddNetworkString("ClientPerma:RemoveProp")
util.AddNetworkString("ClientPerma:Ping")

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

concommand.Add( "nuke_clientside_permaprops", function( ply, cmd, args )
    if ply != NULL then
        ply:ChatPrint("This command can only be run by the dedicated server console!")
        return
    end
    sql.Query("DROP TABLE clientside_permaprops")
    net.Start("ClientPerma:ClearAll")
    net.Broadcast()
    print("[Clientside Permaprops] CLIENTSIDE PERMAPROPS DATABASE CLEARED!")
end )

net.Receive("ClientPerma:RemoveProp", function(len, ply)
    if !ply:IsAdmin() then return end
    local rowid = net.ReadUInt(32)
    if !isnumber(rowid) then return end
    local perma_table = sql.Query("SELECT * FROM clientside_permaprops WHERE ROWID=" .. rowid)
    if !istable(perma_table) then return end
    if !istable(perma_table[1]) then return end
    print("[Clientside Permaprops] " .. ply:Nick() .. " [" .. ply:SteamID() .. "] Removing prop: " .. tostring(perma_table[1]["mdl"]) .. " ROWID: " .. tostring(rowid))
    sql.Query("DELETE FROM clientside_permaprops WHERE ROWID=" .. tostring(rowid))
    net.Start("ClientPerma:RemoveProp")
    net.WriteUInt(rowid, 32)
    net.Broadcast()
end)

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

net.Receive("ClientPerma:Ping", function(len, ply)
    if ply.ClientPermafirstrefresh then return end
    ply.ClientPermafirstrefresh = true
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
        send_prop(pos, ang, mdl, prop_skin, mat, rowid, ply)
    end
end)

-- Creating a table
sql.Query("CREATE TABLE IF NOT EXISTS clientside_permaprops( posx DOUBLE , posy DOUBLE , posz DOUBLE , angx DOUBLE , angy DOUBLE , angz DOUBLE , mdl TEXT , prop_skin INTEGER , mat TEXT )" )

-- Inserting a value to the table
-- sql.Query("INSERT INTO clientside_permaprops( id , name ) VALUES( 1 , 'First') ")

-- Removing a value
-- sql.Query("DELETE FROM clientside_permaprops WHERE ROWID=1")

-- Printing the tables data
-- PrintTable( sql.Query("SELECT ROWID, * FROM clientside_permaprops ") )

-- Deleting the table
-- sql.Query("DROP TABLE clientside_permaprops")