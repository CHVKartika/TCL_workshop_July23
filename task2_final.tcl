#! /bin/env tclsh
set filename [ lindex $argv 0]
package require csv
package require struct::matrix
struct::matrix m
set f [open $filename r]
csv::read2matrix $f m , auto
close $f

set num_columns [m columns]
set num_rows [m rows]
m link -transpose my_arr

set i 0
while {$i < $num_rows} {
      puts "\n Info : Setting $my_arr($i,0) as $my_arr($i,1) "
      if { $i==0 } {
      set [ string map {" " ""} $my_arr($i,0)] $my_arr($i,1)
}     else {
      set [ string map {" " ""} $my_arr($i,0)] [ file normalize $my_arr($i,1)]
}

      set i [expr {$i + 1}]

}

if { ! [ file isdirectory $OutputDirectory ] } {
   puts "\n Cannot find the output directory $OutputDirectory. Creating output directory "
   file mkdir $OutputDirectory
} else {
   puts "\n Output directory found"   
}

if { ! [ file isdirectory $NetlistDirectory ] } {
   puts "\n Cannot find the RTL directory $NetlistDirectory. Exiting the tool "
   exit
} else {
   puts "\n RTL directory found"   
}

if { ! [ file exists  $EarlyLibraryPath ] } {
   puts "\n Cannot find the early library path $EarlyLibraryPath. Exiting the tool "
   exit
} else {
   puts "\n Early Library file found"   
}

if { ! [ file exists $LateLibraryPath ] } {
   puts "\n Cannot find the late library path $LateLibraryPath. Exiting the tool "
   exit
} else {
   puts "\n Late Library file found"   
}

if { ! [ file exists $Constraintsfile ] } {
   puts "\n Cannot find the constaraints file  $Constraintsfile. Exiting the tool "
   exit
} else {
   puts "\n Constraints file found"   
}

puts "\n Info : Dumping SDC constraints for $DesignName "
::struct::matrix constraints
set f2 [open $Constraintsfile r]
csv::read2matrix $f2 constraints , auto
close $f2
set const_file_num_rows [ constraints rows ]
set const_file_num_cols [ constraints columns]

set clock_start [ lindex [ lindex [ constraints search all CLOCKS ] 0 ] 1]
set clock_start_col [ lindex [ lindex [ constraints search all CLOCKS ] 0 ] 0]
set inp_port_start [ lindex [ lindex [ constraints search all INPUTS ] 0 ] 1]
set out_port_start [ lindex [ lindex [ constraints search all OUTPUTS ] 0 ] 1]

set clock_early_rise_delay_start [lindex [lindex [constraints search rect $clock_start_col $clock_start [ expr {$const_file_num_cols - 1 }] [ expr {$inp_port_start - 1 }] early_rise_delay ] 0] 0]
set clock_early_fall_delay_start [lindex [lindex [constraints search rect $clock_start_col $clock_start [ expr {$const_file_num_cols - 1 }] [ expr {$inp_port_start - 1 }] early_fall_delay ] 0] 0]
set clock_late_rise_delay_start [lindex [lindex [constraints search rect $clock_start_col $clock_start [ expr {$const_file_num_cols - 1 }] [ expr {$inp_port_start - 1 }] late_rise_delay ] 0] 0]
set clock_late_fall_delay_start [lindex [lindex [constraints search rect $clock_start_col $clock_start [ expr {$const_file_num_cols - 1 }] [ expr {$inp_port_start - 1 }] late_fall_delay ] 0] 0]

