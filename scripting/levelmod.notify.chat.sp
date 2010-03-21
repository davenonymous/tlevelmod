#include <sourcemod>
#include <sdktools>
#include <levelmod>
#include <colors>

#pragma semicolon 1

#define PLUGIN_VERSION "0.1.0"

new Handle:g_hCvarAnnounce;

new Handle:g_hTimerAdvertisement[MAXPLAYERS+1] = INVALID_HANDLE;
new bool:g_bAnnounce;

public Plugin:myinfo =
{
	name = "Leveling Mod, Chat Notifications",
	author = "Thrawn",
	description = "A plugin for Leveling Mod providing chat notifications to players when they level up",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

public OnPluginStart()
{
	g_hCvarAnnounce = CreateConVar("sm_lm_announce", "1", "Announce the mod to clients joining the server", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarAnnounce, Cvar_Changed);
}

public OnConfigsExecuted()
{
	g_bAnnounce = GetConVarBool(g_hCvarAnnounce);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}


public OnClientPutInServer(client)
{
	if(lm_IsEnabled())
	{
		if(g_bAnnounce)
			g_hTimerAdvertisement[client] = CreateTimer(60.0, Timer_Advertisement, client);
	}
}

public OnClientDisconnect(client)
{
	if(lm_IsEnabled())
	{
		if(g_hTimerAdvertisement[client]!=INVALID_HANDLE)
			CloseHandle(g_hTimerAdvertisement[client]);
	}
}

public Action:Timer_Advertisement(Handle:timer, any:client)
{
	g_hTimerAdvertisement[client] = INVALID_HANDLE;
	CPrintToChat(client, "This server is running {blue}Leveling Mod{default}.");
}


public lm_OnClientLevelUp(iClient,iLevel, iAmount, bool:isLevelDown) {
	if(isLevelDown)
		CPrintToChatAllEx(iClient, "{teamcolor}%N{default} has been set back to: {green}Level %i", iClient, iLevel);
	else
		CPrintToChatAllEx(iClient, "{teamcolor}%N{default} has grown to: {green}Level %i", iClient, iLevel);
}