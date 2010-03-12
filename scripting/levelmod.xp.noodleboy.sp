#include <sourcemod>
#include <sdktools>
#include <levelmod>
#include <colors>

new Handle:g_hCvarExpOnkill;
new g_iExpOnKill;

public OnPluginStart()
{
	g_hCvarExpOnkill = CreateConVar("sm_lm_exp_onkill", "15", "Experience to gain on kill", FCVAR_PLUGIN, true, 1.0);

	HookConVarChange(g_hCvarExpOnkill, Cvar_Changed);

	HookEvent("player_death", Event_Player_Death);
	HookEvent("player_hurt", Event_Player_Hurt);
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
			new attackerLevel = lm_GetClientLevel(attacker);
			if(attackerLevel < lm_GetLevelMax())
				lm_GiveXP(attacker, g_iExpOnKill, 1);

			// FIXME: Cvar for death message
			CPrintToChatEx(victim, attacker, "You were killed by {teamcolor}%N {green}(Level %i)", attacker, attackerLevel);
		}
	}
}


public Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled())
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

		new rawDamage = (GetEventInt(event, "damageamount"));
		new damage = (rawDamage / 10);

		if(damage > 0 && IsPlayerAlive(attacker) && attacker != victim && lm_GetClientLevel(attacker) < lm_GetLevelMax())
		{
			if(damage > lm_GetClientXPNext(attacker))
				damage = lm_GetClientXPNext(attacker);

			lm_GiveXP(attacker, damage, 0);
		}
	}
}