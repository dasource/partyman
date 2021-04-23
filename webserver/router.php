<?php
// Set timezone
date_default_timezone_set("UTC");

// Default index file
define("DIRECTORY_INDEX", "index.php");

// Optional array of authorized client IPs for a bit of security
//$config["hostsAllowed"] = array("");
$config["hostsAllowed"] = file('hosts.allow', FILE_IGNORE_NEW_LINES);

//Force default policy to DENY if no file exists
if (!file_exists('hosts.allow')) {
    $config["hostsAllowed"] = array("255.255.255.255"); 
}

// Parse allowed host list
if (!empty($config['hostsAllowed'])) {
    if (!in_array($_SERVER['REMOTE_ADDR'], $config['hostsAllowed'])) {
        http_response_code(403);
        exit;
    }
}

// if requesting a directory then serve the default index
$path = parse_url($_SERVER["REQUEST_URI"], PHP_URL_PATH);
$ext = pathinfo($path, PATHINFO_EXTENSION);
if (empty($ext)) {
    $path = rtrim($path, "/") . "/" . DIRECTORY_INDEX;
}

// If the file exists then return false and let the server handle it
if (file_exists($_SERVER["DOCUMENT_ROOT"] . $path)) {
    return false;
}

// default behavior
http_response_code(404);
