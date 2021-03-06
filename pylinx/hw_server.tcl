# This file is part of cleye.
# 
#     Cleye is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
# 
#     Foobar is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with Foobar.  If not, see <https://www.gnu.org/licenses/>.

# This TCL script helps to enhance a multi-gig serial link using Xilinx FPGAs.


if {![info exists __IBERT_UTIL_SOURCED__]} {
    set __IBERT_UTIL_SOURCED__ 1
}


proc init { {hw_server_url "localhost:3121"} } {
    puts "Opening hardware manager"
    open_hw

    puts "Connect to hardware server"
    # Run quietly to prevent errors when it already connected.
    connect_hw_server -url $hw_server_url -quiet
}


proc fetch_devices { } {

    set allDevices ""
    
    puts "Getting hardware targets (ie. blasters)"
    set targets [get_hw_target]

    # Setting XXside (TX/RX) target
    if { [llength $targets] < 1 } {
        puts "No target blaster found. Please connect one to your machine"
        return -1
    } else {
        for {set i 0} {$i < [llength $targets]} {incr i} {
            set trg [lindex $targets $i]
            close_hw_target -quiet
            puts "Opening target for side: $trg"
            # Run quietly to prevent errors when it already opened.
            open_hw_target $trg -quiet
            
            set devices [get_hw_devices]
            for {set j 0} {$j < [llength $devices]} {incr j} {
                set dev [lindex $devices $j]
                # current_hw_device $dev
                lappend allDevices [list $trg $dev]
            }
        }
    }
    puts $allDevices    
    return $allDevices
}


proc set_device { target device } {
    close_hw_target -quiet
    puts "Opening target: $target   $device"
    # Run quietly to prevent errors when it already opened.
    open_hw_target $target -quiet
    current_hw_device $device -quiet
    refresh_hw_device -update_hw_probes false [lindex $device 1]
}


proc choose_device { allDevices side } {
    # Setting XXside (TX/RX) target
    if { [llength $allDevices] < 1 } {
        puts "No devices found. Please connect one and power up."
        return -1
    } elseif { [llength $allDevices] == 1 } {
        return [lindex $allDevices 0]
    } else {        # if { [llength allDevices] > 1 } 
        puts "Please choose a target for $side"
        for {set i 0} {$i < [llength $allDevices]} {incr i} {
            set trg [lindex $allDevices $i]
            puts " [$i] $trg"
        }
        set c [gets stdin]
        return [lindex $allDevices $c]
    }
}


proc fetch_sio { side } {
    set sios [get_hw_sio_gts]

    # Setting Serial Links
    if { [llength $sios] < 1 } {
        puts "ERR: No sio (Serial I/O) found in this device."
        return -1
    } elseif { [llength $sios] == 1 } {
        return [lindex $sios 0]
    } else {        # if { [llength allDevices] > 1 } 
        puts "Please choose sio for $side"
        for {set i 0} {$i < [llength $sios]} {incr i} {
            set sio [lindex $sios $i]
            puts " [$i] $sio"
        }
        set c [gets stdin]
        
        puts $c
        set retVal [lindex $sios $c]
        puts $retVal
        return $retVal
    }
}


proc run_scan { scanFile {hincr 16} {vincr 16} {scanType "2d_full_eye"} {linkName "*"} {description {Scan 000}} } {
    set xil_newScan [create_hw_sio_scan -description $description $scanType  [lindex [get_hw_sio_links $linkName] 0 ]]
    set_property HORIZONTAL_INCREMENT {$hincr} [get_hw_sio_scans $xil_newScan]
    if { $scanType == "2d_full_eye" } {
        set_property VERTICAL_INCREMENT   {$vincr} [get_hw_sio_scans $xil_newScan]
    }
    run_hw_sio_scan [get_hw_sio_scans $xil_newScan]

    puts "Wait to finish..."
    wait_on_hw_sio_scan $xil_newScan

    write_hw_sio_scan $scanFile [get_hw_sio_scans $xil_newScan] -force
}


proc create_link { sio } {
    puts "############### create_link ###############"
    puts "#  sio          $sio  #"
    puts "##################################################"

    remove_hw_sio_link [  get_hw_sio_links ]
    set linkName [create_hw_sio_link -description {Link 0} [lindex [get_hw_sio_txs $sio*] 0] [lindex [get_hw_sio_rxs $sio*] 0] ]
    
    return $linkName
}



