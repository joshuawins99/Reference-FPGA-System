#!/bin/bash

# Capture the arguments passed to the script
ARGS="$@"

# Call the error_check.py script with the captured arguments
if [ -z "$ARGS" ]; then
  ./error_check.py build_ecp5.sh warnings_ecp5.txt output_ecp5.txt result_ecp5.txt ""
else
  ./error_check.py build_ecp5.sh warnings_ecp5.txt output_ecp5.txt result_ecp5.txt $ARGS
fi
