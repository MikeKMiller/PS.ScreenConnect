function Update-ScreenConnectServer
{
<#
.Synopsis
   Used to update a ScreenConnect server.
.DESCRIPTION
   Used to update a ScreenConnect server to either the latest stable or pre-release.
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   None.
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   If the ScreenConnect downloads page changes in any major degree this script will cease to function safely.
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
    [CmdletBinding(SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  ConfirmImpact='High')]
    [Alias()]
    Param
    (
        # Pick release branch.
        [Parameter(Mandatory=$true, Position=0)]
		[ConfirmNotNullOrEmpty()]
        [Alias("Stable")] 
        [Boolean]$StableReleaseBranchOnly = $true,

        # Choose to update automtically.
        [Parameter(Mandatory=$true, Position=1)]
		[ConfirmNotNullOrEmpty()]
		[Alias("Update")]
        [Boolean]$AutomaticUpdate = $true
    )

    Begin
    {
		Write-Verbose "Acquiring latest ScreenConnect server version."
    }
    Process
    {
		if($StableReleaseBranchOnly)
		{
			try
			{
				$updateStaging = Invoke-WebRequest -Uri "https://www.screenconnect.com/Download"
			}
			catch
			{
				Write-Error $_
			}
			[String[]]$updatesAvailable = ($updateStaging.links | where {$_.innerHTML -like "*Release.msi"}).href
			$updateVersionNumber = [regex]::Match($updatesAvailable, '[0-9][0-9.]*[0-9]').Value
			Write-Verbose "Downloading version $updateVersionNumber."
			if($AutomaticUpdate)
			{
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
				try
				{
					Invoke-WebRequest -Uri "https://www.screenconnect.com/$($updatesAvailable[0])" -OutFile "ScreenConnectStable_$updateVersionNumber.msi"
				}
				catch
				{
					Write-Error $_
				}
				Start-LTProcess -FilePath "ScreenConnectStable_$updateVersionNumber.msi" -ArgumentList "/qn"
			}
			else
			{
				try
				{
					Invoke-WebRequest -Uri "https://www.screenconnect.com/$($updatesAvailable[0])" -OutFile "ScreenConnectStable_$updateVersionNumber.msi"
				}
				catch
				{
					Write-Error $_
				}
			}
		}
		else
		{
			try
			{
				$updateStaging = Invoke-WebRequest -Uri "https://www.screenconnect.com/Download"
			}
			catch
			{
				Write-Error $_
			}
			[String[]]$updatesAvailable = ($updateStaging.links | where {$_.innerHTML -like "*.msi"}).href
			$updateVersionNumber = [regex]::Match($updatesAvailable, '[0-9][0-9.]*[0-9]').Value
			Write-Verbose "Downloading version $updateVersionNumber."
			if($AutomaticUpdate)
			{
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
				try
				{
					Invoke-WebRequest -Uri "https://www.screenconnect.com/$($updatesAvailable[0])" -OutFile "ScreenConnectPreRelease_$updateVersionNumber.msi"
				}
				catch
				{
					Write-Error $_
				}
				Start-LTProcess -FilePath "ScreenConnectPreRelease_$updateVersionNumber.msi" -ArgumentList "/qn"
			}
			else
			{
				try
				{
					Invoke-WebRequest -Uri "https://www.screenconnect.com/$($updatesAvailable[0])" -OutFile "ScreenConnectPreRelease_$updateVersionNumber.msi"
				}
				catch
				{
					Write-Error $_
				}
			}
		}
    }
    End
    {
		Write-Verbose "Actions complete."
    }
}

function Start-LTProcess
{
<#
.Synopsis
   LT helper for starting slient installations.
.DESCRIPTION
   Used from starting silent installations with LabTech scripts.
   Designed to handle failures and timeout in the event of a hung installation.
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   None.
.OUTPUTS
   String.
.NOTES
   String output is due to LT being unable to handle the Write-Error cmdlet and will only handle stdout from Write-Output.
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   LabTech program install assisstence.
.FUNCTIONALITY
   Used to ease the work of installing a program via LabTech.
#>
    Param
    (
        # Path to the executable.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $FilePath,

        # Any parameters needed by the executable.
        [Parameter(Mandatory=$false,
                   Position=1)]
        [string[]]
        $ArgumentList = @(),

        # Time out for installation, default is ten minutes in milliseconds.
        [Parameter(Mandatory=$false,
                   Position=2)]
        [int32]
        $TimeOut = 600000,

		# Switch to silence output.
        [Parameter(Mandatory=$false,
                   Position=3)]
		[switch]
		$Silent
    )

    Begin
    {
        try
        {
            if(!$(Test-Path $FilePath))
            {
                throw [System.IO.FileNotFoundException]
            }
        }
        catch [System.IO.FileNotFoundException]
        {
            Write-Output "The $($FilePath.Substring($FilePath.LastIndexOf('\') + 1)) file could not be found, please verify the path exists."
        }
    }
    Process
    {
        try
        {
            $process = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -PassThru
            if((Get-ItemProperty -Path $FilePath).Extension -eq ".msi")
            {
                $process = Get-Process msiexec | Sort-Object StartTime | Select-Object -Last 1 #Finds the msi process id.
            }
            do {Start-Sleep -Seconds 1}
            until ($process.HasExited -or -not $process.WaitForExit($TimeOut))
            if($process.ExitCode -eq 0)
            {
				if($Silent)
				{
					Write-Output "The $($FilePath.Substring($FilePath.LastIndexOf('\') + 1)) file has installed successfully."
				}
            }
            else
            {
                $process.Kill()
				if($Silent)
				{
					Write-Output "The $($FilePath.Substring($FilePath.LastIndexOf('\') + 1)) file did not install, please install manually."
				}
            }
        }
        catch [System.Exception]
        {
            if($process.HasExited)
            {
				if($Silent)
				{
					Write-Output "The $($FilePath.Substring($FilePath.LastIndexOf('\') + 1)) file did not install, please install manually."
				}
            }
            else
            {
                $process.Kill()
				if($Silent)
				{
					Write-Output "The $($FilePath.Substring($FilePath.LastIndexOf('\') + 1)) file did not install, please install manually."
				}
            }
        }
    }
    End
    {
    }
}