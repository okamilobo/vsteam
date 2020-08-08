# id: 02cc6a73-5cfb-427d-8c8e-b49fb086e8af
# area: processes
# resource name: processes
# route template: _apis/work/{resource}/{processTypeId}
#
# First appears in TFS 2017 U2 with same values in TFS 2017 U3:
# resourceVersion : 1
# minVersion      : 2.1
# maxVersion      : 3.2
# releasedVersion : 0.0
# However, I was unable to get any combination of versions to work.
#
# TFS 2018 U1 returns values
# resourceVersion : 1
# minVersion      : 2.1
# maxVersion      : 4.0
# releasedVersion : 0.0

function Get-VSTeamProcess {
   [CmdletBinding(DefaultParameterSetName = 'List')]
   param(
      [Parameter(ParameterSetName = 'ByName', Position = 0)]
      [ArgumentCompleter([vsteam_lib.ProcessTemplateCompleter])]
      [Alias('ProcessName', 'ProcessTemplate')]
      $Name = '*',

      [Parameter(DontShow = $true, ParameterSetName = 'List')]
      [int] $Top = 100,

      [Parameter(DontShow = $true, ParameterSetName = 'List')]
      [int] $Skip = 0,

      [Parameter(ParameterSetName = 'ByID')]
      [Alias('ProcessTemplateID')]
      [string] $Id
   )
   process {
      # The REST API ignores Top and Skip but allows them to be specified & the function does the same. 
      if ($PSBoundParameters['Top', 'Skip'] -gt 0) {
         Write-Warning "You specified -Top $Top , -Skip $Skip These parameters are ignored and will be removed in future"
      }

      $commonArgs = @{
         # In later APIs you can get the process templates from the 'work' 
         # area. For older APIs the process templates are in the 'processes'
         # area. Default to the newer way of accessing process templates.
         # Get-VSTeamOption -area 'work' -resource 'processes' returns nothing
         # this is odd but the call works.
         area      = 'work'
         resource  = 'processes'
         NoProject = $true
         version   = $(_getApiVersion Processes)
      }

      # If this returns an empty string use the old area of 'process'
      if (-not $commonArgs.version) {
         $commonArgs.area = 'process'
      }

      # Return either a single process by ID or a list of processes
      if ($id) {
         # Call the REST API with an ID
         $resp = _callAPI @commonArgs -id $id

         $process = [VSTeamProcess]::new($resp)

         Write-Output $process
      }
      else {
         try {
            # Call the REST API
            $resp = _callAPI @commonArgs

            # We just fetched all the processes so let's update the cache. Also, cache the URLS for processes
            [vsteam_lib.ProcessTemplateCache]::Update([string[]]$($resp.value | Select-Object -ExpandProperty Name | Sort-Object))

            $resp.value | ForEach-Object {
               [VSTeamProcess]::new($_)
            } | Where-Object { $_.name -like $Name } | Sort-Object -Property Name
         }
         catch {
            # I catch because using -ErrorAction Stop on the Invoke-RestMethod
            # was still running the foreach after and reporting useless errors.
            # This casuses the first error to terminate this execution.
            _handleException $_
         }
      }
   }
}
