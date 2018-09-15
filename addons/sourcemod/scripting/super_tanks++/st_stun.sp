// Super Tanks++: Stun Ability
#undef REQUIRE_PLUGIN
#include <st_clone>
#define REQUIRE_PLUGIN
#include <super_tanks++>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[ST++] Stun Ability",
	author = ST_AUTHOR,
	description = ST_DESCRIPTION,
	version = ST_VERSION,
	url = ST_URL
};

bool g_bCloneInstalled, g_bLateLoad, g_bStun[MAXPLAYERS + 1], g_bTankConfig[ST_MAXTYPES + 1];
float g_flStunDuration[ST_MAXTYPES + 1], g_flStunDuration2[ST_MAXTYPES + 1], g_flStunRange[ST_MAXTYPES + 1], g_flStunRange2[ST_MAXTYPES + 1], g_flStunSpeed[ST_MAXTYPES + 1], g_flStunSpeed2[ST_MAXTYPES + 1];
int g_iStunAbility[ST_MAXTYPES + 1], g_iStunAbility2[ST_MAXTYPES + 1], g_iStunChance[ST_MAXTYPES + 1], g_iStunChance2[ST_MAXTYPES + 1], g_iStunHit[ST_MAXTYPES + 1], g_iStunHit2[ST_MAXTYPES + 1], g_iStunHitMode[ST_MAXTYPES + 1], g_iStunHitMode2[ST_MAXTYPES + 1], g_iStunMessage[ST_MAXTYPES + 1], g_iStunMessage2[ST_MAXTYPES + 1], g_iStunRangeChance[ST_MAXTYPES + 1], g_iStunRangeChance2[ST_MAXTYPES + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evEngine = GetEngineVersion();
	if (evEngine != Engine_Left4Dead && evEngine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "[ST++] Stun Ability only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	g_bCloneInstalled = LibraryExists("st_clone");
}

public void OnLibraryAdded(const char[] name)
{
	if (strcmp(name, "st_clone", false) == 0)
	{
		g_bCloneInstalled = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, "st_clone", false) == 0)
	{
		g_bCloneInstalled = false;
	}
}

public void OnPluginStart()
{
	LoadTranslations("super_tanks++.phrases");
	if (g_bLateLoad)
	{
		for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		{
			if (bIsValidClient(iPlayer))
			{
				OnClientPutInServer(iPlayer);
			}
		}
		g_bLateLoad = false;
	}
}

public void OnMapStart()
{
	vReset();
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	g_bStun[client] = false;
}

public void OnMapEnd()
{
	vReset();
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (ST_PluginEnabled() && damage > 0.0)
	{
		char sClassname[32];
		GetEntityClassname(inflictor, sClassname, sizeof(sClassname));
		if ((iStunHitMode(attacker) == 0 || iStunHitMode(attacker) == 1) && ST_TankAllowed(attacker) && ST_CloneAllowed(attacker, g_bCloneInstalled) && IsPlayerAlive(attacker) && bIsSurvivor(victim))
		{
			if (strcmp(sClassname, "weapon_tank_claw") == 0 || strcmp(sClassname, "tank_rock") == 0)
			{
				vStunHit(victim, attacker, iStunChance(attacker), iStunHit(attacker));
			}
		}
		else if ((iStunHitMode(victim) == 0 || iStunHitMode(victim) == 2) && ST_TankAllowed(victim) && ST_CloneAllowed(victim, g_bCloneInstalled) && IsPlayerAlive(victim) && bIsSurvivor(attacker))
		{
			if (strcmp(sClassname, "weapon_melee") == 0)
			{
				vStunHit(attacker, victim, iStunChance(victim), iStunHit(victim));
			}
		}
	}
}

