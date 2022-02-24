# TCL File Generated by Component Editor 18.1
# Sun Jan 03 16:46:14 CET 2021
# DO NOT MODIFY


# 
# camera_module "camera_module" v1.1
#  2021.01.03.16:46:14
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module camera_module
# 
set_module_property DESCRIPTION ""
set_module_property NAME camera_module
set_module_property VERSION 1.1
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME camera_module
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL camera_module
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file acq.vhd VHDL PATH hdl/acq.vhd
add_fileset_file camera_module.vhd VHDL PATH hdl/camera_module.vhd TOP_LEVEL_FILE
add_fileset_file debay.vhd VHDL PATH hdl/debay.vhd
add_fileset_file dma.vhd VHDL PATH hdl/dma.vhd
add_fileset_file end_fifo.vhd VHDL PATH hdl/end_fifo.vhd
add_fileset_file global_controller.vhd VHDL PATH hdl/global_controller.vhd
add_fileset_file row_fifo.vhd VHDL PATH hdl/row_fifo.vhd


# 
# parameters
# 
add_parameter screen_width NATURAL 640
set_parameter_property screen_width DEFAULT_VALUE 640
set_parameter_property screen_width DISPLAY_NAME screen_width
set_parameter_property screen_width TYPE NATURAL
set_parameter_property screen_width UNITS None
set_parameter_property screen_width ALLOWED_RANGES 0:2147483647
set_parameter_property screen_width HDL_PARAMETER true
add_parameter screen_height NATURAL 480
set_parameter_property screen_height DEFAULT_VALUE 480
set_parameter_property screen_height DISPLAY_NAME screen_height
set_parameter_property screen_height TYPE NATURAL
set_parameter_property screen_height UNITS None
set_parameter_property screen_height ALLOWED_RANGES 0:2147483647
set_parameter_property screen_height HDL_PARAMETER true
add_parameter burst_count NATURAL 10
set_parameter_property burst_count DEFAULT_VALUE 10
set_parameter_property burst_count DISPLAY_NAME burst_count
set_parameter_property burst_count TYPE NATURAL
set_parameter_property burst_count UNITS None
set_parameter_property burst_count ALLOWED_RANGES 0:2147483647
set_parameter_property burst_count HDL_PARAMETER true
add_parameter burst_bitwidth NATURAL 4
set_parameter_property burst_bitwidth DEFAULT_VALUE 4
set_parameter_property burst_bitwidth DISPLAY_NAME burst_bitwidth
set_parameter_property burst_bitwidth TYPE NATURAL
set_parameter_property burst_bitwidth UNITS None
set_parameter_property burst_bitwidth ALLOWED_RANGES 0:2147483647
set_parameter_property burst_bitwidth HDL_PARAMETER true


# 
# display items
# 


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 50000000
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clk clk Input 1


# 
# connection point avalon_slave
# 
add_interface avalon_slave avalon end
set_interface_property avalon_slave addressUnits SYMBOLS
set_interface_property avalon_slave associatedClock clock
set_interface_property avalon_slave associatedReset reset_sink
set_interface_property avalon_slave bitsPerSymbol 8
set_interface_property avalon_slave burstOnBurstBoundariesOnly false
set_interface_property avalon_slave burstcountUnits SYMBOLS
set_interface_property avalon_slave explicitAddressSpan 0
set_interface_property avalon_slave holdTime 0
set_interface_property avalon_slave linewrapBursts false
set_interface_property avalon_slave maximumPendingReadTransactions 0
set_interface_property avalon_slave maximumPendingWriteTransactions 0
set_interface_property avalon_slave readLatency 0
set_interface_property avalon_slave readWaitTime 1
set_interface_property avalon_slave setupTime 0
set_interface_property avalon_slave timingUnits Cycles
set_interface_property avalon_slave writeWaitTime 0
set_interface_property avalon_slave ENABLED true
set_interface_property avalon_slave EXPORT_OF ""
set_interface_property avalon_slave PORT_NAME_MAP ""
set_interface_property avalon_slave CMSIS_SVD_VARIABLES ""
set_interface_property avalon_slave SVD_ADDRESS_GROUP ""

