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
native lm_GetClientXPMax(iClient);





forward lm_OnClientLevelUp(iClient,iLevel);