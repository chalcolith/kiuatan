Param(
  [Parameter(Position=0, Mandatory=$true, HelpMessage="The action to take (build, test, install, package, clean).")]
  [string]
  $Command,

  [Parameter(HelpMessage="The build configuration (Release, Debug).")]
  [string]
  $Config = "Release",

  [Parameter(HelpMessage="The version number to set.")]
  [string]
  $Version = "",

  [Parameter(HelpMessage="Architecture (native, x64).")]
  [string]
  $Arch = "x86-64",

  [Parameter(HelpMessage="Directory to install to.")]
  [string]
  $Destdir = "build/install"
)

$ErrorActionPreference = "Stop"

$target = "kiuatan"
$isLibrary = $true

$rootDir = Split-Path $script:MyInvocation.MyCommand.Path
$srcDir = Join-Path -Path $rootDir -ChildPath $target

if ($Config -ieq "Release")
{
  $configFlag = ""
  $buildDir = Join-Path -Path $rootDir -ChildPath "build/release"
}
elseif ($Config -ieq "Debug")
{
  $configFlag = "--debug"
  $buildDir = Join-Path -Path $rootDir -ChildPath "build/debug"
}
else
{
  throw "Invalid -Config path '$Config'; must be one of (Debug, Release)."
}

if ($Version -eq "")
{
  $Version = (Get-Content "$rootDir\VERSION") + "-" + (& git rev-parse --short --verify HEAD)
}

Write-Output "Configuration:    $Config"
Write-Output "Version:          $Version"
Write-Output "Root directory:   $rootDir"
Write-Output "Source directory: $srcDir"
Write-Output "Build directory:  $buildDir"

# generate pony templated files if necessary
if ($Command -ne "clean")
{
  $versionTimestamp = (Get-ChildItem -Path "$rootDir\VERSION").LastWriteTimeUtc
  Get-ChildItem -Path $srcDir -Include "*.pony.in" -Recurse | ForEach-Object {
    $templateFile = $_.FullName
    $ponyFile = $templateFile.Substring(0, $templateFile.Length - 3)
    $ponyFileTimestamp = [DateTime]::MinValue
    if (Test-Path $ponyFile)
    {
      $ponyFileTimestamp = (Get-ChildItem -Path $ponyFile).LastWriteTimeUtc
    }
    if (($ponyFileTimestamp -lt $versionTimestamp) -or ($ponyFileTimestamp -lt $_.LastWriteTimeUtc))
    {
      Write-Output "$templateFile -> $ponyFile"
      ((Get-Content -Path $templateFile) -replace '%%VERSION%%', $Version) | Set-Content -Path $ponyFile
    }
  }
}

function BuildTarget
{
  $binaryFile = Join-Path -Path $buildDir -ChildPath "$target.exe"
  $binaryTimestamp = [DateTime]::MinValue
  if (Test-Path $binaryFile)
  {
    $binaryTimestamp = (Get-ChildItem -Path $binaryFile).LastWriteTimeUtc
  }

  :buildFiles foreach ($file in (Get-ChildItem -Path $srcDir -Include "*.pony" -Recurse))
  {
    if ($binaryTimestamp -lt $file.LastWriteTimeUtc)
    {
      ponyc.exe "$configFlag" --cpu "$Arch" --output "$buildDir" "$srcDir"
      break buildFiles
    }
  }
}

function BuildTest
{
  $testFile = Join-Path -Path $buildDir -ChildPath "test.exe"
  $testTimestamp = [DateTime]::MinValue
  if (Test-Path $testFile)
  {
    $testTimestamp = (Get-ChildItem -Path $testFile).LastWriteTimeUtc
  }

  :testFiles foreach ($file in (Get-ChildItem -Path $srcDir -Include "*.pony" -Recurse))
  {
    if ($testTimestamp -lt $file.LastWriteTimeUtc)
    {
      $testDir = Join-Path -Path $srcDir -ChildPath "test"
      Write-Output "ponyc `"$configFlag`" --cpu `"$Arch`" --output `"$buildDir`" `"$testDir`""
      ponyc "$configFlag" --cpu "$Arch" --output "$buildDir" "$testDir"
      break testFiles
    }
  }

  Write-Output "test.exe is built"
  return $testFile
}

switch ($Command.ToLower())
{
  "build"
  {
    if (-not $isLibrary)
    {
      BuildTarget
    }
    else
    {
      Write-Output "$target is a library; nothing to build."
    }
    break
  }

  "test"
  {
    if (-not $isLibrary)
    {
      BuildTarget
    }

    $testFile = (BuildTest)[-1]
    & "$testFile"
    break
  }

  "clean"
  {
    if (Test-Path "$buildDir")
    {
      Remove-Item -Path "$buildDir" -Recurse -Force
    }
    break
  }

  "install"
  {
    if (-not $isLibrary)
    {
      $binDir = Join-Path -Path $Destdir -ChildPath "bin"

      if (-not (Test-Path $binDir))
      {
        mkdir "$binDir"
      }

      $binFile = Join-Path -Path $buildDir -ChildPath "$target.exe"
      Copy-Item -Path $binFile -Destination $binDir -Force
    }
    else
    {
      Write-Output "$target is a library; nothing to install."
    }
    break
  }

  "package"
  {
    if (-not $isLibrary)
    {
      $binDir = Join-Path -Path $Destdir -ChildPath "bin"
      $package = "$target-x86-64-pc-windows-msvc.zip"
      Write-Output "Creating $package..."

      Compress-Archive -Path $binDir -DestinationPath "$buildDir\..\$package" -Force
    }
    else
    {
      Write-Output "$target is a library; nothing to package."
    }
    break
  }

  default
  {
    throw "Unknown command '$Command'; must be one of (build, test, install, package, clean)."
  }
}
