//DC
#include <sourcemod>
#include <sdktools>
#include <levelmod>

#pragma semicolon 1

#define NO_ATTACH		0
#define ATTACH_NORMAL		1
#define ATTACH_HEAD		2

#define PLUGIN_VERSION "0.1.0"
#define SOUND_LEVELUP "level/gnomeftw.wav"

new Handle:g_hCvarLevelUpParticles;

new Handle:g_hLevelHUD[MAXPLAYERS+1] = INVALID_HANDLE;

new bool:g_bLevelUpParticles;

////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo =
{
	name = "Leveling Mod, L4D2 Interface, Panel based",
	author = "Thrawn",
	description = "Deprecated! A interface fitting to left4dead2",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

//////////////////////////
//P L U G I N  S T A R T//
//////////////////////////
public OnPluginStart()
{
	// G A M E  C H E C K //
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	if(!(StrEqual(game, "left4dead2")))
	{
		SetFailState("This plugin is not for %s", game);
	}

	g_hCvarLevelUpParticles = CreateConVar("sm_lm_levelupparticle", "1", "Enables level up particle effects", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	HookConVarChange(g_hCvarLevelUpParticles, Cvar_Changed);

	HookEvent("player_spawn",       Event_PlayerSpawn);
}

public OnMapStart() {
	PrecacheSound(SOUND_LEVELUP, true);
}

public OnConfigsExecuted()
{
	g_bLevelUpParticles = GetConVarBool(g_hCvarLevelUpParticles);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

//////////////////////////////////
//C L I E N T  C O N N E C T E D//
//////////////////////////////////
public OnClientPutInServer(client)
{
	if(lm_IsEnabled())
	{
		g_hLevelHUD[client] = CreateTimer(3.0, Timer_DrawHud, client);
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

	if(lm_IsEnabled() && g_hLevelHUD[iClient] == INVALID_HANDLE)
	{
		g_hLevelHUD[iClient] = CreateTimer(0.5, Timer_DrawHud, iClient);
	}
}

public Action:Timer_DrawHud(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		new Handle:HUDPanel = CreatePanel();
		decl String:TempString[256];

		new iPlayerLevel = lm_GetClientLevel(client);
		Format(TempString, sizeof(TempString), "Level: %i", iPlayerLevel);

		SetPanelTitle(HUDPanel, TempString);

		if(iPlayerLevel >= lm_GetLevelMax())
		{
			DrawPanelItem(HUDPanel, "XP: MAX LEVEL REACHED");
		}
		else
		{
			new iRequired = lm_GetXpRequiredForLevel(iPlayerLevel+1) - lm_GetXpRequiredForLevel(iPlayerLevel);
			new iAchieved = lm_GetClientXP(client) - lm_GetXpRequiredForLevel(iPlayerLevel);

			Format(TempString, sizeof(TempString), "XP: %i/%i", iAchieved, iRequired);
			DrawPanelItem(HUDPanel, TempString);
		}

		SendPanelToClient(HUDPanel, client, PanelHandler, 3);
		CloseHandle(HUDPanel);

		g_hLevelHUD[client] = CreateTimer(3.0, Timer_DrawHud, client);
	}
}

public PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	//nothing to do
}

stock ShowMiniMessage(client, String:TempString[]) {
	if(IsClientInGame(client))
	{
		ClearTimer(g_hLevelHUD[client]);

		new Handle:HUDPanel = CreatePanel();
		SetPanelTitle(HUDPanel, TempString);
		SendPanelToClient(HUDPanel, client, PanelHandler, 1);
		CloseHandle(HUDPanel);

		g_hLevelHUD[client] = CreateTimer(1.0, Timer_DrawHud, client);
	}
}

public lm_OnClientLevelUp(client, level, amount, bool:isLevelDown)
{
	if(isLevelDown) {
		ShowMiniMessage(client, "LEVEL LOST");
	} else {
		ShowMiniMessage(client, "LEVEL UP");
		EmitSoundToClient(client, SOUND_LEVELUP);

		if(g_bLevelUpParticles && false) {
			//achieved
			new Float:pos[3];
			GetClientAbsOrigin(client, pos);

			CreateParticle("achieved", 3.0, client, ATTACH_HEAD, 0.0, 0.0, 4.0);
		}
	}
}

public lm_OnClientExperience(client, amount, iChannel)
{
	if(client > 0) {
		decl String:TempString[256];
		Format(TempString, sizeof(TempString), "+%i", amount);

		ShowMiniMessage(client, TempString);
	}
}

stock ClearTimer(&Handle:timer)
{
	if( timer != INVALID_HANDLE )
	{
		KillTimer( timer );
	}
	timer = INVALID_HANDLE;
}

// Particles ------------------------------------------------------------------
// Particle Attachment Types  -------------------------------------------------

/* CreateParticle()
**
** Creates a particle at an entity's position. Attach determines the attachment
** type (0 = not attached, 1 = normal attachment, 2 = head attachment). Allows
** offsets from the entity's position. Returns the handle of the timer that
** deletes the particle (should you wish to trigger it early).
** ------------------------------------------------------------------------- */


stock Handle:CreateParticle(String:type[], Float:time, entity, attach=NO_ATTACH, Float:xOffs=0.0, Float:yOffs=0.0, Float:zOffs=0.0)
{
	new particle = CreateEntityByName("info_particle_system");

	// Check if it was created correctly
	if (IsValidEdict(particle)) {
		decl Float:pos[3];

		// Get position of entity
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);

		// Add position offsets
		pos[0] += xOffs;
		pos[1] += yOffs;
		pos[2] += zOffs;

		// Teleport, set up
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", type);

		if (attach != NO_ATTACH) {
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", entity, particle, 0);

			if (attach == ATTACH_HEAD) {
				SetVariantString("head");
				AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
			}
		}

		// All entities in presents are given a targetname to make clean up easier
		DispatchKeyValue(particle, "targetname", "present");

		// Spawn and start
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");

		return CreateTimer(time, DeleteParticle, particle);
	} else {
		LogError("Presents (CreateParticle): Could not create info_particle_system");
	}

	return INVALID_HANDLE;
}

/* DeleteParticle()
**
** Deletes a particle.
** ------------------------------------------------------------------------- */
public Action:DeleteParticle(Handle:timer, any:particle)
{
	if (IsValidEdict(particle)) {
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));

		if (StrEqual(classname, "info_particle_system", false)) {
			RemoveEdict(particle);
		}
	}
}