public void ST_Configs(const char[] savepath, bool main)
{
	KeyValues kvSuperTanks = new KeyValues("Super Tanks++");
	kvSuperTanks.ImportFromFile(savepath);
	for (int iIndex = ST_MinType(); iIndex <= ST_MaxType(); iIndex++)
	{
		char sName[MAX_NAME_LENGTH + 1];
		Format(sName, sizeof(sName), "Tank %d", iIndex);
		if (kvSuperTanks.JumpToKey(sName))
		{
			main ? (g_bTankConfig[iIndex] = false) : (g_bTankConfig[iIndex] = true);
			main ? (g_iStunAbility[iIndex] = kvSuperTanks.GetNum("Stun Ability/Ability Enabled", 0)) : (g_iStunAbility2[iIndex] = kvSuperTanks.GetNum("Stun Ability/Ability Enabled", g_iStunAbility[iIndex]));
			main ? (g_iStunAbility[iIndex] = iSetCellLimit(g_iStunAbility[iIndex], 0, 1)) : (g_iStunAbility2[iIndex] = iSetCellLimit(g_iStunAbility2[iIndex], 0, 1));
			main ? (g_iStunMessage[iIndex] = kvSuperTanks.GetNum("Stun Ability/Ability Message", 0)) : (g_iStunMessage2[iIndex] = kvSuperTanks.GetNum("Stun Ability/Ability Message", g_iStunMessage[iIndex]));
			main ? (g_iStunMessage[iIndex] = iSetCellLimit(g_iStunMessage[iIndex], 0, 1)) : (g_iStunMessage2[iIndex] = iSetCellLimit(g_iStunMessage2[iIndex], 0, 1));
			main ? (g_iStunChance[iIndex] = kvSuperTanks.GetNum("Stun Ability/Stun Chance", 4)) : (g_iStunChance2[iIndex] = kvSuperTanks.GetNum("Stun Ability/Stun Chance", g_iStunChance[iIndex]));
			main ? (g_iStunChance[iIndex] = iSetCellLimit(g_iStunChance[iIndex], 1, 9999999999)) : (g_iStunChance2[iIndex] = iSetCellLimit(g_iStunChance2[iIndex], 1, 9999999999));
			main ? (g_flStunDuration[iIndex] = kvSuperTanks.GetFloat("Stun Ability/Stun Duration", 5.0)) : (g_flStunDuration2[iIndex] = kvSuperTanks.GetFloat("Stun Ability/Stun Duration", g_flStunDuration[iIndex]));
			main ? (g_flStunDuration[iIndex] = flSetFloatLimit(g_flStunDuration[iIndex], 0.1, 9999999999.0)) : (g_flStunDuration2[iIndex] = flSetFloatLimit(g_flStunDuration2[iIndex], 0.1, 9999999999.0));
			main ? (g_iStunHit[iIndex] = kvSuperTanks.GetNum("Stun Ability/Stun Hit", 0)) : (g_iStunHit2[iIndex] = kvSuperTanks.GetNum("Stun Ability/Stun Hit", g_iStunHit[iIndex]));
			main ? (g_iStunHit[iIndex] = iSetCellLimit(g_iStunHit[iIndex], 0, 1)) : (g_iStunHit2[iIndex] = iSetCellLimit(g_iStunHit2[iIndex], 0, 1));
			main ? (g_iStunHitMode[iIndex] = kvSuperTanks.GetNum("Stun Ability/Stun Hit Mode", 0)) : (g_iStunHitMode2[iIndex] = kvSuperTanks.GetNum("Stun Ability/Stun Hit Mode", g_iStunHitMode[iIndex]));
			main ? (g_iStunHitMode[iIndex] = iSetCellLimit(g_iStunHitMode[iIndex], 0, 2)) : (g_iStunHitMode2[iIndex] = iSetCellLimit(g_iStunHitMode2[iIndex], 0, 2));
			main ? (g_flStunRange[iIndex] = kvSuperTanks.GetFloat("Stun Ability/Stun Range", 150.0)) : (g_flStunRange2[iIndex] = kvSuperTanks.GetFloat("Stun Ability/Stun Range", g_flStunRange[iIndex]));
			main ? (g_flStunRange[iIndex] = flSetFloatLimit(g_flStunRange[iIndex], 1.0, 9999999999.0)) : (g_flStunRange2[iIndex] = flSetFloatLimit(g_flStunRange2[iIndex], 1.0, 9999999999.0));
			main ? (g_iStunRangeChance[iIndex] = kvSuperTanks.GetNum("Stun Ability/Stun Range Chance", 16)) : (g_iStunRangeChance2[iIndex] = kvSuperTanks.GetNum("Stun Ability/Stun Range Chance", g_iStunRangeChance[iIndex]));
			main ? (g_iStunRangeChance[iIndex] = iSetCellLimit(g_iStunRangeChance[iIndex], 1, 9999999999)) : (g_iStunRangeChance2[iIndex] = iSetCellLimit(g_iStunRangeChance2[iIndex], 1, 9999999999));
			main ? (g_flStunSpeed[iIndex] = kvSuperTanks.GetFloat("Stun Ability/Stun Speed", 0.25)) : (g_flStunSpeed2[iIndex] = kvSuperTanks.GetFloat("Stun Ability/Stun Speed", g_flStunSpeed[iIndex]));
			main ? (g_flStunSpeed[iIndex] = flSetFloatLimit(g_flStunSpeed[iIndex], 0.1, 0.9)) : (g_flStunSpeed2[iIndex] = flSetFloatLimit(g_flStunSpeed2[iIndex], 0.1, 0.9));
			kvSuperTanks.Rewind();
		}
	}
	delete kvSuperTanks;
}

public void ST_Event(Event event, const char[] name)
{
	if (strcmp(name, "player_death") == 0)
	{
		int iTankId = event.GetInt("userid"), iTank = GetClientOfUserId(iTankId);
		if (iStunAbility(iTank) == 1 && ST_TankAllowed(iTank) && ST_CloneAllowed(iTank, g_bCloneInstalled))
		{
			vRemoveStun(iTank);
		}
	}
}

