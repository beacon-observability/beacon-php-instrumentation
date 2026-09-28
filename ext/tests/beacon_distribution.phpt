--TEST--
Beacon distribution marker is available without changing the hook API
--FILE--
<?php
var_dump(defined('OpenTelemetry\\Instrumentation\\BEACON_DISTRIBUTION'));
var_dump(constant('OpenTelemetry\\Instrumentation\\BEACON_DISTRIBUTION'));
?>
--EXPECT--
bool(true)
string(6) "Beacon"
