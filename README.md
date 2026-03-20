# Entra PowerShell Scripts

Practical PowerShell scripts for Microsoft Entra ID administration using Microsoft Graph.

This repository focuses on automating common administrative tasks that are typically performed manually. The goal is to create simple, repeatable workflows for bulk operations.

## Scripts

### `Add-Users-To-Entra-Group.ps1`

Bulk adds users to an Entra group from a CSV file.

**Key features**
- Uses Microsoft Graph PowerShell
- Accepts parameters for group ID and CSV path
- Validates input before making changes
- Processes users individually to avoid full script failure
- Provides clear success and failure output per user

## Requirements

- PowerShell 7
- Microsoft Graph PowerShell modules:
  - `Microsoft.Graph.Authentication`
  - `Microsoft.Graph.Users`
  - `Microsoft.Graph.Groups`

### Install required modules

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
Install-Module Microsoft.Graph.Users -Scope CurrentUser
Install-Module Microsoft.Graph.Groups -Scope CurrentUser
