[cmdletbinding()]                                                              
Param (
    $BaseDir = "C:\Monitoring",
    $Refresh = 300
)

$Private = @( Get-ChildItem -Path "$BaseDir\EUCMonitoring\PSGallery\Private\*.ps1" -ErrorAction SilentlyContinue )                                                                       
$Public = @( Get-ChildItem -Path "$BaseDir\EUCMonitoring\PSGallery\Public\*.ps1" -ErrorAction SilentlyContinue )
                                                                                                   
Foreach ($import in @($Public + $Private)) { 
    try {
        unblock-file  "$($import.fullname)" 
        . "$($import.fullname)" 
    } 
    Catch { Write-Error -Message "Failed to import function $($import.fullname): $_" }
}                                                                                                                                                                 

do { 
    $Params = @{
        JSONFile = "$BaseDir\euc-monitoring.json";
        CSSFile  = "$BaseDir\EUCMonitoring\Package\euc-monitoring.css";
        LogFile  = "$BaseDir\euc-monitor.log"
    }
    Start-EUCMonitor @Params
    Write-Host "You can see current results at http:\\localhost:8086\ Login: admin/admin"
    Write-Host "Press Ctrl-C to stop.  Sleeping for $Refresh seconds."
    Start-Sleep $Refresh
} while ($true)