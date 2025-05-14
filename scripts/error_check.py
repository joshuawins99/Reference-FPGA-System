#!/usr/bin/env python3

import subprocess
import sys
import fnmatch
import re

def load_mask_patterns(mask_file):
    with open(mask_file, 'r') as file:
        patterns = file.read().splitlines()
    return patterns

def shell_to_regex(shell_pattern):
    """Convert fnmatch-style pattern to proper regex."""
    shell_pattern = re.escape(shell_pattern)  # Escape special characters
    shell_pattern = shell_pattern.replace(r'\*', '.*')  # Convert '*' to regex '.*'
    return shell_pattern

def filter_output(output, patterns):
    filtered_lines = []
    found_patterns = set()

    regex_patterns = {pattern: re.compile(shell_to_regex(pattern.lstrip("#"))) for pattern in patterns}

    for line in output.splitlines():
        matched = False
        for pattern, regex in regex_patterns.items():
            if regex.search(line):  # Allow partial matches
                matched = True
                found_patterns.add(pattern)
                break
        if not matched:
            filtered_lines.append(line)

    return '\n'.join(filtered_lines), found_patterns

def search_for_warnings_and_errors(output, result_file, patterns):
    warnings_and_errors = [line for line in output.splitlines() if any(w in line.lower() for w in ["warning:", "error:", "warning (", "error"])]

    with open(result_file, 'w') as file:
        if warnings_and_errors:
            file.writelines("\n".join(warnings_and_errors) + "\n")  # Ensure warnings/errors are written with proper new lines
        else:
            file.write("PASS!\n")

    if warnings_and_errors:
        print("Warnings and Errors Found:")
        for line in warnings_and_errors:
            print(line)  # Print each warning/error on a new line

    return warnings_and_errors if warnings_and_errors else print("No Warnings or Errors!")

def execute_script(script_file, mask_file, output_file, result_file, script_params):
    try:
        # Load mask patterns
        patterns = load_mask_patterns(mask_file)

        if script_file == "make":
            #print("Processing 'make' output directly...")
            raw_output = sys.stdin.read()  # Read piped input from Makefile instead of expecting a file

        else:
            # Determine script type and execute it
            if script_file.endswith('.sh'):
                result = subprocess.run(['bash', script_file] + script_params, stderr=subprocess.PIPE, stdout=subprocess.PIPE, text=True, check=True)
            elif script_file.endswith('.bat'):
                result = subprocess.run(['cmd.exe', '/c', script_file] + script_params, stderr=subprocess.PIPE, stdout=subprocess.PIPE, text=True, check=True)
            else:
                print("Unsupported script type. Please provide a .sh or .bat script.")
                sys.exit(1)

            raw_output = result.stdout + "\n" + result.stderr

        # Filter output for patterns
        filtered_output, found_patterns = filter_output(raw_output, patterns)

        # Write filtered output to file (for logging purposes)
        with open(output_file, 'w') as file:
            file.write(filtered_output + "\n")  # Ensure the output ends with a new line

        # Search for warnings and errors
        warnings_and_errors = search_for_warnings_and_errors(filtered_output, result_file, patterns)

        # Check for patterns not found in output
        missing_patterns = set(patterns) - found_patterns
        missing_patterns = {pattern for pattern in missing_patterns if not pattern.startswith("#")}
        if missing_patterns:
            print("\nWarnings and Errors not found:")
            for pattern in missing_patterns:
                print(pattern)
                
    except subprocess.CalledProcessError as e:
        print(f"Error executing the script: {e}")

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
