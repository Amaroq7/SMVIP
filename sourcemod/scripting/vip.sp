#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>

/* Pragmas */
#pragma semicolon 1		//Force to write a semi-colon at the end of a line
#pragma newdecls required	//Force new syntax
/* Pragmas End */

/* Plugin's info */
char szAuthor[] = "Ni3znajomy";
char szVersion[] = "0.1.9";
char szURL[] = "https://github.com/Ni3znajomy";
char szPlugin[] = "V.I.P.";
char szWebPluginVersion[] = "000109";

public Plugin myinfo = 
{
	name = szPlugin,
	description = "V.I.P.",
	author = szAuthor,
	version = szVersion,
	url = szURL
};
/* End Plugin's info */

/* Defines */
#define MAX_MONEY 16000			//Defines technical limit of money
#define PRIMARY_WEAPONS_COUNT 23	//Defines amount of primary weapons
#define SECONDARY_WEAPONS_COUNT 10	//Defines amount of secondary weapons
#define MAX_WEAPONS 63			//Property g_hMyWeapons
/* End Defines */

/* Global variables */
bool g_bIsVip[MAXPLAYERS+1];
bool g_bBuyTimeExpired;
bool g_bDisturbed[MAXPLAYERS+1];
bool g_bShowChangedTeamMsg[MAXPLAYERS+1];

int g_iPrimWeap[MAXPLAYERS+1];
int g_iSecWeap[MAXPLAYERS+1];
int g_iRound;

char g_szPrimaryWeapons[PRIMARY_WEAPONS_COUNT][] = { "Nova", "XM1014", "MAG-7", "Obrzyn", "MAC-10", "MP7", "MP9", "UMP-45", "PP-Bizon", "P90", "FAMAS", "M4A4", "M4A1-S", "Galil AR", "AK-47", "SSG 08", "SG 553", "AUG", "AWP", "G3SG1", "SCAR-20", "M249", "Negev" };
char g_szPrimaryWeaponsEngine[PRIMARY_WEAPONS_COUNT][] = { "weapon_nova", "weapon_xm1014", "weapon_mag7", "weapon_sawedoff", "weapon_mac10", "weapon_mp7", "weapon_mp9", "weapon_ump45", "weapon_bizon", "weapon_p90", "weapon_famas", "weapon_m4a1", "weapon_m4a1_silencer", "weapon_galilar", "weapon_ak47", "weapon_ssg08", "weapon_sg553", "weapon_aug", "weapon_awp", "weapon_g3sg1", "weapon_scar20", "weapon_m249", "weapon_negev" };
char g_szSecondaryWeapons[SECONDARY_WEAPONS_COUNT][] = { "Glock", "P2000", "P250", "USP-S", "Desert Deagle", "Five-SeveN", "Berretty", "Tec-9", "CZ75 Auto (CT)", "CZ75 Auto (TT)"};
char g_szSecondaryWeaponsEngine[SECONDARY_WEAPONS_COUNT][] = { "weapon_glock", "weapon_hkp2000", "weapon_p250", "weapon_usp_silencer", "weapon_deagle", "weapon_fiveseven", "weapon_elite", "weapon_tec9", "weapon_cz75a", "weapon_cz75a" };

int g_iTeamPrimaryWeapons[PRIMARY_WEAPONS_COUNT] = { 0, 0, CS_TEAM_CT, CS_TEAM_T, CS_TEAM_T, 0, CS_TEAM_CT, 0, 0, 0, CS_TEAM_CT, CS_TEAM_CT, CS_TEAM_CT, CS_TEAM_T, CS_TEAM_T, 0, CS_TEAM_T, CS_TEAM_CT, 0, CS_TEAM_T, CS_TEAM_CT, 0, 0 };

