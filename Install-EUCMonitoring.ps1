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
        $InstallDir = "C:\Monitoring",
.PARAMETER InstallDir
    Literal path to install this EUCMonitoring suite. (Where to install everything to)
.PARAMETER GrafanaVersion 
    URL or Literal Path to the current Grafana version zip file.
    https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-5.1.3.windows-x64.zip
.PARAMETER InfluxVersion 
    URL or Literal Path to the current Influx Version zip file.
    Currently: https://dl.influxdata.com/influxdb/releases/influxdb-1.5.3_windows_amd64.zip 
.PARAMETER NSSMVersion
    URL or Literal Path to the current NSSM Version zip file.
    Currently: https://nssm.cc/release/nssm-2.24.zip
.PARAMETER EUCVersion
    Literal Path to the a downloaded or downloadable zip file of the EUCMonitoring project.  Currently, 
    https://github.com/littletoyrobots/EUCMonitoring/tree/v2_TestEngine but this will change as merged. 
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    Hal Lange               1.0             16/04/2018          Initial creation of Install Script
    Hal Lange               1.01            23/04/2018          Allow for local install source
    Adam Yarborough         1.02            18/06/2018          Format and Integrate, update versions
.EXAMPLE
    .\Install-EUCMonitoring -EUCVersion "C:\temp\EUCMonitoring-v2_TestEngine.zip"
#>
param(
    $InstallDir = "C:\Monitoring",
    $GrafanaVersion = "https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-5.1.3.windows-x64.zip", 
    $InfluxVersion = "https://dl.influxdata.com/influxdb/releases/influxdb-1.5.3_windows_amd64.zip", 
    $NSSMVersion = "https://nssm.cc/release/nssm-2.24.zip", 
    [Parameter( Mandatory = $true )] $EUCVersion
)


$InitScript = "$(split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)\Begin-EUCMonitor.ps1"

#open FW for Grafana
write-host "Opening Firewall Rules for Grafana and InfluxDB"

$Catch = New-NetFirewallRule -DisplayName "Grafana Server" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow -Description "Allow Grafana Server"
$Catch = New-NetFirewallRule -DisplayName "InfluxDB Server" -Direction Inbound -LocalPort 8086 -Protocol TCP -Action Allow -Description "Allow InfluxDB Server" -AsJob

function GetAndInstall ( $Product, $DownloadFile, $Dest ) {
    $zipFile = "$DownloadLocation\$Product.zip"
    Write-Host "Downloading $Product to $zipfile"
    if ( ($DownloadFile -match "http://") -or ($DownloadFile -match "https://") ) { 
        $Catch = Invoke-WebRequest $DownloadFile -outFile $zipFile
    }
    else { 
        Copy-Item $DownloadFile -Destination "$DownloadLocation\$Product.zip" 
    }
	
    Write-Host "Installing $Product to $Dest"
    $shell = New-Object -ComObject shell.application
    $zip = $shell.NameSpace($ZipFile)
    foreach ( $item in $zip.items() ) {
        $shell.Namespace($Dest).CopyHere($item)
    }
    $Catch = ""
    Write-Host $Catch
}

function SetupGrafana {
    param ( $DashboardConfig = "C:\Monitoring\EUCMonitoring\DashboardConfig" )
    $pair = "admin:admin"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $basicAuthValue = "Basic $base64"
    $headers = @{ Authorization = $basicAuthValue }
	
    write-host "Setting up Grafana Datasource"
    $datasourceURI = "http://localhost:3000/api/datasources"
    $inFile = "$DashboardConfig\DataSource.json"
    # $out = Invoke-WebRequest -Uri $datasourceURI -Method Post -infile $infile -Headers $headers -ContentType "application/json"
    $Catch = Invoke-WebRequest -Uri $datasourceURI -Method Post -infile $infile -Headers $headers -ContentType "application/json"

    write-host "Setting up Grafana Dashboards"
    write-host "Using $DashboardConfig\Dashboards" -ForegroundColor Magenta
    $gc = get-childitem "$DashboardConfig\Dashboards"
    $dashboardURI = "http://localhost:3000/api/dashboards/import"
    foreach ( $dashboard in $gc ) {
        $inFile = $dashboard.fullname
        # $out = Invoke-WebRequest -Uri $dashboardURI -Method Post -infile $infile -Headers $headers -ContentType "application/json"
        $Catch = Invoke-WebRequest -Uri $dashboardURI -Method Post -infile $infile -Headers $headers -ContentType "application/json"
    }
    # $c = Invoke-WebRequest -URI "http://localhost:3000/api/search?query=EUCMonitoring" -outfile .\home.json -header $headers
    $Catch = Invoke-WebRequest -URI "http://localhost:3000/api/search?query=EUCMonitoring" -outfile .\home.json -header $headers
    $GrafanaConfig = Get-Content -Raw -Path .\home.json | ConvertFrom-Json
    $SiteID = $GrafanaConfig.id
    $GrafanaConfig = "{""theme"": """",""homeDashboardId"":$SiteID,""timezone"":""browser""}"
    Remove-Item .\home.json
	
    write-host "Setting up Grafana Homepage"
    # $c = Invoke-WebRequest -URI "http://localhost:3000/api/org/preferences" -method PUT -body $GrafanaConfig -header $headers -ContentType "application/json"
    $Catch = Invoke-WebRequest -URI "http://localhost:3000/api/org/preferences" -method PUT -body $GrafanaConfig -header $headers -ContentType "application/json"
    
    # This is to avoid the assigned and never used checks.
    $Catch = ""
    Write-Host $Catch
}

#Base Directory for Install
write-host "Install location set to $InstallDir"
write-host "Create folder $InstallDir"
# $dumpVariable = MkDir($InstallDir)
$Catch = MkDir($InstallDir)
#Install Grafana
GetAndInstall "Grafana" $GrafanaVersion $InstallDir 
$Grafana = (get-childitem $installDir | Where-Object {$_.Name -match 'graf'}).FullName

#Install InfluxDB
GetAndInstall "InfluxDB" $InfluxVersion $InstallDir
$Influx = (get-childitem $installDir | Where-Object {$_.Name -match 'infl'}).FullName
$content = [System.IO.File]::ReadAllText("$Influx\influxdb.conf").Replace("/var/lib/influxdb", "/Monitoring/InfluxData/var/lib/influxdb")
[System.IO.File]::WriteAllText("$Influx\influxdb.conf", $content)
[Environment]::SetEnvironmentVariable("Home", $Influx, "Machine")

# Install EUCMonitoring
GetAndInstall "EUCMonitoring" $EUCVersion $InstallDir
$DashboardConfig = "$InstallDir\EUCMonitoring\DashboardConfig"

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


Set-Location "$(split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)"

# Purely to pass variable checks
$Catch = ""
Write-Verbose $Catch

# Launch Notepad and let them edit the file.  
# Later, when working, invoke New-EUCMonitoringConfig $InstallDir
Copy-Item -Path $InitScript -Destination $InstallDir
Copy-Item -Path "$InstallDir\EUCMonitoring\Package\euc-monitoring.json.template" -Destination $InstallDir

Write-Host "Copy your euc-monitoring.json file to $InstallDir and review configurations"
Write-Host "or just edit $InstallDir\euc-monitoring.json.template and save as euc-monitoring.json"
#& "C:\Windows\System32\notepad.exe" $InstallDir\euc-monitoring.json

Write-Host "After configuring, run $InitScript under appropriate privs" 
