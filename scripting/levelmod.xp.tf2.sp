#include <sourcemod>
#include <sdktools>
#include <levelmod>
#include <tf2_stocks>
#include <colors>

#pragma semicolon 1
#define PLUGIN_VERSION "0.1.1"

new Handle:g_hCvarHealExpMult;
new Handle:g_hCvarXPForChargeKill;
new Handle:g_hCvarXPForCapping;
new Handle:g_hCvarXPForWinning;
new Handle:g_hCvarXPForFlagPickup;
new Handle:g_hCvarXPForFlagCap;
new Handle:g_hCvarXPForChargeDeployed;
new Handle:g_hCvarXPForTeleport;
new Handle:g_hCvarXPForStunning;
new Handle:g_hCvarXPForBuffing;
new Handle:g_hCvarXPForDestroying;
new Handle:g_hCvarXPForSapping;
new Handle:g_hCvarXPForMVP;
new Handle:g_hCvarXPForDeflect;
new Handle:g_hCvarXPForItemCrafted;

new g_iHealPointCache[MAXPLAYERS+1];
new g_iHealsOff;
new Float:g_fHealExpMult;

new g_iXPForBuffing;
new g_iXPForChargeKill;
new g_iXPForCapping;
new g_iXPForWinning;
new g_iXPForFlagPickup;
new g_iXPForFlagCap;
new g_iXPForChargeDeployed;
new g_iXPForTeleport;
new g_iXPForStunning;
new g_iXPForDestroying;
new g_iXPForSapping;
new g_iXPForMVP;
new g_iXPForDeflect;
new g_iXPForItemCrafted;

