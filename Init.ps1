﻿param($installPath, $toolsPath, $package, $project)

$driverFile = "IEDriverServer.exe"
$downloadUrl = "https://selenium-release.storage.googleapis.com/2.41/IEDriverServer_Win32_2.41.0.zip"

$contentPath = Join-Path $installPath "content"
$driverPath = Join-Path $contentPath $driverFile

if ((Test-Path $driverPath) -eq $false) {

    # Download selenium driver zip file.
    $tmpFilePath = [IO.Path]::GetTempFileName() + ".zip"
    $webClient = New-Object Net.WebClient

    $proxy = $env:HTTP_PROXY
    if ($proxy -ne $null) {
        if ($proxy -ne "") {
            $webClient.Proxy = New-Object Net.WebProxy -ArgumentList $proxy
        }
    }
    else {
        $cfgpath = "$env:APPDATA\NuGet\NuGet.config"
        if (Test-Path $cfgpath) {
            $cfg = [xml](cat $cfgpath)
            $proxy = $cfg.SelectSingleNode("//config/add[@key='HTTP_PROXY']").value
            if ($proxy -ne $null) {
                $userInfo = $cfg.SelectSingleNode("//config/add[@key='HTTP_PROXY.user']").value
                if ($userInfo -ne $null) {
                    $userInfo = [uri]::EscapeDataString($userInfo)
                    $encryptedString = $cfg.SelectSingleNode("//config/add[@key='HTTP_PROXY.password']").value
                    if ($encryptedString -ne $null) {
                        $entropyBytes = [Text.Encoding]::UTF8.GetBytes("NuGet")
                        $encryptedBytes = [Convert]::FromBase64String($encryptedString)
                        $decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect($encryptedBytes, $entropyBytes, 0) #System.Security.Cryptography.DataProtectionScope
                        $userInfo += (":" + [uri]::EscapeDataString([Text.Encoding]::UTF8.GetString($decryptedBytes)))
                    }
                    $proxyUri = [uri]$proxy
                    $proxy = ("{0}://{1}@{2}" -f $proxyUri.Scheme, $userInfo, $proxyUri.Authority)
                }
                $webClient.Proxy = New-Object Net.WebProxy -ArgumentList $proxy
            }
        }
    }

    $webClient.DownloadFile($downloadUrl, $tmpFilePath)

    $shell = New-Object -com Shell.Application
    $zipFile = $shell.NameSpace($tmpFilePath)

    $zipFile.Items() | `
    where {(Split-Path $_.Path -Leaf) -eq $driverFile} | `
    foreach {
        $contentFolder = $shell.NameSpace($contentPath)
        $contentFolder.copyhere($_.Path)
    }

    rm $tmpFilePath
}
