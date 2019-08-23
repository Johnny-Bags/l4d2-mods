#if !defined JOHNNY_MESSAGES_SP
#define JOHNNY_MESSAGES_SP

#include "players.sp"

#pragma semicolon 1

/*
 * print a message to everybody except for [not_client]
 */
stock void J_PrintToEveryoneElse(int not_client, const char[] msg)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (not_client != client && J_PlayerExists(client) && !IsFakeClient(client))
		{
			PrintToChat(client, msg);
		}
	}
}

#endif
