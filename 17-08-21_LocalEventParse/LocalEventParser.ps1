$LocalEventPath = "D:\Workspace\Cases\FY18\Problem\Security Logs AGIAPDDC1D"
$OutputFileName = "result.csv"

$LocalEventFiles = Get-ChildItem $LocalEventPath  -Filter "*.evtx" 

# Get-WinEvent -Path C:\fso\SavedAppLog.evtx
$ResultObjList = @()

ForEach ($EventFile in $LocalEventFiles) {
    Write-Host ("$EventFile.Name ...")
    $Events = Get-WinEvent -FilterHashtable @{Path = $EventFile.FullName; ID = 5140}
    ForEach ($Event in $Events) {
        $MessageStr = $Event.Message
        $MessageStrSplited = $MessageStr.split("`n")
        #HardCode
        $AccountName = $MessageStrSplited[4].split(":")[1].trim()
        $AccountDomain = $MessageStrSplited[5].split(":")[1].trim()
        $SourceAddress = $MessageStrSplited[9].split(":")[1].trim()
        $SourcePort = $MessageStrSplited[10].split(":")[1].trim()
        $ShareName = $MessageStrSplited[12].split(":")[1].trim()

        $ResultObject = New-Object PSObject -Property @{
            Date          = $Event.TimeCreated.toString("MM-dd-yyyy")
            Time          = $Event.TimeCreated.toString("t")
            AccountName   = $AccountName
            AccountDomain = $AccountDomain
            SourceAddress = $SourceAddress
            SourcePort    = $SourcePort
            Sharename     = $ShareName
        }
        $ResultObjList += $ResultObject
    }
}
$ResultObjList | Select-Object -Property Date, Time, AccountName, AccountDomain, SourceAddress, SourcePort,Sharename | Export-Csv  -Path $OutputFileName



