// Super Tanks++: Absorb Ability
#undef REQUIRE_PLUGIN
#include <st_clone>
#define REQUIRE_PLUGIN

#include <super_tanks++>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[ST++] Absorb Ability",
	author = ST_AUTHOR,
	description = "The Super Tank absorbs most of the damage it receives.",
	version = ST_VERSION,
	url = ST_URL
};

bool g_bCloneInstalled, g_bAbsorb[MAXPLAYERS + 1], g_bLateLoad, g_bTankConfig[ST_MAXTYPES + 1];

float g_flAbsorbBulletDivisor[ST_MAXTYPES + 1], g_flAbsorbBulletDivisor2[ST_MAXTYPES + 1], g_flAbsorbDuration[ST_MAXTYPES + 1], g_flAbsorbDuration2[ST_MAXTYPES + 1], g_flAbsorbExplosiveDivisor[ST_MAXTYPES + 1], g_flAbsorbExplosiveDivisor2[ST_MAXTYPES + 1], g_flAbsorbFireDivisor[ST_MAXTYPES + 1], g_flAbsorbFireDivisor2[ST_MAXTYPES + 1], g_flAbsorbMeleeDivisor[ST_MAXTYPES + 1], g_flAbsorbMeleeDivisor2[ST_MAXTYPES + 1];

int g_iAbsorbAbility[ST_MAXTYPES + 1], g_iAbsorbAbility2[ST_MAXTYPES + 1], g_iAbsorbChance[ST_MAXTYPES + 1], g_iAbsorbChance2[ST_MAXTYPES + 1], g_iAbsorbMessage[ST_MAXTYPES + 1], g_iAbsorbMessage2[ST_MAXTYPES + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!bIsValidGame(false) && !bIsValidGame())
	{
		strcopy(error, err_max, "[ST++] Absorb Ability only supports Left 4 Dead 1 & 2.");

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

	g_bAbsorb[client] = false;
}

