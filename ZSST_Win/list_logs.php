<?php
/*
 * Usage:
 * php list_logs.php <number of lines> <source filter> <destination directory>
 * php list_logs.php 1000 "/usr/local/zend/var/log/*.log" "/tmp/support_tool/logs"
 */

$tailLines = $argv[1];
$filter = $argv[2];
$destDir = $argv[3];

if (! is_file($destDir)) {
    mkdir($destDir, 0777, true);
}

$fileList = array();
$allFiles = array();

foreach (glob($filter) as $file) {
    if (filesize($file)) {
        $fileList[] = $file;
    }
    $allFiles[] = $file;
}

$dirList = "Copied " . count($fileList) . " of " . count($allFiles) . " files: \r\n\r\n";
foreach ($allFiles as $fItem) {
    $dirList .= $fItem . "\r\nsize: " . filesize($fItem) . " bytes\r\nchanged: " . date("d M Y H:i:s", filectime($fItem)) . "\r\n\r\n";
}

file_put_contents("$destDir/_dirlist.txt", $dirList);

foreach ($fileList as $fItem) {
    file_put_contents("$destDir/" . basename($fItem), tail($fItem, $tailLines));
}

function tail($fileName, $nrOfLines)
{
    $SOF = 0;
    $off = 0;
    $char = '';
    $result = '';
    
    if (! is_file($fileName)) {
        return "$fileName is not a file.";
    }
    
    $fHandle = fopen($fileName, 'r');
    
    for ($i = 0; $i <= $nrOfLines; $i ++) {
        
        if ($SOF) {
            continue;
        }
        
        while ($char != "\n") {
            
            $SOF = fseek($fHandle, $off, SEEK_END);
            
            if ($SOF) {
                rewind($fHandle);
                break;
            }
            
            fseek($fHandle, $off --, SEEK_END);
            
            $char = fgetc($fHandle);
            $result = $char . $result;
        }
        $char = '';
    }
    
    fclose($fHandle);
    return $result;
}

