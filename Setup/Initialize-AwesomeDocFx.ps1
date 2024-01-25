[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)][string]$AppTitle = "My Docs"
)

$requiredVersion = "2.75.1"

$checkDoxFxVersion = (docfx --version).Split("+")[0]

if ($checkDoxFxVersion -eq $requiredVersion) {

    Write-Host "DocFx Version Check: OK" -ForegroundColor Green

}

else {

    Write-Host "DocFx Version Check: Not OK" -ForegroundColor Red
    Write-Host "DocFx Version 2.75.1 is required. You are running version $checkDoxFxVersion" -ForegroundColor Red

    if ($checkDoxFxVersion -gt $requiredVersion) {

        Write-Host "Please downgrade your DocFx version to 2.75.1" -ForegroundColor Red
        Write-Host "Run this command:" 'dotnet tool uninstall docfx --global' -ForegroundColor Yellow
        Write-Host "Then run this command:" 'dotnet tool install -g --add-source 'https://api.nuget.org/v3/index.json' --ignore-failed-sources docfx --version 2.75.1' -ForegroundColor Yellow

    }

    else {

        Write-Host "Please upgrade your DocFx version to 2.75.1" -ForegroundColor Red
        Write-Host "Run this command:" "dotnet tool update -g --add-source 'https://api.nuget.org/v3/index.json' --ignore-failed-sources 'docfx' --version '2.75.1'" -ForegroundColor Yellow

    }

}

$docFxJson = (Get-Content -Path .\Setup\docfx_template.json).Replace("appTitlePlaceHolder", $AppTitle)
Set-Content -Path .\Docs\docfx.json -Value $docFxJson -Force

$articlesFiles = Get-ChildItem -Path .\Docs\articles -Directory | ForEach-Object {Remove-Item -Path $_.FullName -Recurse}

$mainToc = @"
- name: Home
  href: articles/
"@

$structure = Import-Csv -Path .\Structure\Structure.csv -Delimiter ";" -Encoding UTF8

function Create-FoldersAndMarkdownFiles {
    param (
        [Parameter(Mandatory=$true)][string]$FolderPath,
        [Parameter(Mandatory=$true)][string]$MarkdownPath,
        [Parameter(Mandatory=$true)][string]$CategoryName,
        [Parameter(Mandatory=$true)][string]$CategorySafeName
    )

    if (!(Test-Path -Path "$FolderPath")) {

        New-Item -Path "$FolderPath" -ItemType Directory

    }

    if (!(Test-Path -Path "$MarkdownPath")) {

        Add-Content -Path "$MarkdownPath" -Value "# $CategoryName"

    }

    else {

        $checkContent1 = Get-Content -Path "$MarkdownPath"

        if ($checkContent1 -notmatch "# $CategoryName") {

            Add-Content -Path "$MarkdownPath" -Value "# $CategoryName"

        }

    }


    if (!(Test-Path -Path .\Docs\articles\$mainCategorySafeName\toc.yml)) {

        New-Item -Path .\Docs\articles\$mainCategorySafeName\toc.yml

    }

    $checkTocContent = Get-Content -Path .\Docs\articles\$mainCategorySafeName\toc.yml

    if ($structure.Category -contains $CategoryName) {

        if ($checkTocContent -notcontains "  href: $CategorySafeName.md") {

            Add-Content -Path .\Docs\articles\$mainCategorySafeName\toc.yml -Value "- name: $CategoryName`n  href: $CategorySafeName.md"

        }

    }

    if ($structure.SubCategory1 -contains $CategoryName) {

        if ($checkTocContent -notcontains "  href: $subCategory1SafeName/$CategorySafeName.md") {

            Add-Content -Path .\Docs\articles\$mainCategorySafeName\toc.yml -Value "- name: $CategoryName`n  href: $subCategory1SafeName/$CategorySafeName.md"

        }

    }

    if ($structure.SubCategory2 -contains $CategoryName) {

        if ($checkTocContent -notcontains "    href: $subCategory1SafeName/$subCategory2SafeName/$CategorySafeName.md") {

            if ($checkTocContent[($checkTocContent.IndexOf("- name: $subCategory1")) +2] -eq "  items:") {

                Add-Content -Path .\Docs\articles\$mainCategorySafeName\toc.yml -Value "  - name: $CategoryName`n    href: $subCategory1SafeName/$subCategory2SafeName/$CategorySafeName.md"

            }

            else {

                Add-Content -Path .\Docs\articles\$mainCategorySafeName\toc.yml -Value "  items:`n  - name: $CategoryName`n    href: $subCategory1SafeName/$subCategory2SafeName/$CategorySafeName.md"

            }


        }

    }

    if ($structure.SubCategory3 -contains $CategoryName) {

        if ($checkTocContent -notcontains "      href: $subCategory1SafeName/$subCategory2SafeName/$subCategory3SafeName/$CategorySafeName.md") {

            if ($checkTocContent[($checkTocContent.IndexOf("  - name: $subCategory2")) +2] -eq "    items:") {

                Add-Content -Path .\Docs\articles\$mainCategorySafeName\toc.yml -Value "    - name: $CategoryName`n      href: $subCategory1SafeName/$subCategory2SafeName/$subCategory3SafeName/$CategorySafeName.md"

            }

            else {

                Add-Content -Path .\Docs\articles\$mainCategorySafeName\toc.yml -Value "    items:`n    - name: $CategoryName`n      href: $subCategory1SafeName/$subCategory2SafeName/$subCategory3SafeName/$CategorySafeName.md"

            }
        }

    }

}

