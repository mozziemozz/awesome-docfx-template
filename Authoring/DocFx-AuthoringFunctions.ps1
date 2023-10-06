function New-DocFxImageLink {
	param (
		[Parameter(Mandatory=$false)][string]$ImgAltText,
		[Parameter(Mandatory=$true)][ValidateSet("root","articles","category","subCategory1","subCategory2","subCategory3")][string]$FolderLevel
	)

	$docsImagesPath = (git rev-parse --show-toplevel) + "/Docs/.attachments"

	switch ($FolderLevel) {
		root {

			$relativePath = ".attachments"

		}
		articles {

			$relativePath = "../.attachments"

		}
		category {

			$relativePath = "../../.attachments"

		}
		subCategory1 {

			$relativePath = "../../../.attachments"

		}
		subCategory2 {

			$relativePath = "../../../../.attachments"

		}
		subCategory3 {

			$relativePath = "../../../../../.attachments"

		}
		Default {}
	}
   
	if (Test-Path ".\Docs\ImageIndex.txt") {
	
		$folderContents = (Get-ChildItem -Path $docsImagesPath).Name
	
		$imageIndex = Get-Content -Path ".\Docs\ImageIndex.txt"
		$newFiles = $folderContents | Where-Object {$imageIndex -notcontains $_}

		if ($newFiles) {

			$newLinks = @()

			foreach ($newFile in $newFiles) {

				if ($newFile.Contains(" ")) {

					$newFileName = $newFile.Replace(" ","_")

					Rename-Item -Path "$docsImagesPath/$newFile" -NewName $newFileName

					$newFile = $newFileName

				}
		
				if (!$ImgAltText) {

					$ImgAltText = ($newFile | Split-Path -Leaf)

				}

				$newImage = "![$ImgAltText]($RelativePath/$newFile)"

				$newLinks += $newImage
				
				Add-Content -Path ".\Docs\ImageIndex.txt" -Value $newFile
		
			}

			Write-Host "Markdown compatible file paths are now in clipboard:" $newLinks -ForegroundColor Cyan
			Set-Clipboard $newLinks

		}
	
		else {
	
			Write-Host "No new images found." -ForegroundColor Magenta
			Set-Content -Path .\Docs\ImageIndex.txt -Value $folderContents
	
		}
	
	}
   
	else {
		
		$folderContents = Get-ChildItem -Path $docsImagesPath
	
		Set-Content -Path ".\Docs\ImageIndex.txt" -Value $null
	
		Write-Warning "ImageIndex.txt not found. The file has been created at .\Docs\ImageIndex.txt"

		New-DocFxImageLink -FolderLevel $FolderLevel
		
	}
    
}

function New-DocFxCodeSnippet {
    param (
        [Parameter(Mandatory=$false)][string]$Language
    )

    $codeSnippet = @'
```LanguagePlaceHolder

```
'@

    if ($Language) {

		$Language = $Language.ToLower()
        $codeSnippet = $codeSnippet.Replace("LanguagePlaceHolder",$Language)

    }

    else {

        $codeSnippet = $codeSnippet.Replace("LanguagePlaceHolder","")

    }

    Write-Host "A new code snippet is now in your clipboard. Press CTRL + V to paste it into your markdown file." -ForegroundColor Cyan
    $codeSnippet | Set-Clipboard
    
}

function New-DocFxCallOut {
    param (
        [Parameter(Mandatory=$true)][ValidateSet("NOTE","TIP","WARNING","IMPORTANT","CAUTION")][string]$Type
    )

    $newCallOut = @"
> [!$Type]
> 
"@

    Write-Host "A new call out is now in your clipboard. Press CTRL + V to paste it into your markdown file." -ForegroundColor Cyan
    $newCallOut | Set-Clipboard
    
}

function New-DocFxLineBreaks {
    param (
        [Parameter(Mandatory=$true)][int]$NumberOfLineBreaks
    )

    $lineBreakCounter = 0

    $newLineBreaks = ""

    do {
        
        $newLineBreaks += "&nbsp;"

        $lineBreakCounter ++

    } until (
        $lineBreakCounter -eq $NumberOfLineBreaks
    )

    Write-Host "$NumberOfLineBreaks linebreaks are now in your clipboard. Press CTRL + V to paste it into your markdown file." -ForegroundColor Cyan
    $newLineBreaks | Set-Clipboard
    
}

function New-DocFxTabbedContent {
	param (
		[Parameter(Mandatory=$true)][string]$TabId,
        [Parameter(Mandatory=$true)][string]$TabNameA,
		[Parameter(Mandatory=$true)][string]$TabNameB
	)

	$TabId = ($TabId.Replace(" ", "-")).ToLower()
	$TabNameSafeA = ($TabNameA.Replace(" ","-") + "-$TabId").ToLower()
	$TabNameSafeB = ($TabNameB.Replace(" ","-") + "-$TabId").ToLower()

	$newTabbedContent = @"

# [$TabNameA](#tab/$TabNameSafeA)

Content for Tab A $TabId...

# [$TabNameB](#tab/$TabNameSafeB)

Content for Tab B $TabId...

---

"@

	Write-Host "Tabbed Content is now in your clipboard. Press CTRL + V to paste it into your markdown file." -ForegroundColor Cyan
	$newTabbedContent | Set-Clipboard

	
}

function Update-DocFxSite {
	param (
		
	)

	docfx .\Docs\docfx.json
	
}

function New-DocFxTableFromCsv {
	param (
		[Parameter(Mandatory=$true)][string]$CsvPath,
		[Parameter(Mandatory=$false)][string]$Delimiter = ";"
	)

	$csvContent = Import-Csv -Path $CsvPath -delimiter $Delimiter -Encoding utf8

	$columnTitles = $csvContent[0].psobject.properties.name
	
	# Make each first letter of column title uppercase
	$columnTitles = $columnTitles | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }

	$tableContent = ""

	foreach ($columnTitle in $columnTitles) {

		$tableContent += "| $columnTitle "

	}

	$tableContent += "|`n"

	foreach ($columnTitle in $columnTitles) {

		$tableContent += "| --- "

	}

	$tableContent += "|"

	foreach ($row in $csvContent) {

		$tableContent += "`n"

		foreach ($columnTitle in $columnTitles) {

			$tableContent += "| $($row.$columnTitle) "

		}

		$tableContent += "|"

	}

	Write-Host "Markdown formatted Table is now in your clipboard. Press CTRL + V to paste it into your markdown file." -ForegroundColor Cyan
	$tableContent | Set-Clipboard

}

function Start-DocFxPreview {
	param (
		
	)

	Start-Process "http://localhost:8080"

	docfx .\docs\docfx.json --serve
	
}