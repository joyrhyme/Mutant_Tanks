// Super Tanks++: Ammo Ability
#undef REQUIRE_PLUGIN
#include <st_clone>
#define REQUIRE_PLUGIN

#include <super_tanks++>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[ST++] Ammo Ability",
	author = ST_AUTHOR,
	description = "The Super Tank takes away survivors' ammunition.",
	version = ST_VERSION,
	url = ST_URL
};

bool g_bCloneInstalled, g_bLateLoad, g_bTankConfig[ST_MAXTYPES + 1];

char g_sAmmoEffect[ST_MAXTYPES + 1][4], g_sAmmoEffect2[ST_MAXTYPES + 1][4];

float g_flAmmoRange[ST_MAXTYPES + 1], g_flAmmoRange2[ST_MAXTYPES + 1];

int g_iAmmoAbility[ST_MAXTYPES + 1], g_iAmmoAbility2[ST_MAXTYPES + 1], g_iAmmoChance[ST_MAXTYPES + 1], g_iAmmoChance2[ST_MAXTYPES + 1], g_iAmmoCount[ST_MAXTYPES + 1], g_iAmmoCount2[ST_MAXTYPES + 1], g_iAmmoHit[ST_MAXTYPES + 1], g_iAmmoHit2[ST_MAXTYPES + 1], g_iAmmoHitMode[ST_MAXTYPES + 1], g_iAmmoHitMode2[ST_MAXTYPES + 1], g_iAmmoMessage[ST_MAXTYPES + 1], g_iAmmoMessage2[ST_MAXTYPES + 1], g_iAmmoRangeChance[ST_MAXTYPES + 1], g_iAmmoRangeChance2[ST_MAXTYPES + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!bIsValidGame(false) && !bIsValidGame())
	{
		strcopy(error, err_max, "[ST++] Ammo Ability only supports Left 4 Dead 1 & 2.");

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

		if ((iAmmoHitMode(attacker) == 0 || iAmmoHitMode(attacker) == 1) && ST_TankAllowed(attacker) && ST_CloneAllowed(attacker, g_bCloneInstalled) && IsPlayerAlive(attacker) && bIsSurvivor(victim))
		{
			if (StrEqual(sClassname, "weapon_tank_claw") || StrEqual(sClassname, "tank_rock"))
			{
				vAmmoHit(victim, attacker, iAmmoChance(attacker), iAmmoHit(attacker), 1, "1");
			}
		}
		else if ((iAmmoHitMode(victim) == 0 || iAmmoHitMode(victim) == 2) && ST_TankAllowed(victim) && ST_CloneAllowed(victim, g_bCloneInstalled) && IsPlayerAlive(victim) && bIsSurvivor(attacker))
		{
			if (StrEqual(sClassname, "weapon_melee"))
			{
				vAmmoHit(attacker, victim, iAmmoChance(victim), iAmmoHit(victim), 1, "2");
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

				g_iAmmoAbility[iIndex] = kvSuperTanks.GetNum("Ammo Ability/Ability Enabled", 0);
				g_iAmmoAbility[iIndex] = iClamp(g_iAmmoAbility[iIndex], 0, 1);
				kvSuperTanks.GetString("Ammo Ability/Ability Effect", g_sAmmoEffect[iIndex], sizeof(g_sAmmoEffect[]), "123");
				g_iAmmoMessage[iIndex] = kvSuperTanks.GetNum("Ammo Ability/Ability Message", 0);
				g_iAmmoMessage[iIndex] = iClamp(g_iAmmoMessage[iIndex], 0, 3);
				g_iAmmoChance[iIndex] = kvSuperTanks.GetNum("Ammo Ability/Ammo Chance", 4);
				g_iAmmoChance[iIndex] = iClamp(g_iAmmoChance[iIndex], 1, 9999999999);
				g_iAmmoCount[iIndex] = kvSuperTanks.GetNum("Ammo Ability/Ammo Count", 0);
				g_iAmmoCount[iIndex] = iClamp(g_iAmmoCount[iIndex], 0, 25);
				g_iAmmoHit[iIndex] = kvSuperTanks.GetNum("Ammo Ability/Ammo Hit", 0);
				g_iAmmoHit[iIndex] = iClamp(g_iAmmoHit[iIndex], 0, 1);
				g_iAmmoHitMode[iIndex] = kvSuperTanks.GetNum("Ammo Ability/Ammo Hit Mode", 0);
				g_iAmmoHitMode[iIndex] = iClamp(g_iAmmoHitMode[iIndex], 0, 2);
				g_flAmmoRange[iIndex] = kvSuperTanks.GetFloat("Ammo Ability/Ammo Range", 150.0);
				g_flAmmoRange[iIndex] = flClamp(g_flAmmoRange[iIndex], 1.0, 9999999999.0);
				g_iAmmoRangeChance[iIndex] = kvSuperTanks.GetNum("Ammo Ability/Ammo Range Chance", 16);
				g_iAmmoRangeChance[iIndex] = iClamp(g_iAmmoRangeChance[iIndex], 1, 9999999999);
			}
			else
			{
				g_bTankConfig[iIndex] = true;

				g_iAmmoAbility2[iIndex] = kvSuperTanks.GetNum("Ammo Ability/Ability Enabled", g_iAmmoAbility[iIndex]);
				g_iAmmoAbility2[iIndex] = iClamp(g_iAmmoAbility2[iIndex], 0, 1);
				kvSuperTanks.GetString("Ammo Ability/Ability Effect", g_sAmmoEffect2[iIndex], sizeof(g_sAmmoEffect2[]), g_sAmmoEffect[iIndex]);
				g_iAmmoMessage2[iIndex] = kvSuperTanks.GetNum("Ammo Ability/Ability Message", g_iAmmoMessage[iIndex]);
				g_iAmmoMessage2[iIndex] = iClamp(g_iAmmoMessage2[iIndex], 0, 3);
				g_iAmmoChance2[iIndex] = kvSuperTanks.GetNum("Ammo Ability/Ammo Chance", g_iAmmoChance[iIndex]);
				g_iAmmoChance2[iIndex] = iClamp(g_iAmmoChance2[iIndex], 1, 9999999999);
				g_iAmmoCount2[iIndex] = kvSuperTanks.GetNum("Ammo Ability/Ammo Count", g_iAmmoCount[iIndex]);
				g_iAmmoCount2[iIndex] = iClamp(g_iAmmoCount2[iIndex], 0, 25);
				g_iAmmoHit2[iIndex] = kvSuperTanks.GetNum("Ammo Ability/Ammo Hit", g_iAmmoHit[iIndex]);
				g_iAmmoHit2[iIndex] = iClamp(g_iAmmoHit2[iIndex], 0, 1);
				g_iAmmoHitMode2[iIndex] = kvSuperTanks.GetNum("Ammo Ability/Ammo Hit Mode", g_iAmmoHitMode[iIndex]);
				g_iAmmoHitMode2[iIndex] = iClamp(g_iAmmoHitMode2[iIndex], 0, 2);
				g_flAmmoRange2[iIndex] = kvSuperTanks.GetFloat("Ammo Ability/Ammo Range", g_flAmmoRange[iIndex]);
				g_flAmmoRange2[iIndex] = flClamp(g_flAmmoRange2[iIndex], 1.0, 9999999999.0);
				g_iAmmoRangeChance2[iIndex] = kvSuperTanks.GetNum("Ammo Ability/Ammo Range Chance", g_iAmmoRangeChance[iIndex]);
				g_iAmmoRangeChance2[iIndex] = iClamp(g_iAmmoRangeChance2[iIndex], 1, 9999999999);
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
		int iAmmoAbility = !g_bTankConfig[ST_TankType(tank)] ? g_iAmmoAbility[ST_TankType(tank)] : g_iAmmoAbility2[ST_TankType(tank)],
			iAmmoRangeChance = !g_bTankConfig[ST_TankType(tank)] ? g_iAmmoChance[ST_TankType(tank)] : g_iAmmoChance2[ST_TankType(tank)];

		float flAmmoRange = !g_bTankConfig[ST_TankType(tank)] ? g_flAmmoRange[ST_TankType(tank)] : g_flAmmoRange2[ST_TankType(tank)],
			flTankPos[3];
		GetClientAbsOrigin(tank, flTankPos);

		for (int iSurvivor = 1; iSurvivor <= MaxClients; iSurvivor++)
		{
			if (bIsSurvivor(iSurvivor))
			{
				float flSurvivorPos[3];
				GetClientAbsOrigin(iSurvivor, flSurvivorPos);

				float flDistance = GetVectorDistance(flTankPos, flSurvivorPos);
				if (flDistance <= flAmmoRange)
				{
					vAmmoHit(iSurvivor, tank, iAmmoRangeChance, iAmmoAbility, 2, "3");
				}
			}
		}
	}
}

static void vAmmoHit(int survivor, int tank, int chance, int enabled, int message, const char[] mode)
{
	if (enabled == 1 && GetRandomInt(1, chance) == 1 && bIsSurvivor(survivor) && GetPlayerWeaponSlot(survivor, 0) > 0)
	{
		char sWeapon[32];
		int iActiveWeapon = GetEntPropEnt(survivor, Prop_Data, "m_hActiveWeapon"),
			iAmmoCount = !g_bTankConfig[ST_TankType(tank)] ? g_iAmmoCount[ST_TankType(tank)] : g_iAmmoCount2[ST_TankType(tank)],
			iAmmoMessage = !g_bTankConfig[ST_TankType(tank)] ? g_iAmmoMessage[ST_TankType(tank)] : g_iAmmoMessage2[ST_TankType(tank)];

		GetEntityClassname(iActiveWeapon, sWeapon, sizeof(sWeapon));
		if (bIsValidEntity(iActiveWeapon))
		{
			if (StrEqual(sWeapon, "weapon_rifle") || StrEqual(sWeapon, "weapon_rifle_desert") || StrEqual(sWeapon, "weapon_rifle_ak47") || StrEqual(sWeapon, "weapon_rifle_sg552"))
			{
				SetEntProp(survivor, Prop_Data, "m_iAmmo", iAmmoCount, _, 3);
			}
			else if (StrEqual(sWeapon, "weapon_smg") || StrEqual(sWeapon, "weapon_smg_silenced") || StrEqual(sWeapon, "weapon_smg_mp5"))
			{
				SetEntProp(survivor, Prop_Data, "m_iAmmo", iAmmoCount, _, 5);
			}
			else if (StrEqual(sWeapon, "weapon_pumpshotgun"))
			{
				if (bIsValidGame())
				{
					SetEntProp(survivor, Prop_Data, "m_iAmmo", iAmmoCount, _, 7);
				}
				else
				{
					SetEntProp(survivor, Prop_Data, "m_iAmmo", iAmmoCount, _, 6);
				}
			}
			else if (StrEqual(sWeapon, "weapon_shotgun_chrome"))
			{
				SetEntProp(survivor, Prop_Data, "m_iAmmo", iAmmoCount, _, 7);
			}
			else if (StrEqual(sWeapon, "weapon_autoshotgun"))
			{
				if (bIsValidGame())
				{
					SetEntProp(survivor, Prop_Data, "m_iAmmo", iAmmoCount, _, 8);
				}
				else
				{
					SetEntProp(survivor, Prop_Data, "m_iAmmo", iAmmoCount, _, 6);
				}
			}
			else if (StrEqual(sWeapon, "weapon_shotgun_spas"))
			{
				SetEntProp(survivor, Prop_Data, "m_iAmmo", iAmmoCount, _, 8);
			}
			else if (StrEqual(sWeapon, "weapon_hunting_rifle"))
			{
				if (bIsValidGame())
				{
					SetEntProp(survivor, Prop_Data, "m_iAmmo", iAmmoCount, _, 9);
				}
				else
				{
					SetEntProp(survivor, Prop_Data, "m_iAmmo", iAmmoCount, _, 2);
				}
			}
			else if (StrEqual(sWeapon, "weapon_sniper_scout") || StrEqual(sWeapon, "weapon_sniper_military") || StrEqual(sWeapon, "weapon_sniper_awp"))
			{
				SetEntProp(survivor, Prop_Data, "m_iAmmo", iAmmoCount, _, 10);
			}
			else if (StrEqual(sWeapon, "weapon_grenade_launcher"))
			{
				SetEntProp(survivor, Prop_Data, "m_iAmmo", iAmmoCount, _, 17);
			}
		}

		SetEntProp(GetPlayerWeaponSlot(survivor, 0), Prop_Data, "m_iClip1", iAmmoCount, 1);

		char sAmmoEffect[4];
		sAmmoEffect = !g_bTankConfig[ST_TankType(tank)] ? g_sAmmoEffect[ST_TankType(tank)] : g_sAmmoEffect2[ST_TankType(tank)];
		vEffect(survivor, tank, sAmmoEffect, mode);

		if (iAmmoMessage == message || iAmmoMessage == 3)
		{
			char sTankName[MAX_NAME_LENGTH + 1];
			ST_TankName(tank, sTankName);
			PrintToChatAll("%s %t", ST_PREFIX2, "Ammo", sTankName, survivor);
		}
	}
}

static int iAmmoChance(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_iAmmoChance[ST_TankType(tank)] : g_iAmmoChance2[ST_TankType(tank)];
}

static int iAmmoHit(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_iAmmoHit[ST_TankType(tank)] : g_iAmmoHit2[ST_TankType(tank)];
}

static int iAmmoHitMode(int tank)
{
	return !g_bTankConfig[ST_TankType(tank)] ? g_iAmmoHitMode[ST_TankType(tank)] : g_iAmmoHitMode2[ST_TankType(tank)];
}