set clock_early_rise_slew_start [lindex [lindex [constraints search rect $clock_start_col $clock_start [ expr {$const_file_num_cols - 1 }] [ expr {$inp_port_start - 1 }] early_rise_slew ] 0] 0]
set clock_early_fall_slew_start [lindex [lindex [constraints search rect $clock_start_col $clock_start [ expr {$const_file_num_cols - 1 }] [ expr {$inp_port_start - 1 }] early_fall_slew ] 0] 0]
set clock_late_rise_slew_start [lindex [lindex [constraints search rect $clock_start_col $clock_start [ expr {$const_file_num_cols - 1 }] [ expr {$inp_port_start - 1 }] late_rise_slew ] 0] 0]
set clock_late_fall_slew_start [lindex [lindex [constraints search rect $clock_start_col $clock_start [ expr {$const_file_num_cols - 1 }] [ expr {$inp_port_start - 1 }] late_fall_slew ] 0] 0]

set frequency_start [lindex [lindex [constraints search rect $clock_start_col $clock_start [ expr {$clock_early_rise_delay_start - 1 }] [ expr {$inp_port_start - 1 }] frequency ] 0] 0]
set duty_cycle_start [lindex [lindex [constraints search rect $clock_start_col $clock_start [ expr {$clock_early_rise_delay_start - 1 }] [ expr {$inp_port_start - 1 }] duty_cycle ] 0] 0]


set sdc_file [ open $OutputDirectory/$DesignName.sdc w ]
set i [ expr { $clock_start + 1}]
set end_of_ports [ expr { $inp_port_start - 1}]
puts "\n Info : Writing to sdc file - clock constraints "
while { $i < $end_of_ports } {
      set TP [ constraints get cell $frequency_start $i]
      set DC [ constraints get cell $duty_cycle_start $i] 
      set CN [ constraints get cell $clock_start_col $i] 
      puts -nonewline $sdc_file "\ncreate_clock -name $CN -period $TP -waveform \{ 0 [ expr {$TP * $DC / 100} ] \} \[get_ports $CN\]  "

      puts -nonewline $sdc_file "\nset_clock_transition -source -rise -min [ constraints get cell $clock_early_rise_slew_start $i ] \[get_clocks [constraints get cell 0 $i] \] "
      puts -nonewline $sdc_file "\nset_clock_transition -source -fall -min [ constraints get cell $clock_early_fall_slew_start $i ] \[get_clocks [constraints get cell 0 $i] \] "
      puts -nonewline $sdc_file "\nset_clock_transition -source -rise -max [ constraints get cell $clock_late_rise_slew_start $i ] \[get_clocks [constraints get cell 0 $i] \] "
      puts -nonewline $sdc_file "\nset_clock_transition -source -fall -max [ constraints get cell $clock_late_fall_slew_start $i ] \[get_clocks [constraints get cell 0 $i] \] "

      puts -nonewline $sdc_file "\nset_clock_latency -source -early -rise [ constraints get cell $clock_early_rise_delay_start $i ] \[get_clocks [constraints get cell 0 $i] \] "
      puts -nonewline $sdc_file "\nset_clock_latency -source -early -fall [ constraints get cell $clock_early_fall_delay_start $i ] \[get_clocks [constraints get cell 0 $i] \] "
      puts -nonewline $sdc_file "\nset_clock_latency -source -late -rise [ constraints get cell $clock_late_rise_delay_start $i ] \[get_clocks [constraints get cell 0 $i] \] "
      puts -nonewline $sdc_file "\nset_clock_latency -source -late -fall [ constraints get cell $clock_late_fall_delay_start $i ] \[get_clocks [constraints get cell 0 $i] \] "


      set i [ expr { $i + 1 } ]
}

