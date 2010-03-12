#include <sourcemod>
#include <sdktools>
#include <levelmod>

#pragma semicolon 1

#define PLUGIN_VERSION "0.1.0"

new Handle:g_hLevelHUD[MAXPLAYERS+1] = INVALID_HANDLE;

new Handle:g_hHudLevel;
new Handle:g_hHudExp;
new Handle:g_hHudPlus1;
new Handle:g_hHudPlus2;
new Handle:g_hHudLevelUp;

////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo =
{
	name = "Leveling Mod, TF2 Interface",
	author = "noodleboy347, Thrawn",
	description = "A interface fitting to tf2",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

//////////////////////////
//P L U G I N  S T A R T//
//////////////////////////
public OnPluginStart()
{
	// O T H E R //
	g_hHudLevel = CreateHudSynchronizer();
	g_hHudExp = CreateHudSynchronizer();
	g_hHudPlus1 = CreateHudSynchronizer();
	g_hHudPlus2 = CreateHudSynchronizer();
	g_hHudLevelUp = CreateHudSynchronizer();
}

//////////////////////////////////
//C L I E N T  C O N N E C T E D//
//////////////////////////////////
public OnClientPostAdminCheck(client)
{
	if(lm_IsEnabled())
	{
		g_hLevelHUD[client] = CreateTimer(5.0, Timer_DrawHud, client);
	}
}

///////////////////
//D R A W  H U D //
///////////////////
public Action:Timer_DrawHud(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		new iPlayerLevel = lm_GetClientLevel(client);

		SetHudTextParams(0.14, 0.90, 2.0, 100, 200, 255, 150);
		ShowSyncHudText(client, g_hHudLevel, "Level: %i", iPlayerLevel);

		SetHudTextParams(0.14, 0.93, 2.0, 255, 200, 100, 150);

		if(iPlayerLevel >= lm_GetLevelMax())
		{
			ShowSyncHudText(client, g_hHudExp, "EXP: MAX LEVEL REACHED", lm_GetClientXP(client), lm_GetClientXPNext(client));
		}
		else
		{
			new iRequired = lm_GetXpRequiredForLevel(iPlayerLevel+1) - lm_GetXpRequiredForLevel(iPlayerLevel);
			new iAchieved = lm_GetClientXP(client) - lm_GetXpRequiredForLevel(iPlayerLevel);

			ShowSyncHudText(client, g_hHudExp, "EXP: %i/%i", iAchieved, iRequired);
		}
	}

	g_hLevelHUD[client] = CreateTimer(1.9, Timer_DrawHud, client);
	return Plugin_Handled;
}

///////////////////////
//D I S C O N N E C T//
///////////////////////
public OnClientDisconnect(client)
{
	if(g_hLevelHUD[client]!=INVALID_HANDLE)
		CloseHandle(g_hLevelHUD[client]);
}

public lm_OnClientLevelUp(client, level)
{
	SetHudTextParams(0.22, 0.90, 5.0, 100, 255, 100, 150, 2);
	ShowSyncHudText(client, g_hHudLevelUp, "LEVEL UP!");
}

public lm_OnClientExperience(client, amount, iChannel)
{
	if(iChannel == 0) {
		SetHudTextParams(0.24, 0.93, 1.0, 255, 100, 100, 150, 1);
		ShowSyncHudText(client, g_hHudPlus1, "+%i", amount);
	} else {
		SetHudTextParams(0.28, 0.93, 1.0, 255, 100, 100, 150, 1);
		ShowSyncHudText(client, g_hHudPlus2, "+%i", amount);
	}
}