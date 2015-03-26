#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <clientprefs>

/* Pragmas */
#pragma semicolon 1		//Force to write a semi-colon at the end of a line
#pragma newdecls required	//Force new syntax
/* Pragmas End */

/* Plugin's info */
char szAuthor[] = "Ni3znajomy";
char szVersion[] = "0.1.8";
char szURL[] = "https://github.com/Ni3znajomy";
char szPlugin[] = "V.I.P.";
char szWebPluginVersion[] = "000108";

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
bool g_bIsVip[MAXPLAYERS];
bool g_bBuyTimeExpired;
bool g_bDisturbed[MAXPLAYERS];
bool g_bShowChangedTeamMsg[MAXPLAYERS];

int g_iPrimWeap[MAXPLAYERS];
int g_iSecWeap[MAXPLAYERS];
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

Menu g_hWeaponsMenuPrimary;
Menu g_hWeaponsMenuSecondary;
Panel g_hPlayerMenu;

Handle g_hPlayerPrim;
Handle g_hPlayerSec;

UserMsg g_hSayText2;
UserMsg g_hWarmupEnded;

bool g_bSayText2Hooked;

/* End Global variables */

/* Enums */
enum
{
	TextInterrupted = 0,
	TextBuyTimeExp
}
/* End Enums */

methodmap Entity
{
	property int index
	{
		public get()
		{
			return view_as<int>(this);
		}
	}

	public Entity(int index)
	{
		return view_as<Entity>(index);
	}

	public void sdk_hook(SDKHookType type, SDKHookCB callback)
	{
		SDKHook(this.index, type, callback);
	}
	
	public void sdk_unhook(SDKHookType type, SDKHookCB callback)
	{
		SDKUnhook(this.index, type, callback);
	}

	public int GetProp(PropType type, const char[] key, int size = 4, int element = 0)
	{
		return GetEntProp(this.index, type, key, size, element);
	}
	public void SetProp(PropType type, const char[] key, int value, int size = 4, int element = 0)
	{
		SetEntProp(this.index, type, key, value, size, element);
	}

	public bool IsValidEd()
	{
		return IsValidEdict(this.index);
	}
}

