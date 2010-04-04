#include <sourcemod>
#include <levelmod>
#include <colors>

#pragma semicolon 1

#define PLUGIN_VERSION "0.1.0"
#define MAXRANKS 100

new Handle:g_hKv = INVALID_HANDLE;
new Handle:g_hCvarAnnounce;
new Handle:g_hCvarRankFile;
new bool:g_bAnnounceOnSpawn;

new Handle:g_hTimerAdvertisement[MAXPLAYERS+1] = INVALID_HANDLE;

new g_iRankCount = 0;
new String:g_sRanks[MAXRANKS][127];
new String:g_sRankFile[255];

public Plugin:myinfo =
{
	name = "Leveling Mod, Ranks",
	author = "Thrawn",
	description = "A plugin for Leveling Mod providing names/ranks for each level",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

public OnPluginStart()
{
	g_hCvarAnnounce = CreateConVar("sm_lm_ranks_announce", "1", "Announce their rank to clients on spawn", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarRankFile = CreateConVar("sm_lm_ranks_file", "configs/tlevelmod.ranks.cfg", "Get the ranks from this file", FCVAR_PLUGIN);

	HookConVarChange(g_hCvarAnnounce, Cvar_Changed);
	HookConVarChange(g_hCvarRankFile, Cvar_Changed);

	HookEvent("player_spawn", Event_Player_Spawn);
}

public OnConfigsExecuted()
{
	g_bAnnounceOnSpawn = GetConVarBool(g_hCvarAnnounce);
	GetConVarString(g_hCvarRankFile, g_sRankFile, sizeof(g_sRankFile));

	ReadRanks(g_sRankFile);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

public Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(lm_IsEnabled() && g_bAnnounceOnSpawn)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		if(client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			if(g_hTimerAdvertisement[client] == INVALID_HANDLE) {
				g_hTimerAdvertisement[client] = CreateTimer(5.0, Timer_Advertisement, client);
			}
		}
	}
}

public Action:Timer_Advertisement(Handle:timer, any:client)
{
	g_hTimerAdvertisement[client] = INVALID_HANDLE;

	CPrintToChat(client, "Your rank is: {olive}%s", g_sRanks[lm_GetClientLevel(client)]);
}

public lm_OnClientLevelUp(iClient,iLevel, iAmount, bool:isLevelDown) {
	LogMessage("levelup to %i (%s)", iLevel, g_sRanks[iLevel]);
	if(!StrEqual(g_sRanks[iLevel], "") && iLevel <= g_iRankCount) {
		CPrintToChat(iClient, "Your leveled up to rank: {olive}%s", g_sRanks[iLevel]);
	}
}

stock ReadRanks(const String:file[]) {
	if(g_hKv != INVALID_HANDLE)
		CloseHandle(g_hKv);

	g_hKv = CreateKeyValues("Spawns");

	decl String:path[256];
	BuildPath(Path_SM, path, sizeof(path), file);

	new cnt = 0;
	if(FileExists(path)) {
		FileToKeyValues(g_hKv, path);

		decl String:sRank[127];
		KvGotoFirstSubKey(g_hKv);

		do {
			new String:sCnt[4];
			IntToString(cnt, sCnt, sizeof(sCnt));
			KvGetString(g_hKv, sCnt, sRank, sizeof(sRank));

			g_sRanks[cnt] = sRank;
			LogMessage("Rank %i is %s", cnt, sRank);
			cnt++;
		} while(!StrEqual(sRank,""));
	} else {
		LogError("File Not Found: %s", path);
	}

	g_iRankCount = cnt;
}