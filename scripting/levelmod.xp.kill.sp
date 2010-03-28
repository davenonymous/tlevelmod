#include <sourcemod>
#include <sdktools>
#include <levelmod>
#include <colors>

#pragma semicolon 1
#define PLUGIN_VERSION "0.1.0"


new Handle:g_hCvarExpOnkill;
new g_iExpOnKill;

////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo =
{
	name = "Leveling Mod, XP, Kill",
	author = "Thrawn",
	description = "A plugin for Leveling Mod, giving Experience for killing.",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

//////////////////////////
//P L U G I N  S T A R T//
//////////////////////////
public OnPluginStart()
{
	// V E R S I O N    C V A R //
	CreateConVar("sm_lm_xp_noodleboy_version", PLUGIN_VERSION, "Version of the plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hCvarExpOnkill = CreateConVar("sm_lm_exp_onkill", "10", "Experience to gain on kill", FCVAR_PLUGIN, true, 1.0);


	HookConVarChange(g_hCvarExpOnkill, Cvar_Changed);

	HookEvent("player_death", Event_Player_Death);
}

public OnConfigsExecuted()
{
	g_iExpOnKill = GetConVarInt(g_hCvarExpOnkill);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}


public Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));

		if(attacker != victim)
		{
			lm_GiveXP(attacker, g_iExpOnKill, 1);
		}
	}
}
