param(
  [string]$CheckName,
  [switch]$ShowStatus = $false,
  [switch]$Reset = $false
)

$WUregPath = "hklm:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"

$WUregName = @(
  # Names we want to read
  "DeferUpgrade"
  "DeferUpdatePeriod"
  "DeferUpgradePeriod"
  "PauseDeferrals"
)

Function Test-RegistryValue {
  param(
    [Alias("PSPath")]
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [String]$Path
    ,
    [Parameter(Position = 1, Mandatory = $true)]
    [String]$Name
    ,
    [Switch]$PassThru
  )

  process {
    if (Test-Path $Path) {
      $Key = Get-Item -LiteralPath $Path
      if ($Key.GetValue($Name, $null) -ne $null) {
        if ($PassThru) {
          Get-ItemProperty $Path $Name
        } else {
          $true
        }
      } else {
        $false
      }
    } else {
      $false
    }
  }
}

Function Get-RegistryValue {
  param(
    [Alias("PSPath")]
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [String]$Path
    ,
    [Parameter(Position = 1, Mandatory = $true)]
    [String]$Name
    ,
    [Switch]$PassThru
  )

  process {

    #Test to see if each WUregPath/Name is valid
    $nameExists = Test-RegistryValue -Path $Path -Name $Name

    IF($nameExists) {
      # The path and name exists
      $regValue = (Get-ItemProperty -Path $Path -Name $Name).$Name

      # Write out the value of the regName.
      Write-Output ($Name + " is set to " + $regValue)
    }
    ELSE{
      # The name does not exist
      Write-Output ("The key " + $Name + " does not exist.")
    }
  }

}

if ($ShowStatus) {
  IF(!(Test-Path $WUregPath))

  {

    New-Item -Path $WUregPath -ErrorAction Stop

  }

  foreach ($WUregName in $WUregName) {

    Get-RegistryValue -Path $WUregPath -Name $WUregName

  }
}

if ($CheckName) {

  Get-RegistryValue -Path $WUregPath -Name $CheckName

}

if ($Reset) {

  foreach ($WUregName in $WUregName) {

    if (Test-RegistryValue -Path $WUregPath -Name $WUregName) {
      #$Key = Get-ItemProperty -Path $WUregPath -Name $WUregName
      Remove-ItemProperty -Path $WUregPath -Name $WUregName
      # Write-Output $Key.PSPath
    }
  }
}