methodmap Player < Entity
{
	public Player(int index)
	{
		return view_as<Player>(index);
	}

	//public ~Player() {};

	property bool vip
	{
		public get()
		{
			return g_bIsVip[this.index];
		}
		public set(bool status)
		{
			g_bIsVip[this.index] = status;
		}
	}

	property AdminId adminid
	{
		public get()
		{
			return GetUserAdmin(this.index);
		}
	}

	property bool disturbed
	{
		public get()
		{
			return g_bDisturbed[this.index];
		}
		public set(bool status)
		{
			g_bDisturbed[this.index] = status;
		}
	}

	property int primary_weapon
	{
		public get()
		{
			return g_iPrimWeap[this.index];
		}
		public set(int weapon)
		{
			g_iPrimWeap[this.index] = weapon;
		}
	}
	
	property int secondary_weapon
	{
		public get()
		{
			return g_iSecWeap[this.index];
		}
		public set(int weapon)
		{
			g_iSecWeap[this.index] = weapon;
		}
	}

	property bool not_changed_team
	{
		public get()
		{
			return g_bShowChangedTeamMsg[this.index];
		}
		public set(bool state)
		{
			g_bShowChangedTeamMsg[this.index] = state;
		}
	}

	property int team
	{
		public get()
		{
			return GetClientTeam(this.index);
		}
		public set(int team)
		{
			CS_SwitchTeam(this.index, team);
		}
	}

	public int IsConnected()
	{
		return IsClientInGame(this.index);
	}

	public int IsAlive()
	{
		return IsPlayerAlive(this.index);
	}

	public int IsFake()
	{
		return IsFakeClient(this.index);
	}

	public bool GetName(char[] name, int maxlen)
	{
		return GetClientName(this.index, name, maxlen);
	}

	public int GetWeaponInSlot(int slot)
	{
		return GetPlayerWeaponSlot(this.index, slot);
	}

	public bool RemoveItem(int item)
	{
		return RemovePlayerItem(this.index, item);
	}

	public int GiveItem(const char[] item)
	{
		return GivePlayerItem(this.index, item);
	}

	public void GetCookie(Handle cookie, char[] buffer, int maxlen)
	{
		GetClientCookie(this.index, cookie, buffer, maxlen);
	}
	
	public void SetCookie(Handle cookie, const char[] value)
	{
		SetClientCookie(this.index, cookie, value);
	}

	public void PrintChatPluginInfo()
	{
		PrintToChat(this.index, "\x01[VIP] \x04Plugin\x02 %s \x04stworzony przez\x02 %s\x04. Obecna wersja \x02 %s\x04.", szPlugin, szAuthor, szVersion);
	}
	public void PrintPluginInfoReplyToConsole()
	{
		if(GetCmdReplySource() != SM_REPLY_TO_CONSOLE)
			SetCmdReplySource(SM_REPLY_TO_CONSOLE);

		ReplyToCommand(this.index, "Plugin: %s\nWersja: %s\nAutor: %s\nStrona: %s\nPlugin skompilowany pod: %s\nLicencja: %s", szPlugin, szVersion, szAuthor, szURL, SOURCEMOD_VERSION, "GPLv3");
	}
	public void InfoChat(int type)
	{
		switch(type)
		{
			case 0: PrintToChat(this.index, "\x01[VIP] \x04Żeby włączyć ponownie menu VIPa napisz \x02/menuv\x04 lub \x02!menuv\x04.");
			case 1: PrintToChat(this.index, "\x01[VIP] \x02Czas kupowania minął!");
		}
	}
	public void VipUpdate()
	{
		this.vip = true;

		if(this.adminid == INVALID_ADMIN_ID)
			this.vip = false;

		if(!GetAdminFlag(this.adminid, Admin_Custom6, Access_Effective))
			this.vip = false;
	}

	public void VIPMenu()
	{
		if(!g_pRound.IntValue)
			return;

		g_hPlayerMenu = new Panel();
	
		g_hPlayerMenu.SetTitle("Menu VIP");
		g_hPlayerMenu.DrawItem("", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		g_hPlayerMenu.DrawText("Broń podstawowa");
		g_hPlayerMenu.DrawItem(g_szPrimaryWeapons[g_iPrimWeap[this.index]]);
		g_hPlayerMenu.DrawItem("", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		g_hPlayerMenu.DrawText("Broń drugorzędna");
		g_hPlayerMenu.DrawItem(g_szSecondaryWeapons[g_iSecWeap[this.index]]);

		g_hPlayerMenu.DrawItem("", ITEMDRAW_NOTEXT|ITEMDRAW_SPACER);
		g_hPlayerMenu.DrawItem("", ITEMDRAW_NOTEXT|ITEMDRAW_SPACER);

		g_hPlayerMenu.DrawItem("Weź bronie");

		g_hPlayerMenu.DrawItem("", ITEMDRAW_NOTEXT|ITEMDRAW_SPACER);
		g_hPlayerMenu.DrawItem("", ITEMDRAW_NOTEXT|ITEMDRAW_SPACER);
		g_hPlayerMenu.DrawItem("", ITEMDRAW_NOTEXT|ITEMDRAW_SPACER);

		g_hPlayerMenu.DrawItem("Wyjdź");

		g_hPlayerMenu.SetKeys((1<<0)|(1<<1)|(1<<4)|(1<<8));

		g_hPlayerMenu.Send(this.index, PlayerMenuHandler, MENU_TIME_FOREVER);

		delete g_hPlayerMenu;
	}

	public void OpenMenuCmd()
	{
		//Check if other menu disturbed player to choose weapon
		if(!this.disturbed)
			return;

		//If disturbed we set it to false
		this.disturbed = false;

		//Check if buytime has expired
		if(g_bBuyTimeExpired)
		{
			this.InfoChat(TextBuyTimeExp);
			return;
		}
		//If everything's ok we show menu
		this.VIPMenu();
	}

	public void ShowMOTD(const char[] title, const char[] msg, int type=MOTDPANEL_TYPE_INDEX)
	{
		char szNum[3];
		IntToString(type, szNum, sizeof(szNum));

		KeyValues kv = new KeyValues("data");
		kv.SetString("title", title);
		kv.SetString("type", szNum);
		kv.SetString("msg", msg);
		ShowVGUIPanel(this.index, "info", kv);
		delete kv;
	}
};

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

	g_hPlayerPrim = RegClientCookie("weapon_prim_vip", "Player weapon primary", CookieAccess_Protected);
	g_hPlayerSec = RegClientCookie("weapon_sec_vip", "Player weapon secondary", CookieAccess_Protected);

	HookEvent("round_start", RoundStartEvent, EventHookMode_Post);
	HookEvent("cs_match_end_restart", EndRestartMatch, EventHookMode_Post);
	HookEvent("announce_phase_end", EndRestartMatch, EventHookMode_Post);
	HookEvent("buytime_ended", BuyTime_Ended, EventHookMode_Post);
	HookEvent("cs_intermission", EndRestartMatch, EventHookMode_Post);
	HookEvent("player_team", PlayerTeamEvent, EventHookMode_Pre);

	RegConsoleCmd("sm_vip_info", VipInfoConsole, "Prints info about VIP plugin");

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

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(sArgs[0] == '/' || sArgs[0] == '!')
	{
		Player player_client = Player(client);
		//Info about plugin in chat
		if(!strcmp(sArgs[1], "vip_release", false))
		{
			player_client.PrintChatPluginInfo();
			return Plugin_Handled;
		}
		//Re-enable vip menu
		else if(!strcmp(sArgs[1], "menuv", false) && g_iRound >= g_pRound.IntValue)
		{
			player_client.OpenMenuCmd();
			return Plugin_Handled;
		}

		else if(!strcmp(sArgs[1], "vip", false))
		{
			player_client.ShowMOTD("Informacje o VIP", g_szUrlMotd, MOTDPANEL_TYPE_URL);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
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
	PrintToChatAll("\x01[VIP]\x04 Chcesz wiedzieć co posiada vip? Napisz na chacie \x02/vip\x04 lub \x02!vip\x03.");
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
			client.InfoChat(TextBuyTimeExp);
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
				client.InfoChat(TextBuyTimeExp);
				return;
			}
			client.InfoChat(TextInterrupted);
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
			client.InfoChat(TextBuyTimeExp);
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
				client.InfoChat(TextBuyTimeExp);
				return;
			}
			client.InfoChat(TextInterrupted);
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
		if(client.IsConnected() && client.IsAlive())
		{
			client.VipUpdate();
			if(client.vip && g_iRound >= g_pRound.IntValue)
				client.VIPMenu();
		}
	}
}

