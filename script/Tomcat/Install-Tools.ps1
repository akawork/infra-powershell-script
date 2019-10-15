function Show-Menu
{
     param (
           [string]$Title = 'My Menu'
     )
     cls
     Write-Host "================ $Title ================" -ForegroundColor Cyan
     Write-Host ""
     Write-Host "1: Press '1' to install AdoptOpenJDK11"
     Write-Host "2: Press '2' to install Tomcat"
     Write-Host "Q: Press 'Q' to quit"
}

function Green
{
    process { Write-Host $_ -ForegroundColor Green }
}

function Red
{
    process { Write-Host $_ -ForegroundColor Red }
}

function Yellow
{
    process { Write-Host $_ -ForegroundColor Yellow }
}

function Get-Time
{
    $now = (Get-Date)
    return $now.ToString("HH:mm:ss")
}

function Log-Message
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$LogMessage
    )

    Write-Output ("{0} - {1}" -f (Get-Time), $LogMessage)
}

function Install-AdoptOpenJDK
{
    Param($url, $currentDir, $adoptHome)
    try
    {
        Log-Message "--------Start download AdoptOpenJDK11---------" | Yellow
        if (!(Test-Path $currentDir -PathType Leaf))
        {
            Invoke-WebRequest -Uri $url -OutFile $currentDir
            Log-Message "- Download success file store at $currentDir" | Green
        }
    }
    catch
    {
        Log-Message "[Error] An error occurred while download Jenkins!" | Red
        throw $_
        break;
    }
    Log-Message "- Start install AdoptOpenJDK"
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/qb","/i","AdoptOpenJDK.msi","INSTALLLEVEL=3" -Wait
    # msiexec.exe /qb /i AdoptOpenJDK.msi INSTALLLEVEL=3
    Log-Message "- The default AdoptOpenJDK will be installed at C:\Program Files\AdoptOpenJDK\" | Green
    #Log-Message "- Setup evironment variable"
    #[Environment]::SetEnvironmentVariable("Path", $Env:Path+";$adoptHome\bin","Machine")
}

function Install-Tomcat
{
    Param($url, $currentDir, $unzipDir, $oldName, $newName)
    try
    {
        Log-Message "--------Start download Tomcat---------" | Yellow
        if (!(Test-Path $currentDir -PathType Leaf ))
        {
            Invoke-WebRequest -Uri $url -OutFile $currentDir
            Log-Message "- Download success file store at $currentDir" | Green
        }
    }
    catch
    {
        Log-Message "[Error] An error occurred while download Jenkins!" | Red
        throw $_
        break;
    }
    Log-Message "- Unzip from $currentDir to $unzipDir"
    Expand-Archive -path $currentDir -destinationpath $unzipDir -Force
    Rename-Item -Path "$unzipDir\$oldName" -NewName "$unzipDir\$newName" -Force
    Set-Location "$unzipDir\tomcat9\bin"
    $content = Get-Content "$unzipDir\tomcat9\bin\service.bat"
    $content.Replace("128","2000") | Set-Content "$unzipDir\tomcat9\bin\service.bat"
    $content= Get-Content "$unzipDir\tomcat9\bin\service.bat"
    $content.Replace("256","4000") | Set-Content "$unzipDir\tomcat9\bin\service.bat"
    Log-Message "- Set java environment variable for current session"
    $envMachine = [Environment]::GetEnvironmentVariable("JAVA_HOME",[System.EnvironmentVariableTarget]::Machine)
    $env:JAVA_HOME = $envMachine
    $env:Path += ";$envMachine/bin"
    Log-Message "- Install Tomcat service"
    .\service.bat install
    Log-Message "- Change autoDeploy to false"
    $conf = Get-Content "$unzipDir\tomcat9\conf\server.xml"
    $conf.Replace("autoDeploy=`"true`"","autoDeploy=`"false`"") | Set-Content "$unzipDir\tomcat9\conf\server.xml"
    Log-Message "- Config service to automatic"
    Set-Service -Name "Tomcat9" -StartupType Automatic
    Log-Message "- Start Tomcat service"
    Start-Service -Name "Tomcat9"
    Log-Message "- Create new firewall rule"
    New-NetFirewallRule -DisplayName "Tomcat" -Name "Tomcat" -Direction Inbound -Protocol TCP -LocalPort 8080 -Profile Domain,Private
}

#Information for tomcat install
$tomcatURl = "http://mirror.downloadvn.com/apache/tomcat/tomcat-9/v9.0.26/bin/apache-tomcat-9.0.26-windows-x64.zip"
$tomcatInstallUrl = "$PSScriptRoot\tomcat.zip"
$tomcatUnzipFolder = "C:\"
$tomcatOldName = "apache-tomcat-9.0.26"
$tomcatNewName = "tomcat9"

#Information for adoptopenjdk
$adoptUrl = "https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.4%2B11_openj9-0.15.1/OpenJDK11U-jdk_x64_windows_openj9_11.0.4_11_openj9-0.15.1.msi"
$adoptInstallDir = "$PSScriptRoot\AdoptOpenJDK.msi"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

do
{
     Show-Menu "Install tools by powershell"
     $input = Read-Host "Please make a selection"
     $choices = $input.Split(",")
     Write-Host $choices[1]
     for($i = 0; $i -lt $choices.Length; $i++)
     {
        switch ($choices[$i].Trim())
        {
               '1'
               {
                    try
                    {
                        Install-AdoptOpenJDK $adoptUrl $adoptInstallDir $adoptHome
                    }
                    catch
                    {
                        Log-Message "[Error] An error occurred!" | Red
                        Log-Message $_
                        Log-Message $_.ScriptStackTrace
                        break;
                    }
                    break;
               }
               '2'
               {
                    try
                    {
                        Install-Tomcat $tomcatURl $tomcatInstallUrl $tomcatUnzipFolder $tomcatOldName $tomcatNewName
                    }
                    catch
                    {
                        Log-Message "[Error] An error occurred!" | Red
                        Log-Message $_
                        Log-Message $_.ScriptStackTrace
                        break;
                    }
                    break;
               }
               'q'
               {
                    return
               }
               default
               {
                    Write-Output "-----Invalid parameter-----" | Red
                    break;
               }
           }
     }
     pause
}
until ($input -eq 'q')
