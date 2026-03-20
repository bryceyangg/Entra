param(
    [Parameter(Mandatory = $false)]
    [string]$GroupId,

    [Parameter(Mandatory = $false)]
    [string]$CsvPath
)

Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups

# Prompt if not provided
if (-not $GroupId) {
    $GroupId = Read-Host "Enter the Entra Group Object ID"
}

if (-not $CsvPath) {
    $CsvPath = Read-Host "Enter the full path to the CSV file"
}

# Connect if not already connected
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "User.Read.All","Group.ReadWrite.All" -NoWelcome
}

# Validate CSV
if (-not (Test-Path $CsvPath)) {
    Write-Error "CSV file not found at: $CsvPath"
    return
}

# Validate Group
try {
    $Group = Get-MgGroup -GroupId $GroupId -ErrorAction Stop
    Write-Host "Target group: $($Group.DisplayName)" -ForegroundColor Cyan
}
catch {
    Write-Error "Invalid group ID or insufficient permissions."
    return
}

# Import CSV
$Users = Import-Csv -Path $CsvPath

if (-not ($Users[0].PSObject.Properties.Name -contains "UserPrincipalName")) {
    Write-Error "CSV must contain 'UserPrincipalName' column."
    return
}

# Get existing members
$ExistingMembers = Get-MgGroupMember -GroupId $GroupId -All | Select-Object -ExpandProperty Id

# Prepare logging
$Results = @()

Write-Host "Processing $($Users.Count) users..." -ForegroundColor Cyan

foreach ($Entry in $Users) {
    $UserUpn = $Entry.UserPrincipalName

    try {
        $User = Get-MgUser -UserId $UserUpn -ErrorAction Stop

        if ($User.Id -in $ExistingMembers) {
            Write-Host "Already in group: $UserUpn" -ForegroundColor Yellow
            $Results += [PSCustomObject]@{
                UserPrincipalName = $UserUpn
                Status            = "AlreadyInGroup"
                Message           = "User already a member"
            }
            continue
        }

        New-MgGroupMemberByRef -GroupId $GroupId -BodyParameter @{
            "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($User.Id)"
        } -ErrorAction Stop

        Write-Host "Added: $UserUpn" -ForegroundColor Green

        $Results += [PSCustomObject]@{
            UserPrincipalName = $UserUpn
            Status            = "Added"
            Message           = "Success"
        }
    }
    catch {
        Write-Warning "Failed: $UserUpn -- $($_.Exception.Message)"

        $Results += [PSCustomObject]@{
            UserPrincipalName = $UserUpn
            Status            = "Failed"
            Message           = $_.Exception.Message
        }
    }
}

# Export results
$LogPath = Join-Path (Split-Path $CsvPath) "Add-Users-Results.csv"
$Results | Export-Csv -Path $LogPath -NoTypeInformation

# Summary
Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "Added: $($Results | Where-Object {$_.Status -eq 'Added'} | Measure-Object | Select -ExpandProperty Count)" -ForegroundColor Green
Write-Host "Already in group: $($Results | Where-Object {$_.Status -eq 'AlreadyInGroup'} | Measure-Object | Select -ExpandProperty Count)" -ForegroundColor Yellow
Write-Host "Failed: $($Results | Where-Object {$_.Status -eq 'Failed'} | Measure-Object | Select -ExpandProperty Count)" -ForegroundColor Red
Write-Host "Log saved to: $LogPath" -ForegroundColor Cyan
