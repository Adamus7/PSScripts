# Modify these 2 variables as needed
$outputFile = "C:\TEMP\result.txt";
$serverList = "C:\TEMP\serverlist.txt"
 
Function driveScan {
    [CmdletBinding()]
    Param (
        $diskDrive
    )
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$diskDrive'" | Select-Object Size, FreeSpace
    $total = "{0:N0}" -f ($disk.Size / 1GB) + " GB"
    $free = "{0:N0}" -f ($disk.FreeSpace / 1GB) + " GB"
    $value = New-Object PsObject -Property @{Total=$total ; free= $free }
    return $value
}

Function folderScan {
    [CmdletBinding()]
    Param (
        $customLocation
    )

$subDirectories = Get-ChildItem $customLocation | Where-Object{($_.PSIsContainer)} | foreach-object{$_.Name}

$folderOutput = @{}
foreach ($i in $subDirectories)
	{
	$targetDir = $customLocation + "\" + $i
	$folderSize = (Get-ChildItem $targetDir -Recurse -Force | Measure-Object -Property Length -Sum).Sum 2> $null
    $folderSizeComplete = "{0:N0}" -f ($folderSize / 1MB) + "MB" 
	$folderOutput.Add("$targetDir" , "$folderSizeComplete")
}
return $folderOutput

}

$Servers = Get-content $serverList
If (Test-Path $outputFile){
	Remove-Item $outputFile
}

Foreach ($Server in $Servers) {
Write-host "Scanning on $server ..."

$driveSpaceScanResult = Invoke-Command -ComputerName $Server -ScriptBlock ${Function:driveScan} -ArgumentList "c:"
$driveCScanResult = Invoke-Command -ComputerName $Server -ScriptBlock ${Function:folderScan} -ArgumentList "c:\"
$UsersFolderScanResult = Invoke-Command -ComputerName $Server -ScriptBlock ${Function:folderScan} -ArgumentList "c:\users"

$total = $driveSpaceScanResult.Total
$free = $driveSpaceScanResult.free

"Server: $server :" | out-file $outputFile -append
"===================" | out-file $outputFile -append
"Total capacity of C: - $Total" | out-file $outputFile -append
"Total space free on C: - $free" | out-file $outputFile -append
" " | out-file $outputFile -append
"Estimated folder sizes for C:\ :" | out-file $outputFile -append
$driveCScanResult.GetEnumerator() | sort-Object Name | format-table -autosize | out-file $outputFile -append
"Estimated folder sizes for Users :" | out-file $outputFile -append
$UsersFolderScanResult.GetEnumerator() | sort-Object Name | format-table -autosize | out-file $outputFile -append
" " | out-file $outputFile -append
" " | out-file $outputFile -append
Write-host "Done."

}
