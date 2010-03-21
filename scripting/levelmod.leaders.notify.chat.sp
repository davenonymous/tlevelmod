#include <sourcemod>
#include <sdktools>
#include <levelmod>
#include <levelmod.leaders>
#include <colors>

#pragma semicolon 1

#define PLUGIN_VERSION "0.1.0"

public Plugin:myinfo =
{
	name = "Leveling Mod, Leaders Chat Notifications",
	author = "Thrawn",
	description = "A plugin for Leveling Mod Leaders providing chat notifications to players when they take the lead etc",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

public OnPluginStart()
{
}

public OnConfigsExecuted()
{
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}


public OnClientPutInServer(client)
{
	if(lm_IsEnabled())
	{
	}
}

public OnClientDisconnect(client)
{
	if(lm_IsEnabled())
	{
	}
}

stock getPlayersOnRank(iLevel, tiedWith[], iExclude = 0) {
	new count = 0;
	for(new client=1; client <= MaxClients; client++) {
		if(!IsClientInGame(client))
			continue;

		if(client == iExclude)
			continue;

		if(lm_GetClientLevel(client) == iLevel) {
			tiedWith[count] = client;
			count++;
		}
	}

	return count;
}

public lm_OnClientChangedLead(iClient, lm_LeaderChange:change) {
	if(!IsClientInGame(iClient))
		return;

	new tiedWith[MAXPLAYERS+1];
	new count = getPlayersOnRank(lm_GetClientLevel(iClient), tiedWith);

	switch(change) {
		case lm_ALONEONLEVEL: {
		}

		case lm_TIEDONLEVEL: {
			decl String:sMessage[255];
			Format(sMessage, 255, "You are tied with ");

			for(new i = 0; i < count; i++) {
				if(IsClientInGame(tiedWith[i]))
					Format(sMessage, 255, "%s{teamcolor}%N{default}%s", sMessage, tiedWith[i], i+1 == count ? "" : ", ");
			}


			CPrintToChat(iClient, sMessage);
		}

		case lm_TAKENTHELEAD: {
			CPrintToChat(iClient, "You have taken the lead!");
		}

		case lm_LOSTTHELEAD: {
			CPrintToChat(iClient, "You have lost the lead!");
		}

		case lm_TIEDFORTHELEAD: {
			decl String:sMessage[255];
			Format(sMessage, 255, "You are tied for the lead with ");

			for(new i = 0; i < count; i++) {
				if(IsClientInGame(tiedWith[i]))
					Format(sMessage, 255, "%s{teamcolor}%N{default}%s", sMessage, tiedWith[i], i+1 == count ? "" : ", ");
			}

			CPrintToChat(iClient, sMessage);
		}
	}
}