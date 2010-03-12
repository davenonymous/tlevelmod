#include <sourcemod>
#include <sdktools>
#include <colors>

#pragma semicolon 1

#define SOUND_LEVELUP "ui/item_acquired.wav"
#define PLUGIN_VERSION "0.1.2"
#define MAXLEVELS 101
#define FMAXLEVELS 100.0

new g_playerLevel[MAXPLAYERS+1];
new g_playerExp[MAXPLAYERS+1];
new g_playerExpNext[MAXPLAYERS+1];

new Handle:g_hTimerAdvertisement[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_hTimerCheckLevelUp[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_hCvarEnable;
new Handle:g_hCvarAnnounce;
new Handle:g_hCvarLevel_default;
new Handle:g_hCvarLevel_max;
new Handle:g_hForwardLevelUp;
new Handle:g_hForwardXPGained;
new Handle:g_hCvarExp_ReqBase;
new Handle:g_hCvarExp_ReqMulti;


new bool:g_bEnabled;
new bool:g_bAnnounce;

new g_iXPForLevel[MAXLEVELS];
new g_iLevelDefault;
new g_iLevelMax;
new g_iExpReqBase;
new Float:g_fExpReqMult;

////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo =
{
	name = "Leveling Core",
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
	g_hCvarAnnounce = CreateConVar("sm_lm_announce", "1", "Announce the mod to clients joining the server", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	g_hCvarLevel_default = CreateConVar("sm_lm_level_default", "0", "Default level for players when they join", FCVAR_PLUGIN, true, 1.0);
	g_hCvarLevel_max = CreateConVar("sm_lm_level_max", "100", "Maxmimum level players can reach", FCVAR_PLUGIN, true, 1.0, true, FMAXLEVELS);

	g_hCvarExp_ReqBase = CreateConVar("sm_lm_exp_reqbase", "100", "Experience required for the first level", FCVAR_PLUGIN, true, 1.0);
	g_hCvarExp_ReqMulti = CreateConVar("sm_lm_exp_reqmulti", "1.0", "Experience required grows by this multiplier every level", FCVAR_PLUGIN, true, 1.0);

	HookConVarChange(g_hCvarEnable, Cvar_Changed);
	HookConVarChange(g_hCvarAnnounce, Cvar_Changed);

	HookConVarChange(g_hCvarLevel_default, Cvar_Changed);
	HookConVarChange(g_hCvarLevel_max, Cvar_Changed);

	HookConVarChange(g_hCvarExp_ReqBase, Cvar_Changed);
	HookConVarChange(g_hCvarExp_ReqMulti, Cvar_Changed);

	// F O R W A R D S //
	g_hForwardLevelUp = CreateGlobalForward("lm_OnClientLevelUp", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardXPGained = CreateGlobalForward("lm_OnClientExperience", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

	// C O M M A N D S //
	RegAdminCmd("sm_lm_setmylevel", Command_SetLevel, ADMFLAG_ROOT);
	RegAdminCmd("sm_lm_givexp", Command_GiveXP, ADMFLAG_ROOT);

	PrecacheSound(SOUND_LEVELUP, true);
}

public OnConfigsExecuted()
{
	g_bEnabled = GetConVarBool(g_hCvarEnable);
	g_bAnnounce = GetConVarBool(g_hCvarAnnounce);

	g_iLevelDefault = GetConVarInt(g_hCvarLevel_default);
	g_iLevelMax = GetConVarInt(g_hCvarLevel_max);

	g_iExpReqBase = GetConVarInt(g_hCvarExp_ReqBase);
	g_fExpReqMult = GetConVarFloat(g_hCvarExp_ReqMulti);

	FillXPForLevel();
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

stock FillXPForLevel() {
	g_iXPForLevel[0] = 0;
	g_iXPForLevel[1] = g_iExpReqBase;

	for(new level=2; level < MAXLEVELS; level++) {
		g_iXPForLevel[level] = g_iXPForLevel[level-1] + RoundFloat(g_iExpReqBase*level*g_fExpReqMult);
	}
}
//////////////////////////////////
//C L I E N T  C O N N E C T E D//
//////////////////////////////////
public OnClientPostAdminCheck(client)
{
	if(g_bEnabled)
	{
		g_playerLevel[client] = g_iLevelDefault;
		g_playerExp[client] = GetMinXPForLevel(g_iLevelDefault);
		g_playerExpNext[client] = GetMinXPForLevel(g_iLevelDefault+1);

		g_hTimerCheckLevelUp[client] = CreateTimer(1.9, Timer_CheckLevelUp, client);

		if(g_bAnnounce)
			g_hTimerAdvertisement[client] = CreateTimer(60.0, Timer_Advertisement, client);
	}
}

///////////////
//T I M E R S//
///////////////
public Action:Timer_Advertisement(Handle:timer, any:client)
{
	g_hTimerAdvertisement[client] = INVALID_HANDLE;
	CPrintToChat(client, "This server is running {blue}Leveling Mod{default}.");
}

public Action:Timer_CheckLevelUp(Handle:timer, any:client)
{
	CheckAndLevelUp(client);
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

public Action:Command_GiveXP(client, args)
{
	new String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));

	new newLevel = StringToInt(arg1);

	GiveXP(client, newLevel, 0);

	return Plugin_Handled;
}


///////////////////////
//D I S C O N N E C T//
///////////////////////
public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		if(g_hTimerAdvertisement[client]!=INVALID_HANDLE)
			CloseHandle(g_hTimerAdvertisement[client]);

		if(g_hTimerCheckLevelUp[client]!=INVALID_HANDLE)
			CloseHandle(g_hTimerCheckLevelUp[client]);
	}
}

///////////////
//S T O C K S//
///////////////
stock CheckAndLevelUp(client) {
	new bool:bGrown = false;
	while(g_playerExp[client] >= g_playerExpNext[client] && g_playerLevel[client] < g_iLevelMax && g_playerExpNext[client] != -1)
	{
		LogMessage("Player is not level %i anymore, (%i >= %i)", g_playerLevel[client], g_playerExp[client], g_playerExpNext[client]);

		g_playerLevel[client]++;
		g_playerExpNext[client] = GetMinXPForLevel(g_playerLevel[client]+1);

		bGrown = true;
		if(g_playerLevel[client] == g_iLevelMax) {
			g_playerExpNext[client] = -1;
		}
	}

	if(bGrown) {
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
	g_playerExp[client] = GetMinXPForLevel(level);
	g_playerExpNext[client] = GetMinXPForLevel(level+1);
	g_playerLevel[client] = level;
}

stock GetMinXPForLevel(level) {
	return g_iXPForLevel[level];
}


stock GiveXP(client, amount, iChannel)
{
	g_playerExp[client] += amount;
	Forward_XPGained(client, amount, iChannel);
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
	CreateNative("lm_GiveXP", Native_GiveXP);

	CreateNative("lm_GetClientLevel", Native_GetClientLevel);
	CreateNative("lm_SetClientLevel", Native_SetClientLevel);
	CreateNative("lm_GiveLevel", Native_GiveLevel);

	CreateNative("lm_GetClientXPNext", Native_GetClientXPNext);
	CreateNative("lm_GetXpRequiredForLevel", Native_GetClientXPForLevel);
	CreateNative("lm_GetLevelMax", Native_GetLevelMax);

	CreateNative("lm_IsEnabled", Native_GetEnabled);





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

	GiveXP(iClient, iXP, iChannel);
}

//lm_GiveLevel(iClient, iLevels);
public Native_GiveLevel(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	new iLevels = GetNativeCell(2);

	AddLevels(iClient, iLevels);
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


//public lm_OnClientExperience(iClient, iXP, iChannel) {};
public Forward_XPGained(client, xp, channel)
{
	Call_StartForward(g_hForwardXPGained);
	Call_PushCell(client);
	Call_PushCell(xp);
	Call_PushCell(channel);
	Call_Finish();
}