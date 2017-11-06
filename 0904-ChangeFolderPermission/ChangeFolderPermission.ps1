# $Path = "C:\Projects"

# $SubFoldersOfProjects = Get-ChildItem $Path -Recurse -Directory

# Foreach ($ProjectFolder in $SubFoldersOfProjects) {
#     if ($ProjectFolder.FullName.Contains("F1100 Architects Appintment\F1101 Terms of Appointment\Invoices")) {
#         $ProjectFolder.FullName
#     }
# }

$Path = "C:\Projects"

$SubFolders = Get-ChildItem $Path -Directory

Foreach ($Folder in $SubFolders) {
    $TargePath = $Folder.FullName + "\F1100 Architects Appintment\F1101 Terms of Appointment\Invoices"
    $TargetFolder = Get-Item $TargePath
    # if ($TargetFolder.FullName.Contains("F1100 Architects Appointment\F1101 Terms of Appointment\Invoices")) {
    #     $TargetFolder.FullName
    # }
}

$Path = "e:\05800-06499"
#$Path = "D:\10000-11500\11107\AD\F1100 Architects Appointment\F1101 Terms of Appointment"

$SubFolders = Get-ChildItem $Path -Directory

Foreach ($Folder in $SubFolders) {
    $TargetFolderPath = $Folder.FullName + "\AD\F1100 Architects Appointment\F1101 Terms of Appointment\Invoices"
    $TargetFolder = Get-Item $TargetFolderPath

    ##   if ($TargetFolder.FullName.Contains("\AD\F1100 Architects Appointment\F1101 Terms of Appointment\Invoices")) {
    Write-host "Setting Permissions for:" $TargetFolder.FullName
    $Acl = Get-Acl $TargetFolder.FullName
    $Group = New-Object System.Security.Principal.NTAccount("Builtin", "Administrators")
    $Acl.SetOwner($Group)
    $Acl.SetAccessRuleProtection($true, $false)
    $inherit = [system.security.accesscontrol.InheritanceFlags]"ContainerInherit,ObjectInherit"
    $propagation = [system.security.accesscontrol.PropagationFlags]"None"
    $accessrule_1 = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", $inherit, $propagation, "Allow")
    $Acl.AddAccessRule($accessrule_1)

    $accessrule_2 = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrator@benoy.co.uk", "FullControl", $inherit, $propagation, "Allow")
    $Acl.AddAccessRule($accessrule_2)

    $accessrule_3 = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", $inherit, $propagation, "Allow")
    $Acl.AddAccessRule($accessrule_3)

    $accessrule_4 = New-Object System.Security.AccessControl.FileSystemAccessRule("_HK Project Finance@benoy.co.uk", "Modify, Synchronize", $inherit, $propagation, "Allow")
    $Acl.AddAccessRule($accessrule_4)

    Set-Acl -AclObject $Acl $TargetFolder.FullName
    Write-Host "..Done."
       
    #    }
}