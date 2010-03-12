#if defined _levelmod_included_
	#endinput
#endif
#define _levelmod_included_

#define LEVELMODAPIVERSION 1


/**
 * Get a clients level
 * 
 * @param iClient		The client to get the level from
 * @return			client level
 */
native lm_GetClientLevel(iClient);

/**
 * Sets a clients level
 *
 * @param iClient		The client to set the level to
 * @param iLevel		The value the level should be set to
 * @return			Nothing.
 */
native lm_SetClientLevel(iClient, iLevel);


/**
 * Get a clients xp
 *
 * @param iClient		The client to get the xp from
 * @return			client experience points
 */
native lm_GetClientXP(iClient);

/**
 * Sets a clients xp (automatically levels up accordingly)
 *
 * @param iClient		The client to set the xp to
 * @param iXP			The value the xp should be set to
 * @return			Nothing.
 */
native lm_SetClientXP(iClient, iXP);

/**
 * Get a clients next level up xp requirements
 *
 * @param iClient		The client to get the value from
 * @return			client next level up xp requirements
 */
native lm_GetClientXPNext(iClient);

/**
 * Gives Experience points to a client, automatically leveling up
 *
 * @param iClient		The client to give xp to
 * @param iXP			Amount of XP to give
 * @param iChannel		Hud-Channel to use (valid: 0 for primary, 1 for secondary)
 */
native lm_GiveXP(iClient, iXP, iChannel);


/**
 * Returns the amount of experience required to be a certain level 
 *
 * @param iLevel		Level to aquire
 * @return			amount of xp needed
 */
native lm_GetXpRequiredForLevel(iLevel);

/**
 * Returns the maximum level a player can get
 *
 * @return			the maximum level a player can get
 */
native lm_GetLevelMax();

/**
 * Returns True if levelmod is enabled
 *
 * @return			is levelmod enabled?
 */
native bool:lm_IsEnabled();

/**
 * Forwards when a client levels up
 *
 * @param iClient		The client who achieved a new level
 * @param iLevel		The level the client achieved
 */
forward lm_OnClientLevelUp(iClient,iLevel);