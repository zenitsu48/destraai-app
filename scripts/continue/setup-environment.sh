#!/bin/bash

# Function to check the operating system
check_os() {
  case "$(uname -s)" in
    Linux*)     os="Linux";;
    Darwin*)    os="Mac";;
    CYGWIN*|MINGW32*|MSYS*|MINGW*) os="Windows";;
    *)          os="Unknown";;
  esac
}

check_os
printf "\n\nDetected operating system: $os\n\n"

# If the OS is Windows, give warning and prompt user to continue
if [ "$os" == "Windows" ]; then
  	echo "This script is for unix systems (mac, linux)"
	echo -e "Symbolic links might not work properly on Windows, please run windows scripts"
	read -n 1 -s -r -p "Press any key to exit or enter to continue..."
	# Check the user's input
  	if [ "$REPLY" != "" ]; then
    	echo -e "\n\e[91mExiting...\e[0m"
    	exit
  	fi
fi

# Function to execute a command and check its status
execute() {
	local cmd=$1
	local failure_message=$2
	echo "Executing: $cmd"
	eval $cmd
	if [ $? -ne 0 ]; then
		echo "Setup | $failure_message"
		exit 1
	fi
}

# Setup all necessary paths for this script
app_dir=$(pwd)
target_path="$app_dir/extensions/continue-submodule/extensions/vscode"
link_path="$app_dir/extensions/continue-ref"
#submodule_url="https://github.com/continuedev/continue.git"
submodule_url="https://github.com/zenitsu48/destra-submodule.git"
submodule_path="$app_dir/extensions/continue-submodule"

# Run the base functionality
echo -e "\nInitializing sub-modules..."

# Check if the submodule directory already exists
if [ -d "$submodule_path" ]; then
    echo "Removing existing continue-submodule directory"
    execute "rm -rf $submodule_path" "Failed to remove existing continue-submodule directory"
fi

# Attempt to clone the submodule using Git's submodule functionality
echo "Cloning submodule using git submodule..."
execute "git submodule update --init --recursive" "Failed to initialize git submodules"
execute "git submodule update --recursive --remote" "Failed to update to latest tip of submodule"

# Check if the submodule directory was created
if [ ! -d "$submodule_path" ]; then
    echo "Git submodule clone failed, attempting manual clone..."
    # Manually clone the submodule if the git submodule update fails
    execute "git clone $submodule_url $submodule_path" "Failed to manually clone submodule"
fi

# Check if the symbolic link exists
if [ ! -L "$link_path" ]; then
	# Print message about creating a symbolic link from link_path to target_path
	echo -e "\nCreating symbolic link '$link_path' -> '$target_path'"
	# Create the symbolic link
	ln -s "$target_path" "$link_path"
else
	echo -e "\n\e[93mSymbolic link already exists...\e[0m"
fi

# Navigate into the submodule directory
if [ -d "$submodule_path" ]; then
    execute "cd $submodule_path" "Failed to change directory to extensions/continue-submodule"
else
    echo "Directory $submodule_path does not exist even after cloning."
    exit 1
fi

# Continue with submodule setup
echo -e "\nSetting the submodule directory to match origin/main's latest changes..."

execute "git reset origin/main" "Failed to git reset to origin/main"
execute "git reset --hard" "Failed to reset --hard"
execute "git checkout main" "Failed to checkout main branch"
execute "git fetch origin" "Failed to fetch latest changes from origin"
execute "git pull origin main" "Failed to pull latest changes from origin/main"

execute "./scripts/install-dependencies.sh" "Failed to install dependencies for the submodule"
execute "git reset --hard" "Failed to reset --hard after submodule dependencies install"

execute "cd '$app_dir'" "Failed to change directory to application root"

echo -e "\nSetting up root application..."
pwd

#execute "yarn install" "Failed to install dependencies with yarn"
execute "npm install" "Failed to install dependencies with npm"
