Set-StrictMode -Version Latest

Describe 'VSTeamAgent' {
   BeforeAll {
      Import-Module SHiPS
      Add-Type -Path "$PSScriptRoot/../../dist/bin/vsteam-lib.dll"

      $sut = (Split-Path -Leaf $PSCommandPath).Replace(".Tests.", ".")

      . "$PSScriptRoot/../../Source/Classes/VSTeamDirectory.ps1"
      . "$PSScriptRoot/../../Source/Classes/VSTeamVersions.ps1"
      . "$PSScriptRoot/../../Source/Classes/VSTeamAgent.ps1"
      . "$PSScriptRoot/../../Source/Private/common.ps1"
      . "$PSScriptRoot/../../Source/Public/Set-VSTeamDefaultProject.ps1"
      . "$PSScriptRoot/../../Source/Public/Get-VSTeamProject.ps1"
      . "$PSScriptRoot/../../Source/Public/$sut"
   
      # Prime the project cache with an empty list. This will make sure
      # any project name used will pass validation and Get-VSTeamProject 
      # will not need to be called.
      [vsteam_lib.ProjectCache]::Update([string[]]@())
      
      ## Arrange
      Mock _getApiVersion { return '1.0-unitTests' } -ParameterFilter { $Service -eq 'DistributedTaskReleased' }

      $testAgent = Get-Content "$PSScriptRoot\sampleFiles\agentSingleResult.json" -Raw | ConvertFrom-Json

      Mock _getInstance { return 'https://dev.azure.com/test' }

      # Even with a default set this URI should not have the project added.
      Set-VSTeamDefaultProject -Project Testing
   }

   Context 'Get-VSTeamAgent' {
      BeforeAll {
         Mock Invoke-RestMethod { return [PSCustomObject]@{
               count = 1
               value = $testAgent
            }
         }

         Mock Invoke-RestMethod { return $testAgent } -ParameterFilter { $Uri -like "*101*" }
      }

      it 'by pool id should return all the agents' {
         ## Act
         Get-VSTeamAgent -PoolId 1

         ## Assert
         Should -Invoke Invoke-RestMethod -Exactly -Times 1 -Scope It -ParameterFilter {
            $Uri -eq "https://dev.azure.com/test/_apis/distributedtask/pools/1/agents?api-version=$(_getApiVersion DistributedTaskReleased)"
         }
      }

      it 'with agent id parameter should return on agent' {
         ## Act
         Get-VSTeamAgent -PoolId 1 -id 101

         ## Assert
         Should -Invoke Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
            $Uri -eq "https://dev.azure.com/test/_apis/distributedtask/pools/1/agents/101?api-version=$(_getApiVersion DistributedTaskReleased)"
         }
      }

      it 'PoolID from pipeline by value should return all the agents' {
         ## Act
         1 | Get-VSTeamAgent

         ## Assert
         Should -Invoke Invoke-RestMethod -Exactly -Times 1 -Scope It -ParameterFilter {
            $Uri -eq "https://dev.azure.com/test/_apis/distributedtask/pools/1/agents?api-version=$(_getApiVersion DistributedTaskReleased)"
         }
      }
   }
}

