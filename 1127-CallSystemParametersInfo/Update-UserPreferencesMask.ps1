function Update-UserPreferencesMask {
    add-type -MemberDefinition @"
[DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, uint pvParam, uint fWinIni);
 
const int SPI_SETTHREADLOCALINPUTSETTINGS = 0x104F; 
const int SPIF_UPDATEINIFILE = 0x01; 
const int SPIF_SENDCHANGE = 0x02;
 
public static void UpdateUserPreferencesMask() {
    SystemParametersInfo(SPI_SETTHREADLOCALINPUTSETTINGS, 0, 1, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
}
"@ -Name UserPreferencesMaskSPI -Namespace Temp
 
    [Temp.UserPreferencesMaskSPI]::UpdateUserPreferencesMask()
 
}

Update-UserPreferencesMask