set i [expr {$inp_port_start + 1 }]
set j 0
set end_of_ports [expr {$out_port_start - 1 }]
puts "\n Info : Writing into sdc file - input constraints; categorizing as bit/bus "
while { $i < $end_of_ports } {
      set netlist [ glob -dir $NetlistDirectory *.v ]
      set inp_ports_list($j) [constraints get cell 0 $i] 
      set temp_file [open /home/vsduser/Desktop/tcl_workshop/temp/tr2 a]
      foreach f $netlist {
                         set f1 [open $f "r"]
                         while { [gets $f1 line] != -1 } {
                               set pattern1 " [constraints get cell 0 $i];"
                               if { [regexp -all -- $pattern1 $line] } {
                                  set pattern2 [lindex [split $line ";"] 0]
                                  if { [regexp -all {input} [lindex [split $pattern2 "\S+"] 0]] } {
                                     set s1 "[lindex [split $pattern2 "\S+"] 0] [lindex [split $pattern2 "\S+"] 1] [lindex [split $pattern2 "\S+"] 2]"
                                     set temp_print [regsub -all {\s+} $s1 " "]
                                     puts -nonewline $temp_file "\n $temp_print"
                                     } 
                               }
                          
                          }
       close $f1 
       }
       close $temp_file
       set j [expr {$j + 1}]        
       set i [expr {$i + 1}]
       }

          
       set i [expr {$inp_port_start + 1}]
       set i1 0
       set temp_file [open /home/vsduser/Desktop/tcl_workshop/temp/tr2 r]
       set temp_file2 [open /home/vsduser/Desktop/tcl_workshop/temp/tr3 w]
       set temp_print2 [join [lsort -unique [split [read $temp_file] \n]] \n]
       puts -nonewline $temp_file2 "\n $temp_print2"
       close $temp_file2
       set temp_file2 [open /home/vsduser/Desktop/tcl_workshop/temp/tr3 r]
      # puts "\n entering while"
       while { [gets $temp_file2 line] != -1 } {
             set temp4 $line
             set temp3 [regexp -all -inline {\w+[^(\[\d*:\d*\])]} $line]
             set l_temp4 [llength $temp4 ]
             set l_temp3 [llength $temp3 ]
             if {$l_temp3 == 3 } {
                set temp2($i1) [regexp -all -inline {\w+[^\s]} [lindex $temp3 2]]
                if { $l_temp4 > 2 } {
                   set inp_ports($i1) [concat $temp2($i1)\*]    
                   } else {
                           set inp_ports($i1) $temp2($i1)
                          }             
                for { set j 0 } { $j < [array size inp_ports_list] } { incr j } {
                                  set temp1 $inp_ports_list($j)
                                  if { $temp2($i1) == $temp1 } {
                                     set inp_port_row($i1) [expr { $j + $i }] 
                                     }
                    }
                   } 
               if {$l_temp3 == 2 } {
                          set temp2($i1) [regexp -all -inline {\w+[^\s]} [lindex $temp3 1]]      
                           if { $l_temp4 > 2 } {
                               set inp_ports($i1) [concat $temp2($i1)\*]    
                              } else {
                                      set inp_ports($i1) $temp2($i1)
                                     }
                          for { set j 0 } { $j < [array size inp_ports_list] } { incr j } { 
                                          set temp1 $inp_ports_list($j)
                                          if { $temp2($i1) == $temp1 } {
                                              set inp_port_row($i1)  [expr { $j + $i }]
                                              } 
                                        

                                      }                                             
                                  }   
                          set i1 [expr { $i1 + 1 }]
                          }
       
       close $temp_file2

set input_early_rise_delay_start [lindex [ lindex [constraints search rect $clock_start_col $inp_port_start [ expr {$const_file_num_cols - 1 }] [ expr {$out_port_start - 1 }] early_rise_delay ] 0] 0]
set input_early_fall_delay_start [lindex [ lindex [constraints search rect $clock_start_col $inp_port_start [ expr {$const_file_num_cols - 1 }] [ expr {$out_port_start - 1 }] early_fall_delay ] 0] 0]
set input_late_rise_delay_start [lindex [ lindex [constraints search rect $clock_start_col $inp_port_start [ expr {$const_file_num_cols - 1 }] [ expr {$out_port_start - 1 }] late_rise_delay ] 0] 0]
set input_late_fall_delay_start [lindex [ lindex [constraints search rect $clock_start_col $inp_port_start [ expr {$const_file_num_cols - 1 }] [ expr {$out_port_start - 1 }] late_fall_delay ] 0] 0]
 
