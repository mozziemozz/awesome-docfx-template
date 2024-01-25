# Update theme

docfx template export modern
$docFxMinJs = (Get-Content -Path .\_exported_templates\modern\public\docfx.min.js).Replace('" target="_blank"', '" target="_self"')
Set-Content -Path .\Docs\templates\awesome\public\docfx.min.js -Value $docFxMinJs
Remove-Item -Path .\_exported_templates -Recurse -Force