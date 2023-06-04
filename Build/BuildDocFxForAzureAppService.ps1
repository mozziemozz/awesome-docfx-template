<#

    .SYNOPSIS
    Web App Deployment Script

    .DESCRIPTION
    The "Web App Deployment Script" is a PowerShell script that automates the deployment of a web application to Microsoft Azure. This script takes two mandatory parameters: ResourceGroupName and AppServiceName. It builds the site using DocFX, creates a deployment zip file, and publishes the web app to Azure.

    .AUTHOR
    Author:         Martin Heusser
    Creation Date:  2023-06-04

    .PARAMETER ResourceGroupName
    The name of the Azure resource group where the web app will be deployed.

    .PARAMETER AppServiceName
    The name of the App Service where the web app will be published.

    .EXAMPLE
    .\DeployWebApp.ps1 -ResourceGroupName "MyResourceGroup" -AppServiceName "MyAppService"

#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][String]$ResourceGroupName,
    [Parameter(Mandatory=$true)][String]$AppServiceName
)

#requires -Modules "Az.Websites"

# Add Web.config file
if (!(Test-Path -Path .\Docs\_site\Web.config)) {

    Copy-Item -Path .\Setup\Web.config -Destination .\Docs

}

# Build the site
docfx .\Docs\docfx.json

# Remve possible existing old zip file
if (Test-Path -Path .\ZipDeploy.zip) {

    Remove-Item -Path .\ZipDeploy.zip -Force

}

# Add files in .\Docs\_site\ to zip archive
Compress-Archive -Path .\Docs\_site\* -DestinationPath "ZipDeploy.zip" -Force

$checkAzureSession = Get-AzContext

if (!$checkAzureSession) {

    Login-AzAccount

}

Write-Host "Publishing Web App... this can take a while..." -ForegroundColor Cyan

# Publish Web App to Azure
Publish-AzWebapp -ResourceGroupName $ResourceGroupName -Name $AppServiceName -ArchivePath .\ZipDeploy.zip -Force

if ($?) {

    $publishedApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName

    Write-Host "Web App published successfully. Go to 'https://$(($publishedapp.HostNames)[0])' to view your site." -ForegroundColor Green

}

else {

    Write-Host "Error while trying to publish the Web App." -ForegroundColor Red

}


