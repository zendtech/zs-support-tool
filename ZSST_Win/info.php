<?php

chdir($argv[1]);

$json = file_get_contents("phpinfo_main.html");
$info = json_decode($json, true);
file_put_contents("real_phpinfo_main.html",$info["phpinfo"]);
