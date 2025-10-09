# Read all files
$mainLines = Get-Content src\main.qml
$funcLines = Get-Content src\main_layer_function.qml

# Split main.qml at line 495
$before = $mainLines[0..494]
$after = $mainLines[495..($mainLines.Length-1)]

# Combine
$newContent = $before + "" + $funcLines + "" + $after

# Write back
$newContent | Out-File src\main.qml -Encoding UTF8
Write-Host "Function inserted successfully"