public void OnMapEnd()
{
	vReset();
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (ST_PluginEnabled() && damage > 0.0)
	{
		if (ST_TankAllowed(victim) && ST_CloneAllowed(victim, g_bCloneInstalled) && IsPlayerAlive(victim) && g_bAbsorb[victim])
		{
			float flAbsorbBulletDivisor = !g_bTankConfig[ST_TankType(victim)] ? g_flAbsorbBulletDivisor[ST_TankType(victim)] : g_flAbsorbBulletDivisor2[ST_TankType(victim)],
				flAbsorbExplosiveDivisor = !g_bTankConfig[ST_TankType(victim)] ? g_flAbsorbExplosiveDivisor[ST_TankType(victim)] : g_flAbsorbExplosiveDivisor2[ST_TankType(victim)],
				flAbsorbFireDivisor = !g_bTankConfig[ST_TankType(victim)] ? g_flAbsorbFireDivisor[ST_TankType(victim)] : g_flAbsorbFireDivisor2[ST_TankType(victim)],
				flAbsorbMeleeDivisor = !g_bTankConfig[ST_TankType(victim)] ? g_flAbsorbMeleeDivisor[ST_TankType(victim)] : g_flAbsorbMeleeDivisor2[ST_TankType(victim)];
			if (damagetype & DMG_BULLET)
			{
				damage /= flAbsorbBulletDivisor;
			}
			else if (damagetype & DMG_BLAST || damagetype & DMG_BLAST_SURFACE || damagetype & DMG_AIRBOAT || damagetype & DMG_PLASMA)
			{
				damage /= flAbsorbExplosiveDivisor;
			}
			else if (damagetype & DMG_BURN || damagetype & (DMG_BURN|DMG_PREVENT_PHYSICS_FORCE) || damagetype & (DMG_BURN|DMG_DIRECT))
			{
				damage /= flAbsorbFireDivisor;
			}
			else if (damagetype & DMG_SLASH || damagetype & DMG_CLUB)
			{
				damage /= flAbsorbMeleeDivisor;
			}

			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
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

				g_iAbsorbAbility[iIndex] = kvSuperTanks.GetNum("Absorb Ability/Ability Enabled", 0);
				g_iAbsorbAbility[iIndex] = iClamp(g_iAbsorbAbility[iIndex], 0, 1);
				g_iAbsorbMessage[iIndex] = kvSuperTanks.GetNum("Absorb Ability/Ability Message", 0);
				g_iAbsorbMessage[iIndex] = iClamp(g_iAbsorbMessage[iIndex], 0, 1);
				g_flAbsorbBulletDivisor[iIndex] = kvSuperTanks.GetFloat("Absorb Ability/Absorb Bullet Divisor", 20.0);
				g_flAbsorbBulletDivisor[iIndex] = flClamp(g_flAbsorbBulletDivisor[iIndex], 0.1, 9999999999.0);
				g_iAbsorbChance[iIndex] = kvSuperTanks.GetNum("Absorb Ability/Absorb Chance", 4);
				g_iAbsorbChance[iIndex] = iClamp(g_iAbsorbChance[iIndex], 1, 9999999999);
				g_flAbsorbDuration[iIndex] = kvSuperTanks.GetFloat("Absorb Ability/Absorb Duration", 5.0);
				g_flAbsorbDuration[iIndex] = flClamp(g_flAbsorbDuration[iIndex], 0.1, 9999999999.0);
				g_flAbsorbExplosiveDivisor[iIndex] = kvSuperTanks.GetFloat("Absorb Ability/Absorb Explosive Divisor", 20.0);
				g_flAbsorbExplosiveDivisor[iIndex] = flClamp(g_flAbsorbExplosiveDivisor[iIndex], 0.1, 9999999999.0);
				g_flAbsorbFireDivisor[iIndex] = kvSuperTanks.GetFloat("Absorb Ability/Absorb Fire Divisor", 200.0);
				g_flAbsorbFireDivisor[iIndex] = flClamp(g_flAbsorbFireDivisor[iIndex], 0.1, 9999999999.0);
				g_flAbsorbMeleeDivisor[iIndex] = kvSuperTanks.GetFloat("Absorb Ability/Absorb Melee Divisor", 200.0);
				g_flAbsorbMeleeDivisor[iIndex] = flClamp(g_flAbsorbMeleeDivisor[iIndex], 0.1, 9999999999.0);
			}
			else
			{
				g_bTankConfig[iIndex] = true;

				g_iAbsorbAbility2[iIndex] = kvSuperTanks.GetNum("Absorb Ability/Ability Enabled", g_iAbsorbAbility[iIndex]);
				g_iAbsorbAbility2[iIndex] = iClamp(g_iAbsorbAbility2[iIndex], 0, 1);
				g_iAbsorbMessage2[iIndex] = kvSuperTanks.GetNum("Absorb Ability/Ability Message", g_iAbsorbMessage[iIndex]);
				g_iAbsorbMessage2[iIndex] = iClamp(g_iAbsorbMessage2[iIndex], 0, 1);
				g_flAbsorbBulletDivisor2[iIndex] = kvSuperTanks.GetFloat("Absorb Ability/Absorb Bullet Divisor", g_flAbsorbBulletDivisor[iIndex]);
				g_flAbsorbBulletDivisor2[iIndex] = flClamp(g_flAbsorbBulletDivisor2[iIndex], 0.1, 9999999999.0);
				g_iAbsorbChance2[iIndex] = kvSuperTanks.GetNum("Absorb Ability/Absorb Chance", g_iAbsorbChance[iIndex]);
				g_iAbsorbChance2[iIndex] = iClamp(g_iAbsorbChance2[iIndex], 1, 9999999999);
				g_flAbsorbDuration2[iIndex] = kvSuperTanks.GetFloat("Absorb Ability/Absorb Duration", g_flAbsorbDuration[iIndex]);
				g_flAbsorbDuration2[iIndex] = flClamp(g_flAbsorbDuration2[iIndex], 0.1, 9999999999.0);
				g_flAbsorbExplosiveDivisor2[iIndex] = kvSuperTanks.GetFloat("Absorb Ability/Absorb Explosive Divisor", g_flAbsorbExplosiveDivisor[iIndex]);
				g_flAbsorbExplosiveDivisor2[iIndex] = flClamp(g_flAbsorbExplosiveDivisor2[iIndex], 0.1, 9999999999.0);
				g_flAbsorbFireDivisor2[iIndex] = kvSuperTanks.GetFloat("Absorb Ability/Absorb Fire Divisor", g_flAbsorbFireDivisor[iIndex]);
				g_flAbsorbFireDivisor2[iIndex] = flClamp(g_flAbsorbFireDivisor2[iIndex], 0.1, 9999999999.0);
				g_flAbsorbMeleeDivisor2[iIndex] = kvSuperTanks.GetFloat("Absorb Ability/Absorb Melee Divisor", g_flAbsorbMeleeDivisor[iIndex]);
				g_flAbsorbMeleeDivisor2[iIndex] = flClamp(g_flAbsorbMeleeDivisor2[iIndex], 0.1, 9999999999.0);
			}

			kvSuperTanks.Rewind();
		}
	}

	delete kvSuperTanks;
}

