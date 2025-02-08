#!/bin/bash

# Capture the arguments passed to the script
ARGS="$@"

# Call the error_check.py script with the captured arguments
if [ -z "$ARGS" ]; then
  ./error_check.py build_cycloneiv.sh warnings_cycloneiv.txt output_cycloneiv.txt result_cycloneiv.txt ""
else
  ./error_check.py build_cycloneiv.sh warnings_cycloneiv.txt output_cycloneiv.txt result_cycloneiv.txt $ARGS
fi
