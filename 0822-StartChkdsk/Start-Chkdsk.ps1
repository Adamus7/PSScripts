

Function Start-Chkdsk 
{
<# 
	.SYNOPSIS 
		Remote scan disk.
		
	.DESCRIPTION 
		Use Start-Chkdsk to remotly start scan disk on specified machines in domain or workgroup.

	.PARAMETER ComputerName 
		Specific Computer Name or Ldap path to object or set of object like computer, OU or whole domain.

	.PARAMETER VolumeList
		Get list of volume on specific machine.
	
	.PARAMETER Volume
		Select volume to scan disk.
		
	.PARAMETER GetEventLog
		Search event log after scan disk.
	
	.PARAMETER FixErrors 
		Indicates what should be done to errors found on the disk. If true, then errors are fixed.
	
	.PARAMETER VigorousIndexCheck 
		If true, a vigorous check of index entries should be performed.
 
	.PARAMETER SkipFolderCycle 
		If true, the folder cycle checking should be skipped.

	.PARAMETER ForceDismount 
		If true, the drive should be forced to dismount before checking.
 
	.PARAMETER RecoverBadSectors 
		If true, the bad sectors should be located and the readable information should be recovered from these sectors.
 
	.PARAMETER OKToRunAtBootUp 
		If true, the chkdsk operation should be performed at next boot up time, in case the operation could not be performed because the disk is locked at time this method is called.

	.EXAMPLE 
		Get-ADComputer PC1 | Start-Chkdsk

		Scan machine PC1 on Volume C: Success - Chkdsk Completed.
		Scan machine PC1 on Volume D: Success - Chkdsk Completed.

	.EXAMPLE 
		Start-Chkdsk -ComputerName "CN=Computers,DC=your,DC=domain,DC=com" -FixErrors -SkipFolderCycle

		Scan machine PC1 on Volume C: Success - Locked and Chkdsk Scheduled on Reboot. You must manually get eventlog later.
		Scan machine PC1 on Volume D: Success - Locked and Chkdsk Scheduled on Reboot. You must manually get eventlog later.
		Scan machine PC2 on Volume C: Success - Locked and Chkdsk Scheduled on Reboot. You must manually get eventlog later.
		Scan machine PC3 on Volume C: Success - Locked and Chkdsk Scheduled on Reboot. You must manually get eventlog later.
		
	.EXAMPLE 
		"PC1", "PC2" | Start-Chkdsk -VolumeList | Format-Table * -AutoSize

		ComputerName DeviceID FileSystem Size[GB] Description
		------------ -------- ---------- -------- -----------
		PC1          A:                         0 Stacja dyskietek 3,5 cala
		PC1          C:       NTFS             59 Lokalny dysk stały
		PC1          D:       NTFS            407 Lokalny dysk stały
		PC1          E:                         0 Dysk CD-ROM
		PC2          C:       NTFS            114 Lokalny dysk stały
		PC2          D:                         0 Dysk CD-ROM
		PC2          E:                         0 Dysk CD-ROM

	.NOTES 
		Author: Michal Gajda 
#>

	[CmdletBinding(
		SupportsShouldProcess=$True,
		ConfirmImpact="Low" 
	)]	
	param(
		[Parameter(ValueFromPipeline=$True)]
		[String]$ComputerName = "LocalHost",
		[Switch]$VolumeList,
		[Switch]$GetEventLog,
		[String]$Volume = "",
		[Switch]$FixErrors = $false,
		[Switch]$VigorousIndexCheck  = $false,
		[Switch]$SkipFolderCycle  = $false,
		[Switch]$ForceDismount  = $false,
		[Switch]$RecoverBadSectors  = $false,
		[Switch]$OKToRunAtBootUp  = $false
	)

	Begin{}

	Process
	{
		if($ComputerName -match "=")
		{
			Write-Verbose "Searching LDAP Objects in path: $ComputerName" 
			$Searcher=[adsisearcher]"(&(objectCategory=computer)(objectClass=computer))" 

			$ComputerName = ([String]$ComputerName).replace("LDAP://","")
			$Searcher.SearchRoot="LDAP://$ComputerName"
			$Results=$Searcher.FindAll()
			$Direct = $false			
		}
		else
		{
			Write-Verbose "Direct access to specific machine: $ComputerName" 
			$Results = $ComputerName			
			$Direct = $true
		}
		
		$ScanStartTime = get-date -uformat "%Y-%m-%d %H:%M:%S"
		
		Foreach($result in $results)
		{
			if($Direct)
			{
				$ComputerName = $result 
			}
			else
			{
				$ComputerName = $result.Properties.Item("Name") 
			}
			
			if($VolumeList)
			{
				if ($pscmdlet.ShouldProcess($ComputerName,"Get volume list"))
				{
					Write-Verbose "Geting volume list on machine: $ComputerName" 
					$disks = Get-WmiObject -ComputerName $ComputerName -Class Win32_LogicalDisk -ErrorAction SilentlyContinue
					if($disks -eq $null)
					{
						Write-Warning "Can't get volume list on machine: $ComputerName"
					}
					else
					{
						$disks | select @{Labe="ComputerName";Expression={$ComputerName}}, DeviceID, FileSystem, @{Label="Size[GB]";Expression={[int]($_.Size/1GB)}}, Description
					}
				}	
			}
			else
			{
				if($Volume -eq "")
				{
					$msg = "Scan volume"
				}
				else
				{
					$msg = "Scan volume $Volume"
				}
				
				if ($pscmdlet.ShouldProcess($ComputerName,$msg))
				{
					if($Volume -eq "")
					{
						Write-Verbose "Geting volume list on machine: $ComputerName" 
						$disks = Get-WmiObject -ComputerName $ComputerName -Class Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue
						if($disks -eq $null)
						{
							Write-Warning "Can't get volume list on machine: $ComputerName"
						}	
					}
					else
					{
						$wql = ""
						$Volume | ForEach { 
							if($wql -ne "")
							{
								$wql += " or "
							}
							$wql = "DeviceID='$($_):'"
						
						}
						Write-Verbose "Geting selected volume list $Volume on machine: $ComputerName" 
						Try
						{
							$disks = Get-WmiObject -ComputerName $ComputerName -Class Win32_LogicalDisk -Filter $wql -ErrorAction SilentlyContinue
						}
						Catch
						{
							Write-Warning "Can't get volume list on machine: $ComputerName"
						}
					}
					
					if($disks -ne $null)
					{
						$disks | foreach {
							$VolName = $_.DeviceID
							Write-Verbose "Start scan for volume $VolName on machine: $ComputerName" 
							Try
							{
								$result = $_.Chkdsk($FixErrors, $VigorousIndexCheck, $SkipFolderCycle, $ForceDismount, $RecoverBadSectors, $OKToRunAtBootUp)
								Write-Host $ReturnValue
								switch($result.ReturnValue)
								{
									0 { Write-Host "Scan machine $ComputerName on Volume "+$VolName+": Success - Chkdsk Completed."}
									1 { Write-Host "Scan machine $ComputerName on Volume "+$VolName+": Success - Locked and Chkdsk Scheduled on Reboot. You must manually get eventlog later."}
									2 { Write-Warning "Scan machine $ComputerName on Volume "+$VolName+": Failure - Unknown File System."}
									3 { Write-Warning "Scan machine $ComputerName on Volume "+$VolName+": Failure - Unknown Error."}
								}
							}
							Catch
							{
								Write-Warning "Can't start scan for volume $VolName on machine: $ComputerName"
							}
						}
					
						if($GetEventLog)
						{
							Get-EventLog -ComputerName $ComputerName -LogName system -After $ScanStartTime  -Source "disk" -ErrorAction SilentlyContinue | Select-Object Index, TimeGenerated, EntryType, Message | Format-Table * -AutoSize
						}
					}
				}
			}
		}
	}
	
	End{}
}

