#include <sourcemod>
#include <sdktools>
#include <levelmod>
#include <tf2_stocks>
#include <colors>

#pragma semicolon 1
#define PLUGIN_VERSION "0.1.0"

new Handle:g_hCvarHealExpMult;
new Handle:g_hCvarXPForChargeKill;
new Handle:g_hCvarXPForCapping;
new Handle:g_hCvarXPForWinning;
new Handle:g_hCvarXPForFlagPickup;
new Handle:g_hCvarXPForFlagCap;

new g_iHealPointCache[MAXPLAYERS+1];
new g_iHealsOff;
new Float:g_fHealExpMult;

new g_iXPForChargeKill;
new g_iXPForCapping;
new g_iXPForWinning;
new g_iXPForFlagPickup;
new g_iXPForFlagCap;

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

	HookConVarChange(g_hCvarHealExpMult, Cvar_Changed);
	HookConVarChange(g_hCvarXPForChargeKill, Cvar_Changed);
	HookConVarChange(g_hCvarXPForCapping, Cvar_Changed);
	HookConVarChange(g_hCvarXPForWinning, Cvar_Changed);
	HookConVarChange(g_hCvarXPForFlagPickup, Cvar_Changed);
	HookConVarChange(g_hCvarXPForFlagCap, Cvar_Changed);

	HookEvent("player_death", Event_Player_Death);
	HookEvent("medic_death", Event_Medic_Death);
	HookEvent("teamplay_point_captured", Event_Captured, EventHookMode_Post);
	HookEvent("teamplay_flag_event", Event_Flag, EventHookMode_Post);
	HookEvent("teamplay_round_win", Event_RoundWin);
}

public OnConfigsExecuted()
{
	g_fHealExpMult = GetConVarFloat(g_hCvarHealExpMult);
	g_iXPForChargeKill = GetConVarInt(g_hCvarXPForChargeKill);
	g_iXPForCapping = GetConVarInt(g_hCvarXPForCapping);
	g_iXPForWinning = GetConVarInt(g_hCvarXPForWinning);
	g_iXPForFlagPickup = GetConVarInt(g_hCvarXPForFlagPickup);
	g_iXPForFlagCap = GetConVarInt(g_hCvarXPForFlagCap);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

//////////////////////////
//E V E N T   H O O K S //
//////////////////////////
public Event_Flag(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new iClient = GetEventInt(event, "player");
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
