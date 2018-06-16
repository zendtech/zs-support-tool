<?php

/*
 * /usr/local/zend/bin/php -nd "extension=/usr/local/zend/lib/php_extensions/mysqli.so" -f /srv/www/htdocs/SupportToolScripts/mysql.php 192.168.56.10 3306 ZS root "$upp0rt" mysql_info.html 
 */

$host = $argv[1];
$port = $argv[2];
$db = $argv[3];
$user = $argv[4];
$pw = $argv[5];
$file = $argv[6];

$head = <<<EOH
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>MySQL Information</title>
</head>
<body>
EOH;

$tail = "\n</body></html>";

$TOC = <<<EOT
<a href=#db_size>Database Size</a><br>
<a href=#table_stats>Tables Statistics</a><br>
<a href=#ver>Schema Versions</a><br>
<a href=#plist>SHOW PROCESSLIST;</a><br>
<a href=#vars>SHOW GLOBAL VARIABLES;</a><br>
<a href=#status>SHOW STATUS;</a><br>
<br>
EOT;


$conn = new mysqli($host, $user, $pw, $db, $port);

if (mysqli_connect_errno()) {
    file_put_contents($file, $head . "MySQL connection failed: " . mysqli_connect_error() . $tail);
    exit();
}

// Servers
$query = "SELECT NODE_ID,NODE_NAME,NODE_IP,STATUS_CODE,REASON_STRING,IS_DELETED FROM ZSD_NODES;";

if ($result = $conn->query($query)) {
    $nodes = "Servers:";
    $nodes .= "<table border=1><tr><th>NODE_ID</th><th>NODE_NAME</th><th>NODE_IP</th>";
    $nodes .= "<th>STATUS_CODE</th><th>REASON_STRING</th><th>IS_DELETED</th></tr>\n";
    while ($row = $result->fetch_assoc()) {
        $nodes .= "<tr><td>${row['NODE_ID']}</td><td>${row['NODE_NAME']}</td><td>${row['NODE_IP']}</td>";
        $nodes .= "<td>${row['STATUS_CODE']}</td><td>${row['REASON_STRING']}</td><td>${row['IS_DELETED']}</td></tr>\n";
    }
    $nodes .= "</table><br>\n";
    $nodes .= <<<EOLE
STATUS_CODE:<br>
0 = <strong>STATUS_OK</strong> - No error<br>
1 = <strong>STATUS_ERROR</strong> - Global error code<br>
3 = <strong>STATUS_RESTART_REQUIRED</strong> - Restart is required<br>
12 = <strong>STATUS_DISCONNECTING_FROM_CLUSTER</strong> - Node is disconnecting from cluster<br>
13 = <strong>STATUS_RELOADING</strong> - Node is reloading it configuration<br>
14 = <strong>STATUS_DISABLING_SERVER</strong> - Node is in the process of being disabled<br>
15 = <strong>STATUS_DISABLED</strong> - Node is disabled<br>
16 = <strong>STATUS_SERVER_RESTARTING</strong> - Server is being restarted<br>
17 = <strong>STATUS_FORCED_REMOVED</strong> - Server was forced removed<br>
<br>REASON_STRING:<br>
4 = <strong>ERROR_DIRECTIVE_MISMATCH</strong> - Directive mismatch was found<br>
5 = <strong>ERROR_DIRECTIVE_MISSING</strong> - Directive exists in the blueprint but is missing on the file system<br>
6 = <strong>ERROR_DAEMON_OFFLINE</strong> - Daemon is offline<br>
9 = <strong>ERROR_EXTENSION_MISSING</strong> - Extension is not installed but is exists in the blueprint<br>
10 = <strong>ERROR_EXTENSION_NOT_LOADED</strong> - Extension is not loaded while it should be according to theblueprint<br>
11 = <strong>EXTENSION_NOT_INSTALLED</strong> - Extension is not installed while it should be according to theblueprint<br>
<br><br>

EOLE;
    $result->free();
}


// Database Size
$query = "SELECT TABLE_SCHEMA AS 'Database', CONCAT(SUM(ROUND(((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024),2)),' MB') AS 'Size' FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '$db';";

