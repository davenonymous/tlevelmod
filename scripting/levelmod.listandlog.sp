#include <sourcemod>
#include <sdktools>
#include <levelmod>
#include <loghelper>

public OnPluginStart()
{
	RegAdminCmd("sm_lm_showlist", Command_ShowList, ADMFLAG_KICK);
}

public OnMapStart()
{
	GetTeams();
}

public lm_OnClientLevelUp(client, level)
{
	LogPlayerEvent(client, "triggered", "levelmod_levelup");
}

public Action:Command_ShowList(client, args)
{
	for(new i = 1; i <= MaxClients; i++) {
		if(IsClientConnected(i) && IsClientInGame(i)) {
			new xp = lm_GetClientXP(i);
			new xpNext = lm_GetClientXPNext(i);
			new level = lm_GetClientLevel(i);
			new base = lm_GetXpRequiredForLevel(level);

			ReplyToCommand(client, "%N is Level %i (XP: %i/%i | %i/%i)", i, level, xp, xpNext, xp - base,xpNext - base);
		}
	}

	return Plugin_Handled;
}