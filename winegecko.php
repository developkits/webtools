<?php
/**
 * Redirects to one of many URLs that have the Wine Gecko installer available.
 * 
 * Usage: 
 * winegecko.php
 * (main usage, redirects to one of many URLs that have the Wine Gecko installer available)
 * 
 * winegecko.php?action=showlist
 * (display a list of server and tells if the file is available for each server)
 * 
 * Copyright (c) 2006 Jonathan Ernst
 */

// Default version if none given
$sVersion = '0.0.1';

// Suffix appended to base name of file
$sFileSuffix = '';

// Folder which contains wine gecko files
$sFolder = 'wine-gecko';

// Check if a specific version was passed
if(isset($_GET['v'])) {
	$sVersion = $_GET['v'];

	if(isset($_GET['arch']))
		$sFileSuffix = $sVersion.'-'.$_GET['arch'];
}

if(!$sFileSuffix)
	$sFileSuffix = $sVersion;

switch($sVersion) {
case '0.0.1':
case '0.1.0':
case '0.9.0':
case '0.9.1':
case '1.0.0':
case '1.1.0':
	$sExt = 'cab';
	break;
default:
	$sExt = 'msi';
}

// Name of the file
$sFileName = sprintf('%s/%s/wine_gecko-%s.%s', $sFolder, $sVersion, $sFileSuffix, $sExt);

// Common code for Wine downloader scripts
require("download.inc.php");
?>