set input_early_rise_slew_start [lindex [ lindex [constraints search rect $clock_start_col $inp_port_start [ expr {$const_file_num_cols - 1 }] [ expr {$out_port_start - 1 }] early_rise_slew ] 0] 0]
set input_early_fall_slew_start [lindex [ lindex [constraints search rect $clock_start_col $inp_port_start [ expr {$const_file_num_cols - 1 }] [ expr {$out_port_start - 1 }] early_fall_slew ] 0] 0]
set input_late_rise_slew_start [lindex [ lindex [constraints search rect $clock_start_col $inp_port_start [ expr {$const_file_num_cols - 1 }] [ expr {$out_port_start - 1 }] late_rise_slew ] 0] 0]
set input_late_fall_slew_start [lindex [ lindex [constraints search rect $clock_start_col $inp_port_start [ expr {$const_file_num_cols - 1 }] [ expr {$out_port_start - 1 }] late_fall_slew ] 0] 0]

set related_clock 9
set i1 2
set i_end  [expr {[array size inp_port_row] + 2} ]
puts "\n Info : Writing to sdc file - input constraints "
while { $i1 < $i_end } {
      set j1 $inp_port_row($i1)
      set CL1 [constraints get cell $related_clock $j1]
  puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks $CL1\] -min -rise -source_latency_included [constraints get cell $input_early_rise_delay_start $j1] \[get_ports $inp_ports($i1)\]"
  puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks $CL1\] -min -fall -source_latency_included [constraints get cell $input_early_fall_delay_start $j1] \[get_ports $inp_ports($i1)\]" 
  puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks $CL1\] -max -rise -source_latency_included [constraints get cell $input_late_rise_delay_start $j1] \[get_ports $inp_ports($i1)\]"
  puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks $CL1\] -max -fall -source_latency_included [constraints get cell $input_late_fall_delay_start $j1] \[get_ports $inp_ports($i1)\]"
      
  puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks $CL1\] -min -rise -source_latency_included [constraints get cell $input_early_rise_delay_start $j1] \[get_ports $inp_ports($i1)\]"
  puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks $CL1\] -min -fall -source_latency_included [constraints get cell $input_early_fall_delay_start $j1] \[get_ports $inp_ports($i1)\]" 
  puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks $CL1\] -max -rise -source_latency_included [constraints get cell $input_late_rise_delay_start $j1] \[get_ports $inp_ports($i1)\]"
  puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks $CL1\] -max -fall -source_latency_included [constraints get cell $input_late_fall_delay_start $j1] \[get_ports $inp_ports($i1)\]"

      set i1 [ expr { $i1 + 1 } ]
}
 


