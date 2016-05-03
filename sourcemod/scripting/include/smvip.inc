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

#if defined _smvip_included
 #endinput
#endif
#define _smvip_included

/**
 * Returns if a client is vip.
 *
 * @param client		Player's index.
 * @return			True if client is vip, false otherwise.
 * @error			Invalid client index.
 */
native bool SMVIP_IsClientVip(int client);

/** 
 * Sets vip status on a client.
 *
 * @param client		Player's index.
 * @param set			True to set vip status, false otherwise.
 * @return			Previous vip state.
 * @error			Invalid client index.
 */
native bool SMVIP_SetClientVip(int client, bool set);

public SharedPlugin __pl_smvip = 
{
	name = "smvip",
	file = "smvip.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public void __pl_smvip_SetNTVOptional()
{
	MarkNativeAsOptional("SMVIP_IsClientVip");
	MarkNativeAsOptional("SMVIP_SetClientVip");
}
