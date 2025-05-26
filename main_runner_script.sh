#!/bin/bash

# Main script runner - executes all .sh scripts from the scripts subdirectory in numerical order
echo "=================================="
echo "   MAIN SCRIPT RUNNER STARTED"
echo "=================================="
echo

# Define the scripts directory
SCRIPTS_DIR="./scripts"

# Check if scripts directory exists
if [ ! -d "$SCRIPTS_DIR" ]; then
    echo "ERROR: Scripts directory '$SCRIPTS_DIR' does not exist!"
    echo "Please create the directory and add your scripts."
    exit 1
fi

echo "Scripts directory found: $SCRIPTS_DIR"
echo "Scanning for .sh files..."
echo

# Create array of all .sh files in the scripts directory
mapfile -t SCRIPTS < <(find "$SCRIPTS_DIR" -name "*.sh" -type f -printf '%f\n' | sort -V)

# Convert to full paths for execution
SCRIPT_PATHS=()
for script in "${SCRIPTS[@]}"; do
    SCRIPT_PATHS+=("$SCRIPTS_DIR/$script")
done

# Check if any scripts were found
if [ ${#SCRIPTS[@]} -eq 0 ]; then
    echo "No .sh scripts found in $SCRIPTS_DIR"
    echo "Please add scripts with naming format: {number}_{scriptname}.sh"
    echo "Example: 1_setup.sh, 2_install.sh, 3_configure.sh"
    exit 1
fi

echo "Found ${#SCRIPTS[@]} script(s) to execute in order:"
for i in "${!SCRIPTS[@]}"; do
    echo "$((i+1)). ${SCRIPTS[i]}"
done
echo

# Function to execute a script with error handling
execute_script() {
    local script_path=$1
    local script_name=$(basename "$script_path")
    
    echo "----------------------------------------"
    echo "Executing: $script_name"
    echo "----------------------------------------"
    
    # Check if script is executable
    if [ ! -x "$script_path" ]; then
        echo "Making script executable..."
        chmod +x "$script_path"
    fi
    
    # Execute the script
    echo "Running $script_name..."
    if bash "$script_path"; then
        echo "✓ $script_name completed successfully"
        return 0
    else
        echo "✗ $script_name failed with exit code $?"
        
        # Ask user if they want to continue
        echo
        read -p "Script failed. Continue with remaining scripts? (y/n): " continue_choice
        case $continue_choice in
            [Yy]* )
                echo "Continuing with next script..."
                return 1
                ;;
            [Nn]* )
                echo "Stopping execution as requested."
                exit 1
                ;;
            * )
                echo "Invalid choice. Stopping execution."
                exit 1
                ;;
        esac
    fi
}

# Execute all scripts in order
successful_scripts=0
failed_scripts=0

for script_path in "${SCRIPT_PATHS[@]}"; do
    if execute_script "$script_path"; then
        ((successful_scripts++))
    else
        ((failed_scripts++))
    fi
    echo
done

# Summary
echo "=================================="
echo "        EXECUTION SUMMARY"
echo "=================================="
echo "Total scripts found: ${#SCRIPTS[@]}"
echo "Successful: $successful_scripts"
echo "Failed: $failed_scripts"
echo

if [ $failed_scripts -eq 0 ]; then
    echo "🎉 All scripts executed successfully!"
    exit 0
else
    echo "⚠️  Some scripts failed during execution."
    exit 1
fi
