#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <johnny/messages.sp>
#include <johnny/players.sp>

#pragma semicolon 1

/*
 * The bezerker has more rage the lower their health is.
 *
 * Rage makes the bezerker:
 *	- Move faster
 *  - Swing their weapon faster
 *	- Do more damage
 *  - Take less damage
 * 
 * The bezerker can also double-jump.
 * 
 * The bezerker is not allowed to use primary weapons.
 *
 * usage:
 *	type !bezerker in chat to become the bezerker.
 */
public Plugin myinfo =
{
	name = "Bezerker",
	author = "Johnny Bags",
	description = "Add bezerker survivor class.",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

static const float MIN_SPEED = 1.0;
static const float MAX_SPEED = 2.0;
//static const float HOBBLE_SPEED = 8.0;
static const float MIN_GRAVITY = 0.5;
static const float MAX_GRAVITY = 1.0;
static const int MAX_DOUBLE_JUMPS = 1;
static int g_bezerkerClient;

int g_lastButtons[MAXPLAYERS + 1];
int	g_lastFlags[MAXPLAYERS + 1];
int g_jumps[MAXPLAYERS + 1];

void HookEvents()
{
	HookEvent("heal_success", event_HealSuccess);
	HookEvent("item_pickup", event_ItemPickup);
	HookEvent("player_death", event_PlayerDeath);
	HookEvent("player_hurt", event_PlayerHurt);
	HookEvent("player_incapacitated", event_PlayerIncapacitated);
	HookEvent("player_spawn", event_PlayerSpawn);
	HookEvent("revive_success", event_ReviveSuccess);
	HookEvent("survivor_rescued", event_SurvivorRescued);
	HookEvent("defibrillator_used", event_DefibUsed);
}

void RegConsoleCmds()
{
	RegConsoleCmd("bezerker", cmd_ToggleBezerker, "Become the bezerker or stop being the bezerker.");
}

/******************************************************************************
 * forwards
 ******************************************************************************/
public void OnPluginStart()
{
	g_bezerkerClient = -1;
	
	HookEvents();
	RegConsoleCmds();
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (PlayerIsBezerker(client))
	{
		DoubleJump(client);
		WeaponSpeed(client, buttons);
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (PlayerIsBezerker(attacker))
	{
		damage *= 1.0 + (CalculateBezerkAmount(attacker) * 3.0);
		
		return Plugin_Changed;
	}
	
	if (PlayerIsBezerker(victim) && !J_IsPlayerIncapacitated(victim))
	{
		damage *= 1.0 - (CalculateBezerkAmount(victim) * 0.75);
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

/******************************************************************************
 * queries
 ******************************************************************************/
/*
 * is there a bezerker active on the server?
 */
bool BezerkerExists()
{
	if (g_bezerkerClient < 0) return false;
	
	return J_PlayerIsHumanSurvivor(g_bezerkerClient);
}

/*
 * is this client the bezerker?
 */
bool PlayerIsBezerker(int client)
{
	return client == g_bezerkerClient && J_PlayerIsHumanSurvivor(client);
}

/******************************************************************************
 * client adjustments
 ******************************************************************************/
void WeaponSpeed(int client, int & buttons)
{
	if (buttons & IN_ATTACK || buttons & IN_ATTACK2)
	{
		int ent = GetPlayerWeaponSlot(client, 1);
		
		if (ent <= 0) return;
		
		float m_flNextPrimaryAttack   = GetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack");
		float m_flNextSecondaryAttack = GetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack");
		float m_flCycle               = GetEntPropFloat(ent, Prop_Send, "m_flCycle");
		bool m_bInReload              = GetEntProp(ent, Prop_Send, "m_bInReload") > 0;
		
		if (m_flCycle > 0.0 || m_bInReload) return;
		
		float bezerkAmount = CalculateBezerkAmount(client);
		
		SetEntPropFloat(ent, Prop_Send, "m_flPlaybackRate", bezerkAmount + 1.0);
		SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", m_flNextPrimaryAttack - (bezerkAmount / 2));
		SetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack", m_flNextSecondaryAttack - (bezerkAmount / 2));
	}
}

/*
 * remove a client's bezerker status and inform everybody
 */
void StopBeingBezerker(int client)
{
	g_bezerkerClient = -1;
	
	PrintYouAreNoLongerBezerker(client);
}

/*
 * make this client a bezerker if a bezerker does not already exist
 */
void BecomeBezerker(int client)
{
	if (BezerkerExists())
	{
		PrintAlreadyHaveBezerker();
		
		return;
	}
	
	g_bezerkerClient = client;
	
	J_GivePlayerMachete(client);
	J_DisarmPrimary(client);
	
	PrintYouAreNowBezerker(client);
}

void SetPlayerSpeedBoost(int client, float v)
{
	float speed = MIN_SPEED + (v * (MAX_SPEED - MIN_SPEED));
	float gravity = MAX_GRAVITY + (v * (MIN_GRAVITY - MAX_GRAVITY));
	
	//if (v >= 1.0) speed = HOBBLE_SPEED;
	
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", speed);
	SetEntityGravity(client, gravity);
}

float CalculateBezerkAmount(int client)
{
	int health = GetClientHealth(client);
	
	return Pow(1.0 - (float(health) / 100.0), 2.0);
}

void GoBezerk(int client)
{
	SetPlayerSpeedBoost(client, CalculateBezerkAmount(client));
}

void DoubleJump(int client)
{
	int currentFlags   = GetEntityFlags(client);
	int currentButtons = GetClientButtons(client);
	
	if (g_lastFlags[client] & FL_ONGROUND)
	{
		if (!(currentFlags & FL_ONGROUND) && !(g_lastButtons[client] & IN_JUMP) && currentButtons & IN_JUMP)
		{
			OriginalJump(client);
		}
	}
	else if (currentFlags & FL_ONGROUND)
	{
		Landed(client);
	}
	else if (!(g_lastButtons[client] & IN_JUMP) && currentButtons & IN_JUMP)
	{
		ReJump(client);
	}
	
	g_lastFlags[client] = currentFlags;
	g_lastButtons[client] = currentButtons;
}

void OriginalJump(int client)
{
	g_jumps[client]++;
}

void Landed(int client)
{
	g_jumps[client] = 0;
}

void ReJump(int client)
{
	if (1 <= g_jumps[client] <= MAX_DOUBLE_JUMPS)
	{
		g_jumps[client]++;
		
		float vel[3];
		
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
		
		vel[2] = 300.0;
		
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
	}
}

/******************************************************************************
 * events
 ******************************************************************************/
public Action event_DefibUsed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	
	if (PlayerIsBezerker(client))
	{
		GoBezerk(client);
	}
}

public Action event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	
	if (PlayerIsBezerker(client))
	{
		GoBezerk(client);
	}
	
	return Plugin_Continue;
}

public Action event_ItemPickup(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (PlayerIsBezerker(client))
	{
		J_DisarmPrimary(client);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (PlayerIsBezerker(client))
	{
		GoBezerk(client);
	}
	
	return Plugin_Continue;
}

public Action event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (PlayerIsBezerker(client) && !J_IsPlayerIncapacitated(client))
	{
		GoBezerk(client);
	}
	
	return Plugin_Continue;
}

public Action event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (PlayerIsBezerker(client))
	{
		SetPlayerSpeedBoost(client, 0.0);
	}
	
	return Plugin_Continue;
}

public Action event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	
	if (PlayerIsBezerker(client))
	{
		GoBezerk(client);
	}
	
	return Plugin_Continue;
}

