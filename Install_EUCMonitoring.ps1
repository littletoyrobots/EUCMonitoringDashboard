<#   
.SYNOPSIS   
    Installs EUC Monitoring for Grafana and Influx.
.DESCRIPTION 
    Downloads and installs:
		Grafana Server
		InfluxDB
		NSSM
		XD_Monitoring Scripts
	Open Firewall ports 3000 and 8086 locally on the server
	configures InfluxDB and Grafana Services
.NOTES
    Current Version:        1.01
    Creation Date:          23/04/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
	Hal Lange				1.0				16/04/2018			Initial creation of Install Script
    Hal Lange	            1.01            23/04/2018          Allow for local install source
    Adam Yarborough         1.02            18/06/2018          Format and Integrate, update versions
.EXAMPLE
    None Required
#>


#######################
#CONFIGURABLE VARIABLES
#######################
$InstallDir = "C:\Monitoring"	#Where to install everything to
$DownloadLocation = (Get-Item Env:Temp).value #Use the Temp folder as Temp Download location
#Source location for Grafana version found here https://grafana.com/grafana/download?platform=windows
$GrafanaVersion = "https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-5.1.3.windows-x64.zip"
#$GrafanaVersion = "C:\Grafana.zip"
#Source location for InfluxDB version found here https://portal.influxdata.com/downloads
$InfluxVersion = "https://dl.influxdata.com/influxdb/releases/influxdb-1.5.3_windows_amd64.zip"
#$InfluxVersion = "C:\InfluxDB.zip"
#Source location for NSSM Version found here https://nssm.cc/download
$NSSMVersion = "https://nssm.cc/release/nssm-2.24.zip"
#$NSSMVersion = "C:\NSSM.zip" 
#Source location for EUCMonitoring Script Location
#$ScriptsVersion = "C:\EUC_Monitoring.zip"
# $ScriptsVersion = "C:\Users\ayarborough\Desktop\EUC_Monitoring.zip"
# Grab the dashboard stuff from the folder of script invocation
$DashboardConfig = "$(split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)\DashboardConfig"





#open FW for Grafana
write-host "Opening Firewall Rules for Grafana and InfluxDB"
#$dumpVariable = New-NetFirewallRule -DisplayName "Grafana Server" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow -Description "Allow Grafana Server"
#$dumpVariable = New-NetFirewallRule -DisplayName "InfluxDB Server" -Direction Inbound -LocalPort 8086 -Protocol TCP -Action Allow -Description "Allow InfluxDB Server" -AsJob

New-NetFirewallRule -DisplayName "Grafana Server" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow -Description "Allow Grafana Server"
New-NetFirewallRule -DisplayName "InfluxDB Server" -Direction Inbound -LocalPort 8086 -Protocol TCP -Action Allow -Description "Allow InfluxDB Server" -AsJob



function GetAndInstall ( $Product, $DownloadFile, $Dest ) {
    $zipFile = "$DownloadLocation\$Product.zip"
    Write-Host "Downloading $Product to $zipfile"
    if ( ($DownloadFile -match "http://") -or ($DownloadFile -match "https://") ) { 
        Invoke-WebRequest $DownloadFile -outFile $zipFile
    }
    else { $ZipFile = $DownloadFile }
	
    Write-Host "Installing $Product to $Dest"
    $shell = New-Object -ComObject shell.application
    $zip = $shell.NameSpace($ZipFile)
    foreach ( $item in $zip.items() ) {
        $shell.Namespace($Dest).CopyHere($item)
    }
}

