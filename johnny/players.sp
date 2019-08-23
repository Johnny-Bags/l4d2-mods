#if !defined JOHNNY_PLAYERS_SP
#define JOHNNY_PLAYERS_SP

#pragma semicolon 1

#include "cvars.sp"

/*
 * remove a client's weapon from a specific slot
 */
stock bool J_DisarmWeaponSlot(int client, int slot)
{
	int ent = GetPlayerWeaponSlot(client, slot);
	
	if (ent >= 0)
	{
		RemovePlayerItem(client, ent);
		RemoveEdict(ent);
		
		return true;
	}
	
	return false;
}

/*
 * remove a client's primary weapon
 */
stock bool J_DisarmPrimary(int client)
{
	return J_DisarmWeaponSlot(client, 0);
}

/*
 * remove a client's secondary weapon
 */
stock bool J_DisarmSecondary(int client)
{
	return J_DisarmWeaponSlot(client, 1);
}

/*
 * give client an item
 */
stock void J_GivePlayerItem(int client, const char[] item)
{
	int flags = GetCommandFlags("give");	
	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	
	FakeClientCommand(client, "give %s", item);
	
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

/*
 * give client adrenaline
 */
stock bool J_GivePlayerAdrenaline(int client)
{
	if (GetPlayerWeaponSlot(client, 4) >= 0) return false;
	
	J_GivePlayerItem(client, "adrenaline");
	
	return true;
}

/*
 * give client pills
 */
stock bool J_GivePlayerPills(int client)
{
	if (GetPlayerWeaponSlot(client, 4) >= 0) return false;
	
	J_GivePlayerItem(client, "pain_pills");
	
	return true;
}

/*
 * give client a first aid kit
 */
stock bool J_GivePlayerFirstAidKit(int client)
{
	if (GetPlayerWeaponSlot(client, 3) >= 0) return false;
	
	J_GivePlayerItem(client, "first_aid_kit");
	
	return true;
}

/*
 * give client a machete
 */
stock bool J_GivePlayerMachete(int client)
{
	J_GivePlayerItem(client, "machete");
	
	return true;
}

/*
 * does the client exist on the server in an interactable state?
 */
stock bool J_PlayerExists(int client)
{
	return
		client > 0 &&
		client <= MaxClients &&
		IsClientInGame(client) &&
		!IsClientInKickQueue(client);
}

/*
 * is the client on the survivors team?
 */
stock bool J_PlayerIsSurvivor(int client)
{
	return GetClientTeam(client) == 2;
}

/*
 * returns true if the client exists on the server as a survivor and is not a
 * bot
 */
stock bool J_PlayerIsHumanSurvivor(int client)
{
	return J_PlayerExists(client) && J_PlayerIsSurvivor(client) && !IsFakeClient(client);
}

stock int J_GetPlayerTempHealth(int client)
{
	if (!J_PlayerExists(client)) return 0;
	
	float healthBuffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float healthBufferTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	float pillsDecayRate = J_CVars_PainPillsDecayRate();
	
	int tempHealth = RoundToCeil(healthBuffer - ((GetGameTime() - healthBufferTime) * pillsDecayRate)) - 1;
	
	return tempHealth < 0 ? 0 : tempHealth;
}

stock void J_SetPlayerTempHealth(int client, int tempHealth)
{
    SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(tempHealth));
    SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

stock bool J_IsPlayerIncapacitated(int client)
{
    return GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1;
}

stock float J_PlayerDistanceFrom(int client, float pos[3])
{
	float playerPos[3];
	
	GetClientAbsOrigin(client, playerPos);
	
	return GetVectorDistance(playerPos, pos);
}

#endif
