function Show-Menu
{
     param (
           [string]$Title = 'My Menu'
     )
     cls
     Write-Host "================ $Title ================" -ForegroundColor Cyan
     Write-Host ""
     Write-Host "1: Press '1' to install Jenkins"
     Write-Host "2: Press '2' to install Git"
     Write-Host "3: Press '3' to install AdoptOpenJDK11"
     Write-Host "4: Press '4' to install Maven"
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

function Install-Jenkins
{
    Param($url, $currentDir, $unzipDir)
    try
    {
        Log-Message "--------Start download Jenkins---------" | Yellow
        if (!(Test-Path $currentDir -PathType Leaf ))
        {
            Invoke-WebRequest -Uri $url -OutFile $currentDir
            Log-Message "- Download success file store at $currentDir" | Green
        }
    }
    catch
    {
        Log-Message "[Error] An error occurred while download jenkins!" | Red
        throw $_
        break;
    }
    Log-Message "- Unzip from $currentDir to $unzipDir"
    Expand-Archive -path $currentDir -destinationpath $unzipDir -Force
    Set-Location $unzipFolder
    Log-Message "- Start install jenkins"
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/qb","/I","jenkins.msi" -Wait
    #msiexec.exe /qb /I jenkins.msi
    Log-Message "- The default jenkins will be installed at C:\Program Files (x86)\Jenkins" | Green
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

function Install-Git
{
    Param($url, $currentDir)
    try
    {
        Log-Message "--------Start download Git---------" | Yellow
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
    Log-Message "- Start install Git"
    Start-Process -FilePath "Git.exe" -ArgumentList "/SILENT","/SUPPRESSMSGBOXES","/NORESTART","/NOCANCEL","/SP-","/LOG" -Wait
    Log-Message "- The default Git will be installed at C:\Program Files\Git" | Green
}

function Install-Maven
{
    Param($url, $currentDir, $unzipDir,$ver)
    try
    {
        Log-Message "--------Start download Maven---------" | Yellow
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
    Log-Message "- Set system evironment for maven"
    $envMachine = [Environment]::GetEnvironmentVariable("Path",[System.EnvironmentVariableTarget]::Machine)
    [Environment]::SetEnvironmentVariable("Path", $envMachine+";$unzipDir\apache-maven-$ver\bin","Machine")
}

#Information for maven install
$mavenUrl = "http://mirrors.viethosting.com/apache/maven/maven-3/3.6.2/binaries/apache-maven-3.6.2-bin.zip"
$mavenInstallUrl = "$PSScriptRoot\maven.zip"
$mavenUnzipFolder = "C:\Program Files\maven"
$mavenVer = "3.6.2"

#Information for git install
$gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.23.0.windows.1/Git-2.23.0-64-bit.exe"
$gitInstallUrl = "$PSScriptRoot\Git.exe"

#Information for adoptopenjdk
$adoptUrl = "https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.4%2B11_openj9-0.15.1/OpenJDK11U-jdk_x64_windows_openj9_11.0.4_11_openj9-0.15.1.msi"
$adoptInstallDir = "$PSScriptRoot\AdoptOpenJDK.msi"

#Information for jenkins install
$jenkinsUrl = "http://ftp-chi.osuosl.org/pub/jenkins/windows/jenkins-2.199.zip"
$installDir = "$PSScriptRoot\jenkins.zip"
$unzipFolder = "$PSScriptRoot\jenkins"

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
                        Install-Jenkins $jenkinsUrl $installDir $unzipFolder
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
                        Install-Git $gitUrl $gitInstallUrl
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
               '3'
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
               '4'
               {
                    try
                    {
                        Install-Maven $mavenUrl $mavenInstallUrl $mavenUnzipFolder $mavenVer
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
