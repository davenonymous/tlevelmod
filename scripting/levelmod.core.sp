#include <sourcemod>
#include <sdktools>
#include <colors>

#pragma semicolon 1

#define SOUND_LEVELUP "ui/item_acquired.wav"
#define PLUGIN_VERSION "0.1.2"

new g_playerLevel[MAXPLAYERS+1];
new g_playerExp[MAXPLAYERS+1];
new g_playerExpNext[MAXPLAYERS+1];
new Handle:g_hLevelHUD[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_hHudLevel;
new Handle:g_hHudExp;
new Handle:g_hHudPlus1;
new Handle:g_hHudPlus2;
new Handle:g_hHudLevelUp;

new Handle:g_hCvarEnable;
new Handle:g_hCvarLevel_default;
new Handle:g_hCvarLevel_max;
new Handle:g_hForwardLevelUp;
new Handle:g_hCvarExp_ReqBase;
new Handle:g_hCvarExp_ReqMulti;

new bool:g_bEnabled;
new g_iLevelDefault;
new g_iLevelMax;
new g_iExpReqBase;
new Float:g_fExpReqMult;

////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo =
{
	name = "[TF2] Leveling Core",
	author = "noodleboy347, Thrawn",
	description = "A RPG-like leveling core to be used by other plugins",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

//////////////////////////
//P L U G I N  S T A R T//
//////////////////////////
public OnPluginStart()
{
	// V E R S I O N    C V A R //
	CreateConVar("sm_lm_version", PLUGIN_VERSION, "Version of the plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	// G A M E  C H E C K //
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	if(!(StrEqual(game, "tf")))
	{
		SetFailState("This plugin is not for %s", game);
	}

	// C O N V A R S //
	g_hCvarEnable = CreateConVar("sm_lm_enabled", "1", "Enables the plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarLevel_default = CreateConVar("sm_lm_level_default", "1", "Default level for players when they join", FCVAR_PLUGIN, true, 1.0);
	g_hCvarLevel_max = CreateConVar("sm_lm_level_max", "100", "Maxmimum level players can reach", FCVAR_PLUGIN, true, 1.0, true, 250.0);

	g_hCvarExp_ReqBase = CreateConVar("sm_lm_exp_reqbase", "500", "Experience required for the first level", FCVAR_PLUGIN, true, 1.0);
	g_hCvarExp_ReqMulti = CreateConVar("sm_lm_exp_reqmulti", "1.4", "Experience required grows by this multiplier every level", FCVAR_PLUGIN, true, 1.0);

	HookConVarChange(g_hCvarEnable, Cvar_Changed);
	HookConVarChange(g_hCvarLevel_default, Cvar_Changed);
	HookConVarChange(g_hCvarLevel_max, Cvar_Changed);

	HookConVarChange(g_hCvarExp_ReqBase, Cvar_Changed);
	HookConVarChange(g_hCvarExp_ReqMulti, Cvar_Changed);

	// F O R W A R D S //
	g_hForwardLevelUp = CreateGlobalForward("lm_OnClientLevelUp", ET_Ignore, Param_Cell, Param_Cell);

	// C O M M A N D S //
	RegAdminCmd("sm_lm_setmylevel", Command_SetLevel, ADMFLAG_ROOT);

	// O T H E R //
	g_hHudLevel = CreateHudSynchronizer();
	g_hHudExp = CreateHudSynchronizer();
	g_hHudPlus1 = CreateHudSynchronizer();
	g_hHudPlus2 = CreateHudSynchronizer();
	g_hHudLevelUp = CreateHudSynchronizer();

	PrecacheSound(SOUND_LEVELUP, true);

	AutoExecConfig(true, "plugins.levelmod");
}

public OnConfigsExecuted()
{
	g_bEnabled = GetConVarBool(g_hCvarEnable);
	g_iLevelDefault = GetConVarInt(g_hCvarLevel_default);
	g_iLevelMax = GetConVarInt(g_hCvarLevel_max);

	g_iExpReqBase = GetConVarInt(g_hCvarExp_ReqBase);
	g_fExpReqMult = GetConVarFloat(g_hCvarExp_ReqMulti);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

//////////////////////////////////
//C L I E N T  C O N N E C T E D//
//////////////////////////////////
public OnClientPostAdminCheck(client)
{
	if(g_bEnabled)
	{
		g_playerLevel[client] = g_iLevelDefault;
		g_playerExp[client] = 0;
		g_playerExpNext[client] = g_iExpReqBase;

		g_hLevelHUD[client] = CreateTimer(5.0, Timer_DrawHud, client);
		CreateTimer(60.0, Timer_Advertisement, client);
	}
}

/////////////////////////////
//A D V E R T I S E M E N T//
/////////////////////////////
public Action:Timer_Advertisement(Handle:timer, any:client)
{
	if(g_bEnabled)
		CPrintToChat(client, "This server is running {blue}Leveling Mod{default}.");
}

///////////////////
//D R A W  H U D //
///////////////////
public Action:Timer_DrawHud(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		CheckAndLevelUp(client);

		SetHudTextParams(0.14, 0.90, 2.0, 100, 200, 255, 150);
		ShowSyncHudText(client, g_hHudLevel, "Level: %i", g_playerLevel[client]);

		SetHudTextParams(0.14, 0.93, 2.0, 255, 200, 100, 150);

		if(g_playerLevel[client] >= g_iLevelMax)
		{
			ShowSyncHudText(client, g_hHudExp, "EXP: MAX LEVEL REACHED", g_playerExp[client], g_playerExpNext[client]);
		}
		else
		{
			new iCurrent = g_playerExp[client] - GetMinXPForLevel(g_playerLevel[client]);
			new iNext = GetMinXPForLevel(g_playerLevel[client]+1) - GetMinXPForLevel(g_playerLevel[client]);

			ShowSyncHudText(client, g_hHudExp, "EXP: %i/%i", iCurrent, iNext);
		}
	}

	g_hLevelHUD[client] = CreateTimer(2.0, Timer_DrawHud, client);
	return Plugin_Handled;
}

stock LevelUpMessage(client) {
	SetHudTextParams(0.22, 0.90, 5.0, 100, 255, 100, 150, 2);
	ShowSyncHudText(client, g_hHudLevelUp, "LEVEL UP!");
}

////////////////////
//C O M M A N D S //
////////////////////
public Action:Command_SetLevel(client, args)
{
	new String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));

	new newLevel = StringToInt(arg1);

	SetLevel(client, newLevel);
	return Plugin_Handled;
}

///////////////////////
//D I S C O N N E C T//
///////////////////////
public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		CloseHandle(Handle:g_hLevelHUD[client]);
	}
}

