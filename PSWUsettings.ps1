<#
Written by Arunderwood - 7/13/16

.SYNOPSIS
        This script is designed as a utility to get and set Windows Update configuration on Windows 10 machines.
    .DESCRIPTION
        This script is designed to be utilized by a technician or an RMM tool to manage a Windows 10 machine between CB and CBB branches.
        It should prove useful in envronments where the administrator does not have access to Group Policy and must resort to manually
        managing setting through each machines registry.

        The following sites were used as reference:
          http://pureinfotech.com/defer-windows-10-upgrades-updates/
          https://technet.microsoft.com/en-us/itpro/windows/plan/windows-update-for-business
          https://technet.microsoft.com/en-us/itpro/windows/manage/introduction-to-windows-10-servicing

    .PARAMETER CheckStatus
      This parameter is used with the following keys:

        DeferUpgrade
        DeferUpdatePeriod
        DeferUpgradePeriod
        PauseDeferrals

      The script will then return the value of the specified key. Can be paired with -Plain.

    .PARAMETER ShowStatus
      Returns the current status of DeferUpgrade, DeferUpdatePeriod, DeferUpgradePeriod, PauseDeferrals.  Can be paired with -Plain.

    .PARAMETER SetDeferUpgrade
      Setting DeferUpgrade to 1 will delay the computer from upgrading to a new branch for the number of months set in DeferUpgradePeriod.

    .PARAMETER SetDeferUpdatePeriod
      Setting DeferUpdatePeriod to a value between 0 and 4 will delay the application of Updates by that many weeks.

        Microsoft defines an upgrade as:
          "Packages of security fixes, reliability fixes, and other bug fixes that are released periodically, typically once a month on Update Tuesday"

    .PARAMETER SetDeferUpgradePeriod
      Setting DeferUpgradePeriod to a value between 0 and 8 will delay the application of Upgrades by that many weeks.

        Microsoft defines an upgrade as:
          "A new Windows 10 release that contains additional features and capabilities, released two to three times per year.

    .PARAMETER SetPauseDeferrals
      Setting PauseDeferrals to 1 will put a temporary hold on all upgrades and updates.

      The hold lasts until the next monthly update shows up, or until the next upgrade makes an appearance.
        "Once a new update or upgrade is available, the value will go back to the previously selected option, re-enabling your validation groups,"

    .PARAMETER Reset
      Invoking this parameter will delete all the managed settings, reseting the computer back to factory updating condition.

    .PARAMETER Plain
      This parameter is typically invoked with the -CheckStatus or -ShowStatus arguments.  It suppresses all extra texts and instructs the script to only return the values themselves.

    .EXAMPLE
      Returns the current values of all managed settings
        .\PSWUsettings.ps1 -ShowStatus

    .EXAMPLE
      Returns just the value of just the DeferUpgradePeriod setting
        .\PSWUsettings.ps1 -CheckStatus DeferUpgradePeriod -Plain

    .EXAMPLE
      Sets DeferUpgrade to 1, DeferUpgradePeriod to 8, and DeferUpdatePeriod to 4
        .\PSWUsettings.ps1 -SetDeferUpgrade 1 -SetDeferUpgradePeriod 8 -SetDeferUpdatePeriod 4


#>
param(
  [ValidateSet("DeferUpgrade","DeferUpdatePeriod","DeferUpgradePeriod","PauseDeferrals")]
  [string]
  $CheckStatus
  ,
  [switch]$ShowStatus = $false
  ,
  [ValidateRange(0,1)]
  [Int]
  $SetDeferUpgrade = -1
  ,
  [ValidateRange(0,4)]
  [Int]
  $SetDeferUpdatePeriod = -1
  ,
  [ValidateRange(0,8)]
  [Int]
  $SetDeferUpgradePeriod = -1
  ,
  [ValidateRange(0,1)]
  [Int]
  $SetPauseDeferrals = -1
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

if ($SetDeferUpgrade -ne -1) {

Set-RegistryValue -Path $WUregPath -Name DeferUpgrade -Value $SetDeferUpgrade

}

if ($SetDeferUpdatePeriod -ne -1) {

Set-RegistryValue -Path $WUregPath -Name DeferUpdatePeriod -Value $SetDeferUpdatePeriod

}

if ($SetDeferUpgradePeriod -ne -1) {

Set-RegistryValue -Path $WUregPath -Name DeferUpgradePeriod -Value $SetDeferUpgradePeriod

}

if ($SetPauseDeferrals -ne -1) {

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

if ($CheckStatus) {

  Get-RegistryValue -Path $WUregPath -Name $CheckStatus

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