function SetupGrafana {
    $pair = "admin:admin"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $basicAuthValue = "Basic $base64"
    $headers = @{ Authorization = $basicAuthValue }
	
    write-host "Setting up Grafana Datasource"
    $datasourceURI = "http://localhost:3000/api/datasources"
    $inFile = "$DashboardConfig\DataSource.json"
    # $out = Invoke-WebRequest -Uri $datasourceURI -Method Post -infile $infile -Headers $headers -ContentType "application/json"
    Invoke-WebRequest -Uri $datasourceURI -Method Post -infile $infile -Headers $headers -ContentType "application/json"

    write-host "Setting up Grafana Dashboards"
    $gc = get-childitem $DashboardConfig\Dashboards
    $dashboardURI = "http://localhost:3000/api/dashboards/import"
    foreach ( $dashboard in $gc ) {
        $inFile = $dashboard.fullname
        # $out = Invoke-WebRequest -Uri $dashboardURI -Method Post -infile $infile -Headers $headers -ContentType "application/json"
        Invoke-WebRequest -Uri $dashboardURI -Method Post -infile $infile -Headers $headers -ContentType "application/json"
    }
    # $c = Invoke-WebRequest -URI "http://localhost:3000/api/search?query=EUCMonitoring" -outfile .\home.json -header $headers
    Invoke-WebRequest -URI "http://localhost:3000/api/search?query=EUCMonitoring" -outfile .\home.json -header $headers
    $GrafanaConfig = Get-Content -Raw -Path .\home.json | ConvertFrom-Json
    $SiteID = $GrafanaConfig.id
    $GrafanaConfig = "{""theme"": """",""homeDashboardId"":$SiteID,""timezone"":""browser""}"
    Remove-Item .\home.json
	
    write-host "Setting up Grafana Homepage"
    # $c = Invoke-WebRequest -URI "http://localhost:3000/api/org/preferences" -method PUT -body $GrafanaConfig -header $headers -ContentType "application/json"
    Invoke-WebRequest -URI "http://localhost:3000/api/org/preferences" -method PUT -body $GrafanaConfig -header $headers -ContentType "application/json"
}

#Base Directory for Install
write-host "Install location set to $InstallDir"
write-host "Create folder $InstallDir"
# $dumpVariable = MkDir($InstallDir)
MkDir($InstallDir)
#Install Grafana
GetAndInstall "Grafana" $GrafanaVersion $InstallDir 
$Grafana = (get-childitem $installDir | Where-Object {$_.Name -match 'graf'}).FullName

#Install InfluxDB
GetAndInstall "InfluxDB" $InfluxVersion $InstallDir
$Influx = (get-childitem $installDir | Where-Object {$_.Name -match 'infl'}).FullName
$content = [System.IO.File]::ReadAllText("$Influx\influxdb.conf").Replace("/var/lib/influxdb", "/Monitoring/InfluxData/var/lib/influxdb")
[System.IO.File]::WriteAllText("$Influx\influxdb.conf", $content)
[Environment]::SetEnvironmentVariable("Home", $Influx, "Machine")

# Install Scripts
# GetAndInstall "EUCMonitor" $ScriptsVersion $InstallDir
# $ScriptsConfig = (get-childitem $installDir | Where-Object {$_.Name -match 'EUCMon'}).FullName
# Copy-Item -Path $DashboardConfig -Destination $InstallDir -Recurse

#Install NSSM
GetAndInstall "NSSM" $NSSMVersion $InstallDir
#Setup Services
$NSSM = (get-childitem $installDir | Where-Object {$_.Name -match 'nssm'}).FullName
$NSSMEXE = "$nssm\win64\nssm.exe"
& $nssmexe Install "Grafana Server" $Grafana\bin\grafana-server.exe
& $nssmexe Install "InfluxDB Server" $Influx\influxd.exe -config influxdb.conf
write-host "Starting Services"
start-service "Grafana Server"
start-service "InfluxDB Server"
& $Influx\influx.exe -execute 'Create Database EUCMonitoring'

# need to import eventually grafana pages.
Set-Location $grafana\bin
& .\Grafana-cli.exe plugins install btplc-status-dot-panel
& .\Grafana-cli.exe plugins install vonage-status-panel
& .\Grafana-cli.exe plugins install briangann-datatable-panel
& .\Grafana-cli.exe plugins install grafana-piechart-panel
write-host "Restarting Grafana Server"
stop-service "Grafana Server"
start-service "Grafana Server"

write-host "Setting up Grafana"
SetupGrafana

if ( -Not (Get-Module -ListAvailable -Name EUCMonitoring) ) {
    Install-Module EUCMonitoring
}
Import-Module EUCMonitoring

Set-Location $InstallDir
Set-EUCMonitoring $InstallDir -Verbose

# Launch Notepad and let them edit the file.  
# Later, when working, invoke New-EUCMonitoringConfig $InstallDir
Copy-Item -Path $InstallDir\euc-monitoring.json.template -Destination $InstallDir\euc-monitoring.json
& "C:\Windows\System32\notepad.exe" $InstallDir\euc-monitoring.json