set i [expr { $out_port_start + 1 }]
set j 0
set end_of_ports [expr { $const_file_num_rows - 1 }]
puts "\n Info : Writing into sdc file - output constraints; categorizing as bit/bus "
while { $i < $end_of_ports } {
      set netlist [ glob -dir $NetlistDirectory *.v ]
      set out_ports_list($j) [constraints get cell 0 $i] 
      set temp_file [open /home/vsduser/Desktop/tcl_workshop/temp/tr4 a]
      foreach f $netlist {
                         set f1 [open $f "r"]
                         while { [gets $f1 line] != -1 } {
                               set pattern1 " [constraints get cell 0 $i];"
                               if { [regexp -all -- $pattern1 $line] } {
                                  set pattern2 [lindex [split $line ";"] 0]
                                  if { [regexp -all {output} [lindex [split $pattern2 "\S+"] 0]] } {
                                     set s1 "[lindex [split $pattern2 "\S+"] 0] [lindex [split $pattern2 "\S+"] 1] [lindex [split $pattern2 "\S+"] 2]"
                                     set temp_print [regsub -all {\s+} $s1 " "]
                                     puts -nonewline $temp_file "\n $temp_print"
                                     } 
                               }
                          
                          }
       close $f1 
       }
       close $temp_file
       set j [expr {$j + 1}]        
       set i [expr {$i + 1}]
       }

          
       set i [expr {$out_port_start + 1}]
       set i1 0
       set temp_file [open /home/vsduser/Desktop/tcl_workshop/temp/tr4 r]
       set temp_file2 [open /home/vsduser/Desktop/tcl_workshop/temp/tr5 w]
       set temp_print2 [join [lsort -unique [split [read $temp_file] \n]] \n]
       puts -nonewline $temp_file2 "\n $temp_print2"
       close $temp_file2
       set temp_file2 [open /home/vsduser/Desktop/tcl_workshop/temp/tr5 r]
      # puts "\n entering while"
       while { [gets $temp_file2 line] != -1 } {
             set temp4 $line
             set temp3 [regexp -all -inline {\w+[^(\[\d*:\d*\])]} $line]
             set l_temp4 [llength $temp4 ]
             set l_temp3 [llength $temp3 ]
             if {$l_temp3 == 3 } {
                set temp2($i1) [regexp -all -inline {\w+[^\s]} [lindex $temp3 2]]
                if { $l_temp4 > 2 } {
                   set out_ports($i1) [concat $temp2($i1)\*]    
                   } else {
                           set out_ports($i1) $temp2($i1)
                          }             
                for { set j 0 } { $j < [array size out_ports_list] } { incr j } {
                                  set temp1 $out_ports_list($j)
                                  if { $temp2($i1) == $temp1 } {
                                     set out_port_row($i1) [expr { $j + $i }] 
                                     }
                    }
                   } 
               if {$l_temp3 == 2 } {
                          set temp2($i1) [regexp -all -inline {\w+[^\s]} [lindex $temp3 1]]      
                           if { $l_temp4 > 2 } {
                               set out_ports($i1) [concat $temp2($i1)\*]    
                              } else {
                                      set out_ports($i1) $temp2($i1)
                                     }
                          for { set j 0 } { $j < [array size out_ports_list] } { incr j } { 
                                          set temp1 $out_ports_list($j)
                                          if { $temp2($i1) == $temp1 } {
                                              set out_port_row($i1)  [expr { $j + $i }]
                                              } 
                                        

                                      }                                             
                                  }   
                          set i1 [expr { $i1 + 1 }]
                          }
       
       close $temp_file2


set output_early_rise_delay_start [lindex [ lindex [constraints search rect $clock_start_col $out_port_start [ expr {$const_file_num_cols - 1 }] [ expr {$const_file_num_rows - 1 }] early_rise_delay ] 0] 0]
set output_early_fall_delay_start [lindex [ lindex [constraints search rect $clock_start_col $out_port_start [ expr {$const_file_num_cols - 1 }] [ expr {$const_file_num_rows - 1 }] early_fall_delay ] 0] 0]
set output_late_rise_delay_start [lindex [ lindex [constraints search rect $clock_start_col $out_port_start [ expr {$const_file_num_cols - 1 }] [ expr {$const_file_num_rows - 1 }] late_rise_delay ] 0] 0]
set output_late_fall_delay_start [lindex [ lindex [constraints search rect $clock_start_col $out_port_start [ expr {$const_file_num_cols - 1 }] [ expr {$const_file_num_rows - 1 }] late_fall_delay ] 0] 0]
set output_load_start [lindex [lindex [constraints search rect $clock_start_col $out_port_start [expr {$const_file_num_cols -1 }] [expr {$const_file_num_rows - 1}] load] 0] 0]

