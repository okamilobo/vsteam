Set-StrictMode -Version Latest

Describe "TeamGitStat" {
   BeforeAll {
      Import-Module SHiPS
      Add-Type -Path "$PSScriptRoot/../../dist/bin/vsteam-lib.dll"
      
      $sut = (Split-Path -Leaf $PSCommandPath).Replace(".Tests.", ".")
      
      . "$PSScriptRoot/../../Source/Classes/VSTeamLeaf.ps1"
      . "$PSScriptRoot/../../Source/Classes/VSTeamVersions.ps1"
      . "$PSScriptRoot/../../Source/Classes/VSTeamFeed.ps1"
      . "$PSScriptRoot/../../Source/Private/common.ps1"
      . "$PSScriptRoot/../../Source/Private/applyTypes.ps1"
      . "$PSScriptRoot/../../Source/Public/Get-VSTeamProject.ps1"
      . "$PSScriptRoot/../../Source/Public/$sut"
      
      # Prime the project cache with an empty list. This will make sure
      # any project name used will pass validation and Get-VSTeamProject 
      # will not need to be called.
      [vsteam_lib.ProjectCache]::Update([string[]]@())

      $singleResult = Get-Content "$PSScriptRoot\sampleFiles\gitStatSingleResult.json" -Raw | ConvertFrom-Json

      # Set the account to use for testing. A normal user would do this
      # using the Set-VSTeamAccount function.
      Mock _getInstance { return 'https://dev.azure.com/test' }

      Mock Invoke-RestMethod { return $singleResult }
   }

   Context 'Get-VSTeamGitStat' {
      It 'should return multiple results' {
         ## Act
         Get-VSTeamGitStat -ProjectName Test -RepositoryId 00000000-0000-0000-0000-000000000000

         ## Assert
         Should -Invoke Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
            $Uri -like "*/Test/*" -and
            $Uri -like "*repositories/00000000-0000-0000-0000-000000000000/stats/branches*"
         }
      }

      It 'by branch name should return multiple results' {
         ## Act
         Get-VSTeamGitStat -ProjectName Test -RepositoryId 00000000-0000-0000-0000-000000000000 -BranchName develop

         ## Assert
         Should -Invoke Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
            $Uri -like "*/Test/*" -and
            $Uri -like "*repositories/00000000-0000-0000-0000-000000000000/stats/branches*" -and
            $Uri -like "*name=develop*"
         }
      }

      It 'by tag should return multiple results' {
         ## Act
         Get-VSTeamGitStat -ProjectName Test -RepositoryId 00000000-0000-0000-0000-000000000000 -BranchName "develop" -VersionType "tag" -Version "test"

         ## Assert
         Should -Invoke Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
            $Uri -like "*/Test/*" -and
            $Uri -like "*repositories/00000000-0000-0000-0000-000000000000/stats/branches*" -and
            $Uri -like "*baseVersionDescriptor.versionType=tag*" -and
            $Uri -like "*baseVersionDescriptor.version=test*"
         }
      }

      It 'by tag with options should return multiple results' {
         ## Act
         Get-VSTeamGitStat -ProjectName Test -RepositoryId 00000000-0000-0000-0000-000000000000 -BranchName "develop" -VersionType "tag" -Version "test" -VersionOptions previousChange

         ## Assert
         Should -Invoke Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
            $Uri -like "*/Test/*" -and
            $Uri -like "*repositories/00000000-0000-0000-0000-000000000000/stats/branches*" -and
            $Uri -like "*baseVersionDescriptor.versionType=tag*" -and
            $Uri -like "*baseVersionDescriptor.version=test*" -and
            $Uri -like "*baseVersionDescriptor.versionOptions=previousChange*"
         }
      }

      It 'by commit should throw because of invalid parameters' {
         ## Act / Assert
         { Get-VSTeamGitStat -ProjectName Test -RepositoryId 00000000-0000-0000-0000-000000000000 -VersionType commit -Version '' } | Should -Throw
      }
   }
}