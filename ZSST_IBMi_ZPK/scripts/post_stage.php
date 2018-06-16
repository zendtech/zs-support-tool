<?php

$pathname = getenv('ZS_APPLICATION_BASE_DIR');

$iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator("$pathname/share"));

foreach($iterator as $item) {
    chmod($item, 0777);
}

