# Enable detailed logging for troubleshooting
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"
$DebugPreference = "Continue"

# Function to execute a command and check its status
function Invoke-CMD {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Command,
        [Parameter(Mandatory=$true)]
        [string]$ErrorMessage
    )

    Write-Host "Executing command: $Command"
    & cmd /c $Command
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Setup | $ErrorMessage" -ForegroundColor Red
        exit 1
    }
}

# Base functionality
function Initialize-BaseFunctionality {
    Write-Host "`nScript is running..." -ForegroundColor White
    Write-Host "`nInitializing sub-modules..." -ForegroundColor White

    # Ensure the submodule path exists
    if (-Not (Test-Path .\extensions\continue-submodule)) {
        Write-Host "Submodule directory 'extensions/continue-submodule' does not exist. Cloning submodule..." -ForegroundColor Yellow
        # Forcefully clone the submodule if it doesn't exist
        Invoke-CMD -Command "git clone https://github.com/continuedev/continue.git ./extensions/continue-submodule" -ErrorMessage "Failed to clone the submodule repository"
    }

    # Initialize and update submodules
    Invoke-CMD -Command "git submodule update --init --recursive" -ErrorMessage "Failed to initialize git submodules"
    Invoke-CMD -Command "git submodule update --recursive --remote" -ErrorMessage "Failed to update to latest tip of submodule"

    # Create the symbolic link
    Create-SymLink

    # Set location to submodule directory
    Write-Host "`nNavigating to submodule directory..." -ForegroundColor White
    Set-Location .\extensions\continue-submodule

    # Checkout main branch
    Write-Host "`nSetting the submodule directory to match origin/main's latest changes..." -ForegroundColor White
    Invoke-CMD -Command "git reset origin/main" -ErrorMessage "Failed to git reset to origin/main"
    Invoke-CMD -Command "git reset --hard" -ErrorMessage "Failed to reset --hard"
    Write-Host "`nChecking out the 'main' branch in submodule..." -ForegroundColor White
    Invoke-CMD -Command "git checkout main" -ErrorMessage "Failed to checkout the 'main' branch in the submodule"
    Invoke-CMD -Command "git fetch origin" -ErrorMessage "Failed to fetch latest changes from origin"
    Invoke-CMD -Command "git pull origin main" -ErrorMessage "Failed to pull latest changes from origin/main"

    # Ensure the install script exists
    $script = Join-Path -Path $modulePath -ChildPath 'scripts\install-dependencies.ps1'
    if (-Not (Test-Path $script)) {
        Write-Host "The script '$script' does not exist." -ForegroundColor Red
        exit 1
    }

    # Run the install script
    Invoke-CMD -Command "powershell.exe -ExecutionPolicy Bypass -File $script" -ErrorMessage "Failed to install dependencies for the submodule"

    # Reset changes to package files
    Invoke-CMD -Command "git reset --hard" -ErrorMessage "Failed to reset --hard after submodule dependencies install"

    # Set location back to root directory
    Set-Location $currentDir

    # Install root application dependencies
    Write-Host "`nSetting up root application..." -ForegroundColor White
    Invoke-CMD -Command "npm install" -ErrorMessage "Failed to install dependencies with npm"
}

# Function to create symbolic link
function Create-SymLink {
    Write-Host "`nCreating symbolic link 'extensions/continue-ref' -> 'extensions/continue-submodule/extensions/vscode'" -ForegroundColor White
    Start-Process powershell.exe -Verb RunAs -ArgumentList ("-ExecutionPolicy Bypass", "-Command", "powershell.exe -ExecutionPolicy Bypass -File '$createLinkScript' '$targetPath' '$linkPath'")
    Start-Sleep 1
}

# Setup all necessary paths for this script
$currentDir = Get-Location
$modulePath = Join-Path -Path $currentDir -ChildPath 'extensions\continue-submodule'
$targetPath = Join-Path -Path $modulePath -ChildPath 'extensions\vscode'
$linkPath = Join-Path -Path $currentDir -ChildPath 'extensions\continue-ref'
$createLinkScript = Join-Path -Path (Get-Item $MyInvocation.MyCommand.Path).Directory -ChildPath 'create-symlink.ps1'

# Run the base functionality
Initialize-BaseFunctionality