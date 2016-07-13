param(
  [string]$CheckName
  ,
  [ValidateRange(0,1)]
  [Int]
  $SetDeferUpgrade
  ,
  [ValidateRange(0,4)]
  [Int]
  $SetDeferUpdatePeriod
  ,
  [ValidateRange(0,8)]
  [Int]
  $SetDeferUpgradePeriod
  ,
  [ValidateRange(0,1)]
  [Int]
  $PauseDeferrals
  ,
  [switch]$ShowStatus = $false
  ,
  [switch]$Reset = $false
  ,
  [switch]$Plain = $false
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
      if(-Not $Plain) {
        Write-Output ($Name + " is set to " + $regValue)
      }
      Else{
        Write-Output $regValue
      }
    }
    ELSE{
      # The name does not exist
      if(-Not $Plain) {
        Write-Output ("The key " + $Name + " does not exist.")
      }
      Else {
        Write-Output "Null"
      }
    }
  }

}

Function Set-RegistryValue {
  param(
    [Alias("PSPath")]
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [String]$Path
    ,
    [Parameter(Position = 1, Mandatory = $true)]
    [String]$Name
    ,
    [Parameter(Position = 3, Mandatory = $true)]
    [String]$Value
    ,
    [Switch]$PassThru
  )

  process {

    #Test to see if each regPath/Name is valid
    $nameExists = Test-RegistryValue -Path $Path -Name $Name

    IF($nameExists) {
      Set-ItemProperty -Path $Path -Name $Name -Value $Value
    }
    Else{
      New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWORD
    }
  }

}

if ($SetDeferUpgrade) {

Set-RegistryValue -Path $WUregPath -Name DeferUpgrade -Value $SetDeferUpgrade

}

if ($SetDeferUpdatePeriod) {

Set-RegistryValue -Path $WUregPath -Name DeferUpdatePeriod -Value $SetDeferUpdatePeriod

}

if ($SetDeferUpgradePeriod) {

Set-RegistryValue -Path $WUregPath -Name DeferUpgradePeriod -Value $SetDeferUpgradePeriod

}

if ($SetPauseDeferrals) {

Set-RegistryValue -Path $WUregPath -Name PauseDeferrals -Value $SetPauseDeferrals

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