int g_iTeamSecondaryWeapons[SECONDARY_WEAPONS_COUNT] = { CS_TEAM_T, CS_TEAM_CT, 0, CS_TEAM_CT, 0, CS_TEAM_CT, CS_TEAM_T, CS_TEAM_T, CS_TEAM_CT, CS_TEAM_T };

char g_szUrlMotd[512] = { "http://YOUR_WEB/vip_web/index.html?web=http://YOUR_WEB/vip_web/vip.php?version=_version&armor=_armor&helmet=_helmet&money=_money&hp=_hp&def=_def&taser=_taser&menu=_menu&prefix=_prefix&res=_res" };

ConVar g_pMaxMoney;
ConVar g_pArmorValue;
ConVar g_pHelmet;
ConVar g_pMoney;
ConVar g_pAddHP;
ConVar g_pDefuser;
ConVar g_pTaser;
ConVar g_pRound;
ConVar g_pPrefix;
ConVar g_pTimer;
ConVar g_pReservation;
ConVar g_pFlag;

Menu g_hWeaponsMenuPrimary;
Menu g_hWeaponsMenuSecondary;
Panel g_hPlayerMenu;

Handle g_hPlayerPrim;
Handle g_hPlayerSec;

UserMsg g_hSayText2;
UserMsg g_hWarmupEnded;

bool g_bSayText2Hooked;

ArrayList g_adtVips;

/* End Global variables */

#include <vip/mtd_maps>

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	//If engine game is not csgo plugin won't load
	if(GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is not compatible with this Engine!");
		return APLRes_Failure;
	}

	CreateNative("IsClientVip", IsClientVip_native);

	return APLRes_Success;
}

public int IsClientVip_native(Handle plugin, int numParams)
{
	Player client = Player(GetNativeCell(1));

	if(1 <= client.index <= MaxClients)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Non-player index! (%i)", client.index);
		return 0;
	}
	
	return client.vip;
}

