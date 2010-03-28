#include <sourcemod>
#include <sdktools>
#include <levelmod>
#include <colors>
#include <sdkhooks>

#pragma semicolon 1
#define PLUGIN_VERSION "0.1.0"

new Handle:g_hCvarExpMult;
new Handle:g_hCvarMaxXP;

new g_iMaxXP;
new Float:g_fExpMult;

////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo =
{
	name = "Leveling Mod, XP, Damage",
	author = "Thrawn",
	description = "A plugin for Leveling Mod, giving Experience for dealing damage (uses SDKHooks).",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

//////////////////////////
//P L U G I N  S T A R T//
//////////////////////////
public OnPluginStart()
{
	g_hCvarExpMult = CreateConVar("sm_lm_exp_dmgmulti", "0.1", "Damage multiplied by this value will be given as xp", FCVAR_PLUGIN, true, 0.0);
	g_hCvarMaxXP = CreateConVar("sm_lm_exp_maxbydmg", "10", "Maximum amount of xp given through damage, 0 = unlimited", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hCvarExpMult, Cvar_Changed);
}

public OnConfigsExecuted()
{
	g_fExpMult = GetConVarFloat(g_hCvarExpMult);
	g_iMaxXP = GetConVarInt(g_hCvarMaxXP);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(lm_IsEnabled())
	{
		new amount = RoundFloat(damage * g_fExpMult);

		if(amount > 0 && IsClientInGame(attacker) && attacker != victim && lm_GetClientLevel(attacker) < lm_GetLevelMax())
		{
			if(amount > g_iMaxXP)
				amount = g_iMaxXP;

			lm_GiveXP(attacker, amount, 0);
		}
	}

	return Plugin_Continue;
}