function Get-VSTeamPool {
   [CmdletBinding(DefaultParameterSetName = 'List')]
   param(
      [Parameter(ParameterSetName = 'ByID', Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
      [Alias('PoolID')]
      [int] $Id
   )

   process {
      $commonArgs = @{
         NoProject = $true
         Area      = 'distributedtask'
         Resource  = 'pools'
         Version   = $(_getApiVersion DistributedTaskReleased)
      }

      if ($id) {
         $resp = _callAPI @commonArgs -Id $id

         # Storing the object before you return it cleaned up the pipeline.
         # When I just write the object from the constructor each property
         # seemed to be written
         $item = [VSTeamPool]::new($resp)

         Write-Output $item
      }
      else {
         $resp = _callAPI @commonArgs

         $objs = @()

         foreach ($item in $resp.value) {
            $objs += [VSTeamPool]::new($item)
         }

         Write-Output $objs
      }
   }
}