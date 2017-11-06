# ------------------------------------------------------------------------
# NAME: AccountName.ps1
# AUTHOR: Debanjan Dutta, Microsoft
# DATE: 03/05/2015
#
# 
# COMMENTS: This script calculates account name for a user based on First
# Name, Last Name. This value is checked for uniqueness and recalculated 
# until found to be unique.
# ---------------------------------------------------------------------
#Add-Type -AssemblyName System
#Add-Type -AssemblyName System.Text
#Add-Type -AssemblyName System.Data


function processFname {
    param([string]$fname)
    #########################Validate against regex to see if there are any special characters
    $fname = [System.Text.RegularExpressions.Regex]::Replace($fname, "[^a-z]", "");
    ##########################3If first name is smaller than 2 then dont do any substring
 
    #################Check if name is in lowercase alphabets only
    if ($fname -cmatch "^[a-z]") {
        $fname = $fname.Trim()
    }


    #if($fname.Length -ge 2)
    #{
    #if($fname -cmatch "^[a-z]")
    #{
    #$fname=$fname.Trim().Substring(0,1)
    #}
    
    #}

    return $fname
 
}

function processLname {
    param([string]$Lname)
    #########################Validate against regex to see if thre are any special characters
    $Lname = [System.Text.RegularExpressions.Regex]::Replace($Lname, "[^a-z]", ""); 
    ##########################3If first name is smaller than 2 then dont do any substring
 
    #################Check if name is in lowercase alphabets only
    if ($Lname -cmatch "^[a-z]") {
        $Lname = $Lname.Trim()
    }
   
    return $Lname
 
}

function processMname {
    param([string]$Mname)

    $Mname = [System.Text.RegularExpressions.Regex]::Replace($Mname, "[^a-z]", "");
 
    #################Check if name is in lowercase alphabets only
    if ($Mname -cmatch "^[a-z]") {
        $Mname = $Mname.Trim()
    }
 

    return $Mname
  
}

function replaceDiacritics {
    param([string]$id, [string]$middleString)
    $SQLServer = "USDC1PVSQL19" #use Server\Instance for named SQL instances! 
    $SQLDBName = "EIMWrapper"
    $sqlConnection = new-object System.Data.SqlClient.SqlConnection "Server = $SQLServer; Database = $SQLDBName; Integrated Security = True"

    $sqlConnection.Open()

    #Create a command object


    $sqlCommand = $sqlConnection.CreateCommand()
    if ($middleString -ne [string]::Empty) {
        $sqlCommand.CommandText = "declare @val varchar(200) select @val=dbo.EIM_Fn_ConvertUnicode(firstname)+','+dbo.EIM_Fn_ConvertUnicode(middlename)+','+dbo.EIM_Fn_ConvertUnicode(lastname) from EIM_T_UserStore where sNowUserReferenceID='$id' select @val"
    }
    else {
        $sqlCommand.CommandText = "declare @val varchar(200) select @val=dbo.EIM_Fn_ConvertUnicode(firstname)+','+dbo.EIM_Fn_ConvertUnicode(lastname) from EIM_T_UserStore where sNowUserReferenceID='$id' select @val"
    }
    #Execute the Command

    [string]$sqlReader = $sqlCommand.ExecuteScalar()

    # Close the database connection

    $sqlConnection.Close()

    return $sqlreader
}

#function ReplaceDiacritics 
#{
#Add-Type -AssemblyName System.Globalization
#Add-Type -AssemblyName System.Text

#param ([String]$src = [String]::Empty)
#  $normalized = $src.Normalize( [System.Text.NormalizationForm]::FormD )
#  $sb = new-object System.Text.StringBuilder
#  $normalized.ToCharArray() | % { 
#   if( [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
#      [void]$sb.Append($_)
#    }
#  }
#  $sb.ToString()
#}

function writeLog{
  param([string]$LogContent)
  $Time = Get-Date -Format G
  Add-Content $LogPath "$Time : $LogContent"
}

#try
#{

