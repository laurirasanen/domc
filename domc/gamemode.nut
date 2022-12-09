DoIncludeScript("domc/util.nut", null);
DoIncludeScript("domc/player.nut", null);
DoIncludeScript("domc/bot.nut", null);
DoIncludeScript("domc/lane.nut", null);

PrecacheModel("models/bots/heavy/bot_heavy.mdl");
PrecacheModel("models/bots/gibs/heavybot_gib_pelvis.mdl");
PrecacheModel("models/bots/gibs/heavybot_gib_arm.mdl");
PrecacheModel("models/bots/gibs/heavybot_gib_arm2.mdl");
PrecacheModel("models/bots/gibs/heavybot_gib_leg.mdl");
PrecacheModel("models/bots/gibs/heavybot_gib_leg2.mdl");
PrecacheModel("models/bots/gibs/heavybot_gib_head.mdl");
PrecacheModel("models/bots/gibs/heavybot_gib_chest.mdl");

PrecacheModel("models/bots/sniper/bot_sniper.mdl");
PrecacheModel("models/bots/gibs/sniperbot_gib_head.mdl");

PrecacheModel("models/bots/demo_boss/bot_demo_boss.mdl");

PrecacheModel("models/items/currencypack_small.mdl");
PrecacheModel("models/items/currencypack_medium.mdl");
PrecacheModel("models/items/currencypack_large.mdl");

function Think()
{
    if (("gamemode_domc" in getroottable()))
    {
        ::gamemode_domc.Think();
    }
}

class GamemodeDomc
{
    players = null;
    bots = null;
    lanes = []

    constructor()
    {
        this.bots = [];
        this.players = {};
        local ply = null;
        while(ply = Entities.FindByClassname(ply, "player"))
        {
            this.players[ply.entindex()] <- Player(ply);
        }
        for (local i = 0; i < 3; i++)
        {
            this.lanes.append(Lane());
        }
    }

    function Think()
    {
        foreach(ply in this.players)
        {
            ply.Think();
        }
    }

    function OnRoundStart()
    {
        Log("round start");

        foreach(ply in this.players)
        {
            ply.OnRoundStart();
        }
    }

    function AddPlayer(userid)
    {
        if (userid in this.players)
        {
            return;
        }

        local ent = GetPlayerFromUserID(userid);
        if (ent && ent.IsValid() && ent.IsPlayer())
        {
            this.players[userid] <- Player(ent);
        }
    }

    function RemovePlayer(userid)
    {
        if (!(userid in this.players))
        {
            return;
        }

        delete this.players[userid];
    }

    function AddBot(type, team, pos, ang, laneIndex)
    {
        Log(format("AddBot %d, %d", type, team, laneIndex));
        local bot = Bot(type, team, pos, ang, this.lanes[laneIndex]);
        this.bots.append(bot);
    }

    function AddNodeToLane(laneIndex, pos)
    {
        Log(format("AddNodeToLane %d %s", laneIndex, pos.tostring()));
        this.lanes[laneIndex].AddNode(pos);
    }

    function DebugDrawLanes(duration)
    {
        foreach (lane in this.lanes)
        {
            lane.DebugDraw(duration);
        }
    }

    function IsBot(entIndex)
    {
        foreach(bot in this.bots)
        {
            if (bot.botEnt.IsValid() && bot.botEnt.GetEntityIndex() == entIndex)
            {
                return true;
            }
        }

        return false;
    }
}

function OnGameEvent_player_spawn(data)
{
    Log("player " + data.userid + " spawned");
    ::gamemode_domc.AddPlayer(data.userid);
}

function OnGameEvent_player_death(data)
{
    Log("player " + data.userid + " died");
    ::gamemode_domc.RemovePlayer(data.userid);
}

function OnGameEvent_teamplay_round_start(data)
{
    local collected = collectgarbage();
    Log("gc: deleted " + collected + " ref cycles");

    ::gamemode_domc.OnRoundStart();
}

function OnGameEvent_teamplay_round_waiting_ends(data)
{
    // TODO: start spawning bots
    Log("teamplay_round_waiting_ends");
}

function OnScriptHook_OnTakeDamage(params)
{
    local ent = params.const_entity;
	local inf = params.inflictor;
    Log(format("take dmg | %s -> %s : %d", inf.GetClassname(), ent.GetClassname(), params.damage));
    if (ent.IsPlayer() && inf.GetClassname() == "base_boss" && params.damage_type == 1)
    {
		// Don't crush the player if a bot pushes them into a wall
        params.damage = 0;
    }
}

if (!("gamemode_domc" in getroottable()))
{
    ::gamemode_domc <- GamemodeDomc();

    if (!("HOOKED_EVENTS" in getroottable()))
    {
        __CollectGameEventCallbacks(this);
        ::HOOKED_EVENTS <- true;
    }

    local thinker = SpawnEntityFromTable("info_target", { targetname = "domc_gamemode" } );
    if(thinker.ValidateScriptScope())
    {
        thinker.GetScriptScope()["Think"] <- Think;
        AddThinkToEnt(thinker, "Think");
    }
}
else
{
    ::gamemode_domc.OnRoundStart();
}

::TestBot <- function(type, team, laneIndex)
{
    if ("gamemode_domc" in getroottable())
    {
        local ply = GetListenServerHost();
        ::gamemode_domc.AddBot(
            type,
            team,
            ply.EyePosition() + ply.GetForwardVector()*256,
            ply.GetAbsAngles(),
            laneIndex
        );
    }
}

::AddLaneNode <- function(laneIndex)
{
    local ply = GetListenServerHost();
    ::gamemode_domc.AddNodeToLane(laneIndex, ply.GetOrigin());
}

::DebugDrawLanes <- function()
{
    ::gamemode_domc.DebugDrawLanes(10.0);
}