set related_clock 5
set i1 2
set i_end  [expr { $const_file_num_rows - $out_port_start - 2 } ]
puts "\n Info: Writing to sdc file - output constraints "
while { $i1 < $i_end } {
      set j1 $out_port_row($i1)
      set CL1 [constraints get cell $related_clock $j1]
  puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks $CL1\] -min -rise -source_latency_included [constraints get cell $output_early_rise_delay_start $j1] \[get_ports $out_ports($i1)\]"
  puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks $CL1\] -min -fall -source_latency_included [constraints get cell $output_early_fall_delay_start $j1] \[get_ports $out_ports($i1)\]" 
  puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks $CL1\] -max -rise -source_latency_included [constraints get cell $output_late_rise_delay_start $j1] \[get_ports $out_ports($i1)\]"
  puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks $CL1\] -max -fall -source_latency_included [constraints get cell $output_late_fall_delay_start $j1] \[get_ports $out_ports($i1)\]"
  puts -nonewline $sdc_file "\nset_load [constraints get cell $output_load_start $j1] \[get_ports $out_ports($i1)\] " 

      set i1 [ expr { $i1 + 1 } ]
}

close $sdc_file

puts "\n Info : SDC file created in $OutputDirectory/$DesignName.sdc "



########################################################
#                   PART 2
########################################################

puts "\n Info : Creating hierarchy check script to be used by Yosys"

set data " read_liberty -lib -ignore_miss_dir -setattr blackblox ${LateLibraryPath}"
set filename "$DesignName.hier.ys"
set fileID [open $OutputDirectory/$filename w ]
puts -nonewline $fileID $data

set netlist [glob -dir $NetlistDirectory *.v]
foreach f $netlist {
                   set data $f
                   puts -nonewline $fileID "\n read_verilog $f"
}

puts -nonewline $fileID "\n hierarchy -check"
close $fileID

puts "\nclose $OutputDirectory/$filename \n"
puts "\n Checking Hierarchy................."
set my_err [catch { exec yosys -s $OutputDirectory/$DesignName.hier.ys >& $OutputDirectory/$DesignName.hierarchy_check.log} msg]
puts "\n Hierarchy error is $my_err"

if { $my_err } {
   set filename "$OutputDirectory/$DesignName.hierarchy_check.log"
   set pattern {refernced in module}
   set count 0
   set fid [open $filename r]
   while {[gets $fid line ] != -1 } {
         incr count [regexp -all -- $pattern $line]
         if {[regexp -all -- $pattern $line]} {
            puts "\n Error : module [lindex $line 2] is not a part of design $DesignName. Please correct RTL in the path '$NetlsitDirectory' "
            puts "\n Heirarchical check FAIL"
            }
         }
        close $fid
} else {
       puts "\n Heirarchical check PASS"
       }
puts "\n Info : Please find heirarchy check details in [file normalize $OutputDirectory/$DesignName.hierarchy_check.log] for more info "


# SYNTHESIS SCRIPT
set enable_prelayout_timing 1
puts "\n Info : Creating main synthesis script to be used by Yosys"
set data "read_liberty -lib -ignore_miss_dir -setattr blackblox ${LateLibraryPath}"
set filename "$DesignName.ys"
set fileID [open $OutputDirectory/$filename w ]
puts -nonewline $fileID $data

set netlist [glob -dir $NetlistDirectory *.v]
foreach f $netlist {
                   set data $f
                   puts -nonewline $fileID "\nread_verilog $f"
}

puts -nonewline $fileID "\nhierarchy -top $DesignName"
puts -nonewline $fileID "\nsynth -top $DesignName"
puts -nonewline $fileID "\nsplitnets -ports -format __\ndfflibmap -liberty $LateLibraryPath\nopt"
puts -nonewline $fileID "\nabc -liberty $LateLibraryPath"
puts -nonewline $fileID "\nflatten"
puts -nonewline $fileID "\nclean -purge\niopadmap -outpad BUFX2 A:Y -bits\nopt\nclean"
puts -nonewline $fileID "\nwrite_verilog $OutputDirectory/$DesignName.synth.v"
close $fileID
puts "\n Info : Synthesis script created and can be accessed from path $OutputDirectory/$DesignName.ys"

