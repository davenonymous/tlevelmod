#include <sourcemod>
#include <levelmod>
#include <tf2_stocks>

#pragma semicolon 1
#define PLUGIN_VERSION "0.1.1"
#define MAXEVENTS 64

new g_iNextId = 0;
new Handle:g_hCvarBox[MAXEVENTS] = {INVALID_HANDLE, ...};
new String:g_sShort[MAXEVENTS][127];
new String:g_sEvent[MAXEVENTS][127];
new String:g_sKey[MAXEVENTS][127];
new String:g_sCondition[MAXEVENTS][127];
new bool:g_bMustBe[MAXEVENTS];
new g_iXPFor[MAXEVENTS];

new Handle:g_hCvarHealExpMult;

new g_iHealPointCache[MAXPLAYERS+1];
new g_iHealsOff;

new Float:g_fHealExpMult;

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

	AssignPointsToEvent("chargekill", 		"Amount of xp given for killing a charged medic",
											"medic_death", "attacker", "20", "charged", true);

	AssignPointsToEvent("chargedeployed", 	"Amount of xp given for deploying a charge",
											"player_chargedeployed", "userid", "5");

	AssignPointsToEvent("destroying", 		"Amount of xp given for destroying a building",
											"object_destroyed", "attacker", "10", "was_building", true);

	AssignPointsToEvent("buffing", 			"Amount of xp given for destroying a building",
											"deploy_buff_banner", "buff_owner", "5");

	AssignPointsToEvent("deflect", 			"Amount of xp given for deflecting a projectile",
											"object_deflected", "userid", "5");

	AssignPointsToEvent("mvp", 				"Amount of xp given to the MVPs at the end of each round",
											"player_mvp", "player", "20");

	AssignPointsToEvent("crafting", 		"Amount of xp given for crafting an item",
											"item_found", "player", "5", "crafted", true);

	AssignPointsToEvent("sapping", 			"Amount of xp given for sapping a building",
											"player_sapped_object", "userid", "5");

	AssignPointsToEventCustom(Event_Captured, 		"capping", 	"Amount of xp given for capping a control point",
													"teamplay_point_captured", "10");

	AssignPointsToEventCustom(Event_RoundWin, 		"winning", 	"Amount of xp given for winning a round",
													"teamplay_point_captured", "20");

	AssignPointsToEventCustom(Event_Flag, 			"flag_pickup", 	"Amount of xp given for picking up a flag",
													"teamplay_flag_event", "5");

	AssignPointsToEventCustom(Event_Flag, 			"flag_cap", 	"Amount of xp given for capturing a flag",
													"teamplay_flag_event", "10");

	AssignPointsToEventCustom(Event_PlayerTeleported,	"teleport", 	"Amount of xp given to the builder when a player uses a teleporter",
													"player_teleported", "2");

	AssignPointsToEventCustom(Event_PlayerStunned, 		"stunning", 	"Amount of xp given for stunning a player (doubles on big stun)",
													"player_stunned", "5");


	g_hCvarHealExpMult = CreateConVar("sm_lm_exp_healmulti", "0.03", "Heal multiplied by this value will be given as xp", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hCvarHealExpMult, Cvar_Changed);

	HookEvent("player_death", Event_Player_Death);
	HookEvent("medic_death", Event_Medic_Death);

	AutoExecConfig(true, "plugin.levelmod.exp.tf2");
}

