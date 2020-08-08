Set-StrictMode -Version Latest

Describe 'VSTeamYamlPipeline' {
   BeforeAll {
      Add-Type -Path "$PSScriptRoot/../../dist/bin/vsteam-lib.dll"
      
      $sut = (Split-Path -Leaf $PSCommandPath).Replace(".Tests.", ".")
      
      . "$PSScriptRoot/../../Source/Classes/VSTeamVersions.ps1"
      . "$PSScriptRoot/../../Source/Private/applyTypes.ps1"
      . "$PSScriptRoot/../../Source/Private/common.ps1"
      . "$PSScriptRoot/../../Source/Public/$sut"

      # Prime the project cache with an empty list. This will make sure
      # any project name used will pass validation and Get-VSTeamProject 
      # will not need to be called.
      [vsteam_lib.ProjectCache]::Update([string[]]@())
      
      $resultsAzD = Get-Content "$PSScriptRoot\sampleFiles\pipelineDefYamlResult.json" -Raw | ConvertFrom-Json
      
      Mock _getInstance { return 'https://dev.azure.com/test' } -Verifiable

      $testYamlPath = "$PSScriptRoot\sampleFiles\azure-pipelines.test.yml"

      Mock Invoke-RestMethod { return $resultsAzD }
   }

   Context 'Test-VSTeamYamlPipeline' {

      It 'With Pipeline with PipelineID and without extra YAML' {
         Test-VSTeamYamlPipeline -projectName project -PipelineId 24

         Should -Invoke Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
            $Uri -like "*https://dev.azure.com/test/project/_apis/pipelines/24/runs*" -and
            $Uri -like "*api-version=$(_getApiVersion Build)*" -and
            $Body -like '*"PreviewRun":*true*' -and
            $Body -notlike '*YamlOverride*'
         }
      }

      It 'With Pipeline with PipelineID and YAML file path' {
         Test-VSTeamYamlPipeline -projectName project -PipelineId 24 -FilePath $testYamlPath

         Should -Invoke Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
            $Uri -like "*https://dev.azure.com/test/project/_apis/pipelines/24/runs*" -and
            $Uri -like "*api-version=$(_getApiVersion Build)*" -and
            $Body -like '*"PreviewRun":*true*' -and
            $Body -like '*YamlOverride*'
         }
      }

      It 'With Pipeline with PipelineID and YAML code' {
         $yamlOverride = [string](Get-Content -raw $testYamlPath)

         Test-VSTeamYamlPipeline -projectName project -PipelineId 24 -YamlOverride $yamlOverride

         Should -Invoke Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
            $Uri -like "*https://dev.azure.com/test/project/_apis/pipelines/24/runs*" -and
            $Uri -like "*api-version=$(_getApiVersion Build)*" -and
            $Body -like '*"PreviewRun":*true*' -and
            $Body -like '*YamlOverride*'
         }
      }
      
      It 'Should create Yaml result' {
         $yamlResult = Test-VSTeamYamlPipeline -projectName project -PipelineId 24 -FilePath $testYamlPath

         $yamlResult | Should -Not -Be $null
      }
   }
}