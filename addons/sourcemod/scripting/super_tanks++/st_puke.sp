// Super Tanks++: Puke Ability
#undef REQUIRE_PLUGIN
#include <st_clone>
#define REQUIRE_PLUGIN

#include <super_tanks++>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[ST++] Puke Ability",
	author = ST_AUTHOR,
	description = "The Super Tank pukes on survivors.",
	version = ST_VERSION,
	url = ST_URL
};

bool g_bCloneInstalled, g_bLateLoad, g_bTankConfig[ST_MAXTYPES + 1];

char g_sPukeEffect[ST_MAXTYPES + 1][4], g_sPukeEffect2[ST_MAXTYPES + 1][4];

float g_flPukeRange[ST_MAXTYPES + 1], g_flPukeRange2[ST_MAXTYPES + 1];

Handle g_hSDKPukePlayer;

int g_iPukeAbility[ST_MAXTYPES + 1], g_iPukeAbility2[ST_MAXTYPES + 1], g_iPukeChance[ST_MAXTYPES + 1], g_iPukeChance2[ST_MAXTYPES + 1], g_iPukeHit[ST_MAXTYPES + 1], g_iPukeHit2[ST_MAXTYPES + 1], g_iPukeHitMode[ST_MAXTYPES + 1], g_iPukeHitMode2[ST_MAXTYPES + 1], g_iPukeMessage[ST_MAXTYPES + 1], g_iPukeMessage2[ST_MAXTYPES + 1], g_iPukeRangeChance[ST_MAXTYPES + 1], g_iPukeRangeChance2[ST_MAXTYPES + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!bIsValidGame(false) && !bIsValidGame())
	{
		strcopy(error, err_max, "[ST++] Puke Ability only supports Left 4 Dead 1 & 2.");

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
	if (StrEqual(name, "st_clone", false))
	{
		g_bCloneInstalled = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "st_clone", false))
	{
		g_bCloneInstalled = false;
	}
}