foreach ($entry in $structure) {

    $mainCategory = $entry.Category
    $subCategory1 = $entry.subCategory1
    $subCategory2 = $entry.subCategory2
    $subCategory3 = $entry.subCategory3

    $mainCategorySafeName = $mainCategory.Replace(" ","-").ToLower()
    $subCategory1SafeName = $subCategory1.Replace(" ","-").ToLower()
    $subCategory2SafeName = $subCategory2.Replace(" ","-").ToLower()
    $subCategory3SafeName = $subCategory3.Replace(" ","-").ToLower()

    if ($mainToc -notmatch "`n- name: $mainCategory`n  href: articles/$mainCategorySafeName/") {

        $mainToc += "`n- name: $mainCategory`n  href: articles/$mainCategorySafeName/"

    }

    # Create main category folders and markdown
    . Create-FoldersAndMarkdownFiles -FolderPath ".\Docs\articles\$mainCategorySafeName" -MarkdownPath ".\Docs\articles\$mainCategorySafeName\$mainCategorySafeName.md" -CategoryName $mainCategory -CategorySafeName $mainCategorySafeName

    if ($entry.SubCategory1) {

        # Create sub category1 folders and markdown
        . Create-FoldersAndMarkdownFiles -FolderPath ".\Docs\articles\$mainCategorySafeName\$subCategory1SafeName" -MarkdownPath ".\Docs\articles\$mainCategorySafeName\$subCategory1SafeName\$subCategory1SafeName.md" -CategoryName $subCategory1 -CategorySafeName $subCategory1SafeName

    }

    if ($entry.SubCategory2) {

        # Create sub category2 markdown
        . Create-FoldersAndMarkdownFiles -FolderPath ".\Docs\articles\$mainCategorySafeName\$subCategory1SafeName\$subCategory2SafeName" -MarkdownPath ".\Docs\articles\$mainCategorySafeName\$subCategory1SafeName\$subCategory2SafeName\$subCategory2SafeName.md" -CategoryName $subCategory2 -CategorySafeName $subCategory2SafeName

    }

    if ($entry.SubCategory3) {

        . Create-FoldersAndMarkdownFiles -FolderPath ".\Docs\articles\$mainCategorySafeName\$subCategory1SafeName\$subCategory2SafeName\$subCategory3SafeName" -MarkdownPath ".\Docs\articles\$mainCategorySafeName\$subCategory1SafeName\$subCategory2SafeName\$subCategory3SafeName\$($subCategory3SafeName).md" -CategoryName $subCategory3 -CategorySafeName $subCategory3SafeName

    }

    # Read-Host

}

Set-Content .\Docs\toc.yml -Value $mainToc

$articlesToc = @"
- name: Home
  href: ../index.md
- name: Getting Started
  href: getting-started.md
"@

Set-Content .\Docs\articles\getting-started.md -Value "# Getting Started"

Set-Content .\Docs\articles\toc.yml -Value $articlesToc