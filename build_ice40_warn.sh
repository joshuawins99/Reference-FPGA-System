#!/bin/bash

# Capture the arguments passed to the script
ARGS="$@"

# Call the error_check.py script with the captured arguments
if [ -z "$ARGS" ]; then
  ./error_check.py build_ice40.sh warnings_ice40.txt output_ice40.txt result_ice40.txt ""
else
  ./error_check.py build_ice40.sh warnings_ice40.txt output_ice40.txt result_ice40.txt $ARGS
fi
