# AKS-backup-disks
Azure Automation Runbook to backup Azure Disks used by AKS (Azure Kubernetes Service).

# Description
If you are using Azure Disks along with AKS, you have probably asked your self how to backup those Azure Disks. Since the disks are not part of an Azure VM, you cannot back them up easily.

We came up with an Azure Automation Runbook that will take snapshots of your disks and will keep them for a certain amount of time

# Features
- Disks inclusion / exclusion
- Configurable retention days
- Automatic deletion of old backups

# Usage

1. Azure Automation

Create a new Azure Automation account or use an existing one.

2. Runbook

Create a new runbook by importing the runbook.ps1 file of this git repository. Runbook type will be "PowerShell".

3. Azure Disks

Add a new tag to the Azure Disks you want to backup:
- Name: snapshot
- Value: true

By adding this tag, you indicate the runbook that you want this disk to be part of your backups.

4. Schedule runbook

You can now schedule your runbook, to run for example on a daily basis.
You will have to provide two parameters:
- Retention Time: Number of days you want to keep your backups
- Azure Environment: Defaults to AzureCloud, but can be AzureChinaCloud, AzureGermanCloud or AzureUSGovernment (See Get-AzEnvironment command)

# Tips

## Backup policy
You can schedule the workbook twice to perform Daily backups and also Monthly backups, both with different retention time: 
-  **Daily Backups**: Every day with retention time = 40 days
- **Monthly Backups**: First day of every month with retention time = 365 days

This config will allow you to have a backup of the last 40 days (1 backup per day) as well as a backup of the last 12 month (1 backup per month).