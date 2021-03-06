﻿#requires -Version 3
function Remove-RubrikNutanixVMSnapshot
{
  <#
      .SYNOPSIS
      Connects to Rubrik and removes an expired Nutanix VM snapshot available for garbage collection.

      .DESCRIPTION
      The Remove-RubrikNutanixVMSnapshot cmdlet will request that the Rubrik API delete an an expired Nutanix VM snapshot.
      The snapshot must a snapshot from a Nutanix VM that is not assigned to an SLA Domain.

      .NOTES
      Written by Mike Preston for community usage
      Twitter: @mwpreston
      GitHub: mwpreston

      .LINK
      https://rubrik.gitbook.io/rubrik-sdk-for-powershell/command-documentation/reference/remove-rubriknutanixvmsnapshot

      .EXAMPLE
      Remove-RubrikNutanixVMSnapshot -id '01234567-8910-1abc-d435-0abc1234d567'
      This will attempt to remove Nutanix VM snapshot (backup) data with the snapshot id `01234567-8910-1abc-d435-0abc1234d567`

      .EXAMPLE
      Remove-RubrikNutanixVMSnapshot -id '01234567-8910-1abc-d435-0abc1234d567' -location local -Confirm:$false
      This will attempt to remove the local copy of the Nutanix VM snapshot (backup) data with the snapshot id `01234567-8910-1abc-d435-0abc1234d567` without user intevention

      .EXAMPLE
      Get-RubrikNutanixVM VM1 | Get-RubrikSnapshot -Date '03/21/2017' | Remove-RubrikNutanixVMSnapshot
      This will attempt to remove any snapshot from `03/21/2017` for the Nutanix VM named `VM1`.
  #>

  [CmdletBinding(SupportsShouldProcess = $true,ConfirmImpact = 'High')]
  Param(
    # ID of the snapshot to delete
    [Parameter(Mandatory = $true,ValueFromPipelineByPropertyName = $true)]
    [String]$id,
    # Snapshot location to delete, either "local" or "all". Defaults to "all"
    [ValidateSet('all','local')]
    [String]$location = "all",
    # Rubrik server IP or FQDN
    [String]$Server = $global:RubrikConnection.server,
    # API version
    [ValidateNotNullorEmpty()]
    [String]$api = $global:RubrikConnection.api
  )

  Begin {

    # The Begin section is used to perform one-time loads of data necessary to carry out the function's purpose
    # If a command needs to be run with each iteration or pipeline input, place it in the Process section

    # Check to ensure that a session to the Rubrik cluster exists and load the needed header data for authentication
    Test-RubrikConnection

    # API data references the name of the function
    # For convenience, that name is saved here to $function
    $function = $MyInvocation.MyCommand.Name

    # Retrieve all of the URI, method, body, query, result, filter, and success details for the API endpoint
    Write-Verbose -Message "Gather API Data for $function"
    $resources = Get-RubrikAPIData -endpoint $function
    Write-Verbose -Message "Load API data for $($resources.Function)"
    Write-Verbose -Message "Description: $($resources.Description)"

  }

  Process {
    if ($PSCmdlet.ShouldProcess("$id", "Remove snapshot ")) {
        $uri = New-URIString -server $Server -endpoint ($resources.URI) -id $id
        $uri = Test-QueryParam -querykeys ($resources.Query.Keys) -parameters ((Get-Command $function).Parameters.Values) -uri $uri
        $body = New-BodyString -bodykeys ($resources.Body.Keys) -parameters ((Get-Command $function).Parameters.Values)
        $result = Submit-Request -uri $uri -header $Header -method $($resources.Method) -body $body
        $result = Test-ReturnFormat -api $api -result $result -location $resources.Result
        $result = Test-FilterObject -filter ($resources.Filter) -result $result

        return $result
    }
  } # End of process
} # End of function