$Date = Get-Date -Format "yyyy-MM-dd"
$LogFolder = "D:\Script3\"
If (!(test-path $LogFolder)) {
    New-Item -ItemType Directory -Force -Path $LogFolder
}
$LogPath = $LogFolder + "AccountnameCraetionScriptLog-" + $Date.ToString() + ".txt"

writeLog "Something you want to log"

$Trace = ""

[string]$startString = $Args[0]
[string]$endString = $Args[1]
[string]$middleString = $Args[2]
[boolean]$isContractor = [System.Convert]::ToBoolean($Args[3])
[boolean]$isVendor = [System.Convert]::ToBoolean($Args[4])
[boolean]$isEmployee = [System.Convert]::ToBoolean($Args[5])
[string]$id = $Args[6]
[string]$account = $Args[7]
[string]$empTypeNum = [string]::Empty

$val = ""
[string]$normalized = replaceDiacritics $id $middleString

#######Calculate employee type number########
if ($isContractor) { 
    $empTypeNum = '9'
}

if ($isVendor) {
    $empTypeNum = '8'
}

if ($isEmployee) { 
    $empTypeNum = ''
}
#########end of employee type no###############

if ($middleString -ne [string]::Empty) {
    $startString = $normalized.Split(",")[0]
    $middleString = $normalized.Split(",")[1]
    $endString = $normalized.Split(",")[2]
}

else {
    $startString = $normalized.Split(",")[0]
    $endString = $normalized.Split(",")[1]
}

#}
#catch
#{
#$Trace+= "Error Reading variables"+ $_.Exception.Message
#}
#[string]$startString='Debangan'
#[string]$endString='Gupta'
#[string]$middleString=''
#[boolean]$isContractor=$true
#[boolean]$isVendor=$false
#[string]$id='SM0000102'
$Trace += "Log from Account Name Script: Cleaned Foreign"