////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo =
{
	name = "Leveling Mod, XP, TF2 Specific",
	author = "Thrawn",
	description = "A plugin for Leveling Mod, specific to tf2, giving Experience for healing, capping etc.",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

//////////////////////////
//P L U G I N  S T A R T//
//////////////////////////
public OnPluginStart()
{
	// G A M E  C H E C K //
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	if(!(StrEqual(game, "tf")))
	{
		SetFailState("This plugin is not for %s", game);
	}

	g_iHealsOff = FindSendPropInfo("CTFPlayer", "m_iHealPoints");
	g_hCvarHealExpMult = CreateConVar("sm_lm_exp_healmulti", "0.03", "Heal multiplied by this value will be given as xp", FCVAR_PLUGIN, true, 0.0);
	g_hCvarXPForChargeKill = CreateConVar("sm_lm_exp_chargekill", "20", "Amount of xp given for killing a charged medic", FCVAR_PLUGIN, true, 0.0);
	g_hCvarXPForCapping = CreateConVar("sm_lm_exp_capping", "20", "Amount of xp given for capping a control point", FCVAR_PLUGIN, true, 0.0);
	g_hCvarXPForWinning = CreateConVar("sm_lm_exp_winning", "20", "Amount of xp given for winning a round", FCVAR_PLUGIN, true, 0.0);
	g_hCvarXPForFlagPickup = CreateConVar("sm_lm_exp_flag_pickup", "5", "Amount of xp given for picking up a flag", FCVAR_PLUGIN, true, 0.0);
	g_hCvarXPForFlagCap = CreateConVar("sm_lm_exp_flag_cap", "10", "Amount of xp given for capturing a flag", FCVAR_PLUGIN, true, 0.0);
	g_hCvarXPForChargeDeployed = CreateConVar("sm_lm_exp_chargedeployed", "10", "Amount of xp given for deploying a charge", FCVAR_PLUGIN, true, 0.0);
	g_hCvarXPForTeleport = CreateConVar("sm_lm_exp_teleport", "2", "Amount of xp given to the builder when a player uses a teleporter", FCVAR_PLUGIN, true, 0.0);
	g_hCvarXPForStunning = CreateConVar("sm_lm_exp_stunning", "5", "Amount of xp given for stunning a player (doubles on big stun)", FCVAR_PLUGIN, true, 0.0);
	g_hCvarXPForBuffing = CreateConVar("sm_lm_exp_buffing", "5", "Amount of xp given for deploying a buff banner", FCVAR_PLUGIN, true, 0.0);
	g_hCvarXPForDestroying = CreateConVar("sm_lm_exp_destroying", "10", "Amount of xp given for destroying a building", FCVAR_PLUGIN, true, 0.0);
	g_hCvarXPForSapping = CreateConVar("sm_lm_exp_sapping", "5", "Amount of xp given for sapping a building", FCVAR_PLUGIN, true, 0.0);
	g_hCvarXPForMVP = CreateConVar("sm_lm_exp_mvp", "20", "Amount of xp given to the MVPs at the end of each round", FCVAR_PLUGIN, true, 0.0);
	g_hCvarXPForDeflect = CreateConVar("sm_lm_exp_deflect", "5", "Amount of xp given for deflecting a projectile", FCVAR_PLUGIN, true, 0.0);
	g_hCvarXPForItemCrafted = CreateConVar("sm_lm_exp_crafting", "5", "Amount of xp given for crafting an item", FCVAR_PLUGIN, true, 0.0);

	HookConVarChange(g_hCvarHealExpMult, Cvar_Changed);
	HookConVarChange(g_hCvarXPForChargeKill, Cvar_Changed);
	HookConVarChange(g_hCvarXPForCapping, Cvar_Changed);
	HookConVarChange(g_hCvarXPForWinning, Cvar_Changed);
	HookConVarChange(g_hCvarXPForFlagPickup, Cvar_Changed);
	HookConVarChange(g_hCvarXPForFlagCap, Cvar_Changed);
	HookConVarChange(g_hCvarXPForChargeDeployed, Cvar_Changed);
	HookConVarChange(g_hCvarXPForTeleport, Cvar_Changed);
	HookConVarChange(g_hCvarXPForStunning, Cvar_Changed);
	HookConVarChange(g_hCvarXPForDestroying, Cvar_Changed);
	HookConVarChange(g_hCvarXPForSapping, Cvar_Changed);
	HookConVarChange(g_hCvarXPForMVP, Cvar_Changed);
	HookConVarChange(g_hCvarXPForDeflect, Cvar_Changed);
	HookConVarChange(g_hCvarXPForItemCrafted, Cvar_Changed);

	HookEvent("player_death", Event_Player_Death);
	HookEvent("medic_death", Event_Medic_Death);
	HookEvent("teamplay_point_captured", Event_Captured, EventHookMode_Post);
	HookEvent("teamplay_flag_event", Event_Flag, EventHookMode_Post);
	HookEvent("teamplay_round_win", Event_RoundWin);
	HookEvent("player_chargedeployed", Event_ChargeDeployed);
	HookEvent("player_teleported", Event_PlayerTeleported);
	HookEvent("player_stunned", Event_PlayerStunned);
	HookEvent("deploy_buff_banner", Event_BuffBanner);
	HookEvent("object_deflected", Event_Deflect);
	HookEvent("player_mvp", Event_MVP);
	HookEvent("item_found", Event_ItemFound);
	HookEvent("player_sapped_object", Event_Sapped);
	HookEvent("object_destroyed", Event_BuildingKill);
}

public OnConfigsExecuted()
{
	g_fHealExpMult = GetConVarFloat(g_hCvarHealExpMult);
	g_iXPForChargeKill = GetConVarInt(g_hCvarXPForChargeKill);
	g_iXPForCapping = GetConVarInt(g_hCvarXPForCapping);
	g_iXPForWinning = GetConVarInt(g_hCvarXPForWinning);
	g_iXPForFlagPickup = GetConVarInt(g_hCvarXPForFlagPickup);
	g_iXPForFlagCap = GetConVarInt(g_hCvarXPForFlagCap);
	g_iXPForChargeDeployed = GetConVarInt(g_hCvarXPForChargeDeployed);
	g_iXPForTeleport = GetConVarInt(g_hCvarXPForTeleport);
	g_iXPForStunning = GetConVarInt(g_hCvarXPForStunning);
	g_iXPForBuffing = GetConVarInt(g_hCvarXPForBuffing);
	g_iXPForDestroying = GetConVarInt(g_hCvarXPForDestroying);
	g_iXPForSapping = GetConVarInt(g_hCvarXPForSapping);
	g_iXPForMVP = GetConVarInt(g_hCvarXPForMVP);
	g_iXPForDeflect = GetConVarInt(g_hCvarXPForDeflect);
	g_iXPForItemCrafted = GetConVarInt(g_hCvarXPForItemCrafted);

}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

//////////////////////////
//E V E N T   H O O K S //
//////////////////////////
public Event_Deflect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new iActor = GetClientOfUserId(GetEventInt(event, "userid"));

		if (!IsClientInGame(iActor))
			return;

		lm_GiveXP(iActor, g_iXPForDeflect, 1);
	}
}

public Event_MVP(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new iActor = GetClientOfUserId(GetEventInt(event, "player"));

		if (!IsClientInGame(iActor))
			return;

		lm_GiveXP(iActor, g_iXPForMVP, 1);
	}
}

public Event_ItemFound(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new iActor = GetClientOfUserId(GetEventInt(event, "player"));

		if (!IsClientInGame(iActor))
			return;

		if (!GetEventBool(event, "crafted"))
			return;

		lm_GiveXP(iActor, g_iXPForItemCrafted, 1);
	}
}

