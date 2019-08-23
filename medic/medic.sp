#include <sourcemod>
#include <sdktools>
#include <johnny/messages.sp>
#include <johnny/players.sp>

#pragma semicolon 1

public Plugin myinfo =
{
	name = "Medic",
	author = "Johnny Bags",
	description = "Add medic survivor class.",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

static int g_medicClient;
static int g_healTickCounter;

static char DEFAULT_HEAL_DISTANCE[] = "300.0";
static char DEFAULT_HEAL_SPEED[] = "1.0";
static char DEFAULT_TEMP_HEALING[] = "2.0";
static char DEFAULT_HEAL_BOOST_DISTANCE[] = "0.2";
static char DEFAULT_GUARDIAN_ANGEL[] = "1";

static float g_healDistance;
static float g_healSpeed;
static float g_tempHealing;
static float g_boostDistance;
static bool g_guardianAngel;

void RegConsoleCmds()
{
	RegConsoleCmd("medic", cmd_ToggleMedic, "Become the medic or stop being the medic.");
}

void HookEvents()
{
	HookEvent("item_pickup", event_ItemPickup);
}

void OnHealDistanceChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_healDistance = StringToFloat(newValue);
}

void OnHealSpeedChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_healSpeed = StringToFloat(newValue);
}

void OnTempHealingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_tempHealing = StringToFloat(newValue);
}

void OnBoostDistanceChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_boostDistance = StringToFloat(newValue);
}

void OnGuardianAngelChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_guardianAngel = StringToInt(newValue) != 0;
}

void CreateConVars()
{
	ConVar cvar_healDistance = CreateConVar("medic_distance", DEFAULT_HEAL_DISTANCE, "Medic heal distance");
	ConVar cvar_healSpeed = CreateConVar("medic_speed", DEFAULT_HEAL_SPEED, "Medic heal speed");
	ConVar cvar_tempHealing = CreateConVar("medic_temp_healing", DEFAULT_TEMP_HEALING, "Amount of temporary healing to get for every 1 point of real health received");
	ConVar cvar_boostDistance = CreateConVar("medic_boost_distance", DEFAULT_HEAL_BOOST_DISTANCE, "How close to the medic players need to be to receive boost healing");
	ConVar cvar_guardianAngel = CreateConVar("medic_guardian_angel", DEFAULT_GUARDIAN_ANGEL, "Can the medic still heal people while dead (by spectating them)?");
	
	J_InitializeConVar(cvar_healDistance, OnHealDistanceChanged);
	J_InitializeConVar(cvar_healSpeed, OnHealSpeedChanged);
	J_InitializeConVar(cvar_tempHealing, OnTempHealingChanged);
	J_InitializeConVar(cvar_boostDistance, OnBoostDistanceChanged);
	J_InitializeConVar(cvar_guardianAngel, OnGuardianAngelChanged);
	
	AutoExecConfig(true, "l4d2_medic");
}

/******************************************************************************
 * forwards
 ******************************************************************************/
public void OnPluginStart()
{
	g_medicClient = -1;
	g_healTickCounter = 0;
	
	HookEvents();
	RegConsoleCmds();
	CreateConVars();
	
	CreateTimer(0.25, timer_HealTick, _, TIMER_REPEAT);
	CreateTimer(60.0, timer_GiveMedicPills, _, TIMER_REPEAT);
	CreateTimer(300.0, timer_GiveMedicFirstAidKit, _, TIMER_REPEAT);
}

/******************************************************************************
 * timers
 ******************************************************************************/
