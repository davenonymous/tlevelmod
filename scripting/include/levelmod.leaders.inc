#if defined _levelmod_lc_included_
	#endinput
#endif
#define _levelmod_lc_included_

#define LEVELMODLEADERCHANGEAPIVERSION 1

enum lm_LeaderChange {
	lm_TAKENTHELEAD,
	lm_LOSTTHELEAD,
	lm_TIEDFORTHELEAD
};

//native lm_GetLeaders();

native lm_IsClientLeader(iClient);
native lm_GetPlayersOnLevel(iLevel);

forward lm_OnClientChangedLeadEx(iClient, lm_LeaderChange:change, tiedWith[], count);
forward lm_OnClientChangedLead(iClient, lm_LeaderChange:change);