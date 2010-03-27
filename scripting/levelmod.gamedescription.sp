#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION 		"1.0.0.0"

public Plugin:myinfo =
{
	name = "Leveling Mod, SetGameDescription",
	author = "Thrawn",
	description = "A plugin for Levelmod, sets game description. Uses SDKHooks.",
	version = PLUGIN_VERSION,
};

public Action:OnGetGameDescription(String:gameDesc[64]) {
	gameDesc = "tLevelMod";
	return Plugin_Changed;
}