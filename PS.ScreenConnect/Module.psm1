<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Update-ScreenConnectServer
{
    [CmdletBinding(SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  ConfirmImpact='High')]
    [Alias()]
    Param
    (
        # Pick release branch
        [Parameter(Mandatory=$true, Position=0)]
        [Alias("Stable")] 
        [Boolean]$StableReleaseBranchOnly = $true,

        # Param2 help description
        [Parameter(ParameterSetName='Parameter Set 1')]
        [AllowNull()]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [ValidateScript({$true})]
        [ValidateRange(0,5)]
        [int]
        $Param2,

        # Param3 help description
        [Parameter(ParameterSetName='Another Parameter Set')]
        [ValidatePattern("[a-z]*")]
        [ValidateLength(0,15)]
        [String]
        $Param3
    )

    Begin
    {
		Write-Verbose "Acquiring latest ScreenConnect server version."
    }
    Process
    {
		if($StableReleaseBranchOnly)
		{
			$updateStaging = Invoke-WebRequest -Uri "https://www.screenconnect.com/Download"
			[String[]]$updatesAvailable = ($updateStaging.links | where {$_.innerHTML -like "*Release.msi"}).href
			$updateVersionNumber = [regex]::Match($updatesAvailable, '[0-9][0-9.]*[0-9]').Value
			Write-Verbose "Downloading version $updateVersionNumber."
			if(!Test-Path $env:SystemDrive\temp)
			{
				try
				{
					New-Item -Path $env:SystemDrive -Name temp -ItemType Directory
				}
				catch
				{
					Write-Error $_
				}
			}
			Set-Location $env:SystemDrive\temp
			Invoke-WebRequest -Uri "https://www.screenconnect.com/$($updatesAvailable[0])" -OutFile "ScreenConnectStable_$updateVersionNumber.msi"
			Start-Process -FilePath .\ScreenConnectStable_$updateVersionNumber.msi -ArgumentList
		}
		else
		{
			$updateStaging = Invoke-WebRequest -Uri "https://www.screenconnect.com/Download"
			[String[]]$updatesAvailable = ($updateStaging.links | where {$_.innerHTML -like "*.msi"}).href
			$updateVersionNumber = [regex]::Match($updatesAvailable, '[0-9][0-9.]*[0-9]').Value
			Write-Verbose "Downloading version $updateVersionNumber."
			if(!Test-Path $env:SystemDrive\temp)
			{
				try
				{
					New-Item -Path $env:SystemDrive -Name temp -ItemType Directory
				}
				catch
				{
					Write-Error $_
				}
			}
			Set-Location $env:SystemDrive\temp
			Invoke-WebRequest -Uri "https://www.screenconnect.com/$($updatesAvailable[0])" -OutFile "ScreenConnectPreRelease_$updateVersionNumber.msi"
			Start-Process -FilePath .\ScreenConnectPreRelease_$updateVersionNumber.msi -ArgumentList
		}

		
    }
    End
    {
			
    }
}