///////////////
//S T O C K S//
///////////////
stock CheckAndLevelUp(client) {
	new bool:bGrown = false;
	while(g_playerExp[client] >= g_playerExpNext[client] && g_playerLevel[client] < g_iLevelMax)
	{
		g_playerLevel[client]++;
		g_playerExpNext[client] = GetMinXPForLevel(g_playerLevel[client]);

		bGrown = true;
		if(g_playerLevel[client] == g_iLevelMax) {
			g_playerExpNext[client] = -1;
			break;
		}
	}

	if(bGrown) {
		LevelUpMessage(client);

		CPrintToChatAllEx(client, "{teamcolor}%N{default} has grown to: {green}Level %i", client, g_playerLevel[client]);
		EmitSoundToClient(client, SOUND_LEVELUP);

		Forward_LevelUp(client, g_playerLevel[client]);
	}
}

stock AddLevels(client, levels = 1)
{
	if(g_playerLevel[client] >= g_iLevelMax)
		return;

	if(g_playerLevel[client] + levels >= g_iLevelMax) {
		g_playerExp[client] = GetMinXPForLevel(g_iLevelMax);
	} else {
		g_playerExp[client] = GetMinXPForLevel(g_playerLevel[client] + levels);
	}
}

stock SetLevel(client, level) {
	g_playerLevel[client] = level;
	g_playerExp[client] = GetMinXPForLevel(level);
	g_playerExpNext[client] = GetMinXPForLevel(level+1);
}

//Calculate the xp one would need for a certain level
stock GetMinXPForLevel(level) {
	return g_iExpReqBase * (RoundFloat(g_fExpReqMult^Float:(level-1)));
}

stock GiveXP(client, amount, Handle:channel)
{
	g_playerExp[client] += amount;

	SetHudTextParams(0.28, 0.93, 1.0, 255, 100, 100, 150, 1);
	ShowSyncHudText(client, channel, "+%i", amount);
}

/////////////////
//N A T I V E S//
/////////////////
#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
	public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
#else
	public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
#endif
{
	RegPluginLibrary("levelmod");

	CreateNative("lm_GetClientXP", Native_GetClientXP);
	CreateNative("lm_SetClientXP", Native_SetClientXP);
	CreateNative("lm_GetClientLevel", Native_GetClientLevel);
	CreateNative("lm_SetClientLevel", Native_SetClientLevel);
	CreateNative("lm_GetClientXPNext", Native_GetClientXPNext);
	CreateNative("lm_GetRequiredXpForLevel", Native_GetClientXPForLevel);
	CreateNative("lm_IsEnabled", Native_GetEnabled);
	CreateNative("lm_GetLevelMax", Native_GetLevelMax);
	CreateNative("lm_GiveXP", Native_GiveXP);



	#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
		return APLRes_Success;
	#else
		return true;
	#endif
}

//lm_GetClientLevel(iClient);
public Native_GetClientLevel(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);

	return g_playerLevel[iClient];
}


//lm_GetClientXP(iClient);
public Native_GetClientXP(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);

	return g_playerExp[iClient];
}

//lm_SetClientLevel(iClient, iLevel);
public Native_SetClientLevel(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	new iLevel = GetNativeCell(2);

	SetLevel(iClient, iLevel);
}


//lm_SetClientXP(iClient, iXP);
public Native_SetClientXP(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	new iXP = GetNativeCell(2);

	g_playerExp[iClient] = iXP;
}

//lm_GiveXP(iClient, iXP, iChannel);
public Native_GiveXP(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	new iXP = GetNativeCell(2);
	new iChannel = GetNativeCell(3);

	if(iChannel == 0)
		GiveXP(iClient, iXP, g_hHudPlus1);
	else
		GiveXP(iClient, iXP, g_hHudPlus2);
}

//lm_GetClientXPNext(iClient);
public Native_GetClientXPNext(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);

	return g_playerExpNext[iClient];
}

//lm_GetLevelMax();
public Native_GetLevelMax(Handle:hPlugin, iNumParams)
{
	return g_iLevelMax;
}

//lm_IsEnabled();
public Native_GetEnabled(Handle:hPlugin, iNumParams)
{
	return g_bEnabled;
}

//lm_GetClientXPForLevel(iLevel);
public Native_GetClientXPForLevel(Handle:hPlugin, iNumParams)
{
	new iLevel = GetNativeCell(1);

	return GetMinXPForLevel(iLevel);
}

//public lm_OnClientLevelUp(iClient, iLevel) {};
public Forward_LevelUp(client, level)
{
	Call_StartForward(g_hForwardLevelUp);
	Call_PushCell(client);
	Call_PushCell(level);
	Call_Finish();
}
