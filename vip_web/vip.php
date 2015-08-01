<?php
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

$version = $_GET['version'];
$armor = $_GET['armor'];
$helmet = $_GET['helmet'];
$money = $_GET['money'];
$hp = $_GET['hp'];
$def = $_GET['def'];
$menu = $_GET['menu'];
$prefix = $_GET['prefix'];

//added as of 0.1.4
$reservation = NULL;

if(isset($_GET['res'])) //(backwards compatibility)
{
	$reservation = $_GET['res'];
}
//0.1.4

$taser = NULL;

//CSS does not have a taser
if(isset($_GET['taser']))
{
	$taser = $_GET['taser'];
}

$css_styles = '<style type="text/css">body {background-color: #000000;} h1 {text-align: center; vertical-align: top; color: yellow; font-size: 25px; font-family: arial; font-weight: bold;} h2 {text-align: center; vertical-align: top; color: yellow; font-size: 15px; font-family: arial;} p2 {text-align:center; color: red; font-size: 9px; font-weight: bold;} a:link {color:green; background-color:transparent; text-decoration:none} a:visited {color:green; background-color:transparent; text-decoration:none} a:hover {color:green; background-color:transparent; text-decoration:underline} num {color: red}</style>';

$html_header = '<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Informacje o VIP</title>'.$css_styles.'</head>';

$html_title = '<body><h1>Informacje o VIP</h1><br /><br />';

$armor_text = NULL;
$money_text = NULL;
$hp_text = NULL;
$def_text = NULL;
$taser_text = NULL;
$menu_text = NULL;
$prefix_text = NULL;

//added as of 0.1.4
$reservation_text = NULL;
//0.1.4

//Version MjMjMnMnRlRl
function decode_plugin_version($ver)
{
	$version_array = str_split($ver, 2);

	$major = $version_array[0];
	$minor = $version_array[1];
	$release = $version_array[2];

	return (int)$major.'.'.(int)$minor.'.'.(int)$release;
}

$number = 0;

if($armor)
{
	if($helmet)
	{
		$armor_text = '<h2><num>'.++$number.'.</num> Dostaje '.$armor.' armora na początku rundy i hełm.</h2><br />';
	}
	else
	{
		$armor_text = '<h2><num>'.++$number.'.</num> Dostaje '.$armor.' armora na początku rundy.</h2><br />';
	}
}
if($money)
{
	$money_text = '<h2><num>'.++$number.'.</num> Dostaje '.$money.' pieniędzy na początku rundy.</h2><br />';
}
if($hp)
{
	$hp_text = '<h2><num>'.++$number.'.</num> Dostaje '.$hp.' HP na początku rundy.</h2><br />';
}
if($def)
{
	$def_text = '<h2><num>'.++$number.'.</num> Dostaje darmowy defuser w CT.</h2><br />';
}
if($taser)
{
	$taser_text = '<h2><num>'.++$number.'.</num> Dostaje darmowy paralizator.</h2><br />';
}
if($menu > 0)
{
	$menu_text = '<h2><num>'.++$number.'.</num> Menu vipa dostępne jest od '.$menu.' rundy.</h2><br />';
}
if($prefix)
{
	$prefix_text = '<h2><num>'.++$number.'.</num> Wyróżniający się prefix przed nickiem na czacie.</h2><br />';
}

//added as of 0.1.4
if($reservation)
{
	$reservation_text = '<h2><num>'.++$number.'.</num> Rezerwacja slota na serwerze.</h2><br />';
}
//0.1.4
$version_text = '<p2>Plugin stworzony przez <a href="https://github.com/Ni3znajomy">Ni3znajomy</a>. Wersja pluginu <a href="https://github.com/Ni3znajomy/SMVIP/blob/master/changelog.txt">'.decode_plugin_version($version).'-dev</a>. Plugin opublikowany na licencji <a href="https://github.com/Ni3znajomy/SMVIP/blob/master/LICENSE">GNU General Public License version 3</a>.</p2>';

$html = $html_header.$html_title.$armor_text.$money_text.$hp_text.$def_text.$taser_text.$menu_text.$prefix_text.$reservation_text;

$html .= $version_text;

echo $html;
