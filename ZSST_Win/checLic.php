<?php
$o = $_GET['o'];
$k = $_GET['k'];
$a=zem_serial_number_info($k, $o);

echo "\n\nZend Server License Information\n\nOrder #: $o   ||  License Key: $k\n\n";
if ($a['license_ok']) {
    echo "The license is VALID\n\n";
} else {
	echo "This license is INVALID (possibly expired)\n\n";
}
switch ($a['edition']) {
	case 2:
		$e = 'Production Enterprise';break;
	case 7:
		$e = 'Production Professional';break;
	case 6:
		$e = 'Production Small Business';break;
	case 8:
		$e = 'Developer Enterprise';break;
	case 3:
		$e = 'Developer Standard';break;
	default:
		$e = 'NOT RECOGNIZED. May be an incompatible license!!!';break;
}
echo "Edition - $e\n";
echo "Expires - " . date('j F Y', $a['expiration_date']) . "\n";
echo "Servers - {$a['num_of_nodes']}\n\n";
