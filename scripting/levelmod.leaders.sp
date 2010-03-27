#include <sourcemod>
#include <sdktools>
#include <levelmod>
#include <levelmod.leaders>

#pragma semicolon 1

#define PLUGIN_VERSION "0.1.1"

new Handle:g_hForwardLeadChange;

new g_iLeaderCount = 0;

enum states {
	ISLEADER,
	ISTIED
}

new bool:g_bClientState[MAXPLAYERS+1][states];

public Plugin:myinfo =
{
	name = "Leveling Mod, Leaders Core",
	author = "Thrawn",
	description = "A plugin for Leveling Mod providing score-leader natives. This is a core using another core.",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

public OnPluginStart()
{
	// V E R S I O N    C V A R //
	CreateConVar("sm_tlevelmod_leaders_version", PLUGIN_VERSION, "Version of the plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hForwardLeadChange = CreateGlobalForward("lm_OnClientChangedLead", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
}


stock collectStates() {
	new iLevelHighest = lm_GetLevelHighest();
	new leaders[MAXPLAYERS+1];
	g_iLeaderCount = getPlayersOnRank(iLevelHighest, leaders);

	for(new client=1; client <= MaxClients; client++) {
		new iLevel = lm_GetClientLevel(client);

		if(iLevel == iLevelHighest) {
			//is a leader
			if(g_iLeaderCount > 1)
				isTiedNow(client);
			else
				isLeaderNow(client);
		} else {
			maybeWasLeader(client);
		}
	}

}

stock maybeWasLeader(client) {
	if(g_bClientState[client][ISLEADER]) {
		StateChange(client, ISLEADER, false);
		StateChange(client, ISTIED, false);
		g_bClientState[client][ISLEADER] = false;
		g_bClientState[client][ISTIED] = false;
	}
}

stock isLeaderNow(client) {
	if(!g_bClientState[client][ISLEADER]) {
		StateChange(client, ISLEADER, true);
		g_bClientState[client][ISLEADER] = true;
		g_bClientState[client][ISTIED] = false;
	}
}

stock isTiedNow(client) {
	if(!g_bClientState[client][ISTIED]) {
		StateChange(client, ISTIED, true);
		g_bClientState[client][ISTIED] = true;
	}
}

stock StateChange(client, states:change, bool:yesno) {
	if(IsClientInGame(client)) {
		if(change == ISLEADER) {
			if(yesno) {
				Forward_LeadChange(client, lm_TAKENTHELEAD);
				LogMessage("%N has taken the lead", client);
			} else {
				Forward_LeadChange(client, lm_LOSTTHELEAD);
				LogMessage("%N has lost the lead", client);
			}
		}

		if(change == ISTIED) {
			if(yesno) {
				Forward_LeadChange(client, lm_TIEDFORTHELEAD);
				LogMessage("%N is tied for the lead", client);
			}
		}
	}
}

public lm_OnClientLevelUp(iClient,iLevel, iAmount, bool:isLevelDown) {
	collectStates();
}

stock getPlayersOnRank(iLevel, tiedWith[], iExclude = 0) {
	new count = 0;
	for(new client=1; client <= MaxClients; client++) {
		if(client == iExclude)
			continue;

		if(lm_GetClientLevel(client) == iLevel) {
			tiedWith[count] = client;
			count++;
		}
	}

	return count;
}


//public lm_OnClientChangedLead(iClient, lm_LeaderChange:change, const String:tiedWith[]) {};
public Forward_LeadChange(iClient, lm_LeaderChange:change)
{
	Call_StartForward(g_hForwardLeadChange);
	Call_PushCell(iClient);
	Call_PushCell(change);
	Call_Finish();
}