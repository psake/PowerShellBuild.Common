#requires -module InvokeBuild,Psake
$manifest           = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
$outputDir          = Join-Path -Path $ENV:BHProjectPath -ChildPath 'Output'
$outputModDir       = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
$outputModVerDir    = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
$ibTasksFilePath    = Join-Path -Path $outputModVerDir -ChildPath 'IB.tasks.ps1'
$psakeFilePath       = Join-Path -Path $outputModVerDir -ChildPath 'psakeFile.ps1'

Describe 'Invoke-Build Conversion' {
    $IBTasksResult = $null
    It 'IB.tasks.ps1 exists' {
        Test-Path $ibTasksFilePath | Should Be $true
    }
    It 'Parseable by invoke-build' {
        invoke-build -file $ibtasksFilePath -whatif -result IBTasksResult | Should BeOfType [String]
    }
    It 'Contains all the tasks that were in the Psake file' {
        #Invoke-PSake Fails in Pester Scope, have to run it in a completely separate runspace
        $psakeTaskNames = Start-Job -ScriptBlock {
            Invoke-PSake -docs -buildfile $USING:psakeFilePath | where name -notmatch '^(default|\?)$' | % name
        } | wait-job | receive-job

        $IBTaskNames = $IBTasksResult.all.name
        foreach ($taskItem in $psakeTaskNames) {
            if ($taskitem -notin $IBTaskNames) {
                throw "Task $taskitem was not successfully converted by Convert-PSAke"
            }
        }
        $Psaketasknames | should Not BeNullOrEmpty
    }
}