###########################################Generate only if first assigned is new####################################################################################
if ($account -eq "000NEW") {
 
 
    [string]$fname = $startString.ToLower()
    [string]$lname = $endString.ToLower()
    [string]$mname = $middleString.ToLower()

    #$fname=[System.Text.RegularExpressions.Regex]::Replace($fname,"[^a-z]","");
    #$lname=[System.Text.RegularExpressions.Regex]::Replace($lname,"[^a-z]","");
    #$mname=[System.Text.RegularExpressions.Regex]::Replace($mname,"[^a-z]","");


    $startString = processFname($startString.ToLower())
    $endString = processLname($endString.ToLower())
    $middleString = processMname($middleString.ToLower())


    #################Searches in wrapper#################
    function searchDB {
        param([string] $username) 
        $SQLServer = "USDC1PVSQL19" #use Server\Instance for named SQL instances! 
        $SQLDBName = "EIMWrapper"
        $SqlQuery = 'EIM_SP_CheckUserName'

        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = True"
        $SqlConnection.Open()
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $SqlCmd.CommandText = $SqlQuery
        $SqlCmd.CommandType = [System.Data.CommandType]'StoredProcedure'

        $SqlCmd.Connection = $SqlConnection

        $a = $sqlcmd.Parameters.AddWithValue("@username", [string]$username)
        $sqlparam = New-Object System.Data.SqlClient.SqlParameter

        $b = $sqlparam.ParameterName = '@count'
        $sqlparam.Direction = [System.Data.ParameterDirection]::Output
        $sqlparam.SqlDbType = [System.Data.SqlDbType]::Int

        $c = $SqlCmd.Parameters.Add($sqlparam)

        $d = $SqlCmd.ExecuteNonQuery()

        $returnVal = $SqlCmd.Parameters["@count"].Value

        $ret = $SqlConnection.Close()

        if ($returnVal -eq 0) {
            return $true
        }

        else {
            return $false
        }

    }

    #################Searches in AD######################          
    function searchAD {
        param ([string]$name)

        ##############################################################################################
        #Query AD
        ##############################################################################################
        $domainList = @("LDAP://dc=apac,dc=ent,dc=bhpbilliton,dc=net", "LDAP://dc=americas,dc=ent,dc=bhpbilliton,dc=net", "LDAP://dc=emea,dc=ent,dc=bhpbilliton,dc=net", "LDAP://dc=external,dc=ent,dc=bhpbilliton,dc=net", "LDAP://dc=ent,dc=bhpbilliton,dc=net")
        [int]$foundCount = 0

        for ([int]$c = 0; $c -lt $domainList.Length; $c++) {
            $strFilter = "(&(objectCategory=User)(sAMAccountName=" + $name + "))"
            $objDomain = New-Object System.DirectoryServices.DirectoryEntry($domainList[$c])
            $objSearcher = New-Object System.DirectoryServices.DirectorySearcher
            $objSearcher.SearchRoot = $objDomain
            $objSearcher.PageSize = 1000
            $objSearcher.Filter = $strFilter
            $objSearcher.SearchScope = "SubTree"

            $colProplist = "sAMAccountName"
            foreach ($I in $colPropList) {$a = $objSearcher.PropertiesToLoad.Add($I)}

            $colResults = $objSearcher.FindAll()

            if ($colResults.Count -eq 0) {
  
            }

            else {
                $foundCount = $foundCount + 1
            }
            ###########################End of Loop#############################################
        }

        ######################Return true if not found####################################
        if ($foundCount -eq 0) {
            return $true
        }

        #####################Return false if found###########################################
        else {
            $false
        }
    }

    #################searches in ADAM####################
    #function searchADAM
    #{
    #param ([string]$name)

    ##############################################################################################
    #Query ADAM
    ##############################################################################################
    #$strFilter = "(&(objectcategory=Person)(objectClass=user)(cn="+$name+"))"
    #$objDomain = New-Object System.DirectoryServices.DirectoryEntry("LDAP://adamexternal.bhpbilliton.net:50002/OU=users,OU=external,DC=bhpbilliton,DC=net")
    #$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
    #$objSearcher.SearchRoot = $objDomain
    #$objSearcher.PageSize = 1000
    #$objSearcher.Filter = $strFilter
    #$objSearcher.SearchScope = "Subtree"

    #$colProplist = "cn"
    #foreach ($I in $colPropList){$a=$objSearcher.PropertiesToLoad.Add($I)}

    #$colResults = $objSearcher.FindAll()

    #if($colResults.Count -eq 0)
    #{
    # return $true
    #}

    #else
    #{
    #return $false
    #}


    #}

    #################writes back generated username in wrapper####################
    function updateUserNAme {
  
        param([string] $username, [string] $ln, [string] $fn, [string] $id)
        $SQLServer = "USDC1PVSQL19" #use Server\Instance for named SQL instances! 
        $SQLDBName = "EIMWrapper"
        $SqlQuery = 'EIM_SP_UpdateUserName'

        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = True"
        $SqlConnection.Open()
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $SqlCmd.CommandText = $SqlQuery
        $SqlCmd.CommandType = [System.Data.CommandType]'StoredProcedure'

        $SqlCmd.Connection = $SqlConnection


        $sqlcmd.Parameters.AddWithValue("@username", [string]$username)


        $sqlcmd.Parameters.AddWithValue("@firstname", [string]$fn)

        $sqlcmd.Parameters.AddWithValue("@lastname", [string]$ln)

        $sqlcmd.Parameters.AddWithValue("@id", [string]$id)

        try {
            $retIntr = $SqlCmd.ExecuteNonQuery()
        }

        catch {
            return $false
        }


        $SqlConnection.Close()

        if ($retIntr -eq -1) { 
            return $false
        }

        if ($retIntr -gt 0) {
            return $true
        }

        else {
            return $false
        }

    }


    $isUnique = 0
    $iteration = 0
    $val = ""
    $VendorNum = 8
    $ContractorNum = 9
    $trace = ""

    ########################################################################################################
    ########################################################################################################
 


    ########################################################################################################################

    #######################If Last Name is four characters or longer########################################################

    if ($endString.Length -ge 4) {
        $val = $endString.Substring(0, 4) + $startString.Substring(0, 1) + $empTypeNum
    }

    #######################If Last Name is three characters##################################################################
    if ($endString.Length -eq 3) {

        ###############################If First name is longer than two characters##############################################
        if ($startString.Length -ge 2) {
            $val = $endString + $startString.Substring(0, 2) + $empTypeNum 
        }

        ##############################If First name is one character#############################################################
        if ($startString.Length -eq 1) {
            $val = $endString + $startString + "_BHP" + $empTypeNum
        }

    }

    #######################If Last Name is two characters####################################################################
    if ($endString.Length -eq 2) {
        ###############################If First name is more than  three characters##############################################
        if ($startString.Length -ge 3) {
            $val = $endString + $startString.Substring(0, 3) + $empTypeNum
        }

        #######################If First name is two or less characters#############################################################
        if ($startString.Length -le 2) {
            $val = $endString + $startString + "_BHP" + $empTypeNum
        }
  
    }

    ##################################If Last Name is one characters############################################################
    if ($endString.Length -eq 1) {
        ###############################If First name is more than  four characters##############################################
        if ($startString.Length -ge 4) {
            $val = $endString + $startString.Substring(0, 4) + $empTypeNum
        }

        ###############################If First name is three characters##############################################
        if ($startString.Length -le 3) {
            $val = $endString + $startString + "_BHP" + $empTypeNum 
        }

    }
    ##########################Check for Uniqueness#################################################
          
    $valAD = searchAD($val)
    $valDB = searchDB($val)
    #$valADAM=searchADAM($val)
    $valADAM = $true

    ######################################If unique############################################################
    if ($valAD -eq $true -and $valDB -eq $true -and $valADAM -eq $true -and ((updateUserNAme $val  $lname  $fname $id) -eq $true)) {
        $Trace += "Log from Account Name Script: User is a vendor, using first name and lastname vendor num`r`n"
        Write-EventLog -LogName "FIMWAL" -Source "FIMWAL" -EventId 0 -Message "$`r`nTrace: $Trace" -EntryType "Information" -Category 0
        return $val
    }

    #####################################If not found unique then continue##################################
    else {

        if ($middleString.Length -ne 0) {

            if (($isVendor -eq $true) -or ($isContractor -eq $true)) {
                $val = $val.Substring(0, $val.Length - 1)
            }

            $val = $val + $middleString.Substring(0, 1) + $empTypeNum

            

            
            
            ########################Check for uniqueness###################################
            $valAD = searchAD($val)
            $valDB = searchDB($val)
            #$valADAM=searchADAM($val)
            $valADAM = $true

            ###########################################If unique########################################################################
            if ($valAD -eq $true -and $valDB -eq $true -and $valADAM -eq $true -and ((updateUserNAme $val  $lname  $fname $id) -eq $true)) {
                $Trace += "Log from Account Name Script: User is a vendor, using first name, middlename and lastname vendor num`r`n"
                Write-EventLog -LogName "FIMWAL" -Source "FIMWAL" -EventId 0 -Message "$`r`nTrace: $Trace" -EntryType "Information" -Category 0
                return $val
            }

            else {
                [System.char[]] $stringArray = 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
              
                for ([int] $i = 0; $i -le 25; $i++) { 
                    if (($i -eq 0) -and (($isVendor -eq $true) -or ($isContractor -eq $true))) {
                        $val = $val.Substring(0, $val.Length - 1)
                    }
                   
                    if (($i -gt 0) -and (($isVendor -eq $true) -or ($isContractor -eq $true))) {
                        $val = $val.Substring(0, $val.Length - 2)
                    }

                    if (($i -gt 0) -and ($isEmployee -eq $true)) {
                        $val = $val.Substring(0, $val.Length - 1)
                    }
                
                    $val = $val + $stringArray[$i] + $empTypeNum
               
                    ##############################Search if unique##############################################
                    $valAD = searchAD($val)
                    $valDB = searchDB($val)
                    #$valADAM=searchADAM($val)
                    $valADAM = $true


                    ###############################################If unique##################################################################
                    if ($valAD -eq $true -and $valDB -eq $true -and $valADAM -eq $true -and ((updateUserNAme $val  $lname  $fname $id) -eq $true)) {
                        $Trace += "Log from Account Name Script: User is a vendor, using first name and lastname vendor num and alphabetic suffix'r'n"
                        #Write-EventLog -LogName "FIMWAL" -Source "FIMWAL" -EventId 0 -Message "$`r`nTrace: $Trace" -EntryType "Information" -Category 0
                        return $val
                    } 
                                                        
                }

                #########################################If no unique name found######################################################
                # $valAD=searchAD($val)
                # $valDB=searchDB($val)
                #$valADAM=searchADAM($val)

                #if($valAD-eq $true -and $valDB -eq $true -and $valADAM -eq $true -and ((updateUserNAme $val  $lname  $fname $id) -eq $true)) 
               
                #{
                #   $guid=[System.Guid]::NewGuid().ToString().Substring(0,7)
                #  $guid=[System.Text.RegularExpressions.Regex]::Replace($guid,"[^a-z]","");
                # $val=$endString + $guid
                #$Trace+="Log from Account Name Script: User is a vendor, using last option, using random suffix`r`n"
                #Write-EventLog -LogName "FIMWAL" -Source "FIMWAL" -EventId 0 -Message "$`r`nTrace: $Trace" -EntryType "Error" -Category 0
                #return $val
                #}
              
              
            }

        }
        ############################################If not unique####################################################################
        else {
            [System.char[]] $stringArray = 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
              
            for ([int] $i = 0; $i -le 25; $i++) { 
                if (($i -eq 0) -and (($isVendor -eq $true) -or ($isContractor -eq $true))) {
                    $val = $val.Substring(0, $val.Length - 1)
                }
                   
                if (($i -gt 0) -and (($isVendor -eq $true) -or ($isContractor -eq $true))) {
                    $val = $val.Substring(0, $val.Length - 2)
                }

                if (($i -gt 0) -and ($isEmployee -eq $true)) {
                    $val = $val.Substring(0, $val.Length - 1)
                }
                
                $val = $val + $stringArray[$i] + $empTypeNum
               
                ##############################Search if unique##############################################
                $valAD = searchAD($val)
                $valDB = searchDB($val)
                #$valADAM=searchADAM($val)
                $valADAM = $true


                ###############################################If unique##################################################################
                if ($valAD -eq $true -and $valDB -eq $true -and $valADAM -eq $true -and ((updateUserNAme $val  $lname  $fname $id) -eq $true)) {
                    $Trace += "Log from Account Name Script: User is a vendor, using first name and lastname vendor num and alphabetic suffix'r'n"
                    #Write-EventLog -LogName "FIMWAL" -Source "FIMWAL" -EventId 0 -Message "$`r`nTrace: $Trace" -EntryType "Information" -Category 0
                    return $val
                } 
                                                        
            }

            #########################################If no unique name found######################################################
            # $valAD=searchAD($val)
            # $valDB=searchDB($val)
            #$valADAM=searchADAM($val)

            #if($valAD-eq $true -and $valDB -eq $true -and $valADAM -eq $true -and ((updateUserNAme $val  $lname  $fname $id) -eq $true)) 
               
            #{
            #   $guid=[System.Guid]::NewGuid().ToString().Substring(0,7)
            #  $guid=[System.Text.RegularExpressions.Regex]::Replace($guid,"[^a-z]","");
            # $val=$endString + $guid
            #$Trace+="Log from Account Name Script: User is a vendor, using last option, using random suffix`r`n"
            #Write-EventLog -LogName "FIMWAL" -Source "FIMWAL" -EventId 0 -Message "$`r`nTrace: $Trace" -EntryType "Error" -Category 0
            #return $val
            #}
              
              
        }
    }
}
           
#######################################3Account Name generated previously return existing value#############################################            
else {
    return $account
}