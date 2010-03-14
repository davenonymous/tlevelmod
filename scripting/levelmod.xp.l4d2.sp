#include <sourcemod>
#include <sdktools>
#include <levelmod>
#include <colors>

#pragma semicolon 1
#define PLUGIN_VERSION "0.1.0"

new Handle:g_hCvarXPForWinning;
new Handle:g_hCvarXPForSpecialKill;
new Handle:g_hCvarXPForZombieKill;
new Handle:g_hCvarXPForSaving;
new Handle:g_hCvarXPForTankKill;

new g_iXPForSpecialKill;
new g_iXPForZombieKill;
new g_iXPForTankKill;
new g_iXPForSaving;
new g_iXPForWinning;

////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo =
{
	name = "Leveling Mod, XP, L4D2 Specific",
	author = "Thrawn",
	description = "A plugin for Leveling Mod, specific to l4d2, giving Experience for killing zombies, special infected etc.",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

//////////////////////////
//P L U G I N  S T A R T//
//////////////////////////
public OnPluginStart()
{
	g_hCvarXPForWinning = CreateConVar("sm_lm_exp_winning", "20", "Amount of xp given for winning a round", FCVAR_PLUGIN, true, 0.0);
	g_hCvarXPForSpecialKill = CreateConVar("sm_lm_exp_specialkill", "10", "Amount of xp given for killing a special zombie", FCVAR_PLUGIN, true, 0.0);
	g_hCvarXPForZombieKill = CreateConVar("sm_lm_exp_zombiekill", "2", "Amount of xp given for killing a common zombie", FCVAR_PLUGIN, true, 0.0);
	g_hCvarXPForSaving = CreateConVar("sm_lm_exp_saving", "20", "Amount of xp given for saving an incapped player", FCVAR_PLUGIN, true, 0.0);
	g_hCvarXPForTankKill = CreateConVar("sm_lm_exp_specialkill", "30", "Amount of xp given for killing a tank", FCVAR_PLUGIN, true, 0.0);

	HookEvent("tank_killed", Event_TankKill);
	HookEvent("charger_killed", Event_SpecialKill);
	HookEvent("spitter_killed", Event_SpecialKill);
	HookEvent("jockey_killed", Event_SpecialKill);
	HookEvent("charger_killed", Event_SpecialKill);
	HookEvent("infected_death", Event_ZombieKill);

	HookEvent("revive_success", Event_Revive);

	HookEvent("versus_match_finished", Event_RoundWin);
	HookEvent("scavenge_match_finished", Event_RoundWin);
}

public OnConfigsExecuted()
{
	g_iXPForWinning = GetConVarInt(g_hCvarXPForWinning);
	g_iXPForTankKill = GetConVarInt(g_hCvarXPForTankKill);
	g_iXPForSpecialKill = GetConVarInt(g_hCvarXPForSpecialKill);
	g_iXPForZombieKill = GetConVarInt(g_hCvarXPForZombieKill);
	g_iXPForSaving = GetConVarInt(g_hCvarXPForSaving);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

//////////////////////////
//E V E N T   H O O K S //
//////////////////////////
public Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new team = GetEventInt(event, "winners");

		for (new client = 1; client <= MaxClients; client++) {
			if(GetClientTeam(client) == team) {
				lm_GiveXP(client, g_iXPForWinning, 1);
			}
		}
	}
}

public Event_Revive(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "userid"));

		if(attacker > 0)
		{
			lm_GiveXP(attacker, g_iXPForSaving, 1);
		}
	}
}

public Event_SpecialKill(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

		if(attacker > 0)
		{
			lm_GiveXP(attacker, g_iXPForSpecialKill, 1);
		}
	}
}

public Event_TankKill(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

		if(attacker > 0)
		{
			lm_GiveXP(attacker, g_iXPForTankKill, 1);
		}
	}
}

public Event_ZombieKill(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

		if(attacker > 0)
		{
			if(GetEventBool(event, "headshot"))
				lm_GiveXP(attacker, g_iXPForZombieKill, 1);
			else
				lm_GiveXP(attacker, g_iXPForZombieKill, 1);
		}
	}
}
