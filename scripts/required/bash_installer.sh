#!/bin/bash

# Universal Package Installer Script
# Installs packages listed in packages.txt using apt (with snap fallback)

# Configuration
INSTALLER_NAME="Package Installer"
INSTALLER_VERSION="1.0.0"
LOG_FILE=""
PACKAGES_FILE="$(dirname "$0")/packages.txt"
PACKAGES=()
DRY_RUN=false
START_TIME=""
SUCCESSFULLY_INSTALLED=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging function
log() {
    local message="$(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo "$message"
    if [[ "$LOG_FILE" != "/dev/null" && -w "$LOG_FILE" ]] 2>/dev/null; then
        echo "$message" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

# Print colored output
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Initialize logging
init_logging() {
    local possible_log_dirs=(
        "/tmp"
        "$HOME/.local/log"
        "$HOME/log"
        "$(dirname "$0")/log"
        "$(dirname "$0")"
    )
    
    LOG_FILE=""
    
    for log_dir in "${possible_log_dirs[@]}"; do
        if [[ ! -d "$log_dir" ]]; then
            if mkdir -p "$log_dir" 2>/dev/null; then
                print_color "$BLUE" "📁 Created log directory: $log_dir"
            else
                continue
            fi
        fi
        
        local test_file="$log_dir/test_write_$$"
        if touch "$test_file" 2>/dev/null; then
            rm -f "$test_file" 2>/dev/null
            LOG_FILE="$log_dir/package_installer.log"
            print_color "$GREEN" "📝 Using log file: $LOG_FILE"
            break
        fi
    done
    
    if [[ -z "$LOG_FILE" ]]; then
        print_color "$YELLOW" "⚠️  Warning: No writable directory found for logging. Logging disabled."
        LOG_FILE="/dev/null"
    fi
    
    if [[ "$LOG_FILE" != "/dev/null" ]]; then
        if ! touch "$LOG_FILE" 2>/dev/null; then
            print_color "$YELLOW" "⚠️  Warning: Cannot create log file $LOG_FILE. Logging disabled."
            LOG_FILE="/dev/null"
        fi
    fi
    echo
}

# Load configuration from packages.txt
load_config() {
    if [[ ! -f "$PACKAGES_FILE" ]]; then
        echo "❌ Error: packages.txt file not found in script directory"
        echo
        print_color "$YELLOW" "📝 Please create a packages.txt file with packages listed one per line:"
        echo "   # Comments start with #"
        echo "   package1"
        echo "   package2"
        echo "   package3"
        exit 1
    fi
    
    print_color "$BLUE" "📂 Loading package list from packages.txt..."
    
    PACKAGES=()
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        line=$(echo "$line" | xargs)
        if [[ -n "$line" ]]; then
            PACKAGES+=("$line")
        fi
    done < "$PACKAGES_FILE"
    
    if [[ ${#PACKAGES[@]} -eq 0 ]]; then
        print_color "$RED" "❌ No packages found in packages.txt"
        exit 1
    fi
    
    log "Packages to install: ${PACKAGES[*]}"
    print_color "$GREEN" "✅ Found ${#PACKAGES[@]} packages to install"
    echo
}

# Print banner
print_banner() {
    echo
    echo "=================================================="
    print_color "$BLUE" "    📦 $INSTALLER_NAME v$INSTALLER_VERSION"
    echo "    🚀 Smart Package Management Tool"
    echo "=================================================="
    echo
}

# Check sudo access
check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        print_color "$YELLOW" "⚠️  Warning: Running as root user."
        echo "   This is not recommended for security reasons."
        read -p "   Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_color "$BLUE" "👋 Goodbye! Run this script as a regular user for better security."
            exit 1
        fi
        echo
    else
        print_color "$BLUE" "🔐 Checking sudo access..."
        if ! sudo -n true 2>/dev/null; then
            print_color "$YELLOW" "🔑 This script requires sudo access for package installation."
            print_color "$BLUE" "   Please enter your password when prompted."
            echo
            if ! sudo true; then
                print_color "$RED" "❌ Failed to obtain sudo access. Exiting."
                exit 1
            fi
        fi
        print_color "$GREEN" "✅ Sudo access confirmed"
        echo
    fi
}

# Detect operating system
detect_os() {
    print_color "$BLUE" "🔍 Detecting operating system..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/debian_version ]]; then
            OS="debian"
            PKG_MANAGER="apt"
            print_color "$GREEN" "🐧 Detected: Debian/Ubuntu-based Linux (using apt → snap)"
        elif [[ -f /etc/redhat-release ]]; then
            OS="redhat"
            PKG_MANAGER="yum"
            print_color "$GREEN" "🐧 Detected: RedHat/CentOS/Fedora Linux (using yum/dnf)"
        elif [[ -f /etc/arch-release ]]; then
            OS="arch"
            PKG_MANAGER="pacman"
            print_color "$GREEN" "🐧 Detected: Arch-based Linux (using pacman)"
        else
            OS="linux"
            PKG_MANAGER="apt"
            print_color "$GREEN" "🐧 Detected: Generic Linux (defaulting to apt → snap)"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PKG_MANAGER="brew"
        print_color "$GREEN" "🍎 Detected: macOS (using brew)"
    else
        print_color "$RED" "❌ Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    log "Detected OS: $OS with package manager: $PKG_MANAGER"
    echo
}

# Install snapd if not present
install_snapd() {
    print_color "$BLUE" "📦 Installing snapd..."
    
    if [[ -f /etc/debian_version ]]; then
        sudo apt update && sudo apt install -y snapd
        sudo systemctl enable --now snapd
        sudo systemctl enable --now snapd.apparmor
    elif [[ -f /etc/redhat-release ]]; then
        if command -v dnf &> /dev/null; then
            sudo dnf install -y snapd
        else
            sudo yum install -y snapd
        fi
        sudo systemctl enable --now snapd
        sudo ln -sf /var/lib/snapd/snap /snap
    elif [[ -f /etc/arch-release ]]; then
        if command -v yay &> /dev/null; then
            yay -S --noconfirm snapd
        elif command -v paru &> /dev/null; then
            paru -S --noconfirm snapd
        else
            print_color "$YELLOW" "⚠️  Please install snapd manually using your AUR helper"
            exit 1
        fi
        sudo systemctl enable --now snapd
        sudo ln -sf /var/lib/snapd/snap /snap
    else
        print_color "$RED" "❌ Unable to install snapd on this system. Please install it manually."
        exit 1
    fi
    
    sleep 5
    print_color "$GREEN" "✅ snapd installed successfully"
}

# Install system package (no loading here - called from main function)
install_system_package() {
    local package="$1"
    
    if [[ -f /etc/debian_version ]]; then
        if sudo apt update >/dev/null 2>&1 && sudo apt install -y "$package" >/dev/null 2>&1; then
            SUCCESSFULLY_INSTALLED+=("$package (apt)")
            return 0
        fi
    elif [[ -f /etc/redhat-release ]]; then
        if command -v dnf &> /dev/null; then
            if sudo dnf install -y "$package" >/dev/null 2>&1; then
                SUCCESSFULLY_INSTALLED+=("$package (dnf)")
                return 0
            fi
        else
            if sudo yum install -y "$package" >/dev/null 2>&1; then
                SUCCESSFULLY_INSTALLED+=("$package (yum)")
                return 0
            fi
        fi
    elif [[ -f /etc/arch-release ]]; then
        if sudo pacman -S --noconfirm "$package" >/dev/null 2>&1; then
            SUCCESSFULLY_INSTALLED+=("$package (pacman)")
            return 0
        fi
    else
        print_color "$RED" "Unable to install $package. Please install it manually."
        return 1
    fi
    
    return 1
}

# Install dependencies
install_dependencies() {
    local deps=("$@")
    print_color "$BLUE" "🔧 Installing dependencies: ${deps[*]}"
    
    case "$PKG_MANAGER" in
        "apt")
            for dep in "${deps[@]}"; do
                if ! install_with_apt "$dep"; then
                    print_color "$YELLOW" "⚠️  Failed to install $dep via apt"
                fi
            done
            ;;
        "yum")
            for dep in "${deps[@]}"; do
                print_color "$BLUE" "   📦 Installing $dep..."
                if command -v dnf &> /dev/null; then
                    sudo dnf install -y "$dep" >/dev/null 2>&1
                else
                    sudo yum install -y "$dep" >/dev/null 2>&1
                fi
            done
            ;;
        "pacman")
            print_color "$BLUE" "   📦 Installing packages..."
            sudo pacman -S --noconfirm "${deps[@]}" >/dev/null 2>&1
            ;;
        "brew")
            print_color "$BLUE" "   🍺 Installing via brew..."
            brew install "${deps[@]}" >/dev/null 2>&1
            ;;
        *)
            print_color "$RED" "❌ Please install the following packages manually: ${deps[*]}"
            exit 1
            ;;
    esac
    
    print_color "$GREEN" "✅ Dependencies installed"
    echo
}

