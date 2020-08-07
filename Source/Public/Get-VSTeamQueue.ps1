function Get-VSTeamQueue {
   [CmdletBinding(DefaultParameterSetName = 'List')]
   param(
      [Parameter(ParameterSetName = 'List')]
      [string] $queueName,

      [Parameter(ParameterSetName = 'List')]
      [ValidateSet('None', 'Manage', 'Use')]
      [string] $actionFilter,

      [Parameter(ParameterSetName = 'ByID')]
      [Alias('QueueID')]
      [string] $id,

      [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
      [ProjectValidateAttribute()]
      [ArgumentCompleter([ProjectCompleter])]
      [string] $ProjectName
   )

   process {
      $commonArgs = @{
         ProjectName = $projectName
         Area        = 'distributedtask'
         Resource    = 'queues'
         Version     = $(_getApiVersion DistributedTask)
      }

      if ($id) {
         $resp = _callAPI @commonArgs -Id $id

         $item = [VSTeamQueue]::new($resp, $ProjectName)

         Write-Output $item
      }
      else {
         $resp = _callAPI @commonArgs -QueryString @{ queueName = $queueName; actionFilter = $actionFilter }

         $objs = @()

         foreach ($item in $resp.value) {
            $objs += [VSTeamQueue]::new($item, $ProjectName)
         }

         Write-Output $objs
      }
   }
}
