// Super Tanks++: Witch Ability
#undef REQUIRE_PLUGIN
#include <st_clone>
#define REQUIRE_PLUGIN

#include <super_tanks++>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[ST++] Witch Ability",
	author = ST_AUTHOR,
	description = "The Super Tank converts nearby common infected into Witch minions.",
	version = ST_VERSION,
	url = ST_URL
};

bool g_bCloneInstalled, g_bLateLoad, g_bTankConfig[ST_MAXTYPES + 1];

float g_flWitchRange[ST_MAXTYPES + 1], g_flWitchRange2[ST_MAXTYPES + 1];

int g_iWitchAbility[ST_MAXTYPES + 1], g_iWitchAbility2[ST_MAXTYPES + 1], g_iWitchAmount[ST_MAXTYPES + 1], g_iWitchAmount2[ST_MAXTYPES + 1], g_iWitchDamage[ST_MAXTYPES + 1], g_iWitchDamage2[ST_MAXTYPES + 1], g_iWitchMessage[ST_MAXTYPES + 1], g_iWitchMessage2[ST_MAXTYPES + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (!bIsValidGame(false) && !bIsValidGame())
	{
		strcopy(error, err_max, "[ST++] Witch Ability only supports Left 4 Dead 1 & 2.");

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
		if (bIsWitch(attacker) && bIsSurvivor(victim))
		{
			int iOwner;
			if (HasEntProp(attacker, Prop_Send, "m_hOwnerEntity"))
			{
				iOwner = GetEntPropEnt(attacker, Prop_Send, "m_hOwnerEntity");
			}

			if (ST_TankAllowed(iOwner) && ST_CloneAllowed(iOwner, g_bCloneInstalled))
			{
				int iWitchDamage = !g_bTankConfig[ST_TankType(iOwner)] ? g_iWitchDamage[ST_TankType(iOwner)] : g_iWitchDamage2[ST_TankType(iOwner)];
				damage = float(iWitchDamage);

				return Plugin_Changed;
			}
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

				g_iWitchAbility[iIndex] = kvSuperTanks.GetNum("Witch Ability/Ability Enabled", 0);
				g_iWitchAbility[iIndex] = iClamp(g_iWitchAbility[iIndex], 0, 1);
				g_iWitchMessage[iIndex] = kvSuperTanks.GetNum("Witch Ability/Ability Message", 0);
				g_iWitchMessage[iIndex] = iClamp(g_iWitchMessage[iIndex], 0, 1);
				g_iWitchAmount[iIndex] = kvSuperTanks.GetNum("Witch Ability/Witch Amount", 3);
				g_iWitchAmount[iIndex] = iClamp(g_iWitchAmount[iIndex], 1, 25);
				g_iWitchDamage[iIndex] = kvSuperTanks.GetNum("Witch Ability/Witch Damage", 5);
				g_iWitchDamage[iIndex] = iClamp(g_iWitchDamage[iIndex], 1, 9999999999);
				g_flWitchRange[iIndex] = kvSuperTanks.GetFloat("Witch Ability/Witch Range", 500.0);
				g_flWitchRange[iIndex] = flClamp(g_flWitchRange[iIndex], 1.0, 9999999999.0);
			}
			else
			{
				g_bTankConfig[iIndex] = true;

				g_iWitchAbility2[iIndex] = kvSuperTanks.GetNum("Witch Ability/Ability Enabled", g_iWitchAbility[iIndex]);
				g_iWitchAbility2[iIndex] = iClamp(g_iWitchAbility2[iIndex], 0, 1);
				g_iWitchMessage2[iIndex] = kvSuperTanks.GetNum("Witch Ability/Ability Message", g_iWitchMessage[iIndex]);
				g_iWitchMessage2[iIndex] = iClamp(g_iWitchMessage2[iIndex], 0, 1);
				g_iWitchAmount2[iIndex] = kvSuperTanks.GetNum("Witch Ability/Witch Amount", g_iWitchAmount[iIndex]);
				g_iWitchAmount2[iIndex] = iClamp(g_iWitchAmount2[iIndex], 1, 25);
				g_iWitchDamage2[iIndex] = kvSuperTanks.GetNum("Witch Ability/Witch Damage", g_iWitchDamage[iIndex]);
				g_iWitchDamage2[iIndex] = iClamp(g_iWitchDamage2[iIndex], 1, 9999999999);
				g_flWitchRange2[iIndex] = kvSuperTanks.GetFloat("Witch Ability/Witch Range", g_flWitchRange[iIndex]);
				g_flWitchRange2[iIndex] = flClamp(g_flWitchRange2[iIndex], 1.0, 9999999999.0);
			}

			kvSuperTanks.Rewind();
		}
	}

	delete kvSuperTanks;
}

public void ST_Ability(int tank)
{
	int iWitchAbility = !g_bTankConfig[ST_TankType(tank)] ? g_iWitchAbility[ST_TankType(tank)] : g_iWitchAbility2[ST_TankType(tank)];
	if (iWitchAbility == 1 && ST_TankAllowed(tank) && ST_CloneAllowed(tank, g_bCloneInstalled) && IsPlayerAlive(tank))
	{
		int iWitchMessage = !g_bTankConfig[ST_TankType(tank)] ? g_iWitchMessage[ST_TankType(tank)] : g_iWitchMessage2[ST_TankType(tank)],
			iWitchCount, iInfected = -1;

		while ((iInfected = FindEntityByClassname(iInfected, "infected")) != INVALID_ENT_REFERENCE)
		{
			float flWitchRange = !g_bTankConfig[ST_TankType(tank)] ? g_flWitchRange[ST_TankType(tank)] : g_flWitchRange[ST_TankType(tank)];
			int iWitchAmount = !g_bTankConfig[ST_TankType(tank)] ? g_iWitchAmount[ST_TankType(tank)] : g_iWitchAmount2[ST_TankType(tank)];
			if (iWitchCount < 4 && iGetWitchCount() < iWitchAmount)
			{
				float flTankPos[3], flInfectedPos[3], flInfectedAng[3];
				GetClientAbsOrigin(tank, flTankPos);
				GetEntPropVector(iInfected, Prop_Send, "m_vecOrigin", flInfectedPos);
				GetEntPropVector(iInfected, Prop_Send, "m_angRotation", flInfectedAng);

				float flDistance = GetVectorDistance(flInfectedPos, flTankPos);
				if (flDistance <= flWitchRange)
				{
					RemoveEntity(iInfected);

					int iWitch = CreateEntityByName("witch");
					if (bIsValidEntity(iWitch))
					{
						TeleportEntity(iWitch, flInfectedPos, flInfectedAng, NULL_VECTOR);

						DispatchSpawn(iWitch);
						ActivateEntity(iWitch);
						SetEntProp(iWitch, Prop_Send, "m_hOwnerEntity", tank);

						iWitchCount++;
					}
				}
			}
		}

		if (iWitchMessage == 1)
		{
			char sTankName[MAX_NAME_LENGTH + 1];
			ST_TankName(tank, sTankName);
			PrintToChatAll("%s %t", ST_PREFIX2, "Witch", sTankName);
		}
	}
}