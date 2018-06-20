                                                                             
$Private = @( Get-ChildItem -Path EUCMonitoring\PSGallery\Private\*.ps1 -ErrorAction SilentlyContinue )                                                                       
$Public = @( Get-ChildItem -Path EUCMonitoring\PSGallery\Public\*.ps1 -ErrorAction SilentlyContinue )
                                                                                                   
Foreach ($import in @($Public + $Private)) { 
    try { . "$($import.fullname)" } 
    Catch { Write-Error -Message "Failed to import function $($import.fullname): $_" }
}                                                                                                                                                                 

do { 
    Start-EUCMonitor -JSONFile .\euc-monitoring.json -CSSFile .\euc-monitoring.css -Verbose 
    Write-Host "You can see current results at http:\\localhost:8086\ Login: admin/admin"
    Write-Host "Press Ctrl-C to stop."
    Start-Sleep 300
} while ($true)


