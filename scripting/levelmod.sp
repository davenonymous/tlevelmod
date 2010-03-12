//////////////////////////
//G L O B A L  S T U F F//
//////////////////////////
#include <sourcemod>
#include <sdktools>
#include <colors>

#pragma semicolon 1

#define SOUND_LEVELUP "ui/item_acquired.wav"

#define PLUGIN_VERSION "0.1.1"

new playerLevel[MAXPLAYERS+1];
new playerExp[MAXPLAYERS+1];
new playerExpMax[MAXPLAYERS+1];
new Handle:levelHUD[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:hudLevel;
new Handle:hudEXP;
new Handle:hudPlus1;
new Handle:hudPlus2;
new Handle:hudLevelUp;

new Handle:cvar_enable;
new Handle:cvar_level_default;
new Handle:cvar_level_max;
new Handle:cvar_exp_default;
new Handle:cvar_exp_levelup;
new Handle:cvar_exp_onkill;
new Handle:g_hForwardLevelUp;

////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo = 
{
	name = "[TF2] Cosmetic Leveling Mod",
	author = "noodleboy347",
	description = "A cosmetic RPG-like level mod",
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
	cvar_enable = CreateConVar("clm_enabled", "1", "Enables the plugin");
	cvar_level_default = CreateConVar("clm_level_default", "1", "Default level for players when they join");
	cvar_level_max = CreateConVar("clm_level_max", "100", "Maxmimum level players can reach");
	cvar_exp_default = CreateConVar("clm_exp_default", "40", "Default max experience for players when they join");
	cvar_exp_levelup = CreateConVar("clm_exp_levelup", "20", "Experience increase on level up");
	cvar_exp_onkill = CreateConVar("clm_exp_onkill", "15", "Experience to gain on kill");
	CreateConVar("clm_version", PLUGIN_VERSION, "Version of the plugin");
	
	// F O R W A R D S //
	g_hForwardLevelUp = CreateGlobalForward("lm_OnClientLevelUp", ET_Ignore, Param_Cell, Param_Cell);
	
	// C O M M A N D S //
	RegAdminCmd("clm_setmylevel", Command_SetLevel, ADMFLAG_ROOT);
	
	// H O O K S //
	HookEvent("player_hurt", Player_Hurt);
	HookEvent("player_death", Player_Death);
	
	// O T H E R //
	hudLevel = CreateHudSynchronizer();
	hudEXP = CreateHudSynchronizer();
	hudPlus1 = CreateHudSynchronizer();
	hudPlus2 = CreateHudSynchronizer();
	hudLevelUp = CreateHudSynchronizer();
	PrecacheSound(SOUND_LEVELUP, true);
	AutoExecConfig(true, "cosmetic-leveling-mod");

}
//////////////////////////////////
//C L I E N T  C O N N E C T E D//
//////////////////////////////////
public OnClientPostAdminCheck(client)
{
	if(GetConVarInt(cvar_enable))
	{
		playerLevel[client] = GetConVarInt(cvar_level_default);
		playerExp[client] = 0;
		playerExpMax[client] = GetConVarInt(cvar_exp_default);
		levelHUD[client] = CreateTimer(5.0, DrawHud, client);
		CreateTimer(60.0, Advertisement, client);
	}
}

/////////////////////////////
//A D V E R T I S E M E N T//
/////////////////////////////
public Action:Advertisement(Handle:timer, any:client)
{
	if(GetConVarInt(cvar_enable))
	CPrintToChat(client, "This server is running {blue}Cosmetic Leveling Mod{default}.");
}

///////////////////
//D R A W  H U D //
///////////////////
public Action:DrawHud(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if(playerExp[client] >= playerExpMax[client] && playerLevel[client] < GetConVarInt(cvar_level_max))
		{
			LevelUp(client, playerLevel[client] + 1);
		}
		SetHudTextParams(0.14, 0.90, 2.0, 100, 200, 255, 150);
		ShowSyncHudText(client, hudLevel, "Level: %i", playerLevel[client]);
		SetHudTextParams(0.14, 0.93, 2.0, 255, 200, 100, 150);
		if(playerLevel[client] >= GetConVarInt(cvar_level_max))
		{
			ShowSyncHudText(client, hudEXP, "EXP: MAX LEVEL REACHED", playerExp[client], playerExpMax[client]);
		}
		else
		{
			ShowSyncHudText(client, hudEXP, "EXP: %i/%i", playerExp[client], playerExpMax[client]);
		}
	}
	levelHUD[client] = CreateTimer(2.0, DrawHud, client);
	return Plugin_Handled;
}

