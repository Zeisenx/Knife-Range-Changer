
#include <sourcemod>
#include <dhooks>

public Plugin myinfo = 
{
	name = "Knife Range Changer",
	author = "Zeisen",
	version = "1.0.1",
	description = "",
	url = "http://steamcommunity.com/profiles/76561198002384750"
}

Handle g_detour;

Address g_addrSwingOrStab;

int g_primaryOffset;
int g_secondaryOffset;

ConVar g_cvPrimaryRange, g_cvSecondaryRange;

#define DEFAULT_PRIMARY_RANGE 48
#define DEFAULT_SECONDARY_RANGE 32

public void OnPluginStart()
{
	Handle gameConf = LoadGameConfigFile("knife_range_changer.games");
	if(gameConf == INVALID_HANDLE)
		SetFailState("Failed to load gamedata");
	
	g_addrSwingOrStab = GameConfGetAddress(gameConf, "SwingOrStab");
	
	if(!g_addrSwingOrStab)
		SetFailState("Failed to get CKnife::SwingOrStab address");
	
	g_primaryOffset = GameConfGetOffset(gameConf, "CKnife_ReachPrimary");
	g_secondaryOffset = GameConfGetOffset(gameConf, "CKnife_ReachSecondary");
	
	g_detour = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity);
	if (!g_detour)
		SetFailState("Failed to setup detour for CKnife::SwingOrStab");
	
	DHookAddParam(g_detour, HookParamType_Int);
	if (!DHookSetFromConf(g_detour, gameConf, SDKConf_Signature, "CKnife::SwingOrStab"))
		SetFailState("Failed to load CKnife::SwingOrStab signature from gamedata");
	
	if (!DHookEnableDetour(g_detour, false, Detour_OnSwingOrStab))
		SetFailState("Failed to detour CKnife::SwingOrStab.");
	
	char strBuffer[4];

	IntToString(DEFAULT_PRIMARY_RANGE, strBuffer, sizeof(strBuffer));
	g_cvPrimaryRange = CreateConVar("kniferange_primary", strBuffer);

	IntToString(DEFAULT_SECONDARY_RANGE, strBuffer, sizeof(strBuffer));
	g_cvSecondaryRange = CreateConVar("kniferange_secondary", strBuffer);

	delete gameConf;
}

public void OnPluginEnd()
{
	StoreToAddress(g_addrSwingOrStab+view_as<Address>(g_primaryOffset), DEFAULT_PRIMARY_RANGE, NumberType_Int32);
	StoreToAddress(g_addrSwingOrStab+view_as<Address>(g_secondaryOffset), DEFAULT_SECONDARY_RANGE, NumberType_Int32);
}

public MRESReturn Detour_OnSwingOrStab(int knife, Handle hParams)
{
	int owner = GetEntPropEnt(knife, Prop_Data, "m_hOwner");
	if (owner <= 0)
		return MRES_Ignored;
	
	int primaryRange = g_cvPrimaryRange.IntValue;
	int secondaryRange = g_cvSecondaryRange.IntValue;
	
	StoreToAddress(g_addrSwingOrStab+view_as<Address>(g_primaryOffset), primaryRange, NumberType_Int32);
	StoreToAddress(g_addrSwingOrStab+view_as<Address>(g_secondaryOffset), secondaryRange, NumberType_Int32);
	
	return MRES_Ignored;
}
