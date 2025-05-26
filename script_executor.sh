#!/bin/bash

check_signature() {
    if [ ! -f "signature.txt" ] || [ ! -s "signature.txt" ]; then
        echo "No valid signature found, creating one..."
        
        # Create a signature with timestamp and basic system info
        {
            echo "Installation Signature"
            echo "======================"
            echo "Created: $(date)"
            echo "User: $(whoami)"
            echo "Host: $(hostname)"
            echo "Directory: $(pwd)"
            echo "Script Version: 1.0"
        } > signature.txt
        
        echo "Signature created successfully"
        echo ""
    else
        echo "Valid signature found, proceeding..."
        echo ""
    fi
}

display_logo() {
    if [ -f "logo.txt" ]; then
        echo "=================================="
        cat logo.txt
        echo "=================================="
        echo ""
    else
        echo "Warning: logo.txt file not found in current directory"
        echo ""
    fi
    
    # Loading bar
    echo "Initializing..."
    echo -n "["
    
    # Progress bar with 50 steps over 5 seconds
    for i in {1..50}; do
        echo -n "█"
        sleep 0.1
    done
    
    echo "] 100%"
    echo ""
}

run_system_updates() {
    echo "Running system updates..."
    echo "Updating package lists..."
    sudo apt update
    echo "Upgrading packages..."
    sudo apt upgrade -y
    echo "System updates completed."
    echo ""
}

execute_scripts_in_dir() {
    local dir_name="$1"
    local script_array=()
    
    for file in "$dir_name"/*.sh; do
        if [ -f "$file" ]; then
            script_array+=("$(basename "$file")")
        fi
    done
    
    if [ ${#script_array[@]} -eq 0 ]; then
        return 0
    fi
    
    IFS=$'\n' sorted=($(sort <<<"${script_array[*]}"))
    unset IFS
    
    # Make all scripts in the array executable
    for script in "${sorted[@]}"; do
        local script_path="$dir_name/$script"
        chmod +x "$script_path"
    done
    
    # Execute all scripts in order
    for script in "${sorted[@]}"; do
        local script_path="$dir_name/$script"
        bash "$script_path"
    done
}

display_logo
check_signature
run_system_updates

if [ ! -d "scripts" ]; then
    echo "Error: 'scripts' directory not found in current location"
    exit 1
fi

cd scripts || { echo "Error: Cannot navigate to scripts directory"; exit 1; }

all_folders=()
for dir in */; do
    if [ -d "$dir" ]; then
        all_folders+=("${dir%/}")
    fi
done

if [ ${#all_folders[@]} -eq 0 ]; then
    echo "No subdirectories found in scripts folder"
    exit 0
fi

if [ -d "required" ]; then
    execute_scripts_in_dir "required"
fi

while true; do
    read -p "Would you like to install additional scripts? (y/n): " response
    case $response in
        [Yy]* ) 
            available_folders=()
            for folder in "${all_folders[@]}"; do
                if [ "$folder" != "required" ]; then
                    available_folders+=("$folder")
                fi
            done
            
            if [ ${#available_folders[@]} -eq 0 ]; then
                echo "No additional folders available"
                break
            fi
            
            # Show available folders immediately after user says yes
            echo ""
            echo "╔══════════════════════════════════════╗"
            echo "║          Available Folders          ║"
            echo "╠══════════════════════════════════════╣"
            for i in "${!available_folders[@]}"; do
                printf "║ %-2s. %-30s ║\n" "$((i+1))" "${available_folders[i]}"
            done
            echo "╚══════════════════════════════════════╝"
            echo ""
            
            while true; do
                read -p "Enter the number of the folder you want to install scripts from: " choice
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#available_folders[@]}" ]; then
                    chosen_folder="${available_folders[$((choice-1))]}"
                    break
                else
                    echo "Invalid choice. Please enter a number between 1 and ${#available_folders[@]}."
                fi
            done
            
            execute_scripts_in_dir "$chosen_folder"
            ;;
        [Nn]* ) 
            echo "Exiting script..."
            exit 0
            ;;
        * ) 
            echo "Please answer yes (y) or no (n)."
            ;;
    esac
done