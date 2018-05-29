##################################################################
#Script to collect server information and generate a HTML report
#Script File Name: ServerInfor.ps1 
#Date Created: 18/8/2017 
###################################################################

$TargetServer = $env:computername;

#Helper Functions
function CreateItem ($itemName, $itemValue) {
    return New-Object PSObject -Property @{
        Item  = $itemName
        Value = $itemValue
    }
}

Function Convert-Size {
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [Alias("Length")]
        [int64]$Size
    )
    Begin {
        If (-Not $ConvertSize) {
            Write-Verbose ("Creating signature from Win32API")
            $Signature = @"
                 [DllImport("Shlwapi.dll", CharSet = CharSet.Auto)]
                 public static extern long StrFormatByteSize( long fileSize, System.Text.StringBuilder buffer, int bufferSize );
"@
            $Global:ConvertSize = Add-Type -Name SizeConverter -MemberDefinition $Signature -PassThru
        }
        Write-Verbose ("Building buffer for string")
        $stringBuilder = New-Object Text.StringBuilder 1024
    }
    Process {
        Write-Verbose ("Converting {0} to upper most size" -f $Size)
        $ConvertSize::StrFormatByteSize( $Size, $stringBuilder, $stringBuilder.Capacity ) | Out-Null
        $stringBuilder.ToString()
    }
}

