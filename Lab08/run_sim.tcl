open_project /home/waroon/SecondYear/FirstSemester/DigitalLab/Lab08/lab8/lab8.xpr

set tb_path /home/waroon/SecondYear/FirstSemester/DigitalLab/Lab08/lab8/lab8.srcs/sim_1/new/lab8_1_tb.vhdl

if {[llength [get_filesets -quiet sim_1]] == 0} {
    create_fileset -simset sim_1
}

if {[lsearch [get_files -quiet -of_objects [get_filesets sim_1]] $tb_path] < 0} {
    add_files -fileset sim_1 -norecurse $tb_path
}

set_property top lab8_1_tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1

set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

launch_simulation

run -all

close_sim -force
close_project
puts "SIM_SCRIPT_DONE"
