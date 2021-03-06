function Test-ForUnimportedModuleFile
{
    param(
    [Parameter(ParameterSetName='TestModuleInfo',Mandatory=$true,ValueFromPipeline=$true)]
    [Management.Automation.PSModuleInfo]
    $ModuleInfo
    )
    
    process {
        $verbNounPairFiles = $ModuleInfo.Path | 
            Split-Path | 
            Get-ChildItem -Filter *-*.ps1 | 
            Select-Object -ExpandProperty Fullname
        
        $moduleScriptFiles = $moduleInfo.ExportedCommands.Values | 
            Where-Object { $_.ScriptBlock }  | 
            ForEach-Object {$_.ScriptBlock.File } 
                
        $missingFiles = 
            Compare-Object -ReferenceObject $verbNounPairFiles -DifferenceObject $moduleScriptFiles | 
            Where-Object { $_.SideIndicator -eq '<=' } |
            Select-Object -ExpandProperty InputObject

        if ($missingFiles) {            
            $missingFileNames = $missingFiles | 
                Split-Path -Leaf
            
            if ($moduleInfo.Path -like "*.psm1") {
                $lines = [IO.File]::ReadAllLines($moduleInfo.Path)                
            }    
            
            $missingFileNames = $missingFileNames | 
                Where-Object {
                    foreach ($l in $lines) {
                        if ($l -like "*$_*") {
                            return
                        }
                    }
                    $true
                }
            
            if ($MissingFileNames) {
                Write-Error -Message "$ModuleInfo does not import some .ps1s in the directory.  The files are: $($missingFileNames -join ',') " -ErrorId "ScriptCop.UnimportedModuleFiles" -TargetObject $missingFileNames  -Category "NotInstalled"                                 
            }
        }
    }
}
 
