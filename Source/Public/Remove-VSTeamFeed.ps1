function Remove-VSTeamFeed {
   [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
   param (
      [Parameter(ParameterSetName = 'ByID', Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
      [Alias('FeedId')]
      [string[]] $Id,

      [switch] $Force
   )
   process {
      foreach ($item in $id) {
         if ($Force -or $pscmdlet.ShouldProcess($item, "Delete Package Feed")) {
            # Call the REST API
            _callAPI -Method Delete -subDomain feeds `
               -Area packaging `
               -Resource feeds `
               -Id $item `
               -Version  $(_getApiVersion Packaging) | Out-Null

            Write-Output "Deleted Feed $item"
         }
      }
   }
}
