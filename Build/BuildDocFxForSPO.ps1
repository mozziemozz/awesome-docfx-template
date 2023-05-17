$checkPnPSession = Get-PnPContext

if (!$checkPnPSession) {

    if (!(Test-Path -Path .\Build\SiteUrl.txt)) {

        $siteUrl = Read-Host "Enter or paste your SharePoint Online target site url"

        Set-Content -Path .\Build\SiteUrl.txt -Value $siteUrl -NoNewline

    }

    else {

        $siteUrl = Get-Content -Path .\Build\SiteUrl.txt

    }

    Connect-PnPOnline -Interactive -Url $siteUrl

}

$targetDocumentLibrary = (Get-Content -Path .\Docs\docfx.json | ConvertFrom-Json).build.globalMetadata._appTitle

$checkDocumentLibraries = Get-PnPList

if ($checkDocumentLibraries.Title -notcontains $targetDocumentLibrary) {

    New-PnPList -Title $targetDocumentLibrary -Template DocumentLibrary -OnQuickLaunch

}


$checkCustomScripts = Get-PnPTenantSite -Url $siteUrl

if ($checkCustomScripts.DenyAddAndCustomizePages -eq "Disabled") {

    Write-Host "Custom scripts are already enabled for this site." -ForegroundColor Green

} 

else {

    Write-Host "Custom scripts are not enabled for this site. They will be enabled now." -ForegroundColor Yellow
    Set-PnPSite -Identity $siteUrl -NoScriptSite $false

}

if ((Test-Path -Path .\Docs\_site_last_build)) {

    Remove-Item -Path .\Docs\_site_last_build -Recurse -Force

}


if ((Test-Path -Path .\Docs\_site)) {

    $isInitialBuild = $false

    Rename-Item -Path .\Docs\_site -NewName "_site_last_build"

    New-Item -Path .\Docs\_site -ItemType Directory

}

else {

    $isInitialBuild = $true

}

docfx .\Docs\docfx.json --build

$htmlFiles = Get-ChildItem -Path ".\Docs\_site" -Recurse -Filter "*.html"

foreach ($htmlFile in $htmlFiles) {

    $htmlFile.FullName
    
    $content = Get-Content -Path $htmlFile.FullName -Encoding UTF8

    $content = $content.Replace("index.html","index.aspx")

    $content = $content.Replace('.htm"','_enlarged.aspx"')

    Set-Content -Path $htmlFile.FullName -Value $content -Force -Encoding UTF8

    Rename-Item -Path $htmlFile.FullName -NewName $htmlFile.Name.Replace("html","aspx") -Force

    # Read-Host

}

$htmFiles = Get-ChildItem -Path ".\Docs\_site" -Recurse -Filter "*.htm"

foreach ($htmFile in $htmFiles) {

    Rename-Item -Path $htmFile.FullName -NewName $htmFile.Name.Replace(".htm","_enlarged.aspx") -Force

}


$jsonFiles = Get-ChildItem -Path ".\Docs\_site" -Recurse -Filter "*.json"

foreach ($jsonFile in $jsonFiles) {

    $json.FullName

    $content = (Get-Content -Path $jsonFile.FullName -Encoding UTF8) -replace ('.html"','.aspx"')
    Set-Content -Path $jsonFile.FullName -Value $content -Force -Encoding UTF8

}

$LocalFolderPath = ((git rev-parse --show-toplevel) + "/Docs/_site").Replace('/','\')

# Resolve-PnPFolder -SiteRelativePath $targetDocumentLibrary

$newSiteBuildFiles = Get-ChildItem -Path .\Docs\_site -Recurse -File

if ($isInitialBuild) {

    foreach ($file in $newSiteBuildFiles) {

        $spoTargetPath = $file.DirectoryName.Replace($LocalFolderPath,$targetDocumentLibrary).Replace('\','/')

        Add-PnPFile -Path ($File.FullName.ToString()) -Folder $spoTargetPath -NewFileName $file.Name -Values @{"Title" = $($File.Name) } | Out-Null
        Write-Host "Uploaded File: $($File.FullName)`nat $spoTargetPath/$($file.Name)"

        # Read-Host

    }

}

else {

    foreach ($file in $newSiteBuildFiles) {

        $newFileHash = Get-FileHash -Path $file.FullName

        $file.FullName

        if (Test-Path -Path $file.FullName.Replace("_site","_site_last_build")) {

            $lastFileHash = Get-FileHash -Path $file.FullName.Replace("_site","_site_last_build")

        }

        else {

            $lastFileHash = $null

        }

        $file.FullName.Replace("_site","_site_last_build")

        if ($newFileHash.Hash -eq $lastFileHash.Hash) {

            Write-Host "File '$($file.Name)' is unchanged." -ForegroundColor Green

        }

        else {

            if ($null -eq $lastFileHash) {

                Write-Host "File '$($file.Name)' is new." -ForegroundColor Yellow

            }

            else {

                Write-Host "File '$($file.Name)' is changed." -ForegroundColor Yellow

            }

            $spoTargetPath = $file.DirectoryName.Replace($LocalFolderPath,$targetDocumentLibrary).Replace('\','/')

            Add-PnPFile -Path ($File.FullName.ToString()) -Folder $spoTargetPath -NewFileName $file.Name -Values @{"Title" = $($File.Name) } | Out-Null
            Write-Host "Uploaded File: $($File.FullName)`nat $spoTargetPath/$($file.Name)"            

        }

        # Read-Host

    }

}