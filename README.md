# SMVIP

## About
SMVIP is a plugin for SourceMod that give for specified players extra bonuses. It is developed under **General Public License version 3**.

## Supported games
- Counter-Strike: Global Offensive
- Counter-Strike: Source

## Features
- [x] vip prefix in chat (cvar)
- [x] weapon menu with own skins (cvar)
- [x] greetings when a vip comes to a server
- [x] dynamic motd
- [x] free taser (cvar)
- [x] additional hp at round start (cvar)
- [x] free defuser (cvar)
- [x] extra money at round start (cvar)
- [x] prints in chat who, currently on a server, has VIP status (command)
- [ ] multilingual
- [ ] vip models

## Requirements
- SourceMod 1.7 or newer (older may work, but they are not supported)
- WWW server

## Installation
##### index.html
- Replace "YOUR_WEB" with your web, f.e.
```javascript
window.open(currentlocation.replace("page http://example.com/vip_web/index.html?web=", ""), "_blank");
```
##### vip.sp
- Replace "YOUR_WEB" with your web, f.e.
```sourcepawn
char g_szUrlMotd[512] = { "http://example.com/vip_web/index.html?web=http://example.com/vip_web/vip.php?version=_version&armor=_armor&helmet=_helmet&money=_money&hp=_hp&def=_def&taser=_taser&menu=_menu&prefix=_prefix&res=_res" };
```
- Put vip_web folder on WWW server
- Compile vip.sp
- Put vip.sp into scripting folder
- Put vip.smx into plugins folder
- Run server and configure **cfg/sourcemod/vip.cfg**

## Authors and Contributors
Karol Szuster (@Ni3znajomy)

## Support or Contact
Having trouble with SMVIP? Contact karolsz9898@gmail.com or create an issue at GitHub.
