using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management.Automation

# This class defines an attribute that allows the user the tab complete
# build numbers for function parameters. For this completer to work the
# users must have already provided the ProjectName parameter for the
# function or set a default project.
class BuildCompleter : IArgumentCompleter {
   [IEnumerable[CompletionResult]] CompleteArgument(
      [string] $CommandName,
      [string] $ParameterName,
      [string] $WordToComplete,
      [Language.CommandAst] $CommandAst,
      [IDictionary] $FakeBoundParameters) {

      $results = [List[CompletionResult]]::new()

      # If the user has explicitly added the -ProjectName parameter
      # to the command use that instead of the default project.
      $projectName = $FakeBoundParameters['ProjectName']

      # Only use the default project if the ProjectName parameter was
      # not used
      if (-not $projectName) {
         $projectName = _getDefaultProject
      }

      # If there is no projectName by this point just return a empty
      # list.
      if ($projectName) {
         foreach ($value in (Get-VSTeamBuild -ProjectName $projectName).buildNumber) {
            if ($value -like "$WordToComplete*") {
               $results.Add([CompletionResult]::new("'$($value.replace("'","''"))'", $value, 0, $value))
            }
         }
      }

      return $results
   }
}