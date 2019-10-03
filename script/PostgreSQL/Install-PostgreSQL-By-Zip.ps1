$pgSource = "http://get.enterprisedb.com/postgresql/postgresql-11.5-2-windows-x64-binaries.zip"
$pgInstaller = "$PSScriptRoot\postgresql.zip"
$pgInstallPath = "C:\Program Files\PostgreSQL"
$newConfig = "
host    all             all             192.168.0.0/16            md5
host    all             all             0.0.0.0/0                 md5
"
$now = (Get-Date)
# Here is folder to store install log \Log\<date_time>.log
$log = "C:\Log\" + $now.ToString(" yyyy-MM-dd_HH-mm-ss") + ".log"

#function for write color text output
function Green
{
    process { Write-Host $_ -ForegroundColor Green }
}

function Red
{
    process { Write-Host $_ -ForegroundColor Red }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

function Set-Permission($installPath)
{
    $Acl = Get-Acl $installPath
    $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $Acl.SetAccessRule($Ar)
    Set-Acl $installPath $Acl
}

# Start logging
Start-Transcript -Path $Log

#Download PostgreSQL
# Create a HTTP request
$httpRequest = [System.Net.WebRequest]::Create($pgSource)
# Get response
$httpResponse = $httpRequest.GetResponse()
#Get status code
$httpStatus = [int]$httpResponse.StatusCode
if ($httpStatus -eq 200)
{
    Write-Host "Start download PostgreSQL..."
    Invoke-WebRequest $pgSource -OutFile $pgInstaller
    Write-Output "Download postgre success! File save at $pgInstaller" | Green
}
else
{
    Write-Output "Can not download from this url: $pgSource" | Red
}

#Unzip
Write-Output "Waiting for Unzip from $pgInstaller to $pgInstallPath"
Unzip $pgInstaller $pgInstallPath

#Set permission for initdb.exe can create data folder in install directory
Write-Output "Set permission for install folder"
Set-Permission $pgInstallPath

# Init the database
Set-Location "$pgInstallPath\pgsql\bin"
Write-Output "Init the database"
.\initdb.exe -U postgres -A md5 -E utf8 -W -D ../data

# Replace old config to new config
Write-Host "Reconfig PostgreSQL for local and remote connection access..."
$contentConfig = Get-Content -Path "$pgInstallPath\pgsql\data\pg_hba.conf"
$contentConfig.Replace("host    all             all             127.0.0.1/32            md5",$newConfig) | Set-Content "$pgInstallPath\pgsql\data\pg_hba.conf"

# Create new firewall rule
Write-Host "Create new firewall rule"
New-NetFirewallRule -DisplayName "PostgreSQL Server" -Name "PostgreSQL Server" -Direction Inbound -Protocol TCP -LocalPort 5432 -Profile Domain,Private

Write-Output "Install success" | Green

# Clean file zip after install
Write-Host "Clean install file at $pgInstaller"
Remove-Item -Path $pgInstaller

# End logging
Stop-Transcript
