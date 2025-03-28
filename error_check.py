#!/usr/bin/env python3

import subprocess
import sys
import fnmatch

def load_mask_patterns(mask_file):
    with open(mask_file, 'r') as file:
        patterns = file.read().splitlines()
    return patterns

def filter_output(output, patterns):
    filtered_lines = []
    found_patterns = set()
    for line in output.splitlines():
        matched = False
        for pattern in patterns:
            # Check if the pattern is intermittent
            is_intermittent = pattern.startswith("#")
            if fnmatch.fnmatch(line, pattern.lstrip("#")):
                matched = True
                found_patterns.add(pattern)
                break
        if not matched:
            filtered_lines.append(line)
    return '\n'.join(filtered_lines), found_patterns

def search_for_warnings_and_errors(output_file, result_file, patterns):
    with open(output_file, 'r') as file:
        lines = file.readlines()
    
    warnings_and_errors = []
    for line in lines:
        if "Warning:" in line or "Error:" in line or "ERROR" in line or "Warning (" in line or "warning:" in line or "error:" in line:
            warnings_and_errors.append(line)
    
    with open(result_file, 'w') as file:
        if (warnings_and_errors):
            file.writelines(warnings_and_errors)
        else:
            file.write("PASS!")
    
    if warnings_and_errors:
        return warnings_and_errors
    else:
        print("No Warnings or Errors!")
        return []

def execute_script(script_file, mask_file, output_file, result_file, script_params):
    try:
        # Load mask patterns
        patterns = load_mask_patterns(mask_file)
        
        # Determine script type and execute it
        if script_file.endswith('.sh'):
            result = subprocess.run(['bash', script_file] + script_params, stderr=subprocess.PIPE, stdout=subprocess.PIPE, text=True, check=True)
        elif script_file.endswith('.bat'):
            result = subprocess.run(['cmd.exe', '/c', script_file] + script_params, stderr=subprocess.PIPE, stdout=subprocess.PIPE, text=True, check=True)
        else:
            print("Unsupported script type. Please provide a .sh or .bat script.")
            sys.exit(1)
        
        # Filter the captured stderr output
        filtered_stderr, found_patterns = filter_output(result.stderr, patterns)
        # Filter the captured stdout output
        filtered_stdout, found_patterns_stdout = filter_output(result.stdout, patterns)
        
        # Write the filtered stdout and stderr output to the specified file
        with open(output_file, 'w') as file:
            file.write(filtered_stdout)
            file.write('\n')
            file.write(filtered_stderr)
        
        # Search for warnings and errors in the output file and print them
        warnings_and_errors = search_for_warnings_and_errors(output_file, result_file, patterns)
        
        # Print the contents of the result file
        if warnings_and_errors:
            print("Warnings and Errors Found:")
            for line in warnings_and_errors:
                print(line, end='')
        # Check for patterns not found in the output
        missing_patterns = set(patterns) - found_patterns - found_patterns_stdout
        #print(found_patterns)
        # Filter out intermittent patterns from missing patterns
        missing_patterns = {pattern for pattern in missing_patterns if not pattern.startswith("#")}
        if missing_patterns:
            print("\nWarnings and Errors not found:")
            for pattern in missing_patterns:
                print(pattern)
    except subprocess.CalledProcessError as e:
        print(f"Error executing the script: {e}")
        with open(output_file, 'w') as file:
            file.write(e.output)

if __name__ == "__main__":
    if len(sys.argv) < 6:
        print("Usage: ./script.py <script_file> <mask_file> <output_file> <result_file> <script_param1> [<script_param2> ...]")
        sys.exit(1)
    
    script_file = sys.argv[1]
    mask_file = sys.argv[2]
    output_file = sys.argv[3]
    result_file = sys.argv[4]
    script_params = sys.argv[5:]

    execute_script(script_file, mask_file, output_file, result_file, script_params)
