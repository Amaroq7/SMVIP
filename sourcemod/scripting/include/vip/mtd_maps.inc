/*
    This file is part of SMVIP.

    SMVIP is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SMVIP is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with SMVIP.  If not, see <http://www.gnu.org/licenses/>.
*/

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

	public int GetProp(PropType type, const char[] key, int size = 4, int element = 0)
	{
		return GetEntProp(this.index, type, key, size, element);
	}
	public void SetProp(PropType type, const char[] key, int value, int size = 4, int element = 0)
	{
		SetEntProp(this.index, type, key, value, size, element);
	}

	public bool IsValid()
	{
		return IsValidEntity(this.index);
	}
}

methodmap Edict < Entity
{
	public Edict(int index)
	{
		return view_as<Edict>(index);
	}

	public bool IsValid()
	{
		return IsValidEdict(this.index);
	}
	
	public void Remove()
	{
		RemoveEdict(this.index);
	}
}

methodmap Player < Edict
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

	#if !defined CSS_SUPPORT
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
	#endif
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

	property int flags
	{
		public get()
		{
			return GetUserFlagBits(this.index);
		}
	}

	property bool connected
	{
		public get()
		{
			return IsClientConnected(this.index);
		}
	}

	property bool in_game
	{
		public get()
		{
			return IsClientInGame(this.index);
		}
	}

	property bool alive
	{
		public get()
		{
			return IsPlayerAlive(this.index);
		}
	}

	property bool fake
	{
		public get()
		{
			return IsFakeClient(this.index);
		}
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

	public void PrintPluginInfoReplyToConsole()
	{
		if(GetCmdReplySource() != SM_REPLY_TO_CONSOLE)
			SetCmdReplySource(SM_REPLY_TO_CONSOLE);

		ReplyToCommand(this.index, "Plugin: %s\nWersja: %s\nAutor: %s\nStrona: %s\nPlugin skompilowany pod: %s\nLicencja: %s", szPlugin, szVersion, szAuthor, szURL, SOURCEMOD_VERSION, "GPLv3");
	}

	public void PrintChat(char[] text, any ...)
	{
		static char szText[192];
		
		SetGlobalTransTarget(this.index);
		VFormat(szText, sizeof(szText), text, 2);
		PrintToChat(this.index, "\x01[VIP] %s", szText);
	}

	public void VipUpdate()
	{
		this.vip = false;

		int iFlags = this.flags;

		if(iFlags)
		{
			static char szFlags[22];
			g_pFlags.GetString(szFlags, sizeof(szFlags));

			if((iFlags & ADMFLAG_ROOT) || (iFlags & ReadFlagString(szFlags)))
				this.vip = true;
		}

		int iIndex = g_adtVips.FindValue(this.index);

		if(this.vip && iIndex == -1)
			g_adtVips.Push(this.index);

		else if(!this.vip && iIndex != -1)
			g_adtVips.Erase(iIndex);
	}

	public void VIPMenu()
	{
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
		int iReqRounds = g_pRound.IntValue;

		if(iReqRounds <= 0 || g_iRound < iReqRounds)
			return;

		//Check if other menu disturbed player to choose weapon
		if(!this.disturbed)
			return;

		//If disturbed we set it to false
		this.disturbed = false;

		#if !defined CSS_SUPPORT
		//Check if buytime has expired
		if(g_bBuyTimeExpired)
		{
			this.PrintChat("\x01[VIP] \x02Czas kupowania minął!");
			return;
		}
		#endif
		//If everything's ok we show menu
		this.VIPMenu();
	}

	public void ShowMOTD(const char[] title, const char[] msg, int type = MOTDPANEL_TYPE_INDEX)
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

	public void PrintVips()
	{
		static char szText[192];
		static char szName[MAX_NAME_LENGTH];
		int iLen;
		Player client;

		iLen = strcopy(szText, sizeof(szText), "VIPy Online: ");

		int iLenArray = g_adtVips.Length;

		if(iLenArray)
		{
			for(int i=0; i<iLenArray; i++)
			{
				client = Player(g_adtVips.Get(i));
				client.GetName(szName, sizeof(szName));

				if(!(i+1 == iLenArray))
					iLen += FormatEx(szText[iLen], sizeof(szText)-iLen, "\x04%s\x01,", szName);
				else
					iLen += FormatEx(szText[iLen], sizeof(szText)-iLen, "\x04%s\x01.", szName);
			}
		}
		else
			strcopy(szText[iLen], sizeof(szText)-iLen, "\x02Brak VIPów Online\x01.");

		this.PrintChat(szText);
	}
};

