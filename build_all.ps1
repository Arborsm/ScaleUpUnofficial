# Build all projects and output to the same folder
param(
    [string]$Configuration = "Release",
    [string]$OutputPath = ""
)

# Read version number
$manifestPath = "ScaleUpUnofficial\manifest.json"
if (Test-Path $manifestPath) {
    $manifest = Get-Content $manifestPath | ConvertFrom-Json
    $version = $manifest.Version
    Write-Host "Version: $version" -ForegroundColor Cyan
} else {
    Write-Host "Warning: Cannot find manifest.json, using default version" -ForegroundColor Yellow
    $version = "unknown"
}

# Set output path if not specified
if ([string]::IsNullOrEmpty($OutputPath)) {
    if ($Configuration -eq "Release") {
        $OutputPath = ".\Release\Scale Up Unofficial"
    } else {
        $OutputPath = ".\bin\$Configuration"
    }
}

Write-Host "Starting build..." -ForegroundColor Green
Write-Host "Configuration: $Configuration" -ForegroundColor Yellow
Write-Host "Version: $version" -ForegroundColor Yellow
Write-Host "Output path: $OutputPath" -ForegroundColor Yellow

# Clear Release folder if Release configuration
if ($Configuration -eq "Release") {
    $releaseDir = ".\Release"
    if (Test-Path $releaseDir) {
        Write-Host ""
        Write-Host "Clearing Release folder..." -ForegroundColor Cyan
        Get-ChildItem -Path $releaseDir -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Ensure output directory exists
New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null

# Build projects
$projects = @(
    @{Path="ScaleUpUnofficial\ScaleUpUnofficial.csproj"; Name="ScaleUpUnofficial"},
    @{Path="PlatonymousScaleUpCompatibilityLayer\PlatonymousScaleUpCompatibilityLayer.csproj"; Name="PlatonymousScaleUpCompatibilityLayer"},
    @{Path="SpritesInDetailCompatibilityLayer\SpritesInDetailCompatibilityLayer.csproj"; Name="SpritesInDetailCompatibilityLayer"}
)

# Build each project directly to its module directory
foreach ($project in $projects) {
    $moduleDir = Join-Path $OutputPath $project.Name
    New-Item -ItemType Directory -Force -Path $moduleDir | Out-Null
    
    Write-Host ""
    Write-Host "Building: $($project.Path)" -ForegroundColor Cyan
    dotnet build $project.Path -c $Configuration -o $moduleDir
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "Build failed: $($project.Path)" -ForegroundColor Red
        Write-Host "Error code: $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
    
    # Copy manifest.json
    $manifestSource = Join-Path (Split-Path $project.Path -Parent) "manifest.json"
    if (Test-Path $manifestSource) {
        Copy-Item $manifestSource -Destination $moduleDir -Force
        Write-Host "Copied: manifest.json" -ForegroundColor Gray
    } else {
        Write-Host "Warning: manifest.json not found: $manifestSource" -ForegroundColor Yellow
    }
    
    # Remove deps.json files
    $depsFile = Join-Path $moduleDir "$($project.Name).deps.json"
    if (Test-Path $depsFile) {
        Remove-Item $depsFile -Force
    }
    
    # Remove dependency DLLs and deps.json from compatibility layers
    # These projects reference ScaleUpUnofficial but shouldn't include its DLL
    if ($project.Name -ne "ScaleUpUnofficial") {
        $dependencyDll = Join-Path $moduleDir "ScaleUpUnofficial.dll"
        $dependencyDeps = Join-Path $moduleDir "ScaleUpUnofficial.deps.json"
        if (Test-Path $dependencyDll) {
            Remove-Item $dependencyDll -Force
            Write-Host "Removed dependency: ScaleUpUnofficial.dll" -ForegroundColor Gray
        }
        if (Test-Path $dependencyDeps) {
            Remove-Item $dependencyDeps -Force
            Write-Host "Removed dependency: ScaleUpUnofficial.deps.json" -ForegroundColor Gray
        }
    }
}

Write-Host ""
Write-Host "All projects built successfully!" -ForegroundColor Green
Write-Host "Output location: $OutputPath" -ForegroundColor Green

# Create zip archive (Release configuration only)
if ($Configuration -eq "Release") {
    $zipFileName = "ScaleUpUnofficial $version.zip"
    $zipPath = Join-Path ".\Release" $zipFileName
    
    Write-Host ""
    Write-Host "Creating zip archive: $zipFileName" -ForegroundColor Cyan
    
    # Delete existing zip file
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    
    # Create zip archive directly from output directory
    # Compress "Scale Up Unofficial" directory so zip contains it
    $parentDir = (Resolve-Path (Split-Path $OutputPath -Parent)).Path
    $dirName = Split-Path $OutputPath -Leaf
    $absoluteZipPath = (Resolve-Path (Split-Path $zipPath -Parent)).Path | Join-Path -ChildPath (Split-Path $zipPath -Leaf)
    Push-Location $parentDir
    Compress-Archive -Path $dirName -DestinationPath $absoluteZipPath -Force
    Pop-Location
    
    Write-Host "Zip archive created: $zipPath" -ForegroundColor Green
}
