#------------------------------------------------------------------------------
# Parameters
#------------------------------------------------------------------------------

# Project Directory
set project_path "."

# The name to use for the project.
set project_name "main"

# This is the name of the top module. This is not the name of the file that
# contains the top module, but the name of the module itself (in the code).
set top_module "main_cycloneiv"

# Name/location of the rtl filelist.
set filelist_file "rtl_filelist.txt"

# Name/location of the sdc file
set sdc_file "main_sdc.sdc"

# Device Family
set device_family "Cyclone IV E"

# Part Number
set part_number "EP4CE6E22C8"
#------------------------------------------------------------------------------

project_new $project_path/$project_name -overwrite

set_global_assignment -name TOP_LEVEL_ENTITY $top_module

set_global_assignment -name FAMILY $device_family
set_global_assignment -name DEVICE $part_number

set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files

# Add HDL files to the project
set raw_files [exec bash ../scripts/convert_filelist.sh $filelist_file]
set filelist [join [split $raw_files " "] "\n"]

foreach file $filelist {
    if {[string match "*.sv" $file]} {
        set_global_assignment -name SYSTEMVERILOG_FILE $file
    } elseif {[string match "*.v" $file]} {
        set_global_assignment -name VERILOG_FILE $file
    } elseif {[string match "*.vhd" $file] || [string match "*.vhdl" $file]} {
        set_global_assignment -name VHDL_FILE $file
    } else {
        puts "Warning: Unknown file type for $file"
    }
}

set_global_assignment -name SDC_FILE $sdc_file

#set_global_assignment -name SIMULATION_TOOL "ModelSim-Altera (VHDL)"

project_close