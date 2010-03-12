//////////////////////////
//G L O B A L  S T U F F//
//////////////////////////
#include <sourcemod>
#include <sdktools>
#include <colors>

#pragma semicolon 1

#define SOUND_LEVELUP "ui/item_acquired.wav"

#define PLUGIN_VERSION "0.1.1"

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
new Handle:g_hCvarExp_levelup;
new Handle:g_hCvarExp_onkill;
new Handle:g_hForwardLevelUp;
new Handle:g_hCvarExp_ReqBase;
new Handle:g_hCvarExp_ReqMulti;

new bool:g_bEnabled;
new g_iLevelDefault;
new g_iLevelMax;
new g_iExpOnKill;
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
	url = "http://www.frozencubes.com"
}

//////////////////////////
//P L U G I N  S T A R T//
//////////////////////////
public OnPluginStart()
{
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

	g_hCvarExp_levelup = CreateConVar("sm_lm_exp_levelup", "20", "Experience increase on level up", FCVAR_PLUGIN, true, 1.0);
	g_hCvarExp_onkill = CreateConVar("sm_lm_exp_onkill", "15", "Experience to gain on kill", FCVAR_PLUGIN, true, 1.0);

	g_hCvarExp_ReqBase = CreateConVar("sm_lm_exp_reqbase", "500", "Experience required for the first level", FCVAR_PLUGIN, true, 1.0);
	g_hCvarExp_ReqMulti = CreateConVar("sm_lm_exp_reqmulti", "1.4", "Experience required grows by this multiplier every level", FCVAR_PLUGIN, true, 1.0);

	CreateConVar("sm_lm_version", PLUGIN_VERSION, "Version of the plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookConVarChange(g_hCvarEnable, Cvar_Changed);
	HookConVarChange(g_hCvarLevel_default, Cvar_Changed);
	HookConVarChange(g_hCvarLevel_max, Cvar_Changed);

	HookConVarChange(g_hCvarExp_levelup, Cvar_Changed);
	HookConVarChange(g_hCvarExp_onkill, Cvar_Changed);
	HookConVarChange(g_hCvarExp_ReqBase, Cvar_Changed);
	HookConVarChange(g_hCvarExp_ReqMulti, Cvar_Changed);

	// F O R W A R D S //
	g_hForwardLevelUp = CreateGlobalForward("lm_OnClientLevelUp", ET_Ignore, Param_Cell, Param_Cell);

	// C O M M A N D S //
	RegAdminCmd("sm_lm_setmylevel", Command_SetLevel, ADMFLAG_ROOT);

	// H O O K S //
	HookEvent("player_hurt", Event_Player_Hurt);
	HookEvent("player_death", Event_Player_Death);

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

	g_iExpOnKill = GetConVarInt(g_hCvarExp_onkill);

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
		CPrintToChat(client, "This server is running {blue}Cosmetic Leveling Mod{default}.");
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

////////////////////////
//D A M A G E  D O N E//
////////////////////////
public Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

		new rawDamage = (GetEventInt(event, "damageamount"));
		new damage = (rawDamage / 10);

		if(damage > 0 && IsPlayerAlive(attacker) && attacker != victim && g_playerLevel[attacker] < g_iLevelMax)
		{
			if(damage > g_playerExpNext[attacker])
				damage = g_playerExpNext[attacker];

			GiveXP(attacker, damage, g_hHudPlus1);
		}
	}
}

////////////////////////////
//P L A Y E R  K I L L E D//
////////////////////////////
public Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));

		if(attacker != victim)
		{
			if(g_playerLevel[attacker] < g_iLevelMax)
				GiveXP(attacker, g_iExpOnKill, g_hHudPlus2);

			// FIXME: Cvar for death message
			CPrintToChatEx(victim, attacker, "You were killed by {teamcolor}%N {green}(Level %i)", attacker, g_playerLevel[attacker]);
		}
	}
}

////////////////////
//S E T  L E V E L//
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
stock LevelUpMessage(client) {
	SetHudTextParams(0.22, 0.90, 5.0, 100, 255, 100, 150, 2);
	ShowSyncHudText(client, g_hHudLevelUp, "LEVEL UP!");
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
	new iXP = GetNativeCell(1);

	g_playerExp[iClient] = iXP;
}

//lm_GetClientXPNext(iClient);
public Native_GetClientXPNext(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);

	return g_playerExpNext[iClient];
}

public Native_GetClientXPForLevel(Handle:hPlugin, iNumParams)
{
	new iLevel = GetNativeCell(1);

	return GetMinXPForLevel(iLevel);
}



public Forward_LevelUp(client, level)
{
	Call_StartForward(g_hForwardLevelUp);
	Call_PushCell(client);
	Call_PushCell(level);
	Call_Finish();
}