public Action event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (PlayerIsBezerker(client))
	{
		J_GivePlayerMachete(client);
		GoBezerk(client);
	}
	
	return Plugin_Continue;
}

public Action event_SurvivorRescued(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "subject"));
	
	if (PlayerIsBezerker(client))
	{
		GoBezerk(client);
	}
	
	return Plugin_Continue;
} 

/******************************************************************************
 * messages
 ******************************************************************************/
void PrintAlreadyHaveBezerker()
{
	char bezerkerName[32];
	
	GetClientName(g_bezerkerClient, bezerkerName, sizeof(bezerkerName));
	
	PrintToChatAll("Our current bezerker is %s.", bezerkerName);
}

void PrintYouAreNoLongerBezerker(int client)
{
	char clientName[32];
	
	GetClientName(client, clientName, sizeof(clientName));
	
	ReplyToCommand(client, "You are no longer bezerker.");
	
	char msg[128];
	
	Format(msg, sizeof(msg), "%s is no longer bezerker.", clientName);
	
	J_PrintToEveryoneElse(client, msg);
}

void PrintYouAreNowBezerker(int client)
{
	char clientName[32];
	
	GetClientName(client, clientName, sizeof(clientName));
	
	ReplyToCommand(client, "You are now bezerker.");
	
	char msg[128];
	
	Format(msg, sizeof(msg), "%s is now bezerker.", clientName);
	
	J_PrintToEveryoneElse(client, msg);
}

/******************************************************************************
 * commands
 ******************************************************************************/
public Action cmd_ToggleBezerker(int client, int args)
{
	if (!J_PlayerIsHumanSurvivor(client)) return Plugin_Continue;
	
	if (g_bezerkerClient == client)
	{
		StopBeingBezerker(client);
	}
	else
	{
		BecomeBezerker(client);
	}
	
	return Plugin_Handled;
}