# Check system requirements
check_requirements() {
    print_color "$BLUE" "⚙️  Checking system requirements..."
    
    if [[ "$PKG_MANAGER" == "apt" ]] && ! command -v snap &> /dev/null; then
        print_color "$YELLOW" "📦 Snap is not installed. Installing snapd for fallback support..."
        install_snapd
    fi
    
    local basic_commands=("curl" "wget" "tar" "unzip")
    local missing_basic=()
    
    for cmd in "${basic_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_basic+=("$cmd")
        fi
    done
    
    if [[ ${#missing_basic[@]} -ne 0 ]]; then
        print_color "$YELLOW" "🔧 Installing missing basic commands: ${missing_basic[*]}"
        install_dependencies "${missing_basic[@]}"
    fi
    
    local available_space
    available_space=$(df /tmp | tail -1 | awk '{print $4}')
    local required_space=102400
    
    if [[ "$available_space" -lt "$required_space" ]]; then
        print_color "$RED" "💾 Insufficient disk space. Required: 100MB, Available: $((available_space/1024))MB"
        exit 1
    fi
    
    print_color "$GREEN" "✅ System requirements check passed"
    echo
}

# Check if package is installed
is_package_installed() {
    local package="$1"
    
    if command -v snap &> /dev/null; then
        if snap list "$package" &> /dev/null; then
            return 0
        fi
    fi
    
    if command -v dpkg &> /dev/null; then
        if dpkg -l 2>/dev/null | grep -q "^ii.*$package "; then
            return 0
        fi
    fi
    
    if command -v apt &> /dev/null; then
        if apt list --installed 2>/dev/null | grep -q "^$package/"; then
            return 0
        fi
    fi
    
    if command -v "$package" &> /dev/null; then
        return 0
    fi
    
    return 1
}

# Simple loading animation that just shows spinner
install_with_loading() {
    local package="$1"
    local method="$2"
    local spin_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local i=0
    
    while true; do
        local char="${spin_chars:$((i % ${#spin_chars})):1}"
        printf "\r   %s Installing %s via %s..." "$char" "$package" "$method"
        sleep 0.2
        ((i++))
    done
}
install_with_apt() {
    local package="$1"
    
    if [[ ! -f /var/cache/apt/pkgcache.bin ]] || [[ $(find /var/cache/apt/pkgcache.bin -mmin +60 2>/dev/null) ]]; then
        print_color "$BLUE" "🔄 Updating apt package cache..."
        sudo apt update >/dev/null 2>&1
    fi
    
    if sudo apt install -y "$package" >/dev/null 2>&1; then
        SUCCESSFULLY_INSTALLED+=("$package (apt)")
        return 0
    else
        return 1
    fi
}

# Install with snap (no loading here - called from main function)
install_with_snap() {
    local package="$1"
    
    if ! command -v snap &> /dev/null; then
        return 1
    fi
    
    # Just do the installation - no loading animation here
    if sudo snap install "$package" >/dev/null 2>&1; then
        SUCCESSFULLY_INSTALLED+=("$package (snap)")
        return 0
    else
        return 1
    fi
}

# Install packages
install_packages() {
    if [[ ${#PACKAGES[@]} -eq 0 ]]; then
        print_color "$YELLOW" "⚠️  No packages to install"
        return 0
    fi
    
    echo "=================================================="
    print_color "$BLUE" "  🚀 Starting installation of ${#PACKAGES[@]} packages..."
    echo "=================================================="
    echo
    log "Package list: ${PACKAGES[*]}"
    
    local installed_count=0
    local skipped_count=0
    local failed_count=0
    local failed_packages=()
    local skipped_packages=()
    
    local package_num=1
    for package in "${PACKAGES[@]}"; do
        echo "--- Package $package_num/${#PACKAGES[@]} ---"
        print_color "$BLUE" "📦 Processing: $package"
        log "Processing package $package_num/${#PACKAGES[@]}: $package"
        
        echo "🔍 Checking if $package is already installed..."
        if is_package_installed "$package"; then
            print_color "$YELLOW" "⏭️  $package is already installed, skipping..."
            log "Skipped $package (already installed)"
            ((skipped_count++))
            skipped_packages+=("$package")
            ((package_num++))
            echo "---"
            echo
            continue
        fi
        
        case "$PKG_MANAGER" in
            "apt")
                print_color "$BLUE" "📦 Installing $package via apt..."
                # Start loading animation in background
                install_with_loading "$package" "apt" &
                local loading_pid=$!
                
                # Do the actual installation
                local install_result=0
                install_with_apt "$package" || install_result=$?
                
                # Stop loading animation
                kill $loading_pid 2>/dev/null || true
                wait $loading_pid 2>/dev/null || true
                printf "\r   %-60s\r" " "  # Clear loading line
                
                if [[ $install_result -eq 0 ]]; then
                    print_color "$GREEN" "✅ $package installed successfully via apt"
                    log "Installed $package via apt"
                    ((installed_count++))
                else
                    print_color "$YELLOW" "🔄 Failed to install $package via apt, trying snap..."
                    
                    # Try snap with loading animation
                    print_color "$BLUE" "📦 Installing $package via snap..."
                    install_with_loading "$package" "snap" &
                    loading_pid=$!
                    
                    install_result=0
                    install_with_snap "$package" || install_result=$?
                    
                    kill $loading_pid 2>/dev/null || true
                    wait $loading_pid 2>/dev/null || true
                    printf "\r   %-60s\r" " "  # Clear loading line
                    
                    if [[ $install_result -eq 0 ]]; then
                        print_color "$GREEN" "✅ $package installed successfully via snap"
                        log "Installed $package via snap"
                        ((installed_count++))
                    else
                        print_color "$RED" "❌ Failed to install $package with both apt and snap"
                        log "Failed to install $package with both apt and snap"
                        ((failed_count++))
                        failed_packages+=("$package")
                    fi
                fi
                ;;
            "yum"|"pacman")
                print_color "$BLUE" "📦 Installing $package via $PKG_MANAGER..."
                install_with_loading "$package" "$PKG_MANAGER" &
                local loading_pid=$!
                
                local install_result=0
                install_system_package "$package" || install_result=$?
                
                kill $loading_pid 2>/dev/null || true
                wait $loading_pid 2>/dev/null || true
                printf "\r   %-60s\r" " "  # Clear loading line
                
                if [[ $install_result -eq 0 ]]; then
                    print_color "$GREEN" "✅ $package installed successfully via $PKG_MANAGER"
                    log "Installed $package via $PKG_MANAGER"
                    ((installed_count++))
                else
                    print_color "$RED" "❌ Failed to install $package via $PKG_MANAGER"
                    log "Failed to install $package via $PKG_MANAGER"
                    ((failed_count++))
                    failed_packages+=("$package")
                fi
                ;;
            "brew")
                if brew list "$package" &> /dev/null; then
                    print_color "$YELLOW" "⏭️  $package is already installed via brew, skipping..."
                    log "Skipped $package (already installed via brew)"
                    ((skipped_count++))
                    skipped_packages+=("$package")
                else
                    print_color "$BLUE" "📦 Installing $package via brew..."
                    install_with_loading "$package" "brew" &
                    local loading_pid=$!
                    
                    local install_result=0
                    if brew install "$package" >/dev/null 2>&1; then
                        SUCCESSFULLY_INSTALLED+=("$package (brew)")
                    else
                        install_result=1
                    fi
                    
                    kill $loading_pid 2>/dev/null || true
                    wait $loading_pid 2>/dev/null || true
                    printf "\r   %-60s\r" " "  # Clear loading line
                    
                    if [[ $install_result -eq 0 ]]; then
                        print_color "$GREEN" "✅ $package installed successfully via brew"
                        log "Installed $package via brew"
                        ((installed_count++))
                    else
                        print_color "$RED" "❌ Failed to install $package via brew"
                        log "Failed to install $package via brew"
                        ((failed_count++))
                        failed_packages+=("$package")
                    fi
                fi
                ;;
            *)
                print_color "$RED" "❌ Unsupported package manager: $PKG_MANAGER"
                log "Unsupported package manager: $PKG_MANAGER"
                return 1
                ;;
        esac
        
        ((package_num++))
        echo "---"
        echo
        sleep 1
    done
    
    echo "=================================================="
    print_color "$GREEN" "            📊 INSTALLATION SUMMARY"
    echo "=================================================="
    echo "Successfully installed: $installed_count packages"
    echo "Already installed (skipped): $skipped_count packages"
    echo "Failed to install: $failed_count packages"
    echo "Total packages processed: ${#PACKAGES[@]}"
    echo "=================================================="
    echo
    
    if [[ $skipped_count -gt 0 && ${#skipped_packages[@]} -le 15 ]]; then
        print_color "$YELLOW" "⏭️  Skipped packages: ${skipped_packages[*]}"
        echo
    fi
    
    if [[ $failed_count -gt 0 ]]; then
        print_color "$RED" "❌ Failed packages: ${failed_packages[*]}"
        echo
    fi
    
    log "Installation summary: $installed_count installed, $skipped_count skipped, $failed_count failed"
}

# Print final summary
print_final_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo
    echo "=============================================="
    print_color "$GREEN" "🎉 INSTALLATION COMPLETE! 🎉"
    echo "=============================================="
    
    if [[ $minutes -gt 0 ]]; then
        print_color "$BLUE" "⏱️  Total runtime: ${minutes}m ${seconds}s"
    else
        print_color "$BLUE" "⏱️  Total runtime: ${seconds}s"
    fi
    
    echo
    
    if [[ ${#SUCCESSFULLY_INSTALLED[@]} -gt 0 ]]; then
        print_color "$GREEN" "📦 Successfully Installed Packages:"
        echo "   (${#SUCCESSFULLY_INSTALLED[@]} packages)"
        echo
        for package in "${SUCCESSFULLY_INSTALLED[@]}"; do
            print_color "$GREEN" "   ✓ $package"
        done
        echo
    else
        print_color "$YELLOW" "No new packages were installed (all were already present)"
        echo
    fi
    
    print_color "$BLUE" "📊 Installation Summary:"
    echo "   • Total packages processed: ${#PACKAGES[@]}"
    echo "   • Successfully installed: ${#SUCCESSFULLY_INSTALLED[@]}"
    
    echo
    print_color "$GREEN" "🙏 Thank you for using the Package Installer!"
    print_color "$BLUE" "   We hope this tool saved you time and made package"
    print_color "$BLUE" "   management easier for your system."
    
    if [[ "$LOG_FILE" != "/dev/null" && -f "$LOG_FILE" ]]; then
        echo
        print_color "$YELLOW" "📝 Detailed logs saved to: $LOG_FILE"
    fi
    
    echo "=============================================="
}

# Open log file
open_log() {
    if [[ "$LOG_FILE" == "/dev/null" || ! -f "$LOG_FILE" ]]; then
        echo "📝 No log file to open"
        return 1
    fi
    
    print_color "$BLUE" "📂 Opening log file: $LOG_FILE"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "$LOG_FILE" 2>/dev/null || true
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v xdg-open &> /dev/null; then
            xdg-open "$LOG_FILE" 2>/dev/null || true
        elif command -v gnome-open &> /dev/null; then
            gnome-open "$LOG_FILE" 2>/dev/null || true
        elif command -v kate &> /dev/null; then
            kate "$LOG_FILE" 2>/dev/null &
        elif command -v gedit &> /dev/null; then
            gedit "$LOG_FILE" 2>/dev/null &
        elif command -v nano &> /dev/null; then
            print_color "$BLUE" "🖊️  Opening log file with nano..."
            nano "$LOG_FILE"
        elif command -v vim &> /dev/null; then
            print_color "$BLUE" "🖊️  Opening log file with vim..."
            vim "$LOG_FILE"
        elif command -v less &> /dev/null; then
            print_color "$BLUE" "📖 Opening log file with less (press 'q' to quit)..."
            less "$LOG_FILE"
        elif command -v cat &> /dev/null; then
            echo "📄 Displaying log file contents:"
            echo "════════════════════════════════"
            cat "$LOG_FILE"
            echo "════════════════════════════════"
        else
            print_color "$RED" "❌ Cannot find a suitable program to open the log file"
            echo "📍 Log file location: $LOG_FILE"
            return 1
        fi
    else
        if command -v less &> /dev/null; then
            print_color "$BLUE" "📖 Opening log file with less (press 'q' to quit)..."
            less "$LOG_FILE"
        else
            echo "📄 Displaying log file contents:"
            echo "════════════════════════════════"
            cat "$LOG_FILE"
            echo "════════════════════════════════"
        fi
    fi
}

# Cleanup on exit
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo
        echo "=================================================="
        print_color "$RED" "        ❌ INSTALLATION FAILED"
        echo "=================================================="
        print_color "$RED" "💥 Package installation failed with exit code: $exit_code"
        echo
        
        if [[ "$LOG_FILE" != "/dev/null" && -f "$LOG_FILE" ]]; then
            print_color "$YELLOW" "📋 Opening log file for troubleshooting..."
            echo
            echo -n "👆 Press Enter to open log file, or Ctrl+C to skip: "
            read -r -t 10 || {
                echo
                print_color "$BLUE" "⏰ Timeout reached, opening log file..."
            }
            
            open_log
        else
            print_color "$YELLOW" "⚠️  No log file available for review"
        fi
        echo
        print_color "$BLUE" "💡 Try running the script again or check the error messages above."
    fi
}

# Main function
main() {
    START_TIME=$(date +%s)
    trap cleanup EXIT
    
    init_logging
    print_banner
    load_config
    check_sudo
    detect_os
    check_requirements
    install_packages
    print_final_summary
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "🚀 Universal Package Installer - Smart package management made easy!"
        echo
        print_color "$BLUE" "📋 DESCRIPTION:"
        echo "   Installs packages from packages.txt using the best available package manager"
        echo "   for your system (apt→snap on Linux, brew on macOS) with intelligent fallbacks."
        echo
        print_color "$GREEN" "⚙️  OPTIONS:"
        echo "   --help, -h     📖 Show this help message"
        echo "   --version, -v  ℹ️  Show version information"
        echo "   --list, -l     📦 List packages in packages.txt without installing"
        echo "   --dry-run      🔍 Show what would be installed without actually installing"
        echo "   --open-log     📂 Open the log file from the last run"
        echo
        print_color "$YELLOW" "📁 SETUP:"
        echo "   The installer reads packages from packages.txt in the same directory."
        echo "   Format: One package per line, comments start with #"
        echo
        print_color "$BLUE" "💡 EXAMPLES:"
        echo "   ./installer.sh              # Install all packages"
        echo "   ./installer.sh --list       # Show what would be installed"
        echo "   ./installer.sh --dry-run    # Preview installation"
        exit 0
        ;;
    --version|-v)
        echo "=================================================="
        echo "  📦 $INSTALLER_NAME v$INSTALLER_VERSION"
        echo "  🚀 Smart Package Management Tool"
        echo "  💻 Cross-platform • 🔄 Multi-manager"
        echo "=================================================="
        exit 0
        ;;
    --list|-l)
        if [[ -f "$PACKAGES_FILE" ]]; then
            echo "=================================================="
            print_color "$BLUE" "  📦 Packages in $PACKAGES_FILE:"
            echo "=================================================="
            grep -v '^#' "$PACKAGES_FILE" | grep -v '^$' | sed 's/^/   📋 /'
            echo
            package_count=$(grep -v '^#' "$PACKAGES_FILE" | grep -v '^$' | wc -l)
            print_color "$GREEN" "📊 Total packages: $package_count"
        else
            print_color "$RED" "❌ packages.txt file not found"
            exit 1
        fi
        exit 0
        ;;
    --open-log)
        if [[ -f "$LOG_FILE" && "$LOG_FILE" != "/dev/null" ]]; then
            open_log
        else
            print_color "$YELLOW" "⚠️  No log file found to open"
            exit 1
        fi
        exit 0
        ;;
    --dry-run)
        DRY_RUN=true
        ;;
esac

# Run main installation
main "$@"