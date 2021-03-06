##################################################################
#Script to run chkdsk on all volumes for a list of computers

#Created: 21/8/2017
#Version: 0.9.2
###################################################################

$LogFile = "result-$(get-date -f yyyy-MM-dd).csv"
$ComputersFilePath = "Computers.txt"

$ComputersArray = @()
$ResulteArray = @()

If (Test-Path $ComputersFilePath) {
    $ComputersArray = Get-Content $ComputersFilePath
}
Else {
    Write-Error "The $ComputersFilePath is not found, check the path."
}

ForEach ($ComputerName in $ComputersArray) {
    If (Test-Connection $ComputerName -Count 1 -ErrorAction SilentlyContinue) {
        $LogicalDisks = Get-WmiObject -ComputerName $ComputerName -Class Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue
        ForEach ( $LogicalDisk in $LogicalDisks) {
            $FixErrors = $false    # does not fix errors 
            $VigorousIndexCheck = $false     # performs a vigorous check of the indexes
            $SkipFolderCycle = $false    # does not skip folder cycle checking.
            $ForceDismount = $false    # will not force a dismount (to enable errors to be   fixed)
            $RecoverBadSecors = $false    # does not recover bad sectors
            $OKToRunAtBootup = $false    # runs now, vs at next bootup
            

            $DeviceID = $LogicalDisk.DeviceID

            $resultObject = New-Object PSObject -Property @{
                ComputerName = $ComputerName
                Volume       = $DeviceID
                Result       = ""
            }

            
            Write-Host("Start scan for volume $DeviceID on machine: $ComputerName")
            try {
                $res = $LogicalDisk.Chkdsk($FixErrors, $VigorousIndexCheck, $SkipFolderCycle, $ForceDismount, $RecoverBadSectors, $OKToRunAtBootUp)
                #bonus from http://msdn.microsoft.com/en-us/library/aa384915(v=vs.85).aspx     
                switch ($res.returnvalue) {
                    0 {
                        "..00 Success - Chkdsk Completed"
                        $resultObject.Result = "Success - Chkdsk Completed"
                    }
                    1 {
                        "..01 Success - Volume Locked and Chkdsk Scheduled on Reboot"
                        $resultObject.Result = "Success - Volume Locked and Chkdsk Scheduled on Reboot"
                    }
                    2 {
                        "..02 Failure - Unsupported File System"
                        $resultObject.Result = "Failure - Unsupported File System"
                    }
                    3 {
                        "..03 Failure - Unknown File System"
                        $resultObject.Result = "Failure - Unknown File System"
                    }
                    4 {
                        "..04 Failure - No Media in drive"
                        $resultObject.Result = "Failure - No Media in drive"
                    }
                    5 {
                        "..05 Failure - Unknown Error"
                        $resultObject.Result = "Failure - Unknown Error"
                    }
                }
                $ResulteArray += $resultObject
                Write-Host("..Scan Finished!")
            }
            catch {
                Write-Warning "Can't start scan for volume $VolName on machine: $ComputerName"
            }
            
        }

    }
    Else {
        write-warning("$ComputerName in the list is unreachable!")
    }

    try {
        $ResulteArray | Export-Csv -Path $LogFile
    }
    catch {
        write-warning("Can't write result to path: $LogFile")
    }

}