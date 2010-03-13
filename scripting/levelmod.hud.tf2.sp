#include <sourcemod>
#include <sdktools>
#include <levelmod>

#pragma semicolon 1

#define PLUGIN_VERSION "0.1.0"
#define SOUND_LEVELUP "ui/item_acquired.wav"

new Handle:g_hCvarLevelUpParticles;

new Handle:g_hLevelHUD[MAXPLAYERS+1] = INVALID_HANDLE;

new Handle:g_hHudLevel;
new Handle:g_hHudExp;
new Handle:g_hHudPlus1;
new Handle:g_hHudPlus2;
new Handle:g_hHudLevelUp;

new bool:g_bLevelUpParticles;

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
	g_hCvarLevelUpParticles = CreateConVar("sm_lm_levelupparticle", "1", "Enables level up particle effects", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	HookConVarChange(g_hCvarLevelUpParticles, Cvar_Changed);

	// O T H E R //
	g_hHudLevel = CreateHudSynchronizer();
	g_hHudExp = CreateHudSynchronizer();
	g_hHudPlus1 = CreateHudSynchronizer();
	g_hHudPlus2 = CreateHudSynchronizer();
	g_hHudLevelUp = CreateHudSynchronizer();
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
			ShowSyncHudText(client, g_hHudExp, "XP: MAX LEVEL REACHED", lm_GetClientXP(client), lm_GetClientXPNext(client));
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

	EmitSoundToClient(client, SOUND_LEVELUP);

	if(g_bLevelUpParticles) {
		//achieved
		new Float:pos[3];
		GetClientAbsOrigin(client, pos);

		TE_Particle("achieved", pos,NULL_VECTOR,NULL_VECTOR,client);
	}
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


stock TE_Particle(String:Name[],
            Float:origin[3]=NULL_VECTOR,
            Float:start[3]=NULL_VECTOR,
            Float:angles[3]=NULL_VECTOR,
            entindex=-1,
            attachtype=-1,
            attachpoint=-1,
            bool:resetParticles=true,
            Float:delay=0.0)
{
    // find string table
    new tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx==INVALID_STRING_TABLE)
    {
        LogError("Could not find string table: ParticleEffectNames");
        return;
    }

    // find particle index
    new String:tmp[256];
    new count = GetStringTableNumStrings(tblidx);
    new stridx = INVALID_STRING_INDEX;
    new i;
    for (i=0; i<count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false))
        {
            stridx = i;
            break;
        }
    }
    if (stridx==INVALID_STRING_INDEX)
    {
        LogError("Could not find particle: %s", Name);
        return;
    }

    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);
    if (entindex!=-1)
    {
        TE_WriteNum("entindex", entindex);
    }
    if (attachtype!=-1)
    {
        TE_WriteNum("m_iAttachType", attachtype);
    }
    if (attachpoint!=-1)
    {
        TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    }
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);
    TE_SendToAll(delay);
}