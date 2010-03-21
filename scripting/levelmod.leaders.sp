#include <sourcemod>
#include <sdktools>
#include <levelmod>
#include <levelmod.leaders>

#pragma semicolon 1

#define PLUGIN_VERSION "0.1.0"

new Handle:g_hForwardLeadChange;

new g_Leaders[MAXPLAYERS+1];
new g_iLeaderLevel = 0;
new g_LeaderCount = 0;

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




public lm_OnClientLevelUp(iClient,iLevel, iAmount, bool:isLevelDown) {
	new iLeaderLevel = g_iLeaderLevel;
	if(isLevelDown) {
		//<iClient> lost <iAmount> level(s) and is now at level <iLevel>
		new iPreviousLevel = iLevel + iAmount;

		//everyone on the previous level is tied with each other  **2**
		//	unless there is only one, he could be the new leader. **1**
		//if no one is on the previous level, the new leaders are
		//  the ones on the second highest level
		new iClientsCntPreviousLevel = 0;
		new iClientsOnPreviousLevel[MAXPLAYERS+1];
		new iClientsCntSameLevel = 0;
		new iClientsOnSameLevel[MAXPLAYERS+1];
		new iClientsCntSecondHighestLevel = 0;
		new iClientsOnSecondHighestLevel[MAXPLAYERS+1];


		new iSecondHighestLeaderLevel = 0;
		for(new client=1; client <= MaxClients; client++) {
			new iHisLevel = lm_GetClientLevel(client);

			if(iLeaderLevel < iHisLevel)
				iLeaderLevel = iHisLevel;

			if(iHisLevel > iSecondHighestLeaderLevel && iHisLevel != g_iLeaderLevel) {
				iSecondHighestLeaderLevel = iHisLevel;
				for(new i=0; i < iClientsCntSecondHighestLevel; i++)
					iClientsOnSecondHighestLevel[i] = 0;

				iClientsCntSecondHighestLevel = 0;
			}

			if(iHisLevel == iSecondHighestLeaderLevel) {
				//client is on the second highest level
				iClientsOnSecondHighestLevel[iClientsCntSecondHighestLevel] = client;
				iClientsCntSecondHighestLevel++;
			}

			if(iHisLevel == iPreviousLevel) {
				//client is on the previous level
				iClientsOnPreviousLevel[iClientsCntPreviousLevel] = client;
				iClientsCntPreviousLevel++;
			}

			if(iHisLevel == iLevel) {
				//client is on the same level
				iClientsOnSameLevel[iClientsCntSameLevel] = client;
				iClientsCntSameLevel++;
			}
		}


		if(iPreviousLevel == g_iLeaderLevel) {
			if(iClientsCntPreviousLevel > 0) {
				Forward_LeadChange(iClient, lm_LOSTTHELEAD, iClientsOnPreviousLevel, iClientsCntPreviousLevel);

				if(iClientsCntSameLevel > 1) {
					for(new i = 0; i < iClientsCntSameLevel; i++) {
						Forward_LeadChange(iClientsOnSameLevel[i], lm_TIEDONLEVEL, iClientsOnSameLevel, iClientsCntSameLevel);
					}
				} else {
					Forward_LeadChange(iClient, lm_ALONEONLEVEL, iClientsOnSameLevel, iClientsCntSameLevel);
				}
			}

			if(iClientsCntPreviousLevel == 1) {
				//**1** iClientsOnPreviousLevel[0] has taken the lead
				Forward_LeadChange(iClientsOnPreviousLevel[0], lm_TAKENTHELEAD, iClientsOnPreviousLevel, iClientsCntPreviousLevel);
				iLeaderLevel = iPreviousLevel;
			}

			if(iClientsCntPreviousLevel > 1) {
				//**2** iClientsOnPreviousLevel[] are tied for the lead
				iLeaderLevel = iPreviousLevel;
				for(new i = 0; i < iClientsCntPreviousLevel; i++) {
					Forward_LeadChange(iClientsOnPreviousLevel[i], lm_TIEDFORTHELEAD, iClientsOnPreviousLevel, iClientsCntPreviousLevel);
				}
			}

			if(iClientsCntPreviousLevel == 0) {
				if(iClientsCntSecondHighestLevel > 0) {
					Forward_LeadChange(iClient, lm_LOSTTHELEAD, iClientsOnSecondHighestLevel, iClientsCntSecondHighestLevel);

					if(iClientsCntSameLevel > 1) {
						for(new i = 0; i < iClientsCntSameLevel; i++) {
							Forward_LeadChange(iClientsOnSameLevel[i], lm_TIEDONLEVEL, iClientsOnSameLevel, iClientsCntSameLevel);
						}
					} else {
						Forward_LeadChange(iClient, lm_ALONEONLEVEL, iClientsOnSameLevel, iClientsCntSameLevel);
					}
				}


				if(iClientsCntSecondHighestLevel == 1) {
					//**3** iClientsOnSecondHighestLevel[0] has taken the lead
					Forward_LeadChange(iClientsOnSecondHighestLevel[0], lm_TAKENTHELEAD, iClientsOnSecondHighestLevel, iClientsCntSecondHighestLevel);
					iLeaderLevel = iLevel;
				}

				if(iClientsCntSecondHighestLevel > 1) {
					//**4** iClientsOnSecondHighestLevel[] are tied for the lead
					iLeaderLevel = iLevel;
					for(new i = 0; i < iClientsCntSecondHighestLevel; i++) {
						Forward_LeadChange(iClientsOnSecondHighestLevel[i], lm_TIEDFORTHELEAD, iClientsOnSecondHighestLevel, iClientsCntSecondHighestLevel);
					}
				}
			}
		} else {
			//what if previous level was not the leader level
			if(iClientsCntSameLevel > 1) {
				for(new i = 0; i < iClientsCntSameLevel; i++) {
					Forward_LeadChange(iClientsOnSameLevel[i], lm_TIEDONLEVEL, iClientsOnSameLevel, iClientsCntSameLevel);
				}
			} else {
				Forward_LeadChange(iClient, lm_ALONEONLEVEL, iClientsOnSameLevel, iClientsCntSameLevel);
			}

			if(iClientsCntPreviousLevel > 1) {
				for(new i = 0; i < iClientsCntPreviousLevel; i++) {
					Forward_LeadChange(iClientsOnPreviousLevel[i], lm_TIEDONLEVEL, iClientsOnPreviousLevel, iClientsCntPreviousLevel);
				}
			} else {
				Forward_LeadChange(iClient, lm_ALONEONLEVEL, iClientsOnPreviousLevel, iClientsCntPreviousLevel);
			}
		}
	} else {
		//<iClient> gained <iAmount> level(s) and is now at level <iLevel>

		new iPreviousLevel = iLevel - iAmount;

		//everyone on the previous level is tied with each other  **2**
		//	unless there is only one, he could be the new leader. **1**
		//if no one is on the previous level, the new leaders are
		//  the ones on the second highest level
		new iClientsCntPreviousLevel = 0;
		new iClientsOnPreviousLevel[MAXPLAYERS+1];
		new iClientsCntSameLevel = 0;
		new iClientsOnSameLevel[MAXPLAYERS+1];
		new iClientsCntSecondHighestLevel = 0;
		new iClientsOnSecondHighestLevel[MAXPLAYERS+1];

		new iSecondHighestLeaderLevel = 0;
		for(new client=1; client <= MaxClients; client++) {
			new iHisLevel = lm_GetClientLevel(client);

			if(iLeaderLevel < iHisLevel)
				iLeaderLevel = iHisLevel;

			if(iHisLevel > iSecondHighestLeaderLevel && iHisLevel != g_iLeaderLevel) {
				iSecondHighestLeaderLevel = iHisLevel;
				for(new i=0; i < iClientsCntSecondHighestLevel; i++)
					iClientsOnSecondHighestLevel[i] = 0;

				iClientsCntSecondHighestLevel = 0;
			}

			if(iHisLevel == iSecondHighestLeaderLevel) {
				//client is on the second highest level
				iClientsOnSecondHighestLevel[iClientsCntSecondHighestLevel] = client;
				iClientsCntSecondHighestLevel++;
			}

			if(iHisLevel == iPreviousLevel) {
				//client is on the previous level
				iClientsOnPreviousLevel[iClientsCntPreviousLevel] = client;
				iClientsCntPreviousLevel++;
			}

			if(iHisLevel == iLevel) {
				//client is on the same level
				iClientsOnSameLevel[iClientsCntSameLevel] = client;
				iClientsCntSameLevel++;
			}
		}

		if(iPreviousLevel == g_iLeaderLevel) {
			//was a leader
			if(iClientsCntPreviousLevel > 0) {
				for(new i = 0; i < iClientsCntPreviousLevel; i++) {
					Forward_LeadChange(iClientsOnPreviousLevel[i], lm_LOSTTHELEAD, iClientsOnSameLevel, iClientsCntSameLevel);
				}

				if(iClientsCntPreviousLevel > 1) {
					for(new i = 0; i < iClientsCntPreviousLevel; i++) {
						Forward_LeadChange(iClientsOnPreviousLevel[i], lm_TIEDONLEVEL, iClientsOnPreviousLevel, iClientsCntPreviousLevel);
					}
				} else {
					Forward_LeadChange(iClient, lm_ALONEONLEVEL, iClientsOnPreviousLevel, iClientsCntPreviousLevel);
				}
			}
		} else {
			if(iLevel == iLeaderLevel) {
				//FIXME: second heighest

				if(iClientsCntSameLevel > 1) {
					for(new i = 0; i < iClientsCntSameLevel; i++) {
						Forward_LeadChange(iClientsOnSameLevel[i], lm_TIEDFORTHELEAD, iClientsOnSameLevel, iClientsCntSameLevel);
					}
				} else {
					Forward_LeadChange(iClient, lm_TAKENTHELEAD, iClientsOnSameLevel, iClientsCntSameLevel);
					iLeaderLevel = iLevel;
				}

				if(iClientsCntPreviousLevel == 1) {
					//**1** iClientsOnPreviousLevel[0] has taken the lead
					Forward_LeadChange(iClientsOnPreviousLevel[0], lm_ALONEONLEVEL, iClientsOnPreviousLevel, iClientsCntPreviousLevel);
				}

				if(iClientsCntPreviousLevel > 1) {
					//**2** iClientsOnPreviousLevel[] are tied for the lead
					for(new i = 0; i < iClientsCntPreviousLevel; i++) {
						Forward_LeadChange(iClientsOnPreviousLevel[i], lm_TIEDONLEVEL, iClientsOnPreviousLevel, iClientsCntPreviousLevel);
					}
				}

				if(iClientsCntPreviousLevel == 0) {
				}
			} else {
				//was and is no leader
				if(iClientsCntSameLevel > 1) {
					for(new i = 0; i < iClientsCntSameLevel; i++) {
						Forward_LeadChange(iClientsOnSameLevel[i], lm_TIEDONLEVEL, iClientsOnSameLevel, iClientsCntSameLevel);
					}
				} else {
					Forward_LeadChange(iClient, lm_ALONEONLEVEL, iClientsOnSameLevel, iClientsCntSameLevel);
					iLeaderLevel = iLevel;
				}

				if(iClientsCntPreviousLevel == 1) {
					//**1** iClientsOnPreviousLevel[0] has taken the lead
					Forward_LeadChange(iClientsOnPreviousLevel[0], lm_ALONEONLEVEL, iClientsOnPreviousLevel, iClientsCntPreviousLevel);
				}

				if(iClientsCntPreviousLevel > 1) {
					//**2** iClientsOnPreviousLevel[] are tied for the lead
					for(new i = 0; i < iClientsCntPreviousLevel; i++) {
						Forward_LeadChange(iClientsOnPreviousLevel[i], lm_TIEDONLEVEL, iClientsOnPreviousLevel, iClientsCntPreviousLevel);
					}
				}
			}
		}
	}

	g_iLeaderLevel = iLeaderLevel;
	LogMessage("The leader level is: %i", iLeaderLevel);
	g_LeaderCount = getPlayersOnRank(iLeaderLevel, g_Leaders);
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
public Forward_LeadChange(iClient, lm_LeaderChange:change, tiedWith[], size)
{
	Call_StartForward(g_hForwardLeadChange);
	Call_PushCell(iClient);
	Call_PushCell(change);
	Call_Finish();
}