public void OnPluginStart()
{
	g_pMaxMoney = FindConVar("mp_maxmoney");

	g_pAddHP = CreateConVar("sm_vip_addhp", "5", "How many HP add to the player at spawn", FCVAR_PLUGIN, true, 0.0, false);
	g_pArmorValue = CreateConVar("sm_vip_armor", "100", "How many armor set to the player at spawn", FCVAR_PLUGIN, true, 0.0, false);
	g_pHelmet = CreateConVar("sm_vip_helmet", "1", "Sets the player the helmet", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_pMoney = CreateConVar("sm_vip_money", "300", "How much money give to the player at spawn", FCVAR_PLUGIN, true, 0.0, false);
	g_pDefuser = CreateConVar("sm_vip_defuser", "1", "Gives the defuser to the player", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_pTaser = CreateConVar("sm_vip_taser", "1", "Gives the taser (zeus) to the player", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_pRound = CreateConVar("sm_vip_menu_round", "3", "Specifies from which round vip menu is enabled", FCVAR_PLUGIN, true, 0.0, false);
	g_pPrefix = CreateConVar("sm_vip_prefix", "1", "Enables vip prefix in chat", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_pTimer = CreateConVar("sm_vip_msg", "60", "Time in seconds when the info is displayed to the players", FCVAR_PLUGIN, true, 0.0, false);
	g_pReservation = CreateConVar("sm_vip_reservation", "1", "Defines that vip has a reservation slot (info only for motd)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_pFlag = CreateConVar("sm_vip_flag", "t", "Defines flag for VIP privileges", FCVAR_NONE);

	AutoExecConfig(true, "vip");

	g_pAddHP.AddChangeHook(ConChanged);
	g_pArmorValue.AddChangeHook(ConChanged);
	g_pHelmet.AddChangeHook(ConChanged);
	g_pMoney.AddChangeHook(ConChanged);
	g_pDefuser.AddChangeHook(ConChanged);
	g_pTaser.AddChangeHook(ConChanged);
	g_pRound.AddChangeHook(ConChanged);
	g_pPrefix.AddChangeHook(ConChanged);
	g_pReservation.AddChangeHook(ConChanged);
	g_pFlags.AddChangeHook(ConChanged);

	g_hPlayerPrim = RegClientCookie("weapon_prim_vip", "Player weapon primary", CookieAccess_Protected);
	g_hPlayerSec = RegClientCookie("weapon_sec_vip", "Player weapon secondary", CookieAccess_Protected);

	HookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy);
	HookEvent("cs_match_end_restart", EndRestartMatch, EventHookMode_PostNoCopy);
	HookEvent("announce_phase_end", EndRestartMatch, EventHookMode_PostNoCopy);
	HookEvent("buytime_ended", BuyTime_Ended, EventHookMode_PostNoCopy);
	HookEvent("cs_intermission", EndRestartMatch, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
	HookEvent("player_team", PlayerTeamEvent, EventHookMode_Pre);

	RegConsoleCmd("sm_vip_info", VipInfoConsole, "Prints info about VIP plugin");
	RegConsoleCmd("vip", ShowVipInfo, "Shows MOTD about VIP");
	RegConsoleCmd("vips", ShowVipsOnServer, "Shows VIPs on server");
	RegAdminCmd("menuv", ReopenVipMenu, ADMFLAG_CUSTOM6, "Reopens vip menu");

	g_adtVips = new ArrayList(1);

	//VIP prefix
	g_hSayText2 = GetUserMessageId("SayText2");

	g_hWarmupEnded = GetUserMessageId("WarmupHasEnded");
	HookUserMessage(g_hWarmupEnded, WarmupEnded_Hook, false);
}

public Action PlayerTeamEvent(Event event, const char[] name, bool dontBroadcast)
{
	Player client = Player(GetClientOfUserId(event.GetInt("userid")));

	if(client.vip && client.not_changed_team)
		event.BroadcastDisabled = true;

	return Plugin_Continue;
}

public void ConChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar != g_pFlags)
	{
		static char szName[10];
	
		if(convar == g_pAddHP)
		{
			strcopy(szName, sizeof(szName), "hp");
		}
		else if(convar == g_pArmorValue)
		{
			strcopy(szName, sizeof(szName), "armor");
		}
		else if(convar == g_pHelmet)
		{
			strcopy(szName, sizeof(szName), "helmet");
		}
		else if(convar == g_pMoney)
		{
			strcopy(szName, sizeof(szName), "money");
		}
		else if(convar == g_pDefuser)
		{
			strcopy(szName, sizeof(szName), "def");
		}
		else if(convar == g_pTaser)
		{
			strcopy(szName, sizeof(szName), "taser");
		}
		else if(convar == g_pRound)
		{
			strcopy(szName, sizeof(szName), "menu");
		}
		else if(convar == g_pPrefix)
		{
			strcopy(szName, sizeof(szName), "prefix");
			int iNewValue = StringToInt(newValue);
			//int iOldValue = StringToInt(oldValue);
			if(iNewValue == 1)
			{	
				if(!g_bSayText2Hooked)
				{
					HookUserMessage(g_hSayText2, SayText2_Hook, true);
					g_bSayText2Hooked = true;
				}
			}
			else
			{
				UnhookUserMessage(g_hSayText2, SayText2_Hook, true);
				g_bSayText2Hooked = false;
			}
		}
		else if(convar == g_pReservation)
		{
			strcopy(szName, sizeof(szName), "res");
		}
		
		BuildUrl(szName, oldValue, newValue, convar);
	}
	else
	{
		static bool bOverrided;
		if(bOverrided)
		{
			UnsetCommandOverride("menuv", Override_Command);
			AddCommandOverride("menuv", Override_Command, ReadFlagString(newValue));
		}
		else
		{
			AddCommandOverride("menuv", Override_Command, ReadFlagString(newValue));
			bOverrided = true;
		}
	}
}

public void BuildUrl(const char[] unique_name, const char[] oldValue, const char[] newValue, ConVar changed)
{
	//g_szUrlMotd[] = { "http://localhost/vip.php?version=_version&armor=_armor&helmet=_helmet&money=_money&hp=_hp&def=_def&taser=_taser&menu=_menu&prefix=_prefix&res=_res" };
	
	if(changed == null)
	{
		char szTemp[8];
		char szKey[10][] = { "_version", "_armor", "_helmet", "_money", "_hp", "_def", "_taser", "_menu", "_prefix", "_res" };

		int pos;

		//Version
		ReplaceString(g_szUrlMotd, sizeof(g_szUrlMotd), szKey[pos++], szWebPluginVersion);

		//Armor
		IntToString(g_pArmorValue.IntValue, szTemp, sizeof(szTemp));
		ReplaceString(g_szUrlMotd, sizeof(g_szUrlMotd), szKey[pos++], szTemp);

		//Helmet
		IntToString(g_pHelmet.BoolValue, szTemp, sizeof(szTemp));
		ReplaceString(g_szUrlMotd, sizeof(g_szUrlMotd), szKey[pos++], szTemp);

		//Money
		IntToString(g_pMoney.IntValue, szTemp, sizeof(szTemp));
		ReplaceString(g_szUrlMotd, sizeof(g_szUrlMotd), szKey[pos++], szTemp);

		//HP
		IntToString(g_pAddHP.IntValue, szTemp, sizeof(szTemp));
		ReplaceString(g_szUrlMotd, sizeof(g_szUrlMotd), szKey[pos++], szTemp);

		//Defuser
		IntToString(g_pDefuser.BoolValue, szTemp, sizeof(szTemp));
		ReplaceString(g_szUrlMotd, sizeof(g_szUrlMotd), szKey[pos++], szTemp);

		//Taser
		IntToString(g_pTaser.BoolValue, szTemp, sizeof(szTemp));
		ReplaceString(g_szUrlMotd, sizeof(g_szUrlMotd), szKey[pos++], szTemp);

		//Menu
		IntToString(g_pRound.IntValue, szTemp, sizeof(szTemp));
		ReplaceString(g_szUrlMotd, sizeof(g_szUrlMotd), szKey[pos++], szTemp);

		//Prefix
		IntToString(g_pPrefix.BoolValue, szTemp, sizeof(szTemp));
		ReplaceString(g_szUrlMotd, sizeof(g_szUrlMotd), szKey[pos++], szTemp);

		//Reservation
		IntToString(g_pReservation.BoolValue, szTemp, sizeof(szTemp));
		ReplaceString(g_szUrlMotd, sizeof(g_szUrlMotd), szKey[pos++], szTemp);
	}
	else
	{
		static char szTemp[20], szTemp2[20];
		FormatEx(szTemp, sizeof(szTemp), "%s=%s", unique_name, oldValue);
		FormatEx(szTemp2, sizeof(szTemp2), "%s=%s", unique_name, newValue);
		ReplaceString(g_szUrlMotd, sizeof(g_szUrlMotd), szTemp, szTemp2);
	}
}

public Action WarmupEnded_Hook(UserMsg msg_id, Protobuf msg, const int[] players, int playersNum, bool reliable, bool init)
{
	g_iRound = 0;

	return Plugin_Continue;
}

public Action SayText2_Hook(UserMsg msg_id, Protobuf msg, const int[] players, int playersNum, bool reliable, bool init)
{
	Player client = Player(msg.ReadInt("ent_idx"));

	//VIP prefix
	if(client.vip)
	{
		static char szTemp[128];
		msg.ReadString("params", szTemp, sizeof(szTemp), 0);
		Format(szTemp, sizeof(szTemp), "[VIP] %s", szTemp);
		msg.SetString("params", szTemp, 0);
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

//Info about plugin in console
public Action VipInfoConsole(int client, int args)
{
	Player player_client = Player(client);
	player_client.PrintPluginInfoReplyToConsole();
	
	return Plugin_Handled;
}

public Action ShowVipInfo(int client, int args)
{
	Player player_client = Player(client);

	player_client.ShowMOTD("Informacje o VIP", g_szUrlMotd, MOTDPANEL_TYPE_URL);
	return Plugin_Handled;
}

public Action ReopenVipMenu(int client, int args)
{
	Player player_client = Player(client);

	player_client.OpenMenuCmd();
	return Plugin_Handled;
}

public Action ShowVipsOnServer(int client, int args)
{
	Player player_client = Player(client);
	
	player_client.PrintVips();
	return Plugin_Handled;
}

public void BuyTime_Ended(Event event, const char[] name, bool dontBroadcast)
{
	g_bBuyTimeExpired = true;
}

public void EndRestartMatch(Event event, const char[] name, bool dontBroadcast)
{
	g_iRound = 0;
}

public void OnConfigsExecuted()
{
	g_hWeaponsMenuPrimary = new Menu(WeaponsHandlerPrimary);
	g_hWeaponsMenuSecondary = new Menu(WeaponsHandlerSecondary);
	
	for(int i=0; i<PRIMARY_WEAPONS_COUNT; i++)
		g_hWeaponsMenuPrimary.AddItem(g_szPrimaryWeapons[i], g_szPrimaryWeapons[i]);

	for(int i=0; i<SECONDARY_WEAPONS_COUNT; i++)
		g_hWeaponsMenuSecondary.AddItem(g_szSecondaryWeapons[i], g_szSecondaryWeapons[i]);

	g_hWeaponsMenuPrimary.SetTitle("Bronie podstawowe");
	g_hWeaponsMenuSecondary.SetTitle("Bronie drugorzędne");
	g_hWeaponsMenuPrimary.ExitBackButton = true;
	g_hWeaponsMenuSecondary.ExitBackButton = true;
	g_hWeaponsMenuPrimary.ExitButton = false;
	g_hWeaponsMenuSecondary.ExitButton = false;

	BuildUrl("", "", "", null);

	if(g_pPrefix.BoolValue && !g_bSayText2Hooked)
	{
		HookUserMessage(g_hSayText2, SayText2_Hook, true);
		g_bSayText2Hooked = true;
	}

	CreateTimer(g_pTimer.FloatValue, TimerVipInfo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action TimerVipInfo(Handle timer)
{
	PrintChatAll("\x01[VIP]\x04 Chcesz wiedzieć co posiada vip? Napisz na chacie \x02/vip\x04 lub \x02!vip\x03.");
}

//Load client's preferences
public void OnClientCookiesCached(int client)
{
	Player client_pl = Player(client);

	static char szOption[3];

	client_pl.GetCookie(g_hPlayerPrim, szOption, sizeof(szOption));
	client_pl.primary_weapon = StringToInt(szOption);

	client_pl.GetCookie(g_hPlayerSec, szOption, sizeof(szOption));
	client_pl.secondary_weapon = StringToInt(szOption);
}

public int WeaponsHandlerPrimary(Menu menu, MenuAction action, int param1, int param2)
{
	Player client = Player(param1);
	if(action == MenuAction_Select)
	{
		if(g_bBuyTimeExpired)
		{
			client.PrintChat("\x01[VIP] \x02Czas kupowania minął!");
			return;
		}
		client.primary_weapon = param2;

		static char szOption[3];
		IntToString(param2, szOption, sizeof(szOption));
		
		client.SetCookie(g_hPlayerPrim, szOption);
		client.VIPMenu();
	}
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
			client.VIPMenu();

		else if(param2 == MenuCancel_Interrupted)
		{
			//Check if buytime has expired
			if(g_bBuyTimeExpired)
			{
				client.PrintChat("\x01[VIP] \x02Czas kupowania minął!");
				return;
			}
			client.PrintChat("\x01[VIP] \x04Żeby włączyć ponownie menu VIPa napisz \x02/menuv\x04 lub \x02!menuv\x04.");
			client.disturbed = true;
		}
	}
}

public int WeaponsHandlerSecondary(Menu menu, MenuAction action, int param1, int param2)
{
	Player client = Player(param1);

	if(action == MenuAction_Select)
	{
		if(g_bBuyTimeExpired)
		{
			client.PrintChat("\x01[VIP] \x02Czas kupowania minął!");
			return;
		}
		client.secondary_weapon = param2;

		static char szOption[3];
		IntToString(param2, szOption, sizeof(szOption));
		
		client.SetCookie(g_hPlayerSec, szOption);

		client.VIPMenu();
	}
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
			client.VIPMenu();

		else if(param2 == MenuCancel_Interrupted)
		{
			//Check if buytime has expired
			if(g_bBuyTimeExpired)
			{
				client.PrintChat("\x01[VIP] \x02Czas kupowania minął!");
				return;
			}
			client.PrintChat("\x01[VIP] \x04Żeby włączyć ponownie menu VIPa napisz \x02/menuv\x04 lub \x02!menuv\x04.");
			client.disturbed = true;
		}
	}
}

public void RoundStartEvent(Event event, const char[] name, bool dontBroadcast)
{
	++g_iRound;
	g_bBuyTimeExpired = false;

	for(int i=1; i <= MaxClients; i++)
	{
		Player client = Player(i);
		if(client.connected)
			client.VipUpdate();
	}
}

public int PlayerMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	Player client = Player(param1);

	if(!client.in_game)
		return;
	
	if(action == MenuAction_Select && client.alive)
	{
		if(g_bBuyTimeExpired)
		{
			client.PrintChat("\x01[VIP] \x02Czas kupowania minął!");
			return;
		}
		if(param2 == 1)
		{
			g_hWeaponsMenuPrimary.Display(client.index, MENU_TIME_FOREVER);
		}
		else if(param2 == 2)
		{
			g_hWeaponsMenuSecondary.Display(client.index, MENU_TIME_FOREVER);
		}
		else if(param2 == 5)
		{
			client.not_changed_team = true;
			int iWeapon;
			if((iWeapon = client.GetWeaponInSlot(CS_SLOT_PRIMARY)) != -1)
				client.RemoveItem(iWeapon);

			if((iWeapon = client.GetWeaponInSlot(CS_SLOT_SECONDARY)) != -1)
				client.RemoveItem(iWeapon);

			int iTeam = client.team;

			if(g_iTeamPrimaryWeapons[client.primary_weapon])
				client.team = g_iTeamPrimaryWeapons[client.primary_weapon];

			client.GiveItem(g_szPrimaryWeaponsEngine[client.primary_weapon]);

			if(g_iTeamSecondaryWeapons[client.secondary_weapon])
				client.team = g_iTeamSecondaryWeapons[client.secondary_weapon];

			client.GiveItem(g_szSecondaryWeaponsEngine[client.secondary_weapon]);

			client.team = iTeam;
			
			client.not_changed_team = false;

			if(client.team == CS_TEAM_CT)
				client.SetProp(Prop_Send, "m_bHasDefuser", g_pDefuser.BoolValue);

			//int iUSP = GetEntProp(iWeapon, Prop_Send, "m_bSilencerOn", 1);
		}
		else if(param2 == 9)
		{
			//Player exited menu
			//Nothing here
		}
	}
	else if(action == MenuAction_Cancel && param2 == MenuCancel_Interrupted)
	{
		//Check if buytime has expired
		if(g_bBuyTimeExpired)
		{
			client.PrintChat("\x01[VIP] \x02Czas kupowania minął!");
			return;
		}
		client.PrintChat("\x01[VIP] \x04Żeby włączyć ponownie menu VIPa napisz \x02/menuv\x04 lub \x02!menuv\x04.");
		client.disturbed = true;
	}
}

public void OnClientPostAdminCheck(int client)
{
	Player client_pl = Player(client);

	if(!client_pl.fake && client_pl.connected)
	{
		client_pl.VipUpdate();
		if(!client_pl.vip)
			return;
		
		static char szName[MAX_NAME_LENGTH];
		client_pl.GetName(szName, sizeof(szName));
		client_pl.vip = true;
		PrintChatAll("\x01[VIP]\x01 Na serwer wbił VIP\x10 %s\x01.", szName);
	}
}

public void OnClientDisconnect(int client)
{
	Player client_pl = Player(client);
	if(client_pl.vip)
	{
		client_pl.vip = false;
		client_pl.disturbed = false;
	}
}

public void PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	Player client_pl = Player(GetClientOfUserId(event.GetInt("userid")));
	if(client_pl.vip && client_pl.alive)
	{
		client_pl.SetProp(Prop_Send, "m_iHealth", client_pl.GetProp(Prop_Send, "m_iHealth")+g_pAddHP.IntValue);

		if(g_pArmorValue.IntValue)
		{
			client_pl.SetProp(Prop_Send, "m_ArmorValue", g_pArmorValue.IntValue);
			
			if(g_pHelmet.BoolValue)
				client_pl.SetProp(Prop_Send, "m_bHasHelmet", g_pHelmet.BoolValue);
		}

		int iMoney = client_pl.GetProp(Prop_Send, "m_iAccount");
		int iMaxMoney = (g_pMaxMoney == null) ? MAX_MONEY : g_pMaxMoney.IntValue;
		int iAddMoney = g_pMoney.IntValue;
		
		client_pl.SetProp(Prop_Send, "m_iAccount", (iMoney+iAddMoney >= iMaxMoney) ? iMaxMoney : iMoney+iAddMoney);
		
		if(client_pl.team == CS_TEAM_CT)
			client_pl.SetProp(Prop_Send, "m_bHasDefuser", g_pDefuser.BoolValue);

		if(g_pTaser.BoolValue)
			client_pl.GiveItem("weapon_taser");

		if(g_iRound >= g_pRound.IntValue)
			client_pl.VIPMenu();
	}
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	if(reason == CSRoundEnd_GameStart)
	{
		g_bBuyTimeExpired = false;
		g_iRound = 0;
	}
	return Plugin_Continue;
}

public void PrintChatAll(char[] text, any ...)
{
	static char szText[192];
	Player client;

	for(int i=1; i<=MaxClients; i++)
	{	
		if(!IsClientInGame(i))
			continue;

		SetGlobalTransTarget(i);
		VFormat(szText, sizeof(szText), text, 2);

		client = Player(i);
		client.PrintChat(szText);
	}
}

public void OnPluginEnd()
{
	delete g_hWeaponsMenuPrimary;
	delete g_hWeaponsMenuSecondary;
	delete g_hPlayerPrim;
	delete g_hPlayerSec;

	if(g_bSayText2Hooked)
	{
		UnhookUserMessage(g_hSayText2, SayText2_Hook, true);
		g_bSayText2Hooked = false;
	}

	UnhookUserMessage(g_hWarmupEnded, WarmupEnded_Hook, false);

	UnhookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy);
	UnhookEvent("cs_match_end_restart", EndRestartMatch, EventHookMode_PostNoCopy);
	UnhookEvent("announce_phase_end", EndRestartMatch, EventHookMode_PostNoCopy);
	UnhookEvent("buytime_ended", BuyTime_Ended, EventHookMode_PostNoCopy);
	UnhookEvent("cs_intermission", EndRestartMatch, EventHookMode_PostNoCopy);
	UnhookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
	UnhookEvent("player_team", PlayerTeamEvent, EventHookMode_Pre);
}
