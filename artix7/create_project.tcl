# This script is used to create the Vivado project from everything in the /src
# directory beside this script.
#
# To use this script, open Xilinx Vivado and select `Tools > Run Tcl Script...`
# then select the `generate_project.tcl` script in the file exporer. The script
# will run and produce the Vivado project by importing all of the project
# sources.

#------------------------------------------------------------------------------
# Parameters
#------------------------------------------------------------------------------

# All of the main parameters that can be configured are set in this section.
# These can be changed as desired.

# The name to use for the project.
set project_name "main"

# The part number of the hardware.
set part_number "xc7a35tftg256-3"

# The language to use in simulation. This can be VHDL, Verilog, or Mixed.
set simulator_language "Mixed"

# The target language to use for synthesis. This can be VHDL or Verilog.
set target_language "Verilog"

# This is the name of the top module. This is not the name of the file that
# contains the top module, but the name of the module itself (in the code).
# This can be set to an empty string to let the tools decide the top module
# automatically.
set top_module "main_artix7"

# This is the name of the top module to use in simulation. This is not the name
# of the file that contains the top module, but the name of the module itself
# (in the code). This can be set to an empty string to let the tools decide the
# top module automatically.
set top_sim_module ""

# The root path that all other paths are to be specified with. This is by
# default the path to the directory that this script is in, and it is not
# recommended that this be changed.
set origin_dir [file dirname [file normalize [info script]]]

# The directory that the Vivado project will be generated in. All Vivado
# project files will be stored in this directory.
set project_dir "$origin_dir"

# Get the year from the Vivado version. This is used for automatically
# selecting the synthesis and implementation strategies.
set year [lindex [split [version -short] .] 0]

# The strategies and flows to use in synthesis.
set synthesis_flow "Vivado Synthesis ${year}"
set synthesis_report_strategy "Vivado Synthesis Default Reports"
set synthesis_strategy "Vivado Synthesis Defaults"

# The strategies and flows to use in implementation.
set implementation_flow "Vivado Implementation ${year}"
set implementation_report_strategy "Vivado Implementation Default Reports"
set implementation_strategy "Vivado Implementation Defaults"

# This is a list of messages whose severities should be changed. This is
# treated like a list of tuples where the first element in tuple is the message
# ID and the second is the new severity for it.
set message_severities {
    { "Constraints 18-5210" "INFO"     }
    { "Power 33-332"        "INFO"     }
    { "Synth 8-3331"        "ADVISORY" }
    { "Synth 8-3332"        "INFO"     }
    { "Synth 8-5858"        "INFO"     }
    { "Synth 8-6014"        "INFO"     }
    { "Timing 38-316"       "INFO"     }
}

#------------------------------------------------------------------------------
# Create Project
#------------------------------------------------------------------------------

# This part of the script creates a new project in the proj/ directory relative
# to this script.

# Create a project to add the source files to
create_project $project_name $project_dir

# Set the message severities for the project
for { set i 0 } { $i < [llength $message_severities] } { incr i } {
    set item [lindex $message_severities $i]
    set message_id [lindex $item 0]
    set new_severity [lindex $item 1]
    set_msg_config -ruleid $i -id $message_id -new_severity $new_severity
}

# Project properties
set obj [get_projects $project_name]
set_property default_lib xil_defaultlib $obj
set_property part $part_number $obj
set_property simulator_language $simulator_language $obj
set_property target_language $target_language $obj

set output [exec bash ../scripts/convert_filelist.sh rtl_filelist.txt]
add_files -fileset sources_1 $output

add_files -fileset constrs_1 pin_config_artix7.xdc


# Set the top module for the design if it was specified
if { ! [string equal $top_module ""] } {
    set_property top $top_module [get_filesets sources_1]
}

set_property verilog_define {ARTIX7} [get_filesets sources_1]

set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING auto [get_runs synth_1]

launch_runs synth_1 -jobs 24
wait_on_run synth_1
open_run synth_1 -name netlist_1
report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose \
-max_paths 10 -input_pins -file syn_timing.rpt
report_power -file syn_power.rpt
report_utilization -file syn_util.rpt
report_utilization -append -hierarchical -file syn_util.rpt

set_property strategy Performance_Explore [get_runs impl_1]

launch_runs impl_1 -jobs 24
wait_on_run impl_1
open_run impl_1
place_design -timing_driven
report_timing_summary -delay_type min_max -report_unconstrained \
-check_timing_verbose -max_paths 10 -input_pins -file imp_timing.rpt
report_power -file imp_power.rpt
report_utilization -file imp_util.rpt
report_utilization -append -hierarchical -file imp_util.rpt

write_bitstream -force -bin_file $project_name