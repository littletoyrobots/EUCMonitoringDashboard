# EUCMonitoringDashboard

## How to Install for the first time. 

1. Download EUCMonitoringDashboard.

- Currently [HERE](https://github.com/littletoyrobots/EUCMonitoringDashboard)

2. Download the latest copy of v2_beta (or in my case, v2_TestEngine), as a zip file.

- Currently [HERE](https://github.com/dbretty/EUCMonitoring/tree/v2_beta)

- You might need to Right click the zip file -> properties -> Unblock. 

- You are expected to have any prerequisites of EUCMonitoring Project instance for your environment met 
already.

3. Open Powershell as administrator.

4. By defaults, we install to C:\Monitoring.  Navigate to and run

```
.\Install_EUCMonitoring.ps1 -EUCVersion C:\path\to\EUCMonitoring.zip
```

5. Edit C:\Monitoring\euc-monitoring.json to suit your environment.

6. Run the following with an account with appropriate admin permissions to your EUC Environment. 
```
.\Begin-EUCMonitor.ps1 
```
- or -
```
C:\Monitoring\Begin-EUCMonitor.ps1
```

7. Browse to ```https://localhost:8086/``` and login as admin/admin

8. To uninstall, run .\Uninstall-EUCMonitoring 