if ($result = $conn->query($query)) {
    $db_size = "<a id=db_size>Database Size</a>";
    $db_size .= "<table border=1><tr><th>Database</th><th>Size</th></tr>\n";
    while ($row = $result->fetch_assoc()) {
        $db_size .= "<tr><td>${row['Database']}</td><td>${row['Size']}</td></tr>\n";
    }
    $db_size .= "</table><br>\n";
    $result->free();
}

// Tables Statistics
$query = "SELECT TABLE_NAME AS 'Table', CONCAT(ROUND(((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024),2),' MB') AS 'Size', TABLE_ROWS AS 'Records' FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '$db';";

if ($result = $conn->query($query)) {
    $table_stats = "<a id=table_stats>Tables Statistics</a>";
    $table_stats .= "<table border=1><tr><th>Table</th><th>Size</th><th>Records</th></tr>\n";
    while ($row = $result->fetch_assoc()) {
        $table_stats .= "<tr><td>${row['Table']}</td><td>${row['Size']}</td><td>${row['Records']}</td></tr>\n";
    }
    $table_stats .= "</table><br>\n";
    $result->free();
}

// InnoDB Size
$query = "SELECT CONCAT(ROUND((DATA_FREE / 1024 / 1024),2),' MB') AS 'InnoDB_Size' FROM INFORMATION_SCHEMA.TABLES WHERE ENGINE = 'InnoDB' LIMIT 1;";

if ($result = $conn->query($query)) {
    while ($row = $result->fetch_assoc()) {
        $innodb_size .= "<strong>InnoDB Size: ${row['InnoDB_Size']}</strong><br><br>\n";
}
$result->free();
}

// Schema Versions
$query = "SELECT property, property_value FROM $db.schema_properties;";

if ($result = $conn->query($query)) {
    $ver = "<a id=ver>Schema Versions</a>";
    $ver .= "<table border=1><tr><th>Schema</th><th>Version</th></tr>\n";
    while ($row = $result->fetch_assoc()) {
        $ver .= "<tr><td>${row['property']}</td><td>${row['property_value']}</td></tr>\n";
}
$ver .= "</table><br>\n";
$result->free();
}

// Processlist
$query = "SHOW PROCESSLIST;";

if ($result = $conn->query($query)) {
    $plist = "<a id=plist>$query</a>";
    $plist .= "<table border=1><tr><th>Id</th><th>User</th><th>Host</th>";
    $plist .= "<th>db</th><th>Command</th><th>Time</th>";
    $plist .= "<th>State</th><th>Info</th></tr>\n";
    while ($row = $result->fetch_assoc()) {
        $plist .= "<tr><td>${row['Id']}</td><td>${row['User']}</td><td>${row['Host']}</td>";
        $plist .= "<td>${row['db']}</td><td>${row['Command']}</td><td>${row['Time']}</td>";
        $plist .= "<td>${row['State']}</td><td>${row['Info']}</td></tr>\n";
}
$plist .= "</table><br>\n";
$result->free();
}

// Variables
$query = "SHOW GLOBAL VARIABLES;";

if ($result = $conn->query($query)) {
    $vars = "<a id=vars>$query</a>";
    $vars .= "<table border=1><tr><th>Variable</th><th>Value</th></tr>\n";
    while ($row = $result->fetch_assoc()) {
        $vars .= "<tr><td>${row['Variable_name']}</td><td>${row['Value']}</td></tr>\n";
}
$vars .= "</table><br>\n";
$result->free();
}

// Status
$query = "SHOW STATUS;";

if ($result = $conn->query($query)) {
    $status = "<a id=status>$query</a>";
    $status .= "<table border=1><tr><th>Variable</th><th>Value</th></tr>\n";
    while ($row = $result->fetch_assoc()) {
        $status .= "<tr><td>${row['Variable_name']}</td><td>${row['Value']}</td></tr>\n";
}
$status .= "</table><br>\n";
$result->free();
}

$conn->close();



$output = $head . $nodes . $TOC . "<h1>Zend Server Database Information</h1>" . $db_size . $table_stats . $innodb_size . $ver;
$output .= "<h1>MySQL Information</h1>" . $plist . $vars . $status . $tail;
file_put_contents($file, $output);

