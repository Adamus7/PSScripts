@echo off

for /F %%i in (serverlist.txt) do (
   xcopy GetSqlPort.ps1 \\%%i\C$\Tools\ /Z /Y
   Psexec \\%%i PowerShell c:\tools\GetSqlPort.ps1 
)

# PsExec @serverlist.txt PowerShell \\yuwang-dell\Workspace\temp\GetSqlPort.ps1