public OnConfigsExecuted()
{
	g_fHealExpMult = GetConVarFloat(g_hCvarHealExpMult);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

public Cvar_ChangedDynamic(Handle:convar, const String:oldValue[], const String:newValue[]) {
	for(new i = 0; i < g_iNextId; i++) {
		g_iXPFor[i] = GetConVarInt(g_hCvarBox[i]);
	}
}

stock AssignPointsToEventCustom(EventHook:callback, const String:short[127], const String:desc[127], const String:event[127], const String:defValue[127]) {
	HookEvent(event, Event_Box);

	decl String:cvarName[64];
	Format(cvarName, sizeof(cvarName), "sm_lm_exp_%s", short);

	g_hCvarBox[g_iNextId] = CreateConVar(cvarName, defValue, desc, FCVAR_PLUGIN, true, 0.0);
	g_sShort[g_iNextId] = short;
	g_sEvent[g_iNextId] = event;
	g_sKey[g_iNextId] = "";
	g_sCondition[g_iNextId] = "";
	g_bMustBe[g_iNextId] = false;

	HookConVarChange(g_hCvarBox[g_iNextId], Cvar_ChangedDynamic);
	HookEvent(event, callback, EventHookMode_Post);

	g_iNextId++;
}

stock AssignPointsToEvent(const String:short[127], const String:desc[127], const String:event[127], const String:key[127], const String:defValue[127], const String:condition[127] = "", bool:mustBe = true) {
	HookEvent(event, Event_Box);

	decl String:cvarName[64];
	Format(cvarName, sizeof(cvarName), "sm_lm_exp_%s", short);

	g_hCvarBox[g_iNextId] = CreateConVar(cvarName, defValue, desc, FCVAR_PLUGIN, true, 0.0);
	g_sShort[g_iNextId] = short;
	g_sEvent[g_iNextId] = event;
	g_sKey[g_iNextId] = key;
	g_sCondition[g_iNextId] = condition;
	g_bMustBe[g_iNextId] = mustBe;

	HookConVarChange(g_hCvarBox[g_iNextId], Cvar_ChangedDynamic);
	HookEvent(event, Event_Box);

	g_iNextId++;
}

stock FindEventID(const String:eventName[]) {
	for(new i = 0; i < g_iNextId; i++) {
		if(StrEqual(eventName, g_sEvent[i])) {
			return i;
		}
	}

	return -1;
}

//////////////////////////
//E V E N T   H O O K S //
//////////////////////////
public Event_Box(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new iEID = FindEventID(name);
		if(iEID != -1) {
			new iActor = GetClientOfUserId(GetEventInt(event,g_sKey[iEID]));

			if (iActor == 0 || iActor > MaxClients || !IsClientInGame(iActor))
				return;

			if (!StrEqual(g_sCondition[iEID],"") && GetEventBool(event, g_sCondition[iEID]) != g_bMustBe[iEID]) {
				return;
			}

			lm_GiveXP(iActor, g_iXPFor[iEID], 1);
		}
	}
}

public Event_Captured(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new iEID = FindEventID(name);
		if(iEID != -1) {
			decl String:cappers[128];
			GetEventString(event, "cappers", cappers, sizeof(cappers));

			new len = strlen(cappers);
			for (new i = 0; i < len; i++)
			{
				new client = cappers{i};
				lm_GiveXP(client, g_iXPFor[iEID], 1);
			}
		}
	}
}

public Event_PlayerStunned(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new iEID = FindEventID(name);
		if(iEID != -1) {
			new iStunner = GetClientOfUserId(GetEventInt(event, "stunner"));
			new iVictim = GetClientOfUserId(GetEventInt(event, "victim"));

			if (!IsClientInGame(iStunner) || iStunner == iVictim)
				return;

			lm_GiveXP(iStunner, GetEventBool(event, "big_stun") ? g_iXPFor[iEID] * 2 : g_iXPFor[iEID], 1);
		}
	}
}

public Event_PlayerTeleported(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new iEID = FindEventID(name);
		if(iEID != -1) {
			new iBuilder = GetClientOfUserId(GetEventInt(event, "builderid"));
			new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

			if (!IsClientInGame(iClient) || iBuilder == iClient)
				return;

			lm_GiveXP(iClient, g_iXPFor[iEID], 1);
		}
	}
}

public Event_Flag(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new iEID = FindEventID(name);
		if(iEID != -1) {
			new iClient = GetClientOfUserId(GetEventInt(event, "player"));
			new iFlagStatus = GetEventInt(event, "eventtype");

			if (!IsClientInGame(iClient))
				return;

			if(iFlagStatus == 2) {
				//The flag was capped
				lm_GiveXP(iClient, g_iXPFor[iEID], 1);
			}
		}
	}
}


public Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new iEID = FindEventID(name);
		if(iEID != -1) {
			new team = GetEventInt(event, "team");

			for (new client = 1; client <= MaxClients; client++) {
				if(IsClientInGame(client) && GetClientTeam(client) == team) {
					lm_GiveXP(client, g_iXPFor[iEID], 1);
				}
			}
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

			new amount = RoundFloat(healing * g_fHealExpMult);

			if(amount > 0 && lm_GetClientLevel(victim) < lm_GetLevelMax()) {
				lm_GiveXP(victim, amount, 0);
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

	if (iLifeHealPoints > 0 && client > 0 && client < MaxClients && IsClientInGame(client) && TF2_GetPlayerClass(client) != TFClass_Medic)
	{
		new amount = RoundFloat(iLifeHealPoints * g_fHealExpMult);
		if(amount > 0 && lm_GetClientLevel(client) < lm_GetLevelMax()) {
			lm_GiveXP(client, amount, 0);
		}
	}

	g_iHealPointCache[client] = iTotalHealPoints;
}
