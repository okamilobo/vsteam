Set-StrictMode -Version Latest

Describe 'VSTeamReleaseDefinition' {
   BeforeAll {
      Add-Type -Path "$PSScriptRoot/../../dist/bin/vsteam-lib.dll"
      
      $sut = (Split-Path -Leaf $PSCommandPath).Replace(".Tests.", ".")
      
      . "$PSScriptRoot/../../Source/Classes/VSTeamVersions.ps1"
      . "$PSScriptRoot/../../Source/Private/common.ps1"
      . "$PSScriptRoot/../../Source/Public/Get-VSTeamProject.ps1"
      . "$PSScriptRoot/../../Source/Public/$sut"

      # Prime the project cache with an empty list. This will make sure
      # any project name used will pass validation and Get-VSTeamProject 
      # will not need to be called.
      [vsteam_lib.ProjectCache]::Update([string[]]@())
      
      ## Arrange
      Mock _getApiVersion { return '1.0-unittest' } -ParameterFilter { $Service -eq 'Release' }

      $results = [PSCustomObject]@{
         value = [PSCustomObject]@{
            queue           = [PSCustomObject]@{ name = 'Default' }
            _links          = [PSCustomObject]@{
               self = [PSCustomObject]@{ }
               web  = [PSCustomObject]@{ }
            }
            retentionPolicy = [PSCustomObject]@{ }
            lastRelease     = [PSCustomObject]@{ }
            artifacts       = [PSCustomObject]@{ }
            modifiedBy      = [PSCustomObject]@{ name = 'project' }
            createdBy       = [PSCustomObject]@{ name = 'test' }
         }
      }
   }

   Context 'Remove-VSTeamReleaseDefinition' {
      BeforeAll {
         Mock Invoke-RestMethod { return $results }
      }

      Context 'Services' {
         BeforeAll {
            Mock _getInstance { return 'https://dev.azure.com/test' }
         }

         It 'should delete release definition' {
            ## Act
            Remove-VSTeamReleaseDefinition -projectName project -id 2 -Force

            ## Assert
            Should -Invoke Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
               $Method -eq 'Delete' -and
               $Uri -eq "https://vsrm.dev.azure.com/test/project/_apis/release/definitions/2?api-version=$(_getApiVersion Release)"
            }
         }
      }

      Context 'Server' {
         BeforeAll {
            Mock _useWindowsAuthenticationOnPremise { return $true }
            Mock _getInstance { return 'http://localhost:8080/tfs/defaultcollection' }
         }

         It 'local Auth should delete release definition' {
            ## Act
            Remove-VSTeamReleaseDefinition -projectName project -id 2 -Force

            ## Assert
            Should -Invoke Invoke-RestMethod -Exactly -Scope Context -Times 1 -ParameterFilter {
               $Method -eq 'Delete' -and
               $Uri -eq "http://localhost:8080/tfs/defaultcollection/project/_apis/release/definitions/2?api-version=$(_getApiVersion Release)"
            }
         }
      }
   }
}