public void ST_Ability(int client)
{
	if (ST_TankAllowed(client) && ST_CloneAllowed(client, g_bCloneInstalled) && IsPlayerAlive(client))
	{
		int iStunRangeChance = !g_bTankConfig[ST_TankType(client)] ? g_iStunChance[ST_TankType(client)] : g_iStunChance2[ST_TankType(client)];
		float flStunRange = !g_bTankConfig[ST_TankType(client)] ? g_flStunRange[ST_TankType(client)] : g_flStunRange2[ST_TankType(client)],
			flTankPos[3];
		GetClientAbsOrigin(client, flTankPos);
		for (int iSurvivor = 1; iSurvivor <= MaxClients; iSurvivor++)
		{
			if (bIsSurvivor(iSurvivor))
			{
				float flSurvivorPos[3];
				GetClientAbsOrigin(iSurvivor, flSurvivorPos);
				float flDistance = GetVectorDistance(flTankPos, flSurvivorPos);
				if (flDistance <= flStunRange)
				{
					vStunHit(iSurvivor, client, iStunRangeChance, iStunAbility(client));
				}
			}
		}
	}
}

public void ST_BossStage(int client)
{
	if (iStunAbility(client) == 1 && ST_TankAllowed(client) && ST_CloneAllowed(client, g_bCloneInstalled))
	{
		vRemoveStun(client);
	}
}

stock void vRemoveStun(int client)
{
	for (int iSurvivor = 1; iSurvivor <= MaxClients; iSurvivor++)
	{
		if (bIsSurvivor(iSurvivor) && g_bStun[iSurvivor])
		{
			DataPack dpStopStun = new DataPack();
			CreateDataTimer(0.1, tTimerStopStun, dpStopStun, TIMER_FLAG_NO_MAPCHANGE);
			dpStopStun.WriteCell(GetClientUserId(iSurvivor)), dpStopStun.WriteCell(GetClientUserId(client)), dpStopStun.WriteCell(1);
		}
	}
}

stock void vReset()
{
	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (bIsValidClient(iPlayer))
		{
			g_bStun[iPlayer] = false;
		}
	}
}

stock void vReset2(int client, int owner)
{
	g_bStun[client] = false;
	if (bIsSurvivor(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
	}
	if (iStunMessage(owner) == 1)
	{
		PrintToChatAll("%s %t", ST_PREFIX2, "Stun2", client);
	}
}

stock void vStunHit(int client, int owner, int chance, int enabled)
{
	if (enabled == 1 && GetRandomInt(1, chance) == 1 && bIsSurvivor(client) && !g_bStun[client])
	{
		g_bStun[client] = true;
		float flStunSpeed = !g_bTankConfig[ST_TankType(owner)] ? g_flStunSpeed[ST_TankType(owner)] : g_flStunSpeed2[ST_TankType(owner)],
			flStunDuration = !g_bTankConfig[ST_TankType(owner)] ? g_flStunDuration[ST_TankType(owner)] : g_flStunDuration2[ST_TankType(owner)];
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", flStunSpeed);
		DataPack dpStopStun = new DataPack();
		CreateDataTimer(flStunDuration, tTimerStopStun, dpStopStun, TIMER_FLAG_NO_MAPCHANGE);
		dpStopStun.WriteCell(GetClientUserId(client)), dpStopStun.WriteCell(GetClientUserId(owner)), dpStopStun.WriteCell(enabled);
		if (iStunMessage(owner) == 1)
		{
			char sTankName[MAX_NAME_LENGTH + 1];
			ST_TankName(owner, sTankName);
			PrintToChatAll("%s %t", ST_PREFIX2, "Stun", sTankName, client);
		}
	}
}

stock int iStunAbility(int client)
{
	return !g_bTankConfig[ST_TankType(client)] ? g_iStunAbility[ST_TankType(client)] : g_iStunAbility2[ST_TankType(client)];
}

stock int iStunChance(int client)
{
	return !g_bTankConfig[ST_TankType(client)] ? g_iStunChance[ST_TankType(client)] : g_iStunChance2[ST_TankType(client)];
}

stock int iStunHit(int client)
{
	return !g_bTankConfig[ST_TankType(client)] ? g_iStunHit[ST_TankType(client)] : g_iStunHit2[ST_TankType(client)];
}

stock int iStunHitMode(int client)
{
	return !g_bTankConfig[ST_TankType(client)] ? g_iStunHitMode[ST_TankType(client)] : g_iStunHitMode2[ST_TankType(client)];
}

stock int iStunMessage(int client)
{
	return !g_bTankConfig[ST_TankType(client)] ? g_iStunMessage[ST_TankType(client)] : g_iStunMessage2[ST_TankType(client)];
}

public Action tTimerStopStun(Handle timer, DataPack pack)
{
	pack.Reset();
	int iSurvivor = GetClientOfUserId(pack.ReadCell());
	if (!bIsSurvivor(iSurvivor))
	{
		g_bStun[iSurvivor] = false;
		return Plugin_Stop;
	}
	int iTank = GetClientOfUserId(pack.ReadCell());
	if (!ST_TankAllowed(iTank) || !IsPlayerAlive(iTank) || !ST_CloneAllowed(iTank, g_bCloneInstalled))
	{
		vReset2(iSurvivor, iTank);
		return Plugin_Stop;
	}
	int iStunEnabled = pack.ReadCell();
	if (iStunEnabled == 0)
	{
		vReset2(iSurvivor, iTank);
		return Plugin_Stop;
	}
	vReset2(iSurvivor, iTank);
	return Plugin_Continue;
}