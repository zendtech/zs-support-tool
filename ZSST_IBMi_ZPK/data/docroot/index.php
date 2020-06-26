<?php

if (isSet($_POST['runme'])) {
    $WEB_PATH = escapeshellarg(dirname(dirname($_SERVER["ZendEnablerConfig"])));
    $ZS_PATH = escapeshellarg(dirname($_SERVER["LIBPATH"]));
    $APP_PATH = dirname(__DIR__);
    
    echo "$WEB_PATH - web\n $ZS_PATH - zs\n $APP_PATH - app\n" . __DIR__ . "\n\n";

    $a = shell_exec("ksh $APP_PATH/bin/runner.sh $ZS_PATH $WEB_PATH >> $APP_PATH/docroot/status.php 2>&1");
    echo $a;
    die();
} else if (isSet($_POST['stlist'])) {
    echo '<table class="pure-table"><thead><tr><th>File Name</th><th>File Size</th><th> </th></tr></thead><tbody>';

    foreach (glob(__DIR__ . "/ZSST*.tar.gz") as $filename) {
        $short = str_replace(__DIR__ . '/', '', $filename);
        $shorter = str_replace('.tar.gz', '', $short);
        $btn = '<a class="pure-button" style="color: red" onclick="javascript:getRid(\'' . $shorter . '\')">delete</a>';
        echo "<tr><td><a href=\"$short\">$short</a></td><td>" . round(filesize($filename)/1024, 3) . " KB</td><td>$btn</td></tr>\n";
    }
    echo '</tbody></table>';
    die();
} else if (isSet($_POST['rm'])) {
    $skripach = __DIR__ . '/' . $_POST['rm'] . '.tar.gz';
    if (file_exists($skripach)) {
        unlink($skripach);
    }
    die();
}

?><!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <title>Run Zend Server Support Tool</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link rel="stylesheet" type="text/css" media="screen" href="pure-min.css" />
    <script src="jquery-3.3.1.min.js"></script>
    <script>
        function outStatus(data) {
            $("#output").text(data);
            if (data.search("Support Tool execution completed") > 0) {
                clearInterval(outRefresh);
                getSTList();
                $("#btn").removeClass("pure-button-disabled");
            }
        }
        function getStatus() {
            $.get("status.php", outStatus, "text");
        }
        function runme() {
            $.post("index.php", { runme: "now" });
            $("#btn").addClass("pure-button-disabled");
            outRefresh = setInterval(getStatus, 1500);
        }
        function getSTList() {
            $.post("index.php", { stlist: "please" }, function(data){
                $("#zssts").html(data);
            });
        }
        function getRid(of) {
            $.post("index.php", { rm: of }, getSTList);
        }
    </script>
</head>
<body>
<br><br><br><br><br>
<div class="pure-g">
    <div class="pure-u-1-5"></div>
    <div class="pure-u-3-5 pure-button pure-button-primary" id="btn" onclick="javascript:runme();"><p>Run Zend Server (IBM i) Support Tool</p></div>
    <div class="pure-u-1-5"></div>
</div>
<div class="pure-g">
    <div class="pure-u-1-5"></div>
    <div class="pure-u-3-5"><pre id="output"></pre></div>
    <div class="pure-u-1-5"></div>
</div>
<br><br><br>
<div class="pure-g">
    <div class="pure-u-1-5"></div>
    <div class="pure-u-3-5"><h3>Existing Support Tool Archives:</h3><div id="zssts">-</div></div>
    <div class="pure-u-1-5"></div>
</div>
<script>getSTList();</script>

</body>
</html>
