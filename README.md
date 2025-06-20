# TBAInfo PowerShell Module

**TBAInfo** (The Blue Alliance Info) is a PowerShell module designed to simplify access to data from [The Blue Alliance API v3](https://www.thebluealliance.com/apidocs). It provides a suite of functions to retrieve and analyze data related to the **FIRST Robotics Competition (FRC)**.

---

## Features

- Retrieve lists of all FRC events or teams by year
- Access detailed event data including team lists and match keys
- Fetch team-specific match data and names
- Calculate and retrieve OPR (Offensive Power Rating) and COPR (Calculated Offensive Power Rating) statistics

---

## Requirements

- **PowerShell 7+**
- A valid API key from The Blue Alliance Account Dashboard

---

## Installation

Install the module from the PowerShell Gallery:

```powershell
Install-Module TBAInfo
```

## Usage
1. To work correctly, the TBA API key must be entered into the JSON config file that this module uses.

```PowerShell
Update-TBAJsonAPIKey "MyAPIKey"
```
2. The JSON config file also has default values for the team_key (frc4611)parameter. It's recommended that these is value be changed to your team number. This can be done with the Update-TBAJsonEventKey function:

```PowerShell
Update-TBAJsonTeamKey frc4611
```
or

```PowerShell
Update-TBAJsonTeamKey 4611
```

3. Likewise, the default event key should be changed as well. It is currently set to 2025nyro, but can be changed with the Update-TBAJsonEventKey function.

```PowerShell
Update-TBAJsonEventKey 2025nyro
```

4. Functions that require a team or event key will default to the values in the JSON config file, but also accept -TeamKey and -EventKey parameters to supply different ones too.

5. Available functions to get TBA information include:
* Get-TBAAllEventListByYear
* Get-TBAAllTeamListByYear
* Get-TBAEventCOPR
* Get-TBAEventOPR
* Get-TBAEventRanking
* Get-TBAEventTeamList
* Get-TBATeamEventMatchInfo
* Get-TBATeamEventMatchKey
* Get-TBATeamEventOPR
* Get-TBATeamName

## Notes
* The structure of this repository is based on the [PSModuleDevelopment](https://github.com/PowershellFrameworkCollective/PSModuleDevelopment) module to get a template for a module.
* This module relies heavily on the API provided by [The Blue Alliance](https://www.thebluealliance.com/) and would not be possible without the work they do.