function Get-LocalGroupMembers {  
    param(  
        [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]  
        [Alias("Name")]  
        [string]$ComputerName = "localhost",
        [string]$GroupName = "Administrators"  
    )  
      
    begin {}  
      
    process {  
        # If the account name of the computer object was passed in, it will  
        # end with a $. Get rid of it so it doesn't screw up the WMI query.  
        $ComputerName = $ComputerName.Replace("`$", '')  
  
        # Initialize an array to hold the results of our query.  
        $arr = @()  
  
        # Get hostname of remote system.  $computername could reference cluster/alias name.  Need real hostname for subsequent WMI query. 
        $hostname = (Get-WmiObject -ComputerName $ComputerName -Class Win32_ComputerSystem).Name 
 
        $wmi = Get-WmiObject -ComputerName $ComputerName -Query "SELECT * FROM Win32_GroupUser WHERE GroupComponent=`"Win32_Group.Domain='$Hostname',Name='$GroupName'`""  
  
        # Parse out the username from each result and append it to the array.  
        if ($wmi -ne $null) {  
            foreach ($item in $wmi) {  
                $data = $item.PartComponent -split "\," 
                $domain = ($data[0] -split "=")[1] 
                $name = ($data[1] -split "=")[1] 
                $arr += ("$domain\$name").Replace("""", "") 
                [Array]::Sort($arr) 
            }  
        }  
  
        $hash = @{ComputerName = $ComputerName; Members = $arr}  
        return $hash  
    }  
      
    end {}  
}

#endregin Helper Functions

$htmlFragment = "";
Write-Host "Collecting server information...."
#region check server details HTML Report
$SectionItems = @()

$OperatingSystem = Get-WmiObject -class Win32_OperatingSystem
$ComputerSystem = Get-WmiObject -class Win32_ComputerSystem
$BIOS = Get-WmiObject -class Win32_BIOS

$SectionItems += CreateItem "Hostname" $TargetServer
$SectionItems += CreateItem "Operation System" ($OperatingSystem.Caption + " " + $OperatingSystem.BuildNumber)
$SectionItems += CreateItem "Domain Name" $ComputerSystem.Domain
$SectionItems += CreateItem "Hardware Model" ($ComputerSystem.Model + " " + $ComputerSystem.Manufacturer)
#$SectionItems += CreateItem "Serial Number" $OperatingSystem.SerialNumber
$SectionItems += CreateItem "BIOS Serial Number" $BIOS.SerialNumber

$Pre = "<div class ='section-title'>Server Details</div>"
$Body = $SectionItems | ConvertTo-Html -Property item, value -Fragment | Out-String
$Post = "<br>"
$htmlFragment += $Pre, $Body, $Post
#endregion check server details HTML Report

Write-Host "Collecting Network Information...."
#region TCP IPv6 disabled HTML Report
#read the key HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters /v DisabledComponents = 0xff
$SectionItems = @()
$targetKey = Get-ItemProperty -Path hklm:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters
if($targetKey.DisabledComponents){
    $SectionItems += CreateItem "TCP IPv6 disabled" ("DisabledComponents = " + $targetKey.DisabledComponents)
}
else{
    $SectionItems += CreateItem "TCP IPv6 disabled" "Default"
}


$Pre = "<div class ='section-title'>IPv6 Configuration</div>"
$Body = $SectionItems | ConvertTo-Html -Property item, value -Fragment | Out-String
$Post = "<div style ='font-size: 11px; padding: 5px 20px; color: #000;' ><I><B>Note*:</B><br>
Type 0 to re-enable all IPv6 components (Windows default setting).<br>
Type 0xff to disable all IPv6 components except the IPv6 loopback interface. This value also configures Windows to prefer using IPv4 over IPv6 by changing entries in the prefix policy table.<br>
Type 0x20 to prefer IPv4 over IPv6 by changing entries in the prefix policy table.<br>
Type 0x10 to disable IPv6 on all nontunnel interfaces (both LAN and Point-to-Point Protocol [PPP] interfaces).<br>
Type 0x01 to disable IPv6 on all tunnel interfaces. These include Intra-Site Automatic Tunnel Addressing Protocol (ISATAP), 6to4, and Teredo.<br>
Type 0x11 to disable all IPv6 interfaces except for the IPv6 loopback interface.<br>
</I></div>
<br>"
$htmlFragment += $Pre, $Body, $Post
#endregion TCP IPv6 disabled HTML Report

#region network HTML Report
#

$NetworkAdapters = Get-WmiObject Win32_NetworkAdapter | Foreach-Object {
    $nac = @($_.GetRelated('Win32_NetworkAdapterConfiguration'))[0]
    
    New-Object PSObject -Property @{
        Name                         = $_.Name
        Index                        = $_.Index
        IsIPEnabled                  = $nac.IPEnabled
        DHCPEnabled                  = $nac.DHCPEnabled
        IPAddress                    = $nac.IPAddress
        SubnetMask                   = $nac.IPSubnet
        DefaultIPGateway             = $nac.DefaultIPGateway
        DNSServer                    = $nac.DNSServerSearchOrder
        NetconnectionID              = $_.NetconnectionID
        Speed                        = $_.Speed | Convert-Size
        FullDNSRegistrationEnabled = $nac.FullDNSRegistrationEnabled
    }
}

$Body = ""

foreach ($NIC in $NetworkAdapters) {
    $SectionItems = @()
    $IPAddressString = ""
    $SubnetMaskString = ""
    $DNSServersString = ""
    $DefaultGatewayString = ""

    If ($NIC.IPAddress -ne $null) {
        $IPAddressString = $NIC.IpAddress[0]
    }
    
    If ($NIC.SubnetMask -ne $null) {
        $SubnetMaskString = $NIC.SubnetMask[0]
    }

    if ($NIC.DNSServer -ne $null) {
        $DNSServersString = [string]::join("; ", $NIC.DNSServer);
    }
 
    if ($NIC.DefaultIPGateway -ne $null) {
        $DefaultGatewayString = [string]::join("; ", $NIC.DefaultIPGateway);
    }

    $DuplexString = "False"
    if ($NIC.Duplex) {
        $DuplexString = "True"
    }

    $IPEnabledString = "False"
    if ($NIC.IsIPEnabled) {
        $IPEnabledString = "True"
    }
    
    $FullDNSRegistrationEnabledString = "False"
    if ($NIC.FullDNSRegistrationEnabled) {
        $FullDNSRegistrationEnabledString = "True"
    }

    $SectionItems += CreateItem "NIC Name" $NIC.Name
    $SectionItems += CreateItem "IP Enabled" $IPEnabledString
    if ($Nic.IsIPEnabled) {
        $SectionItems += CreateItem "IP Addressd" $IPAddressString
        $SectionItems += CreateItem "SubnetMask" $SubnetMaskString
        $SectionItems += CreateItem "Gateway" $DefaultGatewayString
        $SectionItems += CreateItem "DNSServers" $DNSServersString
    }
    $SectionItems += CreateItem "NIC Speed" $NIC.Speed
    $SectionItems += CreateItem "Register this connection's addresses in the DNS" $FullDNSRegistrationEnabledString

    #Compile HTML part for each NIC

    $Body += $SectionItems | ConvertTo-Html -Property item, value -Fragment | Out-String

}

$Pre = "<div class ='section-title'>NICs Details </div>"
$Post = "<br>"
$htmlFragment += $Pre, $Body, $Post
$SectionItems = @()

#endregion network interface HTML Report

Write-Host "Collecting Activation Status...."
#region Windows Activation Status HTML Report
$SectionItems = @()
$slmgrStatus = cscript c:\windows\system32\slmgr.vbs /dlv

If (($slmgrStatus | Out-String).Contains("License Status: Licensed")) {
    $SectionItems += CreateItem "License Status" "Licensed"
}
else {
    $SectionItems += CreateItem "License Status" "Unlicensed"
}

$Pre = "<div class ='section-title'>Windows Activation Stauts</div>"
$Body = $SectionItems | ConvertTo-Html -Property item, value -Fragment | Out-String
$Post = "<br>"
$htmlFragment += $Pre, $Body, $Post
#endregion Windows Activation Status HTML Report

Write-Host "Collecting Disks Status...."
#region Logical Disks usage HTML Report
$SectionItems = @()
$LogicalDisks = Get-WMIObject Win32_LogicalDisk | Select-Object DeviceID, VolumeName, Size, FreeSpace

foreach ($Disk in $LogicalDisks) {
    $SectionItems += New-Object PSObject -Property @{
        Volume    = $Disk.DeviceID
        Name      = $Disk.VolumeName
        Size      = $Disk.Size | Convert-Size
        FreeSpace = $Disk.FreeSpace | Convert-Size
    }
}

$Pre = "<div class ='section-title'>Logical Disks Details </div>"
$Post = "<br>"
$Body = $SectionItems | ConvertTo-Html -Property Volume, Name, Size, FreeSpace -Fragment | Out-String
$htmlFragment += $Pre, $Body, $Post
$SectionItems = @()
#endregion Logical Disks usage HTML Report

Write-Host "Collecting System Environmental Variables...."
#region System Environmental Variables HTML Report
$EnvVariables = Get-ChildItem Env:
$Pre = "<div class ='section-title'>System Environmental Variables</div>"
$Post = "<br>"
$Body = $EnvVariables | ConvertTo-Html -Property Name, Value -Fragment | Out-String
$htmlFragment += $Pre, $Body, $Post

#endregion System Environmental Variables HTML Report

Write-Host "Collecting PageFile settings...."
#region PageFile HTML Report
$PageFile = Get-WmiObject Win32_PageFileusage | Select-object Caption, Name, PeakUsage, CurrentUsage

$Pre = "<div class ='section-title'>Page File Details</div>"
$Post = "<br>"
$Body = $PageFile | ConvertTo-Html -Fragment | Out-String
$htmlFragment += $Pre, $Body, $Post

#endregion PageFile HTML Report

Write-Host "Collecting Services details...."
#region Services Status
$SectionItems = @()
$TargetServicesNameList = "Windows Update", "Print Spooler", "OfficeScan NT Listener", "OfficeScan NT RealTime Scan", "Quest KACE Agent WatchDog", "Quest KACE Offline Scheduler", "Quest KACE One Agent"
foreach ($TargetServiceName in $TargetServicesNameList) {
    $TargetService = Get-Service | Where-Object {$_.DisplayName -eq $TargetServiceName}
    if ($TargetService) {
        $SectionItems += New-Object PSObject -Property @{
            ServicesName = $TargetService.DisplayName
            Status       = $TargetService.Status 
        }
    }
    else {
        $SectionItems += New-Object PSObject -Property @{
            ServicesName = $TargetServiceName
            Status       = "Couldn't find this Service on this machine."
        } 
    }
}

$Pre = "<div class ='section-title'>Services Status</div>"
$Post = "<br>"
$Body = $SectionItems | ConvertTo-Html -Fragment | Out-String
$htmlFragment += $Pre, $Body, $Post
$SectionItems = @()
#endregion Services Status

#region Autostart but stopped Services
$SectionItems = @()
$AutostartButNotRuningServicesList = Get-Service | Where-Object {$_.StartType -eq "Automatic" -and $_.Status -ne "Running"}
if ($AutostartButNotRuningServicesList.Count -ne 0) {
    foreach ($Service in $AutostartButNotRuningServicesList) {
        $SectionItems += New-Object PSObject -Property @{
            ServicesName = $Service.DisplayName
            StartType    = $Service.StartType
            Status       = $Service.Status
        }
    }
}

$Pre = "<div class ='section-title'>Autostart but Stopped Services</div>"
$Post = "<br>"
$Body = $SectionItems | ConvertTo-Html -Fragment | Out-String
$htmlFragment += $Pre, $Body, $Post
$SectionItems = @()
#endregion Autostart but stopped Services

Write-Host "Collecting NTP Server information...."
#region NTP status
$SectionItems = @()
$NTPStatus = w32tm /query /status

foreach ( $item in $NTPStatus) {
    $SectionItems += New-Object PSObject -Property @{
        NTPStatus = $item | Out-String
    }
}

$Pre = "<div class ='section-title'>NTP Status</div>"
$Post = "<br>"
$Body = $SectionItems | ConvertTo-Html -Fragment | Out-String
$htmlFragment += $Pre, $Body, $Post
$SectionItems = @()
#endregion NTP status

Write-Host "Collecting Event logs...."
#region Security, System and Application log file sizes
$SectionItems = @()

$TargetEventLogNameList = "Security", "Application", "System"
foreach ($TargetEventLogName in $TargetEventLogNameList) {
    $TargetEventLog = Get-Eventlog -list | Where-Object {$_.Log -eq $TargetEventLogName}
    if ($TargetEventLog) {
        $SectionItems += New-Object PSObject -Property @{
            Log        = $TargetEventLogName
            MaxSize_KB = $TargetEventLog.MaximumKilobytes
        }
    }
    else {
        $SectionItems += New-Object PSObject -Property @{
            Log     = $TargetEventLogName
            MaxSize = "No such log"
        } 
    }
}

$Pre = "<div class ='section-title'>Security, System and Application log file sizes</div>"
$Post = "<br>"
$Body = $SectionItems | ConvertTo-Html -Property Log, MaxSize_KB -Fragment | Out-String
$htmlFragment += $Pre, $Body, $Post
$SectionItems = @()
#endregion Security, System and Application log file sizes

#region Errors and Warnings for Last 30 Days in System Eventlog
$SectionItems = @()

$ErrorandWarnings = Get-EventLog -LogName System -EntryType Error, Warning -After (Get-Date).AddDays(-30)

$Pre = "<div class ='section-title'>Errors and Warnings for Last 30 Days in System Eventlog</div>"
$Post = "<br>"
$Body = $ErrorandWarnings | ConvertTo-Html -Property Index, TimeGenerated, EntryType, InstanceID, Message -Fragment | Out-String
$htmlFragment += $Pre, $Body, $Post
$SectionItems = @()
#endregion Errors and Warnings for Last 30 Days in System Eventlog

Write-Host "Collecting Users and Groups information...."
#region Group Information
$SectionItems = @()

$Groups = Get-WMIObject -Class Win32_Group -Filter "LocalAccount=True" | Select-Object Name,Description

foreach ($item in $Groups) {
    $SectionItems += New-Object PSObject -Property @{
        GroupName = $item.Name
        Comments = $item.Description
        Members =  [string]::Join("; ",(Get-LocalGroupMembers -ComputerName $TargetServer -GroupName $item.Name).Members)
    }

}

$Pre = "<div class ='section-title'>Local Groups</div>"
$Post = "<br>"
$Body = $SectionItems | ConvertTo-Html -Property GroupName, Comments, Members -Fragment | Out-String
$htmlFragment += $Pre, $Body, $Post
$SectionItems = @()
#endregion Group Information

#region LocalUlser Information
$SectionItems = @()

$Users = Get-WmiObject -Class Win32_UserAccount -Filter  "LocalAccount='True'" | Select-Object Caption, Disabled, Description

foreach ($item in $Users) {
    $SectionItems += New-Object PSObject -Property @{
        UserName = $item.Caption
        Enabled = !$item.Disabled
        Description = $item.Description
    }

}

$Pre = "<div class ='section-title'>Local Users</div>"
$Post = "<br>"
$Body = $SectionItems | ConvertTo-Html -Property UserName, Enabled, Description -Fragment | Out-String
$htmlFragment += $Pre, $Body, $Post
$SectionItems = @()
#endregion Group Information

Write-Host "Collecting network sharing information...."
#region Network folder share information
$SectionItems = @()

$SharingFolders = get-WmiObject -class Win32_Share -computer localhost | Select-object Caption, Name, Path, Description

$Pre = "<div class ='section-title'>Sharing Network Folder Information</div>"
$Post = "<br>"
$Body = $SharingFolders | ConvertTo-Html -Property Caption, Name, Path, Description -Fragment | Out-String
$htmlFragment += $Pre, $Body, $Post
$SectionItems = @()
#endregion Network folder share information

Write-Host "Collecting installed softwares...."
#region Installed Softwares
$SectionItems = @()
$InstalledSofterwares = @();
#Local machine x64 softwares
if(Test-Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*){
$InstalledSofterwares += Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Where {$_.DisplayName -ne $null}
}
#Local machine x86 softwares
if(Test-Path HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*){
$InstalledSofterwares += Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Where {$_.DisplayName -ne $null}
}
#Local user x64 softwares
if(Test-Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*){
$InstalledSofterwares += Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Where {$_.DisplayName -ne $null}
}
#Local user x86 softwares
if(Test-Path HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*){
$InstalledSofterwares += Get-ItemProperty HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Where {$_.DisplayName -ne $null}
}

$Pre = "<div class ='section-title'>Installed Softwares</div>"
$Post = "<br>"
$Body = $InstalledSofterwares | ConvertTo-Html -Property DisplayName, DisplayVersion, Publisher, InstallDate -Fragment | Out-String
$htmlFragment += $Pre, $Body, $Post
$SectionItems = @()
#endregion Installed Softwares

#region Compile HTML Report
$HTMLParams = @{
    Head        = $Head
    Title       = "Report for $TargetServer"
    PreContent  = "<H1><font color='white'>Please view in html!</font><br>$TargetServer Report</H1>"
    PostContent = "$($htmlFragment)<i>Report generated on $((Get-Date).ToString())</i>" 
}
$Report = ConvertTo-Html @HTMLParams -CssUri "stylesheet.css" | Out-String
#endregion Compile HTML Report

$ShowFile = $TRUE;
If ($ShowFile) {
    $Report | Out-File ServerReport.html -Encoding "UTF8"
    Invoke-Item ServerReport.html
}
Write-Host "Done!"