public int PlayerMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	Player client = Player(param1);

	if(!client.IsConnected())
		return;
	
	if(action == MenuAction_Select && client.IsAlive())
	{
		if(g_bBuyTimeExpired)
		{
			client.InfoChat(TextBuyTimeExp);
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

			if(client_pl.team == CS_TEAM_CT)
				client_pl.SetProp(Prop_Send, "m_bHasDefuser", g_pDefuser.BoolValue);

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
			client.InfoChat(TextBuyTimeExp);
			return;
		}
		client.InfoChat(TextInterrupted);
		client.disturbed = true;
	}
}

public void OnClientPostAdminCheck(int client)
{
	Player client_pl = Player(client);

	if(!client_pl.IsFake() && client_pl.IsConnected())
	{
		client_pl.VipUpdate();
		if(!client_pl.vip)
			return;
			
		client_pl.sdk_hook(SDKHook_SpawnPost, OnPlayerSpawnPost);
			
		static char szName[MAX_NAME_LENGTH];
		client_pl.GetName(szName, sizeof(szName));
		client_pl.vip = true;
		PrintToChatAll("\x01[VIP]\x01 Na serwer wbil VIP\x10 %s\x01.", szName);
	}
}

public void OnClientDisconnect(int client)
{
	Player client_pl = Player(client);
	if(client_pl.vip)
	{
		client_pl.sdk_unhook(SDKHook_SpawnPost, OnPlayerSpawnPost);
		client_pl.vip = false;
		client_pl.disturbed = false;
	}
}

public void OnPlayerSpawnPost(int client)
{
	Player client_pl = Player(client);
	if(client_pl.vip && client_pl.IsAlive())
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

	UnhookEvent("round_start", RoundStartEvent, EventHookMode_Post);
	UnhookEvent("cs_match_end_restart", EndRestartMatch, EventHookMode_Post);
	UnhookEvent("announce_phase_end", EndRestartMatch, EventHookMode_Post);
	UnhookEvent("buytime_ended", BuyTime_Ended, EventHookMode_Post);
	UnhookEvent("cs_intermission", EndRestartMatch, EventHookMode_Post);
}