public Event_Sapped(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new iActor = GetClientOfUserId(GetEventInt(event, "userid"));

		if (!IsClientInGame(iActor))
			return;

		lm_GiveXP(iActor, g_iXPForSapping, 1);
	}
}

public Event_BuildingKill(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new iActor = GetClientOfUserId(GetEventInt(event, "attacker"));

		if (!IsClientInGame(iActor))
			return;

		if (!GetEventBool(event, "was_building"))
			return;

		lm_GiveXP(iActor, g_iXPForDestroying, 1);
	}
}

public Event_BuffBanner(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new iBuffer = GetClientOfUserId(GetEventInt(event, "buff_owner"));

		if (!IsClientInGame(iBuffer))
			return;

		lm_GiveXP(iBuffer, g_iXPForBuffing, 1);
	}
}

public Event_PlayerStunned(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new iStunner = GetClientOfUserId(GetEventInt(event, "stunner"));
		new iVictim = GetClientOfUserId(GetEventInt(event, "victim"));

		if (!IsClientInGame(iStunner) || iStunner == iVictim)
			return;

		lm_GiveXP(iStunner, GetEventBool(event, "big_stun") ? g_iXPForStunning * 2 : g_iXPForStunning, 1);
	}
}

public Event_PlayerTeleported(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new iBuilder = GetClientOfUserId(GetEventInt(event, "builderid"));
		new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

		if (!IsClientInGame(iClient) || iBuilder == iClient)
			return;

		lm_GiveXP(iClient, g_iXPForTeleport, 1);
	}
}

public Event_ChargeDeployed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

		if (!IsClientInGame(iClient))
			return;

		lm_GiveXP(iClient, g_iXPForChargeDeployed, 1);
	}
}

public Event_Flag(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new iClient = GetClientOfUserId(GetEventInt(event, "player"));
		new iFlagStatus = GetEventInt(event, "eventtype");

		if (!IsClientInGame(iClient))
			return;

		switch (iFlagStatus)
		{
			case 1:
			{
				//The flag was picked up
				lm_GiveXP(iClient, g_iXPForFlagPickup, 1);
			}
			case 2:
			{
				//The flag was capped
				lm_GiveXP(iClient, g_iXPForFlagCap, 1);
			}
		}
	}
}


public Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new team = GetEventInt(event, "team");

		for (new client = 1; client <= MaxClients; client++) {
			if(GetClientTeam(client) == team) {
				lm_GiveXP(client, g_iXPForWinning, 1);
			}
		}
	}
}

public Event_Captured(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		decl String:cappers[128];
		GetEventString(event, "cappers", cappers, sizeof(cappers));

		new len = strlen(cappers);
		for (new i = 0; i < len; i++)
		{
			new client = cappers{i};
			lm_GiveXP(client, g_iXPForCapping, 1);
		}
	}
}

public Event_Medic_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));

		if(victim > 0) {
			new healing = GetEventInt(event, "healing");
			new bool:charged = GetEventBool(event, "charged");

			new amount = RoundFloat(healing * g_fHealExpMult);

			if(amount > 0 && lm_GetClientLevel(victim) < lm_GetLevelMax()) {
				lm_GiveXP(victim, amount, 0);
			}

			if(charged) {
				//killed a charged medic
				new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

				lm_GiveXP(attacker, g_iXPForChargeKill, 1);
			}

		}
	}
}

public Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));

		if(victim > 0)
		{
			DumpHeals(victim);
		}
	}
}

DumpHeals(client)
{
	new iTotalHealPoints = GetEntData(client, g_iHealsOff);
	new iLifeHealPoints = iTotalHealPoints - g_iHealPointCache[client];

	if (iLifeHealPoints > 0 && TF2_GetPlayerClass(client) != TFClass_Medic)
	{
		new amount = RoundFloat(iLifeHealPoints * g_fHealExpMult);
		if(amount > 0 && lm_GetClientLevel(client) < lm_GetLevelMax()) {
			lm_GiveXP(client, amount, 0);
		}
	}

	g_iHealPointCache[client] = iTotalHealPoints;
}


/*
stock AssignPointsToEvent(id, short, desc, event, key, defValue) {
	HookEvent(event, Event_Box);

	decl String:cvarName[64];
	Format(cvarName, sizeof(cvarName), "sm_lm_exp_%s", short);

	decl String:defValString[4];
	Format(defValString, sizeof(defValString), "%i", defValue);

	g_hCvarBox[id] = CreateConVar(cvarName, defValString, desc, FCVAR_PLUGIN, true, 0.0);
}

public Event_Box(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{

		new iActor = GetClientOfUserId(GetEventInt(event,
	}
}
*/
