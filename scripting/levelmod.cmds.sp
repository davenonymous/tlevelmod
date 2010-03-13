#include <sourcemod>
#include <sdktools>
#include <levelmod>

#pragma semicolon 1

#define PLUGIN_VERSION "0.1.0"


////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo =
{
	name = "Leveling Mod, AdminCommands",
	author = "Thrawn",
	description = "Simple commands to set xp, level etc",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

//////////////////////////
//P L U G I N  S T A R T//
//////////////////////////
public OnPluginStart()
{
	// C O M M A N D S //
	RegAdminCmd("sm_lm_setlevel", Command_SetLevel, ADMFLAG_ROOT);
	RegAdminCmd("sm_lm_givexp", Command_GiveXP, ADMFLAG_ROOT);

}

////////////////////
//C O M M A N D S //
////////////////////
public Action:Command_SetLevel(client, args)
{
	if(!lm_IsEnabled()) {
		ReplyToCommand(client, "[SM] Plugin tLevelMod is disabled");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_lm_setlevel <OPT:#id|name> <level>");
		return Plugin_Handled;
	}

	if (args == 1) {
		new String:arg1[64];
		GetCmdArg(1, arg1, sizeof(arg1));

		new newLevel = StringToInt(arg1);

		lm_SetClientLevel(client, newLevel);
	} else if (args == 2) {
		decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));

		// Process the targets
		decl String:strTargetName[MAX_TARGET_LENGTH];
		decl TargetList[MAXPLAYERS], TargetCount;
		decl bool:TargetTranslate;

		if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
											   strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0)
		{
			ReplyToTargetError(client, TargetCount);
			return Plugin_Handled;
		}

		new String:arg2[64];
		GetCmdArg(2, arg2, sizeof(arg2));

		new newLevel = StringToInt(arg2);

		// Apply to all targets
		for (new i = 0; i < TargetCount; i++)
		{
			if (!IsClientConnected(TargetList[i])) continue;
			if (!IsClientInGame(TargetList[i]))    continue;

			lm_SetClientLevel(TargetList[i], newLevel);
		}
	}

	return Plugin_Handled;
}

public Action:Command_GiveXP(client, args)
{
	if(!lm_IsEnabled()) {
		ReplyToCommand(client, "[SM] Plugin tLevelMod is disabled");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_lm_givexp <OPT:#id|name> <amount>");
		return Plugin_Handled;
	}

	if (args == 1) {
		new String:arg1[64];
		GetCmdArg(1, arg1, sizeof(arg1));

		new xpToAdd = StringToInt(arg1);

		lm_GiveXP(client, xpToAdd, 0);
	} else if (args == 2) {
		decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));

		// Process the targets
		decl String:strTargetName[MAX_TARGET_LENGTH];
		decl TargetList[MAXPLAYERS], TargetCount;
		decl bool:TargetTranslate;

		if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED,
											   strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0)
		{
			ReplyToTargetError(client, TargetCount);
			return Plugin_Handled;
		}

		new String:arg2[64];
		GetCmdArg(2, arg2, sizeof(arg2));

		new xpToAdd = StringToInt(arg2);

		// Apply to all targets
		for (new i = 0; i < TargetCount; i++)
		{
			if (!IsClientConnected(TargetList[i])) continue;
			if (!IsClientInGame(TargetList[i]))    continue;

			lm_GiveXP(TargetList[i], xpToAdd, 0);
		}
	}

	return Plugin_Handled;
}