set my_err [catch { exec yosys -s $OutputDirectory/$DesignName.ys >& $OutputDirectory/$DesignName.synthesis.log} msg]
puts "\n Synthesis error is $my_err"

if { $my_err } {
   puts "\nError : Synthesis FAILed due to errors. Please refer to $OutputDirectory/$DesignName.synthesis.log for more information."
   exit
   } else {
          puts "\n Synthesis PASS"
          }

   puts "\n Info : Please refer to $OutputDirectory/$DesignName.synthesis.log for more information."

#EDITING OUTPUT LOG FOR OPENTIMER

set fileID [open /tmp/1 w]
puts -nonewline $fileID [exec grep -v -w "*" $OutputDirectory/$DesignName.synth.v]
close $fileID

set output_file [open $OutputDirectory/$DesignName.final.synth.v w]

set filename "/tmp/1"
set fid [open $filename r]
while {[gets $fid line] != -1} {
      puts -nonewline $output_file [string map {"\\" ""} $line]
      puts -nonewline $output_file "\n" 
}

close $fid
close $output_file

puts "\n Info : Please find the synthesised netlist for $DesignName in the below path."
puts "\n $OutputDirectory/$DesignName.final.synth.v"



#PROCS 
puts "\n Info : Timing Analysis Started............."
puts "\n Info : Initializing threads, libraries, sdc, verilog netlist path "

source /home/vsduser/Desktop/tcl_workshop/procs/reopenStdout.proc
source /home/vsduser/Desktop/tcl_workshop/procs/set_multi_cpu_usage.proc
reopenStdout $OutputDirectory/$DesignName.conf
set_multi_cpu_usage -localCPU 4

source /home/vsduser/Desktop/tcl_workshop/read_lib.proc
read_lib -early /home/vsduser/Desktop/tcl_workshop/lib/osu018_stdcells_Early.lib

read_lib -late /home/vsduser/Desktop/tcl_workshop/lib/osu018_stdcells_Late.lib

source /home/vsduser/Desktop/tcl_workshop/procs/read_verilog.proc
read_verilog $OutputDirectory/$DesignName.final.synth.v

source /home/vsduser/Desktop/tcl_workshop/procs/read_sdc.proc
read_sdc $OutputDirectory/$DesignName.sdc
reopenStdout /dev/tty


if {$enable_prelayout_timing == 1} {
   puts "\n Info : enable_prelayout_timing is $enable_prelayout_timing. Enabling zero-wire load parasitics"
   set spef_file [open $OutputDirectory/$DesignName.spef w]
puts $spef_file "*SPEF \"IEEE 1481 -1998\" "
puts $spef_file "DESIGN \"$DesignName\" "
puts $spef_file "DATE \"Tue Sep 25 11:51:50 2012\""
puts $spef_file "VENDOR\"TAU 2015 Contest\" "
puts $spef_file "PROGRAM \"Benchmark Parasitic Generator\" "
puts $spef_file "VERSION \"0.0\""
puts $spef_file "DESIGN_FLOW\"NETLIST_TYPE_VERILOG\""
puts $spef_file "DIVIDER /"
puts $spef_file "DELIMITER : "
puts $spef_file "BUS_DELIMITER [ ]"
puts $spef_file "*T_UNIT 1 PS"
puts $spef_file "*C_UNIT 1 FF"
puts $spef_file "*R_UNIT 1 KOHM"
puts $spef_file "*L_UNIT 1 UH"
  }
close $spef_file


set conf_file [open $OutputDirectory/$DesignName.conf a]
puts $conf_file "set_spef_fpath $OutputDirectory/$DesignName.spef"
puts $conf_file "init_timer "
puts $conf_file "report_timer "
puts $conf_file "report_wns "
puts $conf_file "report_worst_paths -numPaths 10000 "
close $conf_file


