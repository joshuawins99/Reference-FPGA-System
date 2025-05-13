#!/bin/bash

# Check for Quartus mode parameter
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <file_list> [--quartus]"
    exit 1
fi

# Assign parameters
file_list="$1"
quartus_mode=false

if [[ "$2" == "--quartus" ]]; then
    quartus_mode=true
fi

# Get the directory of the input file
file_list_dir=$(dirname "$(realpath "$file_list")")

# Check if the specified file exists
if [[ ! -f $file_list ]]; then
    echo "Error: File '$file_list' not found."
    exit 1
fi

# Prepare a temporary file to avoid skipping the last line
temp_file=$(mktemp)
cp "$file_list" "$temp_file"
echo "" >> "$temp_file"  # Ensure the last line is processed

# Prepare expanded file list
expanded_file_list=$(mktemp)

# Read and process each line from the file
while IFS= read -r line; do
    [[ -z "$line" ]] && continue  # Skip empty lines
    [[ "$line" == \#* ]] && continue  # Skip lines starting with #

    resolved_path="$file_list_dir/$line"
    if [[ -d $resolved_path ]]; then
        find "$resolved_path" -type f >> "$expanded_file_list"
    elif [[ -f $resolved_path ]]; then
        echo "$resolved_path" >> "$expanded_file_list"
    else
        for item in $resolved_path; do
            [[ -f $item ]] && echo "$item" >> "$expanded_file_list"
        done
    fi
done < "$temp_file"

# Process files for Quartus or standard mode
if $quartus_mode; then
    QSF_FILE="file_list.qsf"
    > "$QSF_FILE"  # Clear QSF file

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue  # Skip empty lines
        extension="${file##*.}"  # Extract file extension

        case "$extension" in
            v) echo "set_global_assignment -name VERILOG_FILE $file" >> "$QSF_FILE" ;;
            sv) echo "set_global_assignment -name SYSTEMVERILOG_FILE $file" >> "$QSF_FILE" ;;
            vhd|vhdl) echo "set_global_assignment -name VHDL_FILE $file" >> "$QSF_FILE" ;;
            *) ;;
        esac
    done < "$expanded_file_list"
    echo "QSF file created successfully!"
else
    single_line_output=$(tr '\n' ' ' < "$expanded_file_list")
    echo "$single_line_output"
fi

# Clean up temporary files
rm "$temp_file" "$expanded_file_list"