add_interface_port avalon_slave AS_address address Input 3
add_interface_port avalon_slave AS_write write Input 1
add_interface_port avalon_slave AS_read read Input 1
add_interface_port avalon_slave AS_writedata writedata Input 32
add_interface_port avalon_slave AS_readdata readdata Output 32
set_interface_assignment avalon_slave embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave embeddedsw.configuration.isPrintableDevice 0


# 
# connection point avalon_master
# 
add_interface avalon_master avalon start
set_interface_property avalon_master addressUnits SYMBOLS
set_interface_property avalon_master associatedClock clock
set_interface_property avalon_master associatedReset reset_sink
set_interface_property avalon_master bitsPerSymbol 8
set_interface_property avalon_master burstOnBurstBoundariesOnly false
set_interface_property avalon_master burstcountUnits WORDS
set_interface_property avalon_master doStreamReads false
set_interface_property avalon_master doStreamWrites false
set_interface_property avalon_master holdTime 0
set_interface_property avalon_master linewrapBursts false
set_interface_property avalon_master maximumPendingReadTransactions 0
set_interface_property avalon_master maximumPendingWriteTransactions 0
set_interface_property avalon_master readLatency 0
set_interface_property avalon_master readWaitTime 1
set_interface_property avalon_master setupTime 0
set_interface_property avalon_master timingUnits Cycles
set_interface_property avalon_master writeWaitTime 0
set_interface_property avalon_master ENABLED true
set_interface_property avalon_master EXPORT_OF ""
set_interface_property avalon_master PORT_NAME_MAP ""
set_interface_property avalon_master CMSIS_SVD_VARIABLES ""
set_interface_property avalon_master SVD_ADDRESS_GROUP ""

add_interface_port avalon_master AM_address address Output 32
add_interface_port avalon_master AM_dataWrite writedata Output 32
add_interface_port avalon_master AM_burstCount burstcount Output burst_bitwidth
add_interface_port avalon_master AM_write write Output 1
add_interface_port avalon_master AM_waitRequest waitrequest Input 1


# 
# connection point reset_sink
# 
add_interface reset_sink reset end
set_interface_property reset_sink associatedClock clock
set_interface_property reset_sink synchronousEdges DEASSERT
set_interface_property reset_sink ENABLED true
set_interface_property reset_sink EXPORT_OF ""
set_interface_property reset_sink PORT_NAME_MAP ""
set_interface_property reset_sink CMSIS_SVD_VARIABLES ""
set_interface_property reset_sink SVD_ADDRESS_GROUP ""

add_interface_port reset_sink rst_n reset_n Input 1


# 
# connection point camera_pixclk
# 
add_interface camera_pixclk clock end
set_interface_property camera_pixclk clockRate 50000000
set_interface_property camera_pixclk ENABLED true
set_interface_property camera_pixclk EXPORT_OF ""
set_interface_property camera_pixclk PORT_NAME_MAP ""
set_interface_property camera_pixclk CMSIS_SVD_VARIABLES ""
set_interface_property camera_pixclk SVD_ADDRESS_GROUP ""

add_interface_port camera_pixclk camera_pixclk clk Input 1


# 
# connection point camera
# 
add_interface camera conduit end
set_interface_property camera associatedClock clock
set_interface_property camera associatedReset ""
set_interface_property camera ENABLED true
set_interface_property camera EXPORT_OF ""
set_interface_property camera PORT_NAME_MAP ""
set_interface_property camera CMSIS_SVD_VARIABLES ""
set_interface_property camera SVD_ADDRESS_GROUP ""

add_interface_port camera camera_frame_valid camera_frame_valid Input 1
add_interface_port camera camera_line_valid camera_line_valid Input 1
add_interface_port camera camera_pixel_data camera_pixel_data Input 12