public void OnPluginStart()
{
	LoadTranslations("super_tanks++.phrases");

	Handle hGameData = LoadGameConfigFile("super_tanks++");
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKPukePlayer = EndPrepSDKCall();

	if (g_hSDKPukePlayer == null)
	{
		PrintToServer("%s Your \"CTerrorPlayer_OnVomitedUpon\" signature is outdated.", ST_PREFIX);
	}

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

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (ST_PluginEnabled() && damage > 0.0)
	{
		char sClassname[32];
		GetEntityClassname(inflictor, sClassname, sizeof(sClassname));

		if ((iPukeHitMode(attacker) == 0 || iPukeHitMode(attacker) == 1) && ST_TankAllowed(attacker) && ST_CloneAllowed(attacker, g_bCloneInstalled) && IsPlayerAlive(attacker) && bIsSurvivor(victim))
		{
			if (StrEqual(sClassname, "weapon_tank_claw") || StrEqual(sClassname, "tank_rock"))
			{
				vPukeHit(victim, attacker, iPukeChance(attacker), iPukeHit(attacker), 1, "1");
			}
		}
		else if ((iPukeHitMode(victim) == 0 || iPukeHitMode(victim) == 2) && ST_TankAllowed(victim) && ST_CloneAllowed(victim, g_bCloneInstalled) && IsPlayerAlive(victim) && bIsSurvivor(attacker))
		{
			if (StrEqual(sClassname, "weapon_melee"))
			{
				vPukeHit(attacker, victim, iPukeChance(victim), iPukeHit(victim), 1, "2");
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
		Format(sName, sizeof(sName), "Tank #%d", iIndex);
		if (kvSuperTanks.JumpToKey(sName))
		{
			if (main)
			{
				g_bTankConfig[iIndex] = false;

				g_iPukeAbility[iIndex] = kvSuperTanks.GetNum("Puke Ability/Ability Enabled", 0);
				g_iPukeAbility[iIndex] = iClamp(g_iPukeAbility[iIndex], 0, 1);
				kvSuperTanks.GetString("Puke Ability/Ability Effect", g_sPukeEffect[iIndex], sizeof(g_sPukeEffect[]), "123");
				g_iPukeMessage[iIndex] = kvSuperTanks.GetNum("Puke Ability/Ability Message", 0);
				g_iPukeMessage[iIndex] = iClamp(g_iPukeMessage[iIndex], 0, 3);
				g_iPukeChance[iIndex] = kvSuperTanks.GetNum("Puke Ability/Puke Chance", 4);
				g_iPukeChance[iIndex] = iClamp(g_iPukeChance[iIndex], 1, 9999999999);
				g_iPukeHit[iIndex] = kvSuperTanks.GetNum("Puke Ability/Puke Hit", 0);
				g_iPukeHit[iIndex] = iClamp(g_iPukeHit[iIndex], 0, 1);
				g_iPukeHitMode[iIndex] = kvSuperTanks.GetNum("Puke Ability/Puke Hit Mode", 0);
				g_iPukeHitMode[iIndex] = iClamp(g_iPukeHitMode[iIndex], 0, 2);
				g_flPukeRange[iIndex] = kvSuperTanks.GetFloat("Puke Ability/Puke Range", 150.0);
				g_flPukeRange[iIndex] = flClamp(g_flPukeRange[iIndex], 1.0, 9999999999.0);
				g_iPukeRangeChance[iIndex] = kvSuperTanks.GetNum("Puke Ability/Puke Range Chance", 16);
				g_iPukeRangeChance[iIndex] = iClamp(g_iPukeRangeChance[iIndex], 1, 9999999999);
			}
			else
			{
				g_bTankConfig[iIndex] = true;

				g_iPukeAbility2[iIndex] = kvSuperTanks.GetNum("Puke Ability/Ability Enabled", g_iPukeAbility[iIndex]);
				g_iPukeAbility2[iIndex] = iClamp(g_iPukeAbility2[iIndex], 0, 1);
				kvSuperTanks.GetString("Puke Ability/Ability Effect", g_sPukeEffect2[iIndex], sizeof(g_sPukeEffect2[]), g_sPukeEffect[iIndex]);
				g_iPukeMessage2[iIndex] = kvSuperTanks.GetNum("Puke Ability/Ability Message", g_iPukeMessage[iIndex]);
				g_iPukeMessage2[iIndex] = iClamp(g_iPukeMessage2[iIndex], 0, 3);
				g_iPukeChance2[iIndex] = kvSuperTanks.GetNum("Puke Ability/Puke Chance", g_iPukeChance[iIndex]);
				g_iPukeChance2[iIndex] = iClamp(g_iPukeChance2[iIndex], 1, 9999999999);
				g_iPukeHit2[iIndex] = kvSuperTanks.GetNum("Puke Ability/Puke Hit", g_iPukeHit[iIndex]);
				g_iPukeHit2[iIndex] = iClamp(g_iPukeHit2[iIndex], 0, 1);
				g_iPukeHitMode2[iIndex] = kvSuperTanks.GetNum("Puke Ability/Puke Hit Mode", g_iPukeHitMode[iIndex]);
				g_iPukeHitMode2[iIndex] = iClamp(g_iPukeHitMode2[iIndex], 0, 2);
				g_flPukeRange2[iIndex] = kvSuperTanks.GetFloat("Puke Ability/Puke Range", g_flPukeRange[iIndex]);
				g_flPukeRange2[iIndex] = flClamp(g_flPukeRange2[iIndex], 1.0, 9999999999.0);
				g_iPukeRangeChance2[iIndex] = kvSuperTanks.GetNum("Puke Ability/Puke Range Chance", g_iPukeRangeChance[iIndex]);
				g_iPukeRangeChance2[iIndex] = iClamp(g_iPukeRangeChance2[iIndex], 1, 9999999999);
			}

			kvSuperTanks.Rewind();
		}
	}

	delete kvSuperTanks;
}

public void ST_Ability(int tank)
{
	if (ST_TankAllowed(tank) && ST_CloneAllowed(tank, g_bCloneInstalled) && IsPlayerAlive(tank))
	{
		int iPukeRangeChance = !g_bTankConfig[ST_TankType(tank)] ? g_iPukeChance[ST_TankType(tank)] : g_iPukeChance2[ST_TankType(tank)];

		float flPukeRange = !g_bTankConfig[ST_TankType(tank)] ? g_flPukeRange[ST_TankType(tank)] : g_flPukeRange2[ST_TankType(tank)],
			flTankPos[3];
		GetClientAbsOrigin(tank, flTankPos);

		for (int iSurvivor = 1; iSurvivor <= MaxClients; iSurvivor++)
		{
			if (bIsSurvivor(iSurvivor))
			{
				float flSurvivorPos[3];
				GetClientAbsOrigin(iSurvivor, flSurvivorPos);

				float flDistance = GetVectorDistance(flTankPos, flSurvivorPos);
				if (flDistance <= flPukeRange)
				{
					vPukeHit(iSurvivor, tank, iPukeRangeChance, iPukeAbility(tank), 2, "3");
				}
			}
		}
	}
}

static void vPukeHit(int survivor, int tank, int chance, int enabled, int message, const char[] mode)
{
	if (enabled == 1 && GetRandomInt(1, chance) == 1 && bIsSurvivor(survivor))
	{
		SDKCall(g_hSDKPukePlayer, survivor, tank, true);

		char sPukeEffect[4];
		sPukeEffect = !g_bTankConfig[ST_TankType(tank)] ? g_sPukeEffect[ST_TankType(tank)] : g_sPukeEffect2[ST_TankType(tank)];
		vEffect(survivor, tank, sPukeEffect, mode);

		int iPukeMessage = !g_bTankConfig[ST_TankType(tank)] ? g_iPukeMessage[ST_TankType(tank)] : g_iPukeMessage2[ST_TankType(tank)];
		if (iPukeMessage == message, iPukeMessage == 3)
		{
			char sTankName[MAX_NAME_LENGTH + 1];
			ST_TankName(tank, sTankName);
			PrintToChatAll("%s %t", ST_PREFIX2, "Puke", sTankName, survivor);
		}
	}
}

static int iPukeAbility(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_iPukeAbility[ST_TankType(tank)] : g_iPukeAbility2[ST_TankType(tank)];
}

static int iPukeChance(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_iPukeChance[ST_TankType(tank)] : g_iPukeChance2[ST_TankType(tank)];
}

static int iPukeHit(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_iPukeHit[ST_TankType(tank)] : g_iPukeHit2[ST_TankType(tank)];
}

static int iPukeHitMode(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_iPukeHitMode[ST_TankType(tank)] : g_iPukeHitMode2[ST_TankType(tank)];
}