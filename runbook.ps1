#########################################
# Parameters
#########################################
Param
(
    [Parameter(Mandatory = $true, HelpMessage = 'Retention time in days for the managed disk snapshots')]
    [String]
    $retentionTime,

    [Parameter(Mandatory = $true, HelpMessage = 'Azure Environment : AzureCloud, AzureChinaCloud, AzureGermanCloud, AzureUSGovernment')]
    [String]
    $azureEnvironment = "AzureCloud"
)
# We get current date
$dateFormat = "yyyy/MM/dd"
$date = Get-Date

################################################
# Connection to Azure
################################################
$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint `
        -EnvironmentName AzureChinaCloud
 }
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

################################################
# Performing snapshots
################################################
"Getting all the disks..."
$disks=Get-AzureRmDisk | Select Name,Tags,Id,Location,ResourceGroupName
"Looping through disks..."
foreach($disk in $disks) {
    Write-Output ("Processing disk: " + $disk.Name)
    foreach($tag in $disk.Tags) {
        if($tag.snapshot -eq 'True') {
            "Creating snapshot..."
            $scheduledDeletionDate = $date.AddDays($retentionTime).ToString($dateFormat)
            $snapshotConfig = New-AzureRmSnapshotConfig -SourceUri $disk.Id -Location $disk.location -SkuName Standard_LRS -CreateOption copy -Tag @{scheduledDeletionDate = "$scheduledDeletionDate"}
            $snapshotName = "snap" + $disk.Name + "-" + $date.Year + "-" + $date.Month + "-" + $date.Day + "-" + $date.Hour + "-" + $date.Minute + "-" + $date.Second
            $snapshot = New-AzureRmSnapshot -ResourceGroupName $disk.ResourceGroupName -SnapshotName $snapshotName -Snapshot $snapshotConfig
        }
    }
}

################################################
# Cleaning old snapshots
################################################
"Getting all the snapshots..."
$snapshots=Get-AzureRmSnapshot | Select Name,Tags,Id,Location,ResourceGroupName
"Looping through snapshots"
foreach($snapshot in $snapshots) {
    Write-Output ("--- Processing snapshot: " + $snapshot.Name)
    foreach($tag in $snapshot.Tags) {
        if(-Not [string]::IsNullOrEmpty($tag.scheduledDeletionDate)) {
            Write-Output ("Found scheduledDeletionDate: " + $tag.scheduledDeletionDate)
            [DateTime]$retrievedScheduledDeletionDate = New-Object DateTime
            if([DateTime]::TryParse($tag.scheduledDeletionDate, [ref]$retrievedScheduledDeletionDate))
            {
                if ($date -gt $retrievedScheduledDeletionDate) {
                    "Removing old expired snapshot"
                    Remove-AzureRmResource -ResourceId $snapshot.Id -Force
                }
                else {
                    "Keeping backup"
                }
            }
            else {
                    "Failed to parse date in tag"
            }
        }
        else {
            "Tag scheduledDeletionDate not found. Keeping snapshot"
        }
    }
}