public Action timer_HealTick(Handle timer)
{
	if (!J_PlayerIsHumanSurvivor(g_medicClient)) return Plugin_Continue;
	
	if (!IsMedicAlive() && !g_guardianAngel) return Plugin_Continue;
	
	float medicPos[3];
	
	GetClientAbsOrigin(g_medicClient, medicPos);
	
	g_healTickCounter += 1;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (J_PlayerIsHumanSurvivor(client) && IsPlayerAlive(client))
		{
			if (client == g_medicClient)
			{
				HealMedicABit(client);
			}
			else
			{
				HealPlayerABit(client, medicPos);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action timer_GiveMedicFirstAidKit(Handle timer)
{
	if (!J_PlayerIsHumanSurvivor(g_medicClient)) return Plugin_Continue;
	
	J_GivePlayerFirstAidKit(g_medicClient);
	
	return Plugin_Continue;
}

public Action timer_GiveMedicPills(Handle timer)
{
	if (!J_PlayerIsHumanSurvivor(g_medicClient)) return Plugin_Continue;
	
	if (GetRandomInt(0, 1) > 0)
	{
		J_GivePlayerAdrenaline(g_medicClient);
	}
	else
	{
		J_GivePlayerPills(g_medicClient);
	}
	
	return Plugin_Continue;
}

/******************************************************************************
 * client adjustments
 ******************************************************************************/
/*
 * heal the medic a little bit depending on their current health and the value
 * of the heal tick counter
 */
void HealMedicABit(int client)
{
	int currentHealth = GetClientHealth(client);
	
	if (currentHealth >= 100) return;
	if (J_IsPlayerIncapacitated(client)) return;
	
	if (currentHealth < 10
	|| (currentHealth < 20 && (g_healTickCounter % 2 == 0))
	|| (currentHealth < 40 && (g_healTickCounter % 4 == 0))
	|| (currentHealth < 60 && (g_healTickCounter % 8 == 0))
	|| (g_healTickCounter % 16 == 0))
	{
		SetEntityHealth(client, currentHealth + 1);
	}
}

/*
 * give the client a little bit of real health and temporary health depending on
 * their current real health and the value of the heal tick counter and their
 * distance from the medic
 */
void HealPlayerABit(int client, float medicPos[3])
{
	int currentHealth = GetClientHealth(client);
	
	if (currentHealth >= 100) return;
	if (J_IsPlayerIncapacitated(client)) return;
	
	int currentTempHealth = J_GetPlayerTempHealth(client);
	int totalHealth = currentHealth + currentTempHealth;
	
	float distance = J_PlayerDistanceFrom(client, medicPos);
	
	if (distance > g_healDistance) return;
	
	float normalizedDistance = distance / g_healDistance;
	
	if (totalHealth < 10
	|| (totalHealth < 20 && (g_healTickCounter % 2 == 0))
	|| (totalHealth < 40 && (g_healTickCounter % 4 == 0))
	|| (totalHealth < 60 && (g_healTickCounter % 8 == 0))
	|| (g_healTickCounter % 16 == 0)
	|| (IsMedicAlive() && normalizedDistance < g_boostDistance && totalHealth < 100))
	{
		int healthToGive = RoundToCeil((1.0 - normalizedDistance) * g_healSpeed);
		
		SetEntityHealth(client, currentHealth + healthToGive);
		
		if (currentHealth + healthToGive + currentTempHealth < 100)
		{
			int tempHealthToGive = RoundToCeil(float(healthToGive) * g_tempHealing);
			
			J_SetPlayerTempHealth(client, currentTempHealth + tempHealthToGive);
		}
	}
}

/*
 * remove a client's medic status and inform everybody
 */
void StopBeingMedic(int client)
{
	g_medicClient = -1;
	
	PrintYouAreNoLongerMedic(client);
}

/*
 * make this client a medic if a medic does not already exist
 */
void BecomeMedic(int client)
{
	if (MedicExists())
	{
		PrintAlreadyHaveMedic();
		
		return;
	}
	
	g_medicClient = client;
	
	J_GivePlayerPills(client);
	J_GivePlayerFirstAidKit(client);
	J_GivePlayerMachete(client);
	J_DisarmPrimary(client);
	
	PrintYouAreNowMedic(client);
}

/******************************************************************************
 * events
 ******************************************************************************/
public Action event_ItemPickup(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (client == g_medicClient)
	{
		J_DisarmPrimary(client);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/******************************************************************************
 * queries
 ******************************************************************************/
/*
 * is there a medic active on the server?
 */
bool MedicExists()
{
	if (g_medicClient < 0) return false;
	
	return J_PlayerIsHumanSurvivor(g_medicClient);
}

/*
 * is the medic alive?
 */
bool IsMedicAlive()
{
	return IsPlayerAlive(g_medicClient);
}

/******************************************************************************
 * messages
 ******************************************************************************/
void PrintAlreadyHaveMedic()
{
	char medicName[32];
	
	GetClientName(g_medicClient, medicName, sizeof(medicName));
	
	PrintToChatAll("Our current medic is %s.", medicName);
}

void PrintYouAreNoLongerMedic(int client)
{
	char clientName[32];
	
	GetClientName(client, clientName, sizeof(clientName));
	
	ReplyToCommand(client, "You are no longer medic.");
	
	char msg[128];
	
	Format(msg, sizeof(msg), "%s is no longer medic.", clientName);
	
	J_PrintToEveryoneElse(client, msg);
}

void PrintYouAreNowMedic(int client)
{
	char clientName[32];
	
	GetClientName(client, clientName, sizeof(clientName));
	
	ReplyToCommand(client, "You are now medic.");
	
	char msg[128];
	
	Format(msg, sizeof(msg), "%s is now medic.", clientName);
	
	J_PrintToEveryoneElse(client, msg);
}

/******************************************************************************
 * commands
 ******************************************************************************/
public Action cmd_ToggleMedic(int client, int args)
{
	if (!J_PlayerIsHumanSurvivor(client)) return Plugin_Continue;
	
	if (g_medicClient == client)
	{
		StopBeingMedic(client);
	}
	else
	{
		BecomeMedic(client);
	}
	
	return Plugin_Handled;
}
