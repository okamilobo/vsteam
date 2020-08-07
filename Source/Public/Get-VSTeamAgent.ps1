function Get-VSTeamAgent {
   [CmdletBinding(DefaultParameterSetName = 'List')]
   param(
      [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
      [int] $PoolId,

      [Parameter(ParameterSetName = 'ByID', Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
      [Alias('AgentID')]
      [int] $Id
   )

   process {
      $commonArgs = @{
         NoProject = $true
         Area      = "distributedtask/pools/$PoolId"
         Resource  = 'agents'
         Body      = @{ includeCapabilities = 'true' }
         Version   = $(_getApiVersion DistributedTaskReleased)
      }

      if ($id) {
         $resp = _callAPI @commonArgs -Id $id

         # Storing the object before you return it cleaned up the pipeline.
         # When I just write the object from the constructor each property
         # seemed to be written
         $item = [VSTeamAgent]::new($resp, $PoolId)

         Write-Output $item
      }
      else {
         $resp = _callAPI @commonArgs

         $objs = @()

         foreach ($item in $resp.value) {
            $objs += [VSTeamAgent]::new($item, $PoolId)
         }

         Write-Output $objs
      }
   }
}