$pgPassword = "postgres"
$pgPort = 5432
$pgInstaller = "$PSScriptRoot\postgresql.exe"
$pgVersion = 11
$pgSource = "https://get.enterprisedb.com/postgresql/postgresql-11.5-2-windows-x64.exe"
$pgInstallPath = "C:\Program Files\PostgreSQL\$pgVersion"
$pgDataPath = "C:\Program Files\PostgreSQL\$pgVersion\data"
$serviceName = "postgresql-$pgVersion"
$now = (Get-Date)
# Here is folder to store install log C:\Log\<date_time>.log
$log = "C:\Log\" + $now.ToString(" yyyy-MM-dd_HH-mm-ss") + ".log"
$newConfig = "a
host    all             all             192.168.0.0/16            md5
host    all             all             0.0.0.0/0                 md5
"

#function for write color text output
function Green
{
    process { Write-Host $_ -ForegroundColor Green }
}

function Red
{
    process { Write-Host $_ -ForegroundColor Red }
}

# Start logging
Start-Transcript -Path $log

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

# Install PostgreSQL
Write-Host "Start install PostgreSQL..."
Start-Process $pgInstaller -ArgumentList "--mode unattended",`
"--prefix `"$pgInstallPath`"", "--datadir `"$pgDataPath`"", "--superpassword `"$pgPassword`"",`
"--serverport $pgPort","--servicename $serviceName" -Wait

#Config and restart service postgre
Write-Host "Reconfig PostgreSQL for local and remote connection access..."
$contentConfig = Get-Content -Path "$pgDataPath\pg_hba.conf"
$postgreService = Get-Service $serviceName

# Replace current config for ipv4 local and remote connection with new config
$contentConfig.Replace("host    all             all             127.0.0.1/32            md5",$newConfig) | Set-Content "$pgDataPath\pg_hba.conf"
Write-Host "Wait for restart service..."
if ($postgreService.Status -eq "Running")
{
    Restart-Service -Name $serviceName
    Write-Output "Restart postgre service success!" | Green
}
else
{
    Write-Host "This service is not running"
}

# Create firewall rule
Write-Host "Create new firewall rule"
New-NetFirewallRule -DisplayName "PostgreSQL Server" -Name "PostgreSQL Server" -Direction Inbound -Protocol TCP -LocalPort 5432 -Profile Domain,Private

# Remove file install of postgresql
Write-Host "Clean install file at $pgInstaller"
Remove-Item -Path $pgInstaller
Write-Output "Install PostgreSQL Success" | Green

# End logging
Stop-Transcript
