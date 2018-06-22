                                                                
Param (
    $EUCMonitoringDir = "C:\Monitoring\EUCMonitoring",
    $RefreshDuration = 300
)
$Private = @( Get-ChildItem -Path "$EUCMonitoringDir\PSGallery\Private\*.ps1" -ErrorAction SilentlyContinue )                                                                       
$Public = @( Get-ChildItem -Path "$EUCMonitoringDir\PSGallery\Public\*.ps1" -ErrorAction SilentlyContinue )
                                                                                                   
Foreach ($import in @($Public + $Private)) { 
    try {
        unblock-file  "$($import.fullname)" 
        . "$($import.fullname)" 
    } 
    Catch { Write-Error -Message "Failed to import function $($import.fullname): $_" }
}                                                                                                                                                                 

do { 
    $Params = @{
        JSONFile = "$EUCMonitoringDir\euc-monitoring.json";
        CSSFile  = "$EUCMonitoringDir\Package\euc-monitoring.css";
        LogFile  = "$EUCMonitoringDir\euc-monitor.log";
        Verbose  = $true
    }
    Start-EUCMonitor @Params
    Write-Host "You can see current results at http:\\localhost:8086\ Login: admin/admin"
    Write-Host "Press Ctrl-C to stop.  Sleeping for $RefreshDuration seconds."
    Start-Sleep $RefreshDuration
} while ($true)