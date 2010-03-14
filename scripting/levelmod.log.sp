#include <sourcemod>
#include <sdktools>
#include <levelmod>
#include <loghelper>

#pragma semicolon 1
#define PLUGIN_VERSION "0.1.0"

////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo =
{
	name = "Leveling Mod, List+Log",
	author = "Thrawn",
	description = "A plugin for Leveling Mod, shows a list to admins and logs every levelup.",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

public OnMapStart()
{
	GetTeams();
}

public lm_OnClientLevelUp(client, level, amount)
{
	LogPlayerEvent(client, "triggered", "levelmod_levelup");
}