##################QOR
#set conf_file1 [open $OutputDirectory/$DesignName.conf r]
#set result_file [open $OutputDirectory/$DesignName.results w]
set time_elapsed_us [time {exec /home/vsduser/OpenTimer-1.0.5/bin/OpenTimer < $OutputDirectory/$DesignName.conf >& $OutputDirectory/$DesignName.results} ]
set time_elapsed_s "[expr {[lindex $time_elapsed_us 0]/1000000}]sec"
puts "\n Info : STA finished in $time_elapsed_s seconds"
puts "\n Info : Refer to $OutputDirectory/$DesignName.results for warnings and errors"
#close $conf_file1
#lose $result_file

##########WORST NEGATIVE SLACK

set worst_RAT_slack "-"
set report_file [open $OutputDirectory/$DesignName.results r]
set pattern {RAT}
while {[gets $report_file line] != -1} {
       if {[regexp $pattern $line]} {
           set worst_RAT_slack "[expr {[lindex $line 3]/1000}]ns"
           break
          } else {
                  continue
                 }


}
close $report_file

set report_file [open $OutputDirectory/$DesignName.results r]
set count 0
while {[gets $report_file line] != -1} {
      incr count [regexp -all -- $pattern $line]
      }

set Number_output_violations $count
close $report_file

######SETUP

set worst_negative_setup_slack "-"
set report_file [open $OutputDirectory/$DesignName.results r]
set pattern {Setup}
while {[gets $report_file line] != -1} {
       if {[regexp $pattern $line]} {
           set worst_negative_setup_slack "[expr {[lindex $line 3]/1000}]ns"
           break
          } else {
                  continue
                 }


}
close $report_file

set report_file [open $OutputDirectory/$DesignName.results r]
set count 0
while {[gets $report_file line] != -1} {
      incr count [regexp -all -- $pattern $line]
      }

set Number_setup_violations $count
close $report_file

############HOLD

set worst_negative_hold_slack "-"
set report_file [open $OutputDirectory/$DesignName.results r]
set pattern {Hold}
while {[gets $report_file line] != -1} {
       if {[regexp $pattern $line]} {
           set worst_negative_hold_slack "[expr {[lindex $line 3]/1000}]ns"
           break
          } else {
                  continue
                 }

}
close $report_file

set report_file [open $OutputDirectory/$DesignName.results r]
set count 0
while {[gets $report_file line] != -1} {
      incr count [regexp -all -- $pattern $line]
      }

set Number_hold_violations $count
close $report_file

###########GATES

set report_file [open $OutputDirectory/$DesignName.results r]
set pattern {Num of gates}
while {[gets $report_file line] != -1} {
       if {[regexp $pattern $line]} {
           set Instance_count [lindex [join $line " "] 4]
           break
          } else {
                  continue
                 }

}
close $report_file


puts "                                                 ******PRE-LAYOUT TIMING RESULTS******                                        "
set formatStr {%15s%15s%15s%15s%15s%15s%15s%15s%15s}

puts [format $formatStr "-----------" "-------" "--------------" "---------" "---------" "--------" "--------" "-------" "-------"]
puts [format $formatStr "Design Name" "Runtime" "Instance Count" "WNS Setup" "FEP Setup" "WNS Hold" "FEP Hold" "WNS RAT" "FEP RAT" ]
puts [format $formatStr "-----------" "-------" "--------------" "---------" "---------" "--------" "--------" "-------" "-------"]

foreach design_name $DesignName runtime $time_elapsed_us instance_count $Instance_count wns_setup $worst_negative_setup_slack fep_setup $Number_setup_violations wns_hold $worst_negative_hold_slack fep_hold $Number_hold_violations wns_rat $worst_RAT_slack fep_rat $Number_output_violations {
        puts [format $formatStr $design_name $runtime $instance_count $wns_setup $fep_setup $wns_hold $fep_hold $wns_rat $fep_rat ]
} 

puts [format $formatStr "-----------" "-------" "--------------" "---------" "---------" "--------" "--------" "-------" "-------"]
