#!/bin/bash

# Display ASCII art for KONTANGO
echo "
██╗  ██╗ ██████╗ ███╗   ██╗████████╗ █████╗ ███╗   ██╗ ██████╗  ██████╗ 
██║ ██╔╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗████╗  ██║██╔════╝ ██╔═══██╗
█████╔╝ ██║   ██║██╔██╗ ██║   ██║   ███████║██╔██╗ ██║██║  ███╗██║   ██║
██╔═██╗ ██║   ██║██║╚██╗██║   ██║   ██╔══██║██║╚██╗██║██║   ██║██║   ██║
██║  ██╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║██║ ╚████║╚██████╔╝╚██████╔╝
╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝  ╚═════╝ 
"

echo "Welcome to the KONTANGO setup script!"
echo

# Ask if user wants to start the install script
read -p "Do you want to start the install script? (y/n): " choice

case $choice in
    [Yy]* )
        echo "Starting installation process..."
        echo
        
        # Detect and confirm operating system
        echo "Detecting operating system..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if [[ -f /etc/debian_version ]]; then
                detected_os="Debian/Ubuntu"
            else
                detected_os="Linux"
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            detected_os="macOS"
        else
            detected_os="Unknown"
        fi
        
        echo "Detected OS: $detected_os"
        echo
        echo "Please select your operating system:"
        echo "1) Ubuntu"
        echo "2) Debian" 
        echo "3) Mac"
        echo
        read -p "Enter your choice (1-3): " os_choice
        
        case $os_choice in
            1)
                selected_os="ubuntu"
                package_manager="apt"
                echo "Ubuntu selected"
                ;;
            2)
                selected_os="debian"
                package_manager="apt"
                echo "Debian selected"
                ;;
            3)
                selected_os="mac"
                package_manager="brew"
                echo "Mac selected"
                ;;
            *)
                echo "Invalid choice. Exiting."
                exit 1
                ;;
        esac
        
        echo
        
        # Handle package manager setup based on OS selection
        if [[ "$selected_os" == "ubuntu" || "$selected_os" == "debian" ]]; then
            # Check if snap is installed
            if command -v snap &> /dev/null; then
                echo "Snap is already installed."
            else
                echo "Installing snap..."
                sudo apt update
                sudo apt install -y snapd
                echo "Snap installed successfully."
            fi
            
            # Update and upgrade system packages
            echo "Updating system packages..."
            sudo apt update && sudo apt upgrade -y
            echo "System packages updated and upgraded successfully."
            
        elif [[ "$selected_os" == "mac" ]]; then
            # Check if brew is installed
            if command -v brew &> /dev/null; then
                echo "Homebrew is already installed."
            else
                echo "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                
                # Add brew to PATH for the current session
                if [[ -f /opt/homebrew/bin/brew ]]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                elif [[ -f /usr/local/bin/brew ]]; then
                    eval "$(/usr/local/bin/brew shellenv)"
                fi
                
                echo "Homebrew installed successfully."
            fi
            
            # Update brew
            echo "Updating Homebrew..."
            brew update && brew upgrade
            echo "Homebrew updated successfully."
        fi
        
        echo
        
        # Check if git is installed
        if ! command -v git &> /dev/null; then
            echo "Git is not installed. Installing git..."
            
            # Install git using the selected package manager
            if [[ "$selected_os" == "ubuntu" || "$selected_os" == "debian" ]]; then
                # Try snap first, fallback to apt if needed
                if command -v snap &> /dev/null; then
                    sudo snap install git --classic
                else
                    sudo apt install -y git
                fi
            elif [[ "$selected_os" == "mac" ]]; then
                brew install git
            fi
            
            echo "Git installed successfully."
        else
            echo "Git is already installed."
        fi
        
        # Check if git is already configured
        git_user=$(git config --global user.name 2>/dev/null)
        git_email=$(git config --global user.email 2>/dev/null)
        
        if [[ -n "$git_user" && -n "$git_email" ]]; then
            echo "Git is already configured:"
            echo "Username: $git_user"
            echo "Email: $git_email"
            echo "Skipping git configuration..."
        else
            echo "Configuring global git workflow..."
            echo
            
            # Get user's git configuration
            read -p "Enter your Git username: " git_username
            read -p "Enter your Git email: " git_email
            
            # Configure git globally
            git config --global user.name "$git_username"
            git config --global user.email "$git_email"
            
            # Ask for additional git configurations
            echo
            echo "Additional Git Configuration Options:"
            echo
            
            read -p "Set default branch name to 'main'? (y/n): " main_branch
            if [[ $main_branch =~ ^[Yy]$ ]]; then
                git config --global init.defaultBranch main
                echo "Default branch set to 'main'"
            fi
            
            read -p "Enable colored output? (y/n): " colored_output
            if [[ $colored_output =~ ^[Yy]$ ]]; then
                git config --global color.ui auto
                echo "Colored output enabled"
            fi
            
            read -p "Set default editor (vim/nano/code): " editor_choice
            case $editor_choice in
                vim)
                    git config --global core.editor vim
                    echo "Default editor set to vim"
                    ;;
                nano)
                    git config --global core.editor nano
                    echo "Default editor set to nano"
                    ;;
                code)
                    git config --global core.editor "code --wait"
                    echo "Default editor set to VS Code"
                    ;;
                *)
                    echo "Skipping editor configuration"
                    ;;
            esac
            
            read -p "Configure pull strategy to rebase? (y/n): " pull_rebase
            if [[ $pull_rebase =~ ^[Yy]$ ]]; then
                git config --global pull.rebase true
                echo "Pull strategy set to rebase"
            fi
            
            echo
            echo "Git configuration completed!"
        fi
        
        echo "Current git configuration:"
        echo "------------------------"
        git config --global --list | grep -E "(user\.|init\.|color\.|core\.editor|pull\.)" 2>/dev/null || echo "No git configuration found"
        
        echo
        echo "Installing GitHub CLI (gh)..."
        echo
        
        # Check if gh is installed
        if ! command -v gh &> /dev/null; then
            echo "GitHub CLI is not installed. Installing gh..."
            
            # Install GitHub CLI using the selected package manager
            if [[ "$selected_os" == "ubuntu" || "$selected_os" == "debian" ]]; then
                # Try snap first, fallback to apt if needed
                if command -v snap &> /dev/null; then
                    sudo snap install gh
                else
                    # Fallback to apt installation
                    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
                    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                    sudo apt update && sudo apt install -y gh
                fi
            elif [[ "$selected_os" == "mac" ]]; then
                brew install gh
            fi
            
            echo "GitHub CLI installed successfully."
        else
            echo "GitHub CLI is already installed."
        fi
        
        echo
        echo "Authenticating with GitHub..."
        echo "Please follow the prompts to authenticate with your GitHub account."
        echo
        
        # Authenticate with GitHub
        gh auth login
        
        # Check if authentication was successful
        if gh auth status &> /dev/null; then
            echo
            echo "GitHub authentication successful!"
            echo
            
            # Navigate to root directory and create folder structure
            echo "Setting up directory structure..."
            
            # Go to root directory (user's home directory)
            cd ~
            
            # Create git folder if it doesn't exist
            if [ ! -d "git" ]; then
                mkdir git
                echo "Created 'git' folder in home directory"
            else
                echo "'git' folder already exists"
            fi
            
            # Navigate to git folder and create github folder
            cd git
            if [ ! -d "github" ]; then
                mkdir github
                echo "Created 'github' folder"
            else
                echo "'github' folder already exists"
            fi
            
            # Navigate to github folder
            cd github
            
            echo "Current directory: $(pwd)"
            echo
            
            # Check if GroundFloor repository already exists
            if [ -d "GroundFloor" ]; then
                echo "GroundFloor repository already exists at: $(pwd)/GroundFloor"
                echo "Skipping repository cloning..."
                
                # Show contents of the existing repository
                echo
                echo "Existing repository contents:"
                ls -la GroundFloor/
                
                repository_exists=true
            else
                echo "Cloning GroundFloor repository..."
                
                # Clone the repository
                if git clone https://github.com/dkontango/GroundFloor.git; then
                    echo
                    echo "Repository cloned successfully!"
                    echo "GroundFloor repository is now available at: $(pwd)/GroundFloor"
                    
                    # Show contents of the cloned repository
                    echo
                    echo "Repository contents:"
                    ls -la GroundFloor/
                    
                    repository_exists=false
                else
                    echo "Failed to clone repository. Please check your internet connection and repository access."
                    exit 1
                fi
            fi
            
        else
            echo "GitHub authentication failed. Please try running 'gh auth login' manually."
            exit 1
        fi
        
        echo
        echo "=================================="
        
        # Check if startup flow already ran by checking both git config and repository
        if [[ -n "$git_user" && -n "$git_email" ]] && [[ "$repository_exists" == true ]]; then
            echo "STARTUP FLOW ALREADY RAN!"
            echo "=================================="
            echo "Previous setup detected:"
            echo "- Git is already configured"
            echo "- GroundFloor repository already exists"
            echo "- All components are in place"
        else
            echo "KONTANGO setup completed successfully!"
            echo "=================================="
            echo "Summary of what was configured:"
            if [[ -z "$git_user" || -z "$git_email" ]]; then
                echo "- Git installed and configured"
            echo "- Snap package manager verified (Ubuntu/Debian)"
            else
                echo "- Git was already configured (skipped)"
            fi
            if [[ "$selected_os" == "ubuntu" || "$selected_os" == "debian" ]]; then
                echo "- Snap package manager verified"
            else
                echo "- Homebrew package manager verified"
            fi
            echo "- GitHub CLI installed and authenticated"
            echo "- Directory structure created: ~/git/github/"
            if [[ "$repository_exists" == false ]]; then
                echo "- GroundFloor repository cloned to: ~/git/github/GroundFloor/"
            else
                echo "- GroundFloor repository was already present (skipped)"
            fi
        fi
        echo
        ;;
    [Nn]* )
        echo "Installation cancelled. Goodbye!"
        exit 0
        ;;
    * )
        echo "Invalid choice. Please run the script again and enter 'y' or 'n'."
        exit 1
        ;;
esac