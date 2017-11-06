$UserProfiles = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" | Where {$_.PSChildName -match "S-1-5-21-(\d+-?){4}$" } | Select-Object @{Name = "SID"; Expression = {$_.PSChildName}}, @{Name = "UserHive"; Expression = {"$($_.ProfileImagePath)\NTuser.dat"}}

# Add in the .DEFAULT User Profile
$DefaultProfile = "" | Select-Object SID, UserHive
$DefaultProfile.SID = ".DEFAULT"
$DefaultProfile.Userhive = "C:\Users\Default\NTuser.dat"
$UserProfiles += $DefaultProfile

# Loop through each profile on the machine</p>
Foreach ($UserProfile in $UserProfiles) {
    # Load User ntuser.dat if it's not already loaded
    If (($ProfileWasLoaded = Test-Path Registry::HKEY_USERS\$($UserProfile.SID) -ErrorAction SilentlyContinue) -eq $false) {
        Start-Process -FilePath "CMD.EXE" -ArgumentList "/C REG.EXE LOAD HKU\$($UserProfile.SID) $($UserProfile.UserHive)" -Wait -WindowStyle Hidden
    }

    # Manipulate the registry
    $key_1 = "Registry::HKEY_USERS\$($UserProfile.SID)\Control Panel\International"
    New-ItemProperty -Path $key_1 -Name "Locale" -Value "00000C09" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "LocaleName" -Value "en-AU" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "s1159" -Value "AM" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "s2359" -Value "PM" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "sCountry" -Value "Australia" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "sCurrency" -Value "$" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "sDate" -Value "/" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "sDecimal" -Value "." -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "sGrouping" -Value "3;0" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "sLanguage" -Value "ENA" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "sList" -Value "," -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "sLongDate" -Value "dddd, d MMMM yyyy" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "sMonDecimalSep" -Value "." -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "sMonGrouping" -Value "3;0" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "sMonThousandSep" -Value "," -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "sNativeDigits" -Value "0123456789" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "sNegativeSign" -Value "-" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "sPositiveSign" -Value "" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "sShortDate" -Value "d/MM/yyyy" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "sThousand" -Value "," -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "sTime" -Value ":" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "sTimeFormat" -Value "h:mm:ss tt" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "sShortTime" -Value "h:mm tt" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "sYearMonth" -Value "MMMM yyyy" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "iCalendarType" -Value "1" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "iCountry" -Value "61" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "iCurrDigits" -Value "2" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "iCurrency" -Value "0" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "iDate" -Value "1" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "iDigits" -Value "2" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "NumShape" -Value "1" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "iFirstDayOfWeek" -Value "0" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "iFirstWeekOfYear" -Value "0" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "iLZero" -Value "1" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "iMeasure" -Value "0" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "iNegCurr" -Value "1" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "iNegNumber" -Value "1" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "iPaperSize" -Value "9" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "iTime" -Value "0" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "iTimePrefix" -Value "0" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_1 -Name "iTLZero" -Value "0" -PropertyType STRING -Force | Out-Null

    $key_2 = "Registry::HKEY_USERS\$($UserProfile.SID)\Control Panel\International\Geo"
    New-ItemProperty -Path $key_2 -Name "Nation" -Value "12" -PropertyType STRING -Force | Out-Null

    $key_3 = "Registry::HKEY_USERS\$($UserProfile.SID)\Control Panel\International\User Profile"
    New-ItemProperty -Path $key_3 -Name "Languages" -Value "en-AU" -PropertyType MULTINGSTRING -Force | Out-Null
    New-ItemProperty -Path $key_3 -Name "ShowAutoCorrection" -Value "1" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $key_3 -Name "ShowTextPrediction" -Value "1" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $key_3 -Name "ShowCasing" -Value "1" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $key_3 -Name "ShowShiftLock" -Value "1" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $key_3 -Name "InputMethodOverride" -Value "0c09:00000409" -PropertyType STRING -Force | Out-Null

    $key_4 = "Registry::HKEY_USERS\$($UserProfile.SID)\Control Panel\International\User Profile\en-AU"
    New-ItemProperty -Path $key_4 -Name "CachedLanguageName" -Value "@Winlangdb.dll,-1107" -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $key_4 -Name "0C09:00000409" -Value "1" -PropertyType DWORD -Force | Out-Null

    $key_5 = "Registry::HKEY_USERS\$($UserProfile.SID)\Control Panel\International\User Profile System Backup"
    New-ItemProperty -Path $key_5 -Name "Languages" -Value "en-AU" -PropertyType MULTINGSTRING -Force | Out-Null
    New-ItemProperty -Path $key_5 -Name "ShowAutoCorrection" -Value "1" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $key_5 -Name "ShowTextPrediction" -Value "1" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $key_5 -Name "ShowCasing" -Value "1" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $key_5 -Name "ShowShiftLock" -Value "1" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $key_5 -Name "InputMethodOverride" -Value "0c09:00000409" -PropertyType STRING -Force | Out-Null

    $key_6 = "Registry::HKEY_USERS\$($UserProfile.SID)\Control Panel\International\User Profile System Backup\en-AU"
    New-ItemProperty -Path $key_6 -Name "0C09:00000409" -Value "1" -PropertyType DWORD -Force | Out-Null

    # Unload NTuser.dat    
    If ($ProfileWasLoaded -eq $false) {
        [gc]::Collect()
        Start-Sleep 1
        Start-Process -FilePath "CMD.EXE" -ArgumentList "/C REG.EXE UNLOAD HKU\$($UserProfile.SID)" -Wait -WindowStyle Hidden| Out-Null
    }
}