#if !defined JOHNNY_CVARS_SP
#define JOHNNY_CVARS_SP

#pragma semicolon 1

ConVar g_painPillsDecayRateConVar = null;
float g_painPillsDecayRate = 0.27;

stock void OnPainPillsDecayRateChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_painPillsDecayRate = StringToFloat(newValue);
}

stock void CallConVarChangedCallback(ConVarChanged callback, Handle convar, const char[] oldValue, const char[] newValue)
{
	Call_StartFunction(INVALID_HANDLE, callback);
	Call_PushCell(convar);
	Call_PushString(oldValue);
	Call_PushString(newValue);
	Call_Finish();
}

stock void J_InitializeConVar(ConVar cvar, ConVarChanged callback)
{
	cvar.AddChangeHook(callback);
	
	char value[32];
	
	cvar.GetString(value, sizeof(value));
	
	CallConVarChangedCallback(callback, cvar, value, value);
}

stock ConVar J_InitializeNamedConVar(const char[] name, ConVarChanged callback)
{
	ConVar cvar = FindConVar(name);
	
	if (cvar)
	{
		J_InitializeConVar(cvar, callback);
	}
	
	return cvar;
}

stock float J_CVars_PainPillsDecayRate()
{
	if (!g_painPillsDecayRateConVar)
	{
		g_painPillsDecayRateConVar = J_InitializeNamedConVar("pain_pills_decay_rate", OnPainPillsDecayRateChanged);
	}
	
	return g_painPillsDecayRate;
}

#endif
