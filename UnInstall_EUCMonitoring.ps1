$InstallDir = "C:\Monitoring"

#Removing Services
$NSSM = (get-childitem $InstallDir | where {$_.Name -match 'nssm'}).FullName
$NSSMEXE = "$nssm\win64\nssm.exe"
#Remove Grafana Service
& $nssmexe Stop "Grafana Server"
& $nssmexe Remove "Grafana Server" confirm
#Remove Influx Service
& $nssmexe Stop "InfluxDB Server"
& $nssmexe Remove "InfluxDB Server" confirm

#Remove Directories
Remove-Item -path $InstallDir -Recurse

#Remove Variable
Remove-Item Env:\Home

#open FW for Grafana
write-host "Remove Firewall Rules for Grafana and InfluxDB"
Remove-NetFirewallRule -DisplayName "Grafana Server"
Remove-NetFirewallRule -DisplayName "InfluxDB Server"