public void ST_PluginEnd()
{
	vReset();
}

public void ST_Event(Event event, const char[] name)
{
	if (StrEqual(name, "player_incapacitated"))
	{
		int iTankId = event.GetInt("userid"), iTank = GetClientOfUserId(iTankId);
		if (iAbsorbAbility(iTank) == 1 && ST_TankAllowed(iTank) && ST_CloneAllowed(iTank, g_bCloneInstalled) && g_bAbsorb[iTank])
		{
			tTimerStopAbsorb(null, GetClientUserId(iTank));
		}
	}
}

public void ST_Ability(int tank)
{
	int iAbsorbChance = !g_bTankConfig[ST_TankType(tank)] ? g_iAbsorbChance[ST_TankType(tank)] : g_iAbsorbChance2[ST_TankType(tank)];
	if (iAbsorbAbility(tank) == 1 && GetRandomInt(1, iAbsorbChance) == 1 && ST_TankAllowed(tank) && ST_CloneAllowed(tank, g_bCloneInstalled) && IsPlayerAlive(tank) && !g_bAbsorb[tank])
	{
		g_bAbsorb[tank] = true;

		float flAbsorbDuration = !g_bTankConfig[ST_TankType(tank)] ? g_flAbsorbDuration[ST_TankType(tank)] : g_flAbsorbDuration2[ST_TankType(tank)];
		CreateTimer(flAbsorbDuration, tTimerStopAbsorb, GetClientUserId(tank), TIMER_FLAG_NO_MAPCHANGE);

		if (iAbsorbMessage(tank) == 1)
		{
			char sTankName[MAX_NAME_LENGTH + 1];
			ST_TankName(tank, sTankName);
			PrintToChatAll("%s %t", ST_PREFIX2, "Absorb", sTankName);
		}
	}
}

static void vReset()
{
	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (bIsValidClient(iPlayer))
		{
			g_bAbsorb[iPlayer] = false;
		}
	}
}

static int iAbsorbAbility(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_iAbsorbAbility[ST_TankType(tank)] : g_iAbsorbAbility2[ST_TankType(tank)];
}

static int iAbsorbMessage(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_iAbsorbMessage[ST_TankType(tank)] : g_iAbsorbMessage2[ST_TankType(tank)];
}

public Action tTimerStopAbsorb(Handle timer, int userid)
{
	int iTank = GetClientOfUserId(userid);
	if (!ST_TankAllowed(iTank) || !IsPlayerAlive(iTank) || !ST_CloneAllowed(iTank, g_bCloneInstalled) || !g_bAbsorb[iTank])
	{
		g_bAbsorb[iTank] = false;

		return Plugin_Stop;
	}

	g_bAbsorb[iTank] = false;

	if (iAbsorbMessage(iTank) == 1)
	{
		char sTankName[MAX_NAME_LENGTH + 1];
		ST_TankName(iTank, sTankName);
		PrintToChatAll("%s %t", ST_PREFIX2, "Absorb2", sTankName);
	}

	return Plugin_Continue;
}