////////////////////////
//D A M A G E  D O N E//
////////////////////////
public Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(cvar_enable))
	{
		new damaged = GetClientOfUserId(GetEventInt(event, "userid"));
		new client = GetClientOfUserId(GetEventInt(event, "attacker"));
		new rawDamage = (GetEventInt(event, "damageamount"));
		new damage = (rawDamage / 10);
		if(!(damage <= 0) && IsPlayerAlive(client) && (client != damaged) && playerLevel[client] < GetConVarInt(cvar_level_max))
		{
			if(damage >= playerExpMax[client])
			{
				damage = playerExpMax[client];
			}
			playerExp[client] = playerExp[client] + damage;
			SetHudTextParams(0.24, 0.93, 1.0, 255, 100, 100, 150, 1);
			ShowSyncHudText(client, hudPlus1, "+%i", damage);
		}
	}
}

////////////////////////////
//P L A Y E R  K I L L E D//
////////////////////////////
public Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(cvar_enable))
	{
		new client = GetClientOfUserId(GetEventInt(event, "attacker"));
		new killed = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client != killed && GetConVarInt(cvar_exp_onkill) >= 1 && playerLevel[client] < GetConVarInt(cvar_level_max))
		{
			new expBoost = GetConVarInt(cvar_exp_onkill);
			playerExp[client] = playerExp[client] + expBoost;
			SetHudTextParams(0.28, 0.93, 1.0, 255, 100, 100, 150, 1);
			ShowSyncHudText(client, hudPlus2, "+%i", expBoost);
		}
		CPrintToChatEx(killed, client, "You were killed by {teamcolor}%N {green}(Level %i)", client, playerLevel[client]);
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
	LevelUp(client, newLevel);
	return Plugin_Handled;
}

///////////////////////
//D I S C O N N E C T//
///////////////////////
public OnClientDisconnect(client)
{
	if(GetConVarInt(cvar_enable))
	{
		CloseHandle(Handle:levelHUD[client]);
	}
}

///////////////
//S T O C K S//
///////////////
stock LevelUp(client, level)
{
	playerLevel[client] = level;
	playerExp[client] = playerExp[client] - playerExpMax[client];
	SetHudTextParams(0.22, 0.90, 5.0, 100, 255, 100, 150, 2);
	ShowSyncHudText(client, hudLevelUp, "LEVEL UP!");
	playerExpMax[client] = playerExpMax[client] + GetConVarInt(cvar_exp_levelup);
	if(level == GetConVarInt(cvar_level_max))
	{
		playerExpMax[client] = 0;
	}
	CPrintToChatAllEx(client, "{teamcolor}%N{default} has grown to: {green}Level %i", client, playerLevel[client]);
	EmitSoundToClient(client, SOUND_LEVELUP);
	
	Forward_LevelUp(client, level);
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
	CreateNative("lm_GetClientXPMax", Native_GetClientXPMax);
	
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
	
	return playerLevel[iClient];
}


//lm_GetClientXP(iClient);
public Native_GetClientXP(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	
	return playerExp[iClient];
}

//lm_SetClientLevel(iClient, iLevel);
public Native_SetClientLevel(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	new iLevel = GetNativeCell(2);
	
	LevelUp(iClient, iLevel);
}


//lm_SetClientXP(iClient, iXP);
public Native_SetClientXP(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	new iXP = GetNativeCell(1);
	
	playerExp[iClient] = iXP;
	
	if(playerExp[iClient] >= playerExpMax[iClient] && playerLevel[iClient] < GetConVarInt(cvar_level_max))
	{
		LevelUp(iClient, playerLevel[iClient] + 1);
	}
}

//lm_GetClientXPMax(iClient);
public Native_GetClientXPMax(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	
	return playerExpMax[iClient];
}


public Forward_LevelUp(client, level)
{
	Call_StartForward(g_hForwardLevelUp);    
	Call_PushCell(client);
	Call_PushCell(level);
	Call_Finish();	
}