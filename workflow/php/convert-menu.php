<?php

$serialized = $argv[1];
$location_slug = $argv[2];
$new_location_id = $argv[3];
$theme = unserialize($serialized);
$theme['nav_menu_locations'][$location_slug] = intval($new_location_id);
echo serialize($theme);