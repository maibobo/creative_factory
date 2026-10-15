# pg078-axi-bram-ctrl

- Category: `foundation`
- Source: `F:\Xiliinx文档\pg078-axi-bram-ctrl.pdf`
- SHA-256: `4c5b322d4dd0f839520a3117750fabd32972dcd421a1823e3aeaa560eceb4095`
- Extractor: `pypdf:85pages`
- Tags: `axi, bram`
- Duplicate sources:
  - none

## Page 1

AXI Block RAM (BRAM)
Controller v4.0
LogiCORE IP Product Guide
Vivado Design Suite
PG078 October 5, 2016

## Page 2

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 2
PG078 October 5, 2016
Table of Contents
IP Facts
Chapter 1: Overview
Feature Summary. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  8
Applications . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  10
Licensing and Ordering Information . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  11
Chapter 2: Product Specification
Standards . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  12
Performance. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  13
Resource Utilization. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  14
Port Descriptions . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  14
Register Space  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  22
Chapter 3: Designin g with the Core
General Design Guidelines  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  34
Clocking. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  69
Resets . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  69
Chapter 4: Design Flow Steps
Customizing and Generating the Core . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  . .  70
Constraining the Core  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  73
Simulation  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  74
Synthesis and Implementation . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  74
Chapter 5: Test Bench
Messages and Warnings  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  76
Chapter 6: Example Design
Appendix A: Migrating and Upgrading
Migrating to the Vivado Design Suite. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  78
Upgrading in the Vivado Design Suite  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  78
Send Feedback

## Page 3

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 3
PG078 October 5, 2016
Appendix B: Verification, Comp liance, and Interoperability
Simulation  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  79
Appendix C: Debugging
Finding Help on Xilinx.com  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  80
Debug Tools . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  . . . . . . . . . . .  81
Hardware Debug  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  82
Interface Debug . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  82
Appendix D: Additional Reso urces and Legal Notices
Xilinx Resources . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  83
References  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  83
Revision History . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  83
Please Read: Important Legal Notices  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  85
Send Feedback

## Page 4

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 4
PG078 October 5, 2016 Product Specification
Introduction
The LogiCORE™ IP AXI Block RAM (BRAM) Controller
is a soft IP core for us e with the Xilinx Vivado™
Design Suite. The core is designed as an AXI
Endpoint slave IP for integration with the AXI
interconnect and system master devices to
communicate to local block RAM. The core supports
both single and burst transactions to the block RAM
and is optimized for performance.
Features
• AXI4 (memory mapped) slave interface
• Low latency memory controller
• Separate read and write channel interfaces to
utilize dual port FPGA BRAM technology
• Option to arbitrate read and write data for use
with a single port of block RAM (in AXI4 and
AXI4LITE modes)
• Configurable BRAM data width (32-, 64-, 128-,
256-, 512-, and 1024-bit) (equals AXI slave port
data width size)
• Supports memory sizes up to a maximum of 2
MBytes (byte size 8 or 9)
• Supports INCR burst sizes up to 256 data
transfers, and WRAP bursts of 2, 4, 8, and 16
data beats
• Supports AXI narrow and unaligned write burst
transfers
• Compatible with Xilinx AXI Interconnect
• Supports two-deep address pipelining on each
read and write channel (order must be
maintained)
• Reduced footprint option for AXI4-Lite
• Supports of both Internal  and External modes of
BRAM block instances
• Optional ECC support with 32-, 64- or 128-bit
BRAM data widths
° AXI4-Lite register inte rface for status and
control of ECC operations
° Available interrupt output signal for ECC
error detection
• Hamming code and HSIAO algorithm support for 32,
64-bit BRAM data widths and HSIAO algorithm
support for 128-bit BRAM data width
IP Facts
LogiCORE IP Facts Table
Core Specifics
Supported
Device Family (1)
UltraScale+™,
UltraScale™,
Zynq ®-7000, 7 Series
Supported User
Interfaces AXI4, AXI4-Lite
Resources See Performance and Resource Utilization web page.
Provided with Core
Design Files VHDL
Example Design VHDL
Test Bench VHDL
Constraints File XDC
Simulation
Model Not Provided
Supported
S/W Driver
(2) Standalone
Tested Design Flows (3)
Design Entry Vivado Design Suite
Simulation For supported simulators, see the Xilinx Design
Tools: Release Notes Guide .
Synthesis Vivado Synthesis
Support
Provided by Xilinx at the Xilinx Support web page
Notes:
1. For a complete listing of supported devices, see the Vivado IP
Catalog.
2. Standalone driver details can be found in the SDK directory
(<install_directory>/SDK/<re lease>/data/embeddedsw/doc/
xilinx_drivers.htm). Linux OS and driver support information
is available from
the Xilinx Wiki page
.
3. For the supported versions of the tools, see the
Xilinx Design Tools: Release Notes Guide .
Send Feedback

## Page 5

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 5
PG078 October 5, 2016
Chapter 1
Overview
The AXI BRAM Controller core can be configured such that a single port to the BRAM block
or both ports to the BRAM block are utilized in either an AXI4 or AXI4-Lite controller
configuration. The AXI BRAM Controller IP can be configured with ECC functionality on the
datapath with an available external ECC regi ster set via a second AXI4-Lite control port
connection. Figure 1-1  and Figure 1-2  illustrate the top-level port connections and main
modules of the AXI BRAM Controller IP core . Several instantiation modes exist based on
interface connection and BRAM  module port utilization.
Figure 1-1  illustrates the connections when the AXI BRAM core is configured for an
AXI4-Lite mode to the BRAM block. A single port utilization to the BRAM block or a dual
port mode to the BRAM block can be  utilized (via a parameter setting). Figure 1-2  illustrates
the generated HDL core for supporting a AXI4 transaction interface. Single port usage to
the BRAM block can be configured over an e nhanced performance setting in a dual port
configuration.
All communication with AXI master devices is performed through a five channel AXI
interface. All write operations  are initiated on the Write Address Channel (AW) of the AXI
bus which specifies the type of write tr ansaction and the corresponding address
information. The Write Data Chan nel (W) communicates all write data for the single or burst
write operations. The Write Response Channel (B) is used as the handshaking or response
on the write operation.
On read operations, the Read Address Channe l (AR) communicates all address and control
information when the AXI master requests a read transfer. The AXI slave AXI BRAM
Controller IP responds on the Read Address Channel (AR) when the read operation can be
processed. When the read data is available to  send back to the AXI master, the Read Data
Channel (R) translates the data and status of the operation.
Send Feedback

## Page 6

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 6
PG078 October 5, 2016
Chapter 1: Overview
X-Ref Target - Figure 1-1
Figure 1-1: AXI4-Lite BRAM Controller Block Diagram
BRAM Block
(32-bit)
Port A for single
port only.
Port A & B for
dual port.
Optional
ECC
Lite
SM
AXI4-Lite
Interconnect
Write Address
Channel (AW)
Read Address
Channel (AR)
Write Data
Channel (W)
Read Data
Channel (R)
Write Response
Channel (B)
AXI4-Lite
Interconnect
PG078_c1_01_100813
ECC Register Set
(when C_ECC = 1)
Send Feedback

## Page 7

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 7
PG078 October 5, 2016
Chapter 1: Overview
ECC Description
You can enable ECC functionality in the IP co re. ECC allows an AXI master to detect and
correct single and detect double  bit errors in the BRAM block. The ECC status and control
are accessible via an additional AXI4-Lite cont rol interface on the AX I BRAM Controller core.
The ECC functionality can be enabled regardless of  dual or single port BRAM access. ECC is
enabled by configuring the design parameter, C_ ECC = 1. The ECC is available only when the
BRAM block is configured to a 32-, 64-, or 128-bit data width. Hamming code and HSIAO
algorithms are available for 32 and 64-bit BR AM data widths. For 128-bit BRAM data width
configurations, only HSIA O algorithm is available.
X-Ref Target - Figure 1-2
Figure 1-2: AXI4 BRAM Controller Block Diagram
Send Feedback

## Page 8

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 8
PG078 October 5, 2016
Chapter 1: Overview
Feature Summary
AXI4 Compatibility
The AXI BRAM Controller IP core is compliant  to the AMBA® AXI4 interface specifications
listed in References in Appendix D . The AXI BRAM Controller core includes these features
and exceptions:
• Support for 32-, 64-, 128-, 256-, 512-, and 1024-bit BRAM data widths
• Support for all AXI4 burst types and sizes
° AXI BRAM Controller handles FIXED bursts as  INCR type burst operations (no FIFO
burst type capability in the BRAM core)
° 16 beats for WRAP bursts
° 16 beats for FIXED bursts (treated as INCR burst type)
° 256 beats for INCR burst (without exclusive access)
• Support for burst sizes that are less than the width of the block RAM, for example,
narrow bursts. Data transfers are on different  byte lanes for each beat of the burst.
• AXI user signals are not necessary or supported
• The AXI BRAM Controller executes all tran sactions in order rega rdless of thread ID
value. No read reordering or write reordering is implemented.
• No caching or buffering functionality is  supported in the AXI BRAM Controller
AXI4-Lite Support
As per the AXI specification, the AXI BRAM  Controller supports a ll requests from an
AXI4-Lite master or AXI4-Lite Interconnect. Th e core can be configured for optimized FPGA
resource usage and BRAM port utilization in this mode. The AXI4-Lite mode only supports
a 32-bit AXI data bus width and single data be at transfers. No unaligned, narrow, or burst
types transfers are acknowledged by the AXI BRAM Controller IP core when configured in
this mode.
The AXI4-Lite IP core can be configured as du al port to the block RAM or configured to
arbitrate to a single port of block RAM at the AR and AW AXI inte rfaces. In this mode
(C_SINGLE_PORT_BRAM = 1), only one active operation is allowed at a time in the AXI BRAM
Controller core.
BRAM Interface
The BRAM interface is optimized to provide the highest performance interface to the FPGA
BRAM module. The dual-port capability of the Xilinx BRAM technology is utilized in this
Send Feedback

## Page 9

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 9
PG078 October 5, 2016
Chapter 1: Overview
design (when configured in dual-port mode). Port A of the BRAM module is designated as
the write port, while Port B of the BRAM module is designated as the read port.
For decreased size, the AXI BRAM Controller can be  configured in a single  port utilization to
the BRAM module. In this case, Port A is used  for both read and write operations to block
RAM. To reduce resource utilization and limit an y potential impacts to latency, any collisions
between the read and write ports of the block RAM are not detected by the AXI BRAM
Controller.
Systems using 7 series FPGAs that are generated in IP Integrator have a bank of block RAM
based on incorporating the RAMB18E1 or th e RAMB36E1. The block RAM is configured
using the Block Memory Generator IP core. The BRAM block instantiation is not included in
the AXI BRAM Controller IP in an IP Integrator system topology.
Instantiating the AXI BRAM Controller from the Vivado IP Catalog as a stand-alone IP core
requires the BRAM components be instanti ated separately with the Block Memory
Generator tool.
Supported Memory Size
The AXI BRAM Controller supports memory sizes up to a maximum of 2 MBytes (byte size 8
or 9). Table 1-1  shows the supported memory width and depth of AXI BRAM Controller.
The AXI BRAM Controller IP supports a minimum depth of 512 bytes. Any depth that is less
than 512 gets reset to 512 bytes.
ECC Support
ECC support can be enabled in the AXI BRAM Controller IP core by setting the design
parameter, C_ECC = 1. ECC is only supported for BRAM data widths of 32-, 64-, or 128-bit
configurations. More info rmation is described in ECC, page 61 .
Table 1-1: Support Memory Sizes
Data Width (Bits) Memory Depths (Words)
32 512,1k,2k,4k,8k,16k,32k,64k,128k,256k
64 512,1k,2k,4k,8k,16k,32k,64k,128k,256k
128 512,1k,2k,4k,8k,16k,32k,64k,128k,256k
256 512,1k,2k,4k,8k,16k,32k,64k,128k
512 512,1k,2k,4k,8k,16k,32k,64k
1024 512,1k,2k,4k,8k,16k,32k
2048 512,1k,2k,4k,8k,16k
Send Feedback

## Page 10

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 10
PG078 October 5, 2016
Chapter 1: Overview
Applications
The AXI BRAM Controller core is designed to integrate in an AXI system via the AXI
Interconnect topology to provide multiple masters access to block RAM. The AXI BRAM
Controller is an endpoint slave IP core to be attached as a slave AXI device on the AXI
Interconnect. The AXI Interconnect allows th e AXI BRAM Controller to be optimized for
latency and reduce the resources utilized. Th e AXI Interconnect perf orms any mismatching
of master data widths to the size of th e block RAM and the AXI BRAM Controller core.
TIP: Xilinx recommends that the AXI BRAM Controller’ s AXI4 interface data width match the native
width of the AXI Interconnect to which it is attached.
The AXI Interconnect performs the decode of the master address prior to presenting any
operation to the AXI BRAM Controller core. Additional information on the Xilinx AXI
Interconnect is available in References in Appendix D .
The connection of the AXI BRAM Controller core into an example system topology is shown
in Figure 1-3  for both single and dual port BRAM module configurations.
Send Feedback

## Page 11

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 11
PG078 October 5, 2016
Chapter 1: Overview
Licensing and Ordering Information
This Xilinx LogiCORE IP module is provided at no additional cost with the Xilinx Vivado
Design Suite under the terms of the Xilinx End User License .
Information about this and other Xilinx Lo giCORE IP modules is available at the Xilinx
Intellectual Property  page. For information on pricing and availability of other Xilinx
LogiCORE IP modules and tools, contact your local Xilinx sales representative .
X-Ref Target - Figure 1-3
Figure 1-3: AXI System Configuration
AXI BRAM
Controller
AXI
Slave
AXI
Master
AXI
Master
A
B
MS
S
M
Xilinx AXI
Interconnect
AXI BRAM
Controller
AXI-Lite
Master AMS
Xilinx
AXI
Interconnect
AXI
SlaveS
Bopen
Dual Port BRAM Configuration
Single Port BRAM Configuration
BRAM
(AXI4 w/ allowable
data widths) or
(AXI-Lite configured
as 32-bit)
(AXI4 w/ allowable
data widths) or
(AXI-Lite configured
as 32-bit)
BRAM
BRAM
PG078_c1_03_082612
Send Feedback

## Page 12

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 12
PG078 October 5, 2016
Chapter 2
Product Specification
Standards
The AXI BRAM Controller adheres to the AMBA® AXI4 Interface standard (see ARM® AMBA
AXI Protocol Specificatio n, Version 2.0 ARM IHI 002C ) [Ref 1] .
Send Feedback

## Page 13

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 13
PG078 October 5, 2016
Chapter 2: Product Specification
Performance
Maximum Frequencies
The target FPGA was filled with logic to  drive the LUT and BRAM utilization to
approximately 70% and the I/O utilization to  approximately 80%. Using the default tool
options and the slowest speed grade for the target FPGA, the resulting target F MAX
numbers are shown in Table 2-1 .
IMPORTANT: The maximum frequency values for UltraSca le™ architecture and Zynq™-7000 devices
are expected to be similar to Artix-7 and Kintex-7 device numbers.
X-Ref Target - Figure 2-1
Figure 2-1: Virtex-7 FPGA System with the AXI BRAM Controller as the DUT
AXI4-Lite Domain
MicroBlaze
Controller
AXI INTC
AXI GPIO
AXI UARTLite
AXI DDR
Memory
Controller
MDM
MicroBlaze
Domain
AXI4 Domain
Block RAM
Controller
D_LMB
I_LMB
(IC)
(DC)
Device Under
Test (DUT)
Memory
(DP)
PG078_c2_01_022213
LEDs
RS232
AXI CDMA
Virtex-7 FPGA
Memory
Mappped
Interconnect
(AXI4)
Control
Interface
Subset
Interconnect
(AXI4-Lite)
AXI-Lite
Block RAM
AXI Block RAM Block RAM
Block RAM
Send Feedback

## Page 14

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 14
PG078 October 5, 2016
Chapter 2: Product Specification
The target F MAX is influenced by the exact system and is provided for guidance. It is not a
guaranteed value across all systems.
Latency
There is single-clock latency between the channel valid and response signals.
Throughput
The nominal throughput is one read or write a ccess every clock cycle. The only exceptions
are as follows:
• When performing a byte or half wo rd write while the ECC is enabled.
• When an access is ongoing on anothe r port while using multiple ports.
Resource Utilization
For details about resource utilization, visit Performance and Resource Utilization  web page.
Port Descriptions
The AXI BRAM Controller I/O sign als are listed and described in Table 2-2 .
Table 2-1: System Performance
Family Speed Grade
Fmax (MHz)
AXI4 AXI4-Lite
Virtex-7
-1
200 180
Kintex-7 200 180
Artix-7 150 120
Virtex-7
-2
240 200
Kintex-7 240 200
Artix-7 180 140
Virtex-7
-3
280 220
Kintex-7 280 220
Artix-7 200 160
Send Feedback

## Page 15

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 15
PG078 October 5, 2016
Chapter 2: Product Specification
Table 2-2: I/O Signal Description
Signal Name Interface Signal
Type
Init
Status Description
Global Signals
s_axi_aclk S_AXI,
S_AXI_CTRL I AXI Bus Clock.
s_axi_aresetn S_AXI,
S_AXI_CTRL I AXI active-Low reset.
ecc_interrupt O ‘0’ Interrupt to signal ECC error condition: Signal
unused when C_ECC = 0.
ecc_ue O ‘0’
ECC uncorrectable error output flag: The
behavior of this flag is described in ECC,
page 61 . Signal unused when C_ECC = 0.
AXI Write Address Channel Signals (AW)
s_axi_awid
[c_s_axi_id_width-1:0]
S_AXI
(AW) I AXI address write ID. Only generated when
the ID width is set greater than 0.
s_axi_awaddr
[c_s_axi_addr_width-1:0]
S_AXI
(AW) I AXI write address
s_axi_awlen [7:0] S_AXI
(AW) I
AXI address write burst length: The burst
length gives the exact number of transfers in
a burst. Determines the number of data
transfers associated with the write address.
s_axi_awsize [2:0] S_AXI
(AW) I
AXI address write burst si ze: Indicates the size
of each transfer in the burst. Byte lane strobes
determine exactly which byte lanes to update.
s_axi_awburst [1:0] S_AXI
(AW) I
AXI address write burst type: Indicates the
burst type, coupled with the size information,
details how the addre ss for each transfer
within the burst is calculated.
s_axi_awlock [2:0] S_AXI
(AW) I
AXI write address lock signal: Provides
information about atomic operation transfers
and barrier transactions.
Unused at this time, but listed here for future
implementation and support.
s_axi_awcache [4:0] S_AXI
(AW) I
AXI write address ca che control signal:
Provides information about bufferable,
cacheable, and allocation attributes.
Unused at this time, but listed here for future
implementation and support.
s_axi_awprot [3:0] S_AXI
(AW) I
AXI write address protection signal.
Unused at this time, but listed here for future
implementation and support.
Send Feedback

## Page 16

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 16
PG078 October 5, 2016
Chapter 2: Product Specification
s_axi_awvalid S_AXI
(AW) I
AXI write address valid . Indicates that the
valid write address and control information is
available.
‘0’ = address and control NOT available
‘1’ = address and control data is available
The address and contro l information remains
stable until the acknowledge signal
(S_AXI_AWREADY) is asserted (active-High).
s_axi_awready S_AXI
(AW) O‘ 0 ’
AXI write address ready. Indicates that the AXI
BRAM Controller has accepted the write
channel address and associated control
signals.
‘0’ = AXI BRAM Controller not ready
‘1’ = AXI BRAM Controller is ready
AXI Write Data Channel Signals (W)
s_axi_wdata
[c_s_axi_data_width-1:0]
S_AXI
(W) I AXI write data.
s_axi_wstrb
[c_s_axi_data_width/8-1:0]
S_AXI
(W) I
AXI write data strobes.  Indicates which bytes
lanes to update in block RAM. Each byte
strobe correlates to a byte other write data
bus. WSTRB[n] corresponds to WDATA[(8*n) +
7:(8*n)].
s_axi_wlast S_AXI
(W) I AXI write data last sign al. Indicates the last
transfer in a write burst.
s_axi_wvalid S_AXI
(W) I
AXI write data valid. Indicates that valid write
data and strobes are available on the write
data channel.
‘0’ = write data and strobes unavailable
‘1’ = write data and strobes available and
valid
s_axi_wready S_AXI
(W) O‘ 0 ’
AXI write data ready. indicates that the AXI
BRAM Controller is read y to accept the write
data and strobes.
‘0’ = AXI BRAM Controller not ready
‘1’ = AXI BRAM Controller is ready
AXI Write Response Channel Signals (B)
s_axi_bid
[c_s_axi_id_width-1:0]
S_AXI
(B) OZ e r o s
AXI write data response  ID. Identification tab
of the write response. BID matches the AWID
value of the write transaction to which the AXI
BRAM Controller is responding. Only
generated when the ID width is set greater
than 0.
Table 2-2: I/O Signal Description (Cont’d)
Signal Name Interface Signal
Type
Init
Status Description
Send Feedback

## Page 17

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 17
PG078 October 5, 2016
Chapter 2: Product Specification
s_axi_bresp [1:0] S_AXI
(B) OZ e r o s
AXI write response. Indica tes the status of the
write transaction. The supported responses of
the AXI BRAM Controller are OKAY (SLVERR
and EXOKAY to be su pported in a future
release).
s_axi_bvalid S_AXI
(B) O‘ 0 ’
AXI write response valid . Asserted by the AXI
BRAM Controller to indicate a valid write
response is available.
‘0’ = write respon se not available
‘1’ = write response is available
s_axi_bready S_AXI
(B) I
Write response ready. Indicates the master
requesting the write operation can accept the
response information.
‘0’ = AXI master not ready
‘1’ = AXI master is ready
AXI Read Address Channel Signals (AR)
s_axi_arid
[c_s_axi_id_width-1:0]
S_AXI
(AR) I
AXI address read ID. Identification tag for the
read address group of si gnals. Only generated
when the ID width is set greater than 0.
s_axi_araddr
[c_s_axi_addr_width-1:0]
S_AXI
(AR) I
AXI read address. The address provides the
initial address of the re ad burst transaction.
Only the start address of the burst is provided
and the control signals indicate the address
detail and calculation fo r each transfer in the
burst.
s_axi_arlen [7:0] S_AXI
(AR) I
AXI address read burst length. The burst
length gives the exact number of transfers in
a burst. Determines the number of data
transfers associated with the read address.
s_axi_arsize [2:0] S_AXI
(AR) I AXI address read burst si ze. Indicates the size
of each transfer in the burst.
s_axi_arburst [1:0] S_AXI
(AR) I
AXI address read burst type. Indicates the
burst type, coupled with the size information,
details how the addre ss for each transfer
within the burst is calculated.
s_axi_arlock [2:0] S_AXI
(AR) I
AXI read address lock signal. Provides
information about atomic  operation transfers.
Unused at this time, but listed here for future
implementation and support.
s_axi_arcache [4:0] S_AXI
(AR) I
AXI read address cache control signal.
Provides information about bufferable,
cacheable, and allocation attributes.
Unused at this time, but listed here for future
implementation and support.
Table 2-2: I/O Signal Description (Cont’d)
Signal Name Interface Signal
Type
Init
Status Description
Send Feedback

## Page 18

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 18
PG078 October 5, 2016
Chapter 2: Product Specification
s_axi_arprot [3:0] S_AXI
(AR) I
AXI read address protection signal.
Unused at this time, but listed here for future
implementation and support.
s_axi_arvalid S_AXI
(AR) I
AXI read address valid. Indicates that the valid
read address and control information is
available.
‘0’ = address and control NOT available
‘1’ = address and control data is available
The address and contro l information remains
stable until the acknowledge signal
(S_AXI_ARREADY) is asserted (active high).
s_axi_arready S_AXI
(AR) O‘ 0 ’
AXI read address ready. Indicates that the AXI
BRAM Controller has accepted the read
channel address and associated control
signals.
‘0’ = AXI BRAM Controller not ready
‘1’ = AXI BRAM Controller is ready
AXI Read Data Channel Signals (R)
s_axi_rid
[c_s_axi_id_width-1:0]
S_AXI
(R) OZ e r o s
AXI read data response  ID. Identification tab
of the read response. RID matches the ARID
value of the read addre ss transaction to which
the AXI BRAM Controller is responding. Only
generated when the ID width is set greater
than 0.
s_axi_rdata
[c_s_axi_data_width-1:0]
S_AXI
(R) OZ e r o s AXI read data.
s_axi_rresp [1:0] S_AXI
(R) OZ e r o s
AXI read response. Indicates the status of the
read transfer. AXI BRAM Controller supports
the OKAY and SLVERR responses.
s_axi_rlast S_AXI
(R) O‘ 0 ’ AXI read data last sign al. Indicates the last
transfer in a read burst.
s_axi_rvalid S_AXI
(R) O‘ 0 ’
AXI read valid. Asserted by the AXI BRAM
Controller to indicate th e required read data
is available and the read transfer can
complete.
‘0’ = read data not available
‘1’ = read data is available
s_axi_rready S_AXI
(R) I
Read ready. Indicates the requesting master
can accept the read data and response
information.
‘0’ = AXI master not ready
‘1’ = AXI master is ready
AXI4-Lite Control Signals (Only Available when C_ecc = 1)
Table 2-2: I/O Signal Description (Cont’d)
Signal Name Interface Signal
Type
Init
Status Description
Send Feedback

## Page 19

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 19
PG078 October 5, 2016
Chapter 2: Product Specification
s_axi_ctrl_awaddr
[c_s_axi_ctrl_addr_
width-1:0]
S_AXI_CTRL
(AW) I
AXI4-Lite control write address
s_axi_ctrl_awvalid S_AXI_CTRL
(AW) I
AXI4-Lite control write address valid.
Indicates that the valid write address and
control information is available.
‘0’ = address and control NOT available
‘1’ = address and control data is available
The address and contro l information remains
stable until the acknowledge signal
(S_AXI_LITE_AWREADY) is asserted
(active-High).
s_axi_ctrl_awready S_AXI_CTRL
(AW) O‘ 0 ’
AXI4-Lite control write address ready.
Indicates that the AX I BRAM Controller has
accepted the write channel address and
associated control signals.
‘0’ = AXI BRAM Controller not ready
‘1’ = AXI BRAM Controller is ready
s_axi_ctrl_wdata
[c_s_axi_ctrl_data_
width-1:0]
S_AXI_CTRL
(W) I
AXI4-Lite control write data.
s_axi_ctrl_wvalid S_AXI_CTRL
(W) I
AXI4-Lite write data valid . Indicates that valid
write data and strobes are available on the
write data channel.
‘0’ = write data and strobes unavailable
‘1’ = write data and strobes available and
valid
s_axi_ctrl_wready S_AXI_CTRL
(W) O‘ 0 ’
AXI4-Lite control write data ready. indicates
that the AXI BRAM Controller is ready to
accept the write data and strobes.
‘0’ = AXI BRAM Controller not ready
‘1’ = AXI BRAM Controller is ready
s_axi_ctrl_bresp [1:0] S_AXI_CTRL
(B) OZ e r o s
AXI4-Lite control response. Indicates the
status of the write tran saction. The supported
responses of the AXI BRAM Controller are
OKAY & SLVERR.
s_axi_ctrl_bvalid S_AXI_CTRL
(B) O‘ 0 ’
AXI4-Lite control write response valid.
Asserted by the AXI BRAM Controller to
indicate a valid write response is available.
‘0’ = write respon se not available
‘1’ = write response is available
Table 2-2: I/O Signal Description (Cont’d)
Signal Name Interface Signal
Type
Init
Status Description
Send Feedback

## Page 20

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 20
PG078 October 5, 2016
Chapter 2: Product Specification
s_axi_ctrl_bready S_AXI_CTRL
(B) I
AXI4-Lite control writ e response ready.
Indicates the master requesting the write
operation can accept the response
information.
‘0’ = AXI master not ready
‘1’ = AXI master is ready
s_axi_ctrl_araddr
[c_s_axi_ctrl_addr_
width-1:0]
S_AXI_CTRL
(AR) I
AXI4-Lite control read address information.
s_axi_ctrl_arvalid S_AXI_CTRL
(AR) I
AXI4-Lite control read address valid. Indicates
that the valid read address and control
information is available.
‘0’ = address and control NOT available
‘1’ = address and control data is available
The address and contro l information remains
stable until the acknowledge signal
(S_AXI_LITE_ARREADY) is asserted
(active-High).
s_axi_ctrl_arready S_AXI_CTRL
(AR) O‘ 0 ’
AXI4-Lite control read address ready.
Indicates that the AX I BRAM Controller has
accepted the read channel address and
associated control signals.
‘0’ = AXI BRAM Controller not ready
‘1’ = AXI BRAM Controller is ready
s_axi_ctrl_rdata
[c_s_axi_ctrl_data_
width-1:0]
S_AXI_CTRL
(R) OZ e r o s
AXI4-Lite control read data.
s_axi_ctrl_rresp [1:0] S_AXI_CTRL
(R) OZ e r o s
AXI4-Lite control read response. Indicates the
status of the read transfer. AXI BRAM
Controller supports the OKAY and SLVERR
responses.
s_axi_ctrl_rvalid S_AXI_CTRL
(R) O‘ 0 ’
AXI4-Lite control read valid. Asserted by the
AXI BRAM Controller to indicate the required
read data is available and the read transfer
can complete.
‘0’ = read data not available
‘1’ = read data is available
s_axi_ctrl_rready S_AXI_CTRL
(R) I
AXI4-Lite control read ready. Indicates the
requesting master can accept the read data
and response information.
‘0’ = AXI master not ready
‘1’ = AXI master is ready
BRAM Signals
bram_rst_a BRAM O ‘0’ Port A BRAM active-High reset.
Table 2-2: I/O Signal Description (Cont’d)
Signal Name Interface Signal
Type
Init
Status Description
Send Feedback

## Page 21

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 21
PG078 October 5, 2016
Chapter 2: Product Specification
bram_clk_a BRAM O ‘0’ Port A BRAM clock. Connected to AClk with
same frequency, same phase alignment.
bram_en_a BRAM O ‘0’ BRAM Port A (write port ) enable signal. Active
High.
bram_we_a
[(c_s_axi_data_width/8) +
c_ecc - 1:0]
BRAM O Zeros
BRAM Port A (write port) write enable signal.
Active High. Byte wise signal to width of block
RAM.
If ECC is enabled, the BRAM_WE_A width
increases to hold the ECC bits as shown in
Table 3-4, page 62 .
bram_addr_a
[c_bram_addr_width-1:0] BRAM O Zeros
BRAM Port A (write port) address bus. Bus is
sized according to data  width and based on
C_S_AXI_BASEADDR and C_S_AXI_HIGHADDR
settings.
bram_wrdata_a [(8 * c_ecc +
c_s_axi_data_width)-1:0] BRAM O Zeros
BRAM Port A (write port ) write data bus. Size
of BRAM write data width is equal to size of
AXI slave port connection to the AXI BRAM
Controller.
If ECC is enabled, th e BRAM_WrData_A width
increases to hold the ECC bits as shown in
Table 3-4, page 62 .
bram_rddata_a [(8 * c_ecc +
c_s_axi_data_width)-1:0] BRAM I
BRAM Port A (read port) read data bus. Size of
BRAM read data width is equal to size of AXI
slave port connection to the AXI BRAM
Controller.
If ECC is enabled, th e BRAM_RdData_A width
increases to hold the ECC bits as shown in
Table 3-4, page 62 .
BRAM_RdData_A port used during the
read-modify-write (if needed) when C_ECC =
1.
BRAM_RdData_A port also used for read
operations when C_SINGLE_PORT_BRAM = 1.
bram_rst_b BRAM O ‘0’ Port B BRAM active-High reset.
bram_clk_b BRAM O ‘0’ Port B BRAM clock. Connected to AClk with
same frequency, same phase alignment.
bram_en_b BRAM O Zeros
BRAM Port B (read port) enable signal. Active
High.
Only used when C_SINGLE_PORT_BRAM = 0.
Table 2-2: I/O Signal Description (Cont’d)
Signal Name Interface Signal
Type
Init
Status Description
Send Feedback

## Page 22

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 22
PG078 October 5, 2016
Chapter 2: Product Specification
Register Space
AXI4-Lite ECC Registers
Table 2-3  summarizes the ECC register set that is available when ECC is enabled (C_ECC = 1)
on the AXI-Lite control interface. Additional  details on each register is provided in ECC
Register Details, page 24 .
bram_we_b
[(c_s_axi_data_width/8) +
c_ecc - 1:0]
(2)
BRAM O Zeros
BRAM Port B (read port ) write enable signal.
Active High.
Fixed to default zeros value (port B is a
read-only port to block RAM).
Size is byte-wise to width of block RAM.
If ECC is enabled, the BRAM_WE_A width
increases to hold the ECC bits as shown in
Table 3-4, page 62 .
bram_addr_b
[c_bram_addr_width-1:0] BRAM O Zeros
BRAM Port B (read port) address bus. Bus is
sized according to data  width and based on
C_S_AXI_BASEADDR and C_S_AXI_HIGHADDR
settings.
Only used when C_SINGLE_PORT_BRAM = 0.
bram_rddata_b [(8 * c_ecc +
c_s_axi_data_width)-1:0] BRAM I
BRAM Port B (read port) read data bus. Size of
BRAM read data width is equal to size of AXI
slave port connection to the AXI BRAM
Controller.
If ECC is enabled, th e BRAM_RdData_B width
increases to hold the ECC bits as shown in
Table 3-4, page 62 .
Only used when C_SINGLE_PORT_BRAM = 0.
bram_wrdata_b [(8 * c_ecc+
c_s_axi_data_width-1:0]
(2) BRAM O Zeros
BRAM Port B (read port) write data bus.
Fixed to default zeros value (port B is a
read-only port to block RAM).
Size of BRAM write data width is equal to size
of AXI slave port connection to the AXI BRAM
Controller.
If ECC is enabled, the BRAM_WrData_B width
increases to match the data width with ECC
bits as shown in Table 3-4, page 62 .
Notes:
1. This AXI IP slave core does not include support for the low power interface signals of the AXI-defined specification.
2. bram_we_b and bram_wrdata_b are unused port signals in the AX I BRAM Controller IP core. These signals are included in the
BRAM interface for tool compatibility (and  the default values are driven properly).
Table 2-2: I/O Signal Description (Cont’d)
Signal Name Interface Signal
Type
Init
Status Description
Send Feedback

## Page 23

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 23
PG078 October 5, 2016
Chapter 2: Product Specification
Table 2-3: AXI BRAM Interface Register Address Map (1)
Base Address + Offset (hex) Register Access
Type Description
C_S_AXI_CTRL_BASEADDR + 0x0 ECC_S TATUS R/WC ECC Status Register
C_S_AXI_CTRL_BASEADDR + 0x4 ECC_EN_IRQ R/W ECC Enable Interrupt Register
C_S_AXI_CTRL_BASEADDR + 0x8 ECC_ON_OFF R/W ECC On/Off Register
C_S_AXI_CTRL_BASEADDR + 0xC CE_CNT R/W Correctable Error Counter Register
C_S_AXI_CTRL_BAS EADDR + 0x100 (1) CE_FFD [31:0] R
Correctable Error First Failing Data Register,
bits [31:0]
Unused in core. Reserved for future
implementation .
C_S_AXI_CTRL_B ASEADDR + 0x104 CE_FFD [63:32] R
Correctable Error First Failing Data Register,
bits [63:32]
Unused in core. Reserved for future
implementation .
C_S_AXI_CTRL_B ASEADDR + 0x108 CE_FFD [95:64] R
Correctable Error First Failing Data Register,
bits [95:64]
Unused in core. Reserved for future
implementation .
C_S_AXI_CTRL_B ASEADDR + 0x10C CE_FFD [127:96] R
Correctable Error First Failing Data Register,
bits [127:96]
Unused in core. Reserved for future
implementation .
(0x120 - 0x17C) Reserved for Expansio n greater than 128-bit BRAM with ECC.
C_BASEADDR + 0x180 CE_FFE R
Correctable Error Firs t Failing ECC Register
Unused in core. Reserved for future
implementation .
(0x184 - 0x1BC) Reserved for Expansion greater than  128-bit BRAM with ECC.
C_S_AXI_CTRL_BASEADDR + 0x1C0 CE_FFA [31:0] R Correctable Error First Failing Address
Register, bits [31:0]
C_S_AXI_CTRL_BASEADDR + 0x1C4 CE_FFA [63:32] R Correctable Error First Failing Address
Register, bits [63:32]
C_S_AXI_CTRL_B ASEADDR + 0x200 UE_FFD [31:0] R
Uncorrectable Error First Failing Data
Register, bits [31:0]
Unused in core. Reserved for future
implementation .
C_S_AXI_CTRL_B ASEADDR + 0x204 UE_FFD [63:32] R
Uncorrectable Error First Failing Data
Register, bits [63:32]
Unused in core. Reserved for future
implementation .
Send Feedback

## Page 24

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 24
PG078 October 5, 2016
Chapter 2: Product Specification
ECC Register Details
ECC_STATUS
This register holds information on the occurrence of correctable and uncorrectable errors.
The status bits are independently set to ‘1’ for the first occurrence of each error type. The
status bits are cleared by writing a ‘1’ to the corresponding bit position, that is, the status
C_S_AXI_CTRL_B ASEADDR + 0x208 UE_FFD [95:64] R
Uncorrectable Error First Failing Data
Register, bits [95:64]
Unused in core. Reserved for future
implementation .
C_S_AXI_CTRL_B ASEADDR + 0x20C UE_FFD [127:96] R
Uncorrectable Error First Failing Data
Register, bits [127:96]
Unused in core. Reserved for future
implementation .
(0x210 - 0x27C) Reserved for expansio n greater than 128-bit BRAM with ECC.
C_S_AXI_CTRL_B ASEADDR + 0x280 UE_FFE R
Uncorrectable Error First Failing ECC
Register
Unused in core. Reserved for future
implementation .
(0x284 - 0x2BC) Reserved for expansio n greater than 128-bit BRAM with ECC.
C_S_AXI_CTRL_BASEADDR + 0x2C0 UE_FFA [31:0] R
Uncorrectable Error First Failing Address
Register, bits [31:0]
Unused in core. Reserved for future
implementation .
C_S_AXI_CTRL_BASEADDR + 0x2C4 UE_FFA [63:32] R
Uncorrectable Error First Failing Address
Register, bits [63:32]
Unused in core. Reserved for future
implementation .
C_S_AXI_CTRL_BASEADDR + 0x300 FI_D [31:0] W Fault Inject  Data Register, bits [31:0]
C_S_AXI_CTRL_BASEADDR + 0x304 FI_D [63:32] W Fault Inject  Data Register, bits [63:32]
C_S_AXI_CTRL_BASEADDR + 0x308 FI_D [95:64] W Fault Inject  Data Register, bits [95:64]
C_S_AXI_CTRL_BASEADD R + 0x30C FI_D [127:96] W Fault In ject Data Register, [127:96]
(0x310 - 0x37C) Reserved for expansio n greater than 128-bit BRAM with ECC.
C_S_AXI_CTRL_BASEADDR + 0x380 FI_ECC W Fault Inject ECC Register
Notes:
1. Grayed cells indicate registers that are not used in the core, but that are reserved for future implementation.
Table 2-3: AXI BRAM Interface Register Address Map (1) (Cont’d)
Base Address + Offset (hex) Register Access
Type Description
Send Feedback

## Page 25

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 25
PG078 October 5, 2016
Chapter 2: Product Specification
bits can only be cleared to ‘0’ and not set to  ‘1’ using a register write. The ECC Status
register operates independently of the ECC Enable Interrupt register.
This register is availa ble only when C_ECC = 1.
ECC_EN_IRQ
This register determines if the value of the CE _STATUS and UE_STATUS bits of the ECC Status
Register asserts the Interrupt output sign al (ECC_Interrupt). If both CE_EN_IRQ and
UE_EN_IRQ are set to ‘1’ (enabled), the value of the Interrupt signal is the logical OR
between the CE_STATUS and UE_STATUS bits.
This register is availa ble only when C_ECC = 1 .
ECC_ON_OFF
The ECC On/Off Control Register allows the app lication to enable or disable ECC checking.
The design parameter, C_ECC_ONOFF_RESET_VA LUE (default on) determines the reset value
Table 2-4: ECC Status Register (ECC_STATUS)
Reserved ECC_STATUS
31 21 0
Table 2-5:  ECC Status Register Bit Definitions
Bit(s) Name Core Access Reset
Value Description
1C E _ S T A T U S R / W C 0 If ‘1’ a correctable error has occurred. Cleared when ‘1’ is
written to this bit position
0U E _ S T A T U S R / W C 0 If ‘1’ an uncorrectable error ha s occurred. Cleared when ‘1’ is
written to this bit position
Table 2-6: ECC Interrupt Enable Register (ECC_EN_IRQ)
Reserved ECC_EN_IRQ
31 21 0
Table 2-7:  ECC Interrupt Enable Register Bit Definitions
Bit(s) Name Core Access Reset
Value Description
1 CE_EN_IRQ R/W 0
If ‘1’, the value of the CE_ST ATUS bit of the ECC Status
Register is propagated to the Interrupt signal.
if ‘0’, the value of the CE_STATUS bit of the ECC Status
Register is not propagated  to the Interrupt signal.
0 UE_EN_IRQ R/W 0
If ‘1’, the value of the UE_STATUS bit of the ECC Status
Register is propagated to the Interrupt signal.
if ‘0’, the value of the UE_STATUS bit of the ECC Status
Register is not propagated  to the Interrupt signal.
Send Feedback

## Page 26

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 26
PG078 October 5, 2016
Chapter 2: Product Specification
for the enable/disable setting of ECC. This fac ilitates start-up operatio ns when ECC might or
might not be initialized in the BRAM block. When disabled, ECC checking is disabled for
read, but ECC generation is active for write operations.
This register is not implemente d if the value of C_ECC is 0 . In this case, ECC checking is always
off.
CE_CNT
This register counts the number of occurrences of correctable errors. It can be cleared or
preset to any value by means of a register write. When the counter reaches its maximum
value it does not wrap around, but stops in crementing and remains at the maximum value.
The width of the counter is defined by the value of the C_CE_COUNTER_WIDTH parameter.
The AXI BRAM Controller has the value of  the CE counter width set to 8 bits.
This counter register is only  accessible when C_ECC = 1 .
CE_FFA [31:0]
This register stores the address (bits [31:0]) of the first occurrence of an access with a
correctable error. When the CE_STATUS bit in the ECC Status Register is cleared, the register
Table 2-8: ECC On/Off Control Register (ECC_ON_OFF)
Reserved ECC_ON_OFF
31 10
Table 2-9:  ECC On/Off Control Register Bit Definitions
Bit(s) Name Core
Access Reset Value Description
0 ECC_ON_OFF R/W
Specified by
design parameter,
C_ECC_ONOFF_
RESET_VALUE
If ‘0’, ECC checking is disabl ed on read operations. (ECC
generation is enabled on write operations when C_ECC
= 1).
If ‘1’, ECC checking is en abled on read operations. All
correctable and uncorrecta ble error conditions are
captured and status updated.
Table 2-10: Correctable Error Counter Register (CE_CNT)
Reserved CE_CNT
31 87 0
Table 2-11: Correctable Error Counter Register Bit Definitions
Bit(s) Name Core
Access
Reset
Value Description
(7:0) CE_CNT R/W 0 Registers holds number of correctable errors
encountered
Send Feedback

## Page 27

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 27
PG078 October 5, 2016
Chapter 2: Product Specification
is re-enabled to store the address of the ne xt correctable error. Storage of the failing
address is enabled after reset.
This register is only im plemented when C_ECC = 1 .
CE_FFA [63:32]
This register is unused in this release of  the AXI BRAM Controller IP core. The maximum
address width setting on the block RAM is 32 .
This register stores the address (bits [63:32]) of the first occurrence of an access with a
correctable error. When the CE_STATUS bit in the ECC Status Register is cleared, the register
is re-enabled to store the address of the ne xt correctable error. Storage of the failing
address is enabled after reset.
This register is only im plemented when C_ECC = 1 .
CE_FFD [31:0]
This register is unused in this rele ase of the AXI BRAM Controller IP core .
CE_FFD [63:32]
This register is unused in this rele ase of the AXI BRAM Controller IP core .
Table 2-12: Correctable Error First Failing Address Register (CE_FFA [31:0])
CE_FFA [31:0]
31 0
Table 2-13: Correctable Error First Failing Address [31:0] Register Bit Definitions
Bit(s) Name Core Access Reset
Value Description
(31:0) CE_FFA [31:0] R 0 Address (bits [31:0]) of th e first occurrence of a
correctable error
Table 2-14: Correctable Error First Failing Address Register (CE_FFA [63:32])
CE_FFA [63:32]
31 0
Table 2-15: Correctable Error First Failing Address [63:32] Register Bit Definitions
Bit(s) Name Core Access Reset Value Description
(31:0) CE_FFA [63:32] R 0 Address (bits [63:32]) of th e first occurrence of a
correctable error
Send Feedback

## Page 28

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 28
PG078 October 5, 2016
Chapter 2: Product Specification
CE_FFD [95:64]
This register is unused in this rele ase of the AXI BRAM Controller IP core .
CE_FFD [127:96]
This register is unused in this rele ase of the AXI BRAM Controller IP core .
CE_FFE
This register is unused in this rele ase of the AXI BRAM Controller IP core .
UE_FFA [31:0]
This register is unused in this rele ase of the AXI BRAM Controller IP core .
UE_FFA [63:32]
This register is unused in this rele ase of the AXI BRAM Controller IP core.
UE_FFD [31:0]
This register is unused in this rele ase of the AXI BRAM Controller IP core .
UE_FFD [63:32]
This register is only used wh en the C_S_AXI_DATA_WIDTH > 32 .
This register stores the (uncorrected) failing da ta (bits [63:32]) of the first occurrence of an
access with an uncorrectable error. When the UE_STATUS bit in the ECC Status Register is
cleared, this register is re-enabled to store th e data of the next uncorrectable error. Storage
of the failing data is enabled after reset.
This register is only im plemented when C_ECC = 1 .
Table 2-16: Uncorrectable Error First Failing Data Register (UE_FFD [63:32])
UE_FFD [63:32]
31 0
Table 2-17: Uncorrectable Error First Failing Data  [63:32] Register Bit Definitions
Bit(s) Name Core
Access
Reset
Value Description
(31:0) UE_FFD [63:32] R 0 Data (bits [63:32) of the first occurrence of an
uncorrectable error.
Send Feedback

## Page 29

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 29
PG078 October 5, 2016
Chapter 2: Product Specification
UE_FFD [95:64]
This register is only used wh en the C_S_AXI_DATA_WIDTH > 64 .
This register is unused in this release of the AXI BRAM Controlle r IP core; however, it will be
available in a future release of the IP core when ECC is supported for 128-bit AXI BRAM data
width configurations.
This register stores the (uncorrected) failing da ta (bits [95:64]) of the first occurrence of an
access with an uncorrectable error. When the UE_STATUS bit in the ECC Status Register is
cleared, this register is re-enabled to store th e data of the next uncorrectable error. Storage
of the failing data is enabled after reset.
This register is only im plemented when C_ECC = 1 .
UE_FFD [127:96]
This register is only used wh en the C_S_AXI_DATA_WIDTH > 64 .
Unused in this release of the AXI BRAM Controller IP core. Will be available in a future
release of the IP core when ECC is su pported for 128-bit AXI BRAM data width
configurations.
This register stores the (uncorrected) failing da ta (bits [127:96]) of the first occurrence of an
access with an uncorrectable error. When the UE_STATUS bit in the ECC Status Register is
cleared, this register is re-enabled to store th e data of the next uncorrectable error. Storage
of the failing data is enabled after reset.
This register is only im plemented when C_ECC = 1 .
Table 2-18: Uncorrectable Error First Failing Data Register (UE_FFD [95:64])
UE_FFD [95:64]
31 0
Table 2-19: Uncorrectable Error First Failing Data  [95:64] Register Bit Definitions
Bit(s) Name Core Access Reset
Value Description
(31:0) UE_FFD [95:64] R 0 Data (bits [95:64]) of the first occurrence of an
uncorrectable error.
Table 2-20: Uncorrectable Error First Failing Data Register (UE_FFD [127:96])
UE_FFD [127:96]
31 0
Send Feedback

## Page 30

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 30
PG078 October 5, 2016
Chapter 2: Product Specification
UE_FFE
This register is unused in this rele ase of the AXI BRAM Controller IP core .
FI_D0
This register is used to inject errors in data  (bits [31:0]) written to the block RAM and can be
used to test the error correction and error signa ling. The bits set in the register toggle the
corresponding data bits (word 0 or bits [31:0]) of the subsequent data written to the block
RAM without affecting the ECC bits written. After the fault has been injected, the Fault
Injection Data Register is cleared automatically.
The register is only implemented if  C_FAULT_INJECT = 1 and C_ECC = 1 .
Injecting faults should be performed in a critic al region in software; that is, writing this
register and the subsequent write to AXI BRAM must not be interrupted.
For larger data width BRAMs with ECC ( 64- and 128-bit configurations), special
consideration must be given across FI_D0, FI_D1, FI_D2 and FI_D3 such that only a single
error condition is introduced.
FI_D1
This register is only used wh en the C_S_AXI_DATA_WIDTH > 32 .
This register is used to inject errors in da ta (bits [63:32]) written to the block RAM and can
be used to test the error correction and error signaling. The bits set in the register toggle
the corresponding data bits (word 1 or bits [ 63:32]) of the subsequent data written to the
Table 2-21: Uncorrectable Error First Failing Data  [127:96] Register Bit Definitions
Bit(s) Name Core Access Reset
Value Description
(31:0) UE_FFD [127:96] R 0 Data (bits [127:96]) of the first occurrence of an
uncorrectable error.
Table 2-22: Fault Injection Data Register (FI_D0)
FI_D0
31 0
Table 2-23: Fault Injection Data (Word 0)  Register Bit Definitions
Bit(s) Name Core Access Reset
Value Description
(31:0) FI_D0 W 0
Bit positions set to ‘1’ toggle the corresponding bits
[31:0] of the next data word  written to the block RAM.
The register is automatically cleared after the fault has
been injected.
Send Feedback

## Page 31

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 31
PG078 October 5, 2016
Chapter 2: Product Specification
block RAM without affecting the ECC bits written.  After the fault has been injected, the Fault
Injection Data Register is cleared automatically.
This register is only implemented if C_FAULT_IN JECT = 1 and C_ECC = 1 .
Injecting faults should be performed in a critic al region in software; that is, writing this
register and the subsequent write to AXI BRAM must not be interrupted.
FI_D2
This register is only used wh en the C_S_AXI_DATA_WIDTH > 64 .
This register is used to inject errors in da ta (bits [95:64]) written to the block RAM and can
be used to test the error correction and error signaling. The bits set in the register toggle
the corresponding data bits (word 2 or bits [ 95:64]) of the subsequent data written to the
block RAM without affecting the ECC bits written.  After the fault has been injected, the Fault
Injection Data Register is cleared automatically.
This register is only implemented if C_FAULT_IN JECT = 1 and C_ECC = 1 .
Injecting faults should be performed in a critic al region in software; that is, writing this
register and the subsequent write to AXI BRAM must not be interrupted.
Table 2-24: Fault Injection Data Register (FI_D1)
FI_D1
31 0
Table 2-25: Fault Injection Data (Word 1)  Register Bit Definitions
Bit(s) Name Core Access Reset
Value Description
(31:0) FI_D1 W 0
Bit positions set to ‘1’ togg le the corresponding bits [ 63:32 ]
of the next data word written to the block RAM. The register
is automatically cleared after the fault has been injected.
Table 2-26: Fault Injection Data Register (FI_D2)
FI_D2
31 0
Table 2-27: Fault Injection Data (Word 2)  Register Bit Definitions
Bit(s) Name Core
Access
Reset
Value Description
(31:0) FI_D2 W 0
Bit positions set to ‘1’ toggle the corresponding bits [95:64] of
the next data word written to the block RAM. The register is
automatically cleared after the fault has been injected.
Send Feedback

## Page 32

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 32
PG078 October 5, 2016
Chapter 2: Product Specification
FI_D3
This register is only used wh en the C_S_AXI_DATA_WIDTH > 64 .
This register is used to inject errors in data  (bits [127:96]) written to the block RAM and can
be used to test the error correction and error signaling. The bits set in the register toggle
the corresponding data bits (word 3 or bits [ 127:96]) of the subsequent data written to the
block RAM without affecting the ECC bits written.  After the fault has been injected, the Fault
Injection Data Register is cleared automatically.
This register is only implemented if C_FAULT_IN JECT = 1 and C_ECC = 1 .
Injecting faults should be performed in a critic al region in software; that is, writing this
register and the subsequent write to AXI BRAM must not be interrupted.
FI_ECC
This register is used to inject errors in th e generated ECC written to the block RAM and can
be used to test the error correction and error signaling. The bits set in the register toggle
the corresponding ECC bits of the next data written to block RAM. After the fault has been
injected, the Fault Injection ECC Re gister is cleared automatically.
The register is only implemented if  C_FAULT_INJECT = 1 and C_ECC = 1 .
Injecting faults should be performed in a critic al region in software; that is, writing this
register and the subsequent write to AXI BRAM must not be interrupted.
Table 2-30  and Table 2-31  describes the register bit usage when C_S_AXI_DATA_WIDTH =
32.
Table 2-28: Fault Injection Data Register (FI_D3)
FI_D3
31 0
Table 2-29: Fault Injection Data (Word 3)  Register Bit Definitions
Bit(s) Name Core
Access
Reset
Value Description
0 to 31 FI_D3 W 0
Bit positions set to ‘1’ toggle th e corresponding bits [127:96] of
the next data word written to the block RAM. The register is
automatically cleared after the fault has been injected.
Table 2-30: Fault Injection ECC Register (FI_ECC) for 32-bit BRAM
Reserved FI_ECC
31 76 0
Send Feedback

## Page 33

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 33
PG078 October 5, 2016
Chapter 2: Product Specification
Table 2-32  and Table 2-33  describe the register bit usag e when C_S_AXI_DATA_WIDTH = 64.
Table 2-34  and Table 2-35  describe the register bit usage when C_S_AXI_DATA_WIDTH =
128.
Table 2-31: Fault Injection ECC Register Bit Definitions for 32-bit BRAM
Bit(s) Name Core
Access
Reset
Value Description
(6:0) FI_ECC R 0
Bit positions set to ‘1’ toggle the corresponding bit of the next ECC
written to the block RAM. The regis ter is automatically cleared after
the fault has been injected.
Table 2-32: Fault Injection ECC Register (FI_ECC) for 64-bit BRAM
Reserved FI_ECC
31 87 0
Table 2-33: Fault Injection ECC Register Bit Definitions for 64-bit BRAM
Bit(s) Name Core
Access
Reset
Value Description
(7:0) FI_ECC R 0
Bit positions set to ‘1’ toggle the corresponding bit of the next
ECC written to the block RAM. The register is automatically
cleared after the faul t has been injected.
Table 2-34: Fault Injection ECC Register (FI_ECC) for 128-bit BRAM
Reserved FI_ECC
31 9 8 0
Table 2-35: Fault Injection ECC Register Bi t Definitions for 128-bit BRAM
Bit(s) Name Core
Access
Reset
Value Description
8 FI_ECC [8] R 0
Bit position set to ‘1’ toggle the corresponding bit of the next
ECC written to the block RAM. The register is automatically
cleared after the faul t has been injected.
(7:0) FI_ECC [7:0] R 0
Bit positions set to ‘1’ toggle th e corresponding bit of the next
ECC written to the block RAM. The register is automatically
cleared after the faul t has been injected.
Send Feedback

## Page 34

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 34
PG078 October 5, 2016
Chapter 3
Designing with the Core
This chapter includes guidelines and additional  information to facilitate designing with the
core.
General Design Guidelines
AXI4-Lite Controller Design
The AXI BRAM Controller IP core can be config ured in a simplified foot print core by setting
the design parameter, C_S_AXI_PROTOCOL = AXI4LITE.
In this configuration, the AXI BRAM Controller  can be configured to interface to a single
port or dual port BRAM. All arbitration to  the block RAM (in a single port mode) is
performed on the AXI write address (AW) and re ad address (AR) channels. Only one active
operation is allowable in the core at a time . The AXI BRAM Controller AW and AR channel
interfaces assign priority to the read channe l when presented with simultaneous assertions
of the ARVALID and AWVALID signals; ensuring the AXI BRAM Controller is compliant with
any AXI4-Lite master. When the AXI BRAM Contro ller is created in a system topology with
the AXI Interconnect IP, it is ensured that ARVALID and AWVALID are not asserted at the
same time and the AXI Interconnect handles the arbitration between the write and read
channels. The AXI Interconnect provides opti mizations in the AXI BRAM Controller core
through the build process by duplicating the ARADDR and AWADDR signals.
To configure the dual-port BRAM mode to the BRAM block, ensure the design parameter,
C_SINGLE_PORT_BRAM = 0.
The AXI4-Lite BRAM Controller is designed fo r minimal FPGA resource utilization. Minimal
registers are utilized, only thos e to support the register outp uts to the AXI4-Lite interface
according to standard.
Send Feedback

## Page 35

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 35
PG078 October 5, 2016
Chapter 3: Designing with the Core
AXI4-Lite Single Write
The write datapath timing in the core is shown in Figure 3-1  for the AXI4-Lite interface
connections. Figure 3-1  assumes that no valid transaction is active on the AXI AR and R
channels.
X-Ref Target - Figure 3-1
Figure 3-1: AXI4-Lite Write Timing
ACLK
AWID[3:0]
AWADDR[31:0]
AWSIZE[2:0]
AWVALID
AWREADY
WDATA[31:0]
WSTRB[3:0]
WLAST
WVALID
WREADY
BID[3:0]
BRESP[1:0]
BVALID
BREADY
BRAM_CLK
BRAM_Addr_A[10:0]
BRAM_WrData_A[31:0]
BRAM_WE_A[3:0]
BRAM_En_A
0
A0001000
2
D0000000
F
0
OKAY
1000
D0000000
F
PG078_c3_01_082912
Send Feedback

## Page 36

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 36
PG078 October 5, 2016
Chapter 3: Designing with the Core
AXI4-Lite Multiple Write
The AXI4-Lite BRAM Controller is able to acce pt continuous single write operations as
shown in Figure 3-2 .
X-Ref Target - Figure 3-2
Figure 3-2: Multiple AXI4-Lite Write Transactions
ACLK
AWID[3:0]
AWADDR[31:0]
AWSIZE[2:0]
AWVALID
AWREADY
WDATA[31:0]
WSTRB[3:0]
WLAST
WVALID
WREADY
BID[3:0]
BRESP[1:0]
BVALID
BREADY
BRAM_CLK
BRAM_Addr_A[10:0]
BRAM_WrData_A[31:0]
BRAM_WE_A[3:0]
BRAM_En_A
0 1 2
A0001000 A0002000 A0003000
2 2 2
D0000000 D1000000 D2000000
F F F
0 1 2
OKAY OKAY OKAY
1000 2000 3000
D0000000 D1000000 D2000000
F F F
PG078_c3_02_082912
Send Feedback

## Page 37

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 37
PG078 October 5, 2016
Chapter 3: Designing with the Core
AXI4-Lite Single Read
The read datapath timing is shown in Figure 3-3  for AXI4-Lite transactions. Multiple read
request operations illustrate the timing of the controller and on the BRAM interface.
X-Ref Target - Figure 3-3
Figure 3-3: AXI4-Lite Read Timing
ACLK
ARID[3:0]
ARADDR[31:0]
ARSIZE[2:0]
ARVALID
ARREADY
RDATA[31:0]
RLAST
RVALID
RREADY
BRAM_CLK
BRAM_Addr_A[10:0]
BRAM_RdData_A[31:0]
BRAM_En_A
0 1
A0001000 A0002000
2 2
D0000000 D1000000
1000 2000
D0000000 D1000000
PG078_c3_03_082912
Send Feedback

## Page 38

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 38
PG078 October 5, 2016
Chapter 3: Designing with the Core
AXI4-Lite Write with ECC
Figure 3-4  illustrates the timing of the read-mod ify-write (RMW) sequence when C_ECC = 1
for write transfers on the AXI4-Lite interface. To save resources the AWADDR and WDATA
are not registered in the AXI4-Lite BRAM co ntroller, so the AWREADY and WREADY output
flag assertions are delayed until the RMW sequence is completed. Also depicted is the
capability of the AXI4-Lite controller to ha ndle back-to-back write request operations.
AXI4 Controller Design
The AXI BRAM Controller meets the performa nce requirement of AXI based systems and
provides minimal latency to/from block RAM. Sing le clock cycle latency is achieved on each
channel Valid to Ready response, depending on  the current core activity. The AXI BRAM
Controller separates the write and read channel activity (w hen C_SINGLE_PORT_BRAM = 0),
so that the controller can handle simultaneo us read and write oper ations from AXI. All
timing relationships between the write addres s and write data channel (as well as read
address and read data channels) are designed to  meet the AXI standard, so as to avoid any
deadlock situations.
X-Ref Target - Figure 3-4
Figure 3-4: AXI4-Lite Write with ECC
ACLK
AWADDR[31:0]
AWVALID
AWREADY
WDATA[31:0]
WSTRB[3:0]
WVALID
WREADY
BRESP[1:0]
BVALID
BREADY
BRAM_CLK
BRAM_Addr_A[10:0]
BRAM_WE_A[4:0]
BRAM_En_A
BRAM_WrData_A[31:0]
BRAM_RdData_A[31:0]
A0001000 A0002000
00000010 00000020
1 1
OKAY OKAY
1000 2000
00 1F 00 1F
03020110 04050620
03020100 04050607
PG078_c3_04_082912
Send Feedback

## Page 39

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 39
PG078 October 5, 2016
Chapter 3: Designing with the Core
No address decoding is performed by the AXI BRAM Controller; all operations received are
accepted. The Xilinx AXI Interconnect provides the address decode.
All AXI master size matching to the data widt h of the block RAM is handled by the Xilinx AXI
Interconnect module. The slave IP port of the AXI BRAM Controller on the AXI Interconnect
is equal to the width of the block RAM (equal to the size of the AXI BRAM Controller). The
AXI BRAM Controller does not need to know th e data width or burst size of the requesting
master, as the Interconnect translates all operations to fit to the data width and burst size
of the data bus connected to the AX I BRAM Controller (and block RAM).
AXI Singles
A single AXI transaction is qualified by the AWSIZE/ARSIZE equal to “000” and AWLEN/
ARLEN set to “0000” for 1 data transfer. All AXI4-Lite operations are supported by the AXI
BRAM Controller when (C_S_AXI_PROTOCOL = AXI4).
Bursting
All burst types presented to the AXI BRAM Co ntroller are supported. However, fixed burst
types are translated into incrementing burst ty pes issued to the block RAM. Wrapping burst
types are support for processor cacheline read and writes with block RAM.
Each burst is specified to have N data transfers (1-256 specified in AWLEN/ARLEN) of M
bytes (1-128 bytes specified in AWSIZE/ARSIZ E). The AXI BRAM Controller supports up to
the AXI4 extension on burst sizes to 256 data beats.
The size of the burst must be equal or less than the size of the BRAM data width. For
instance, 64-bit BRAM only allows bursts of up to 64 byte sizes. Burst sizes less than the full
width of the AXI BRAM Controller  data bus is referred to as a “narrow” burst. All “narrow”
bursts are supported by the AXI BRAM Controlle r. For example, a master is requesting a
byte burst operation to/from a 64-bit data  wide BRAM. For “narrow” bursts, the AXI
protocol defines that the valid byte lanes rotate through the correct byte lanes. In the AXI
BRAM Controller, each write data beat of a burst on the AXI is translated to a write
operation to the block RAM. The BRAM byte enables are configured such that only the valid
bytes are stored in memory. The AXI BRAM Controller does not buffer any subsize data
beats into the full width to the block RAM.  An example is shown in the section, Narrow
Write Bursting, page 46 .
Unaligned burst transfers are allowed and the AXI master must indicate this with the lower
order bits of the address bus provided with the write address channel data handshaking. An
example is shown in section, Unaligned Write Bursting, page 47 . Unaligned burst transfers
can also be indicated with an aligned address,  but use the write data channel data strobes
to indicate the valid byte lanes.
Each write and read channel of the AXI BRAM Co ntroller utilizes an ad dress counter that is
loaded at the beginning of the burst operation. AXI provides the starting address of the
burst, and the AXI BRAM Controller increments  the address based on the BRAM data width.
Send Feedback

## Page 40

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 40
PG078 October 5, 2016
Chapter 3: Designing with the Core
AXI does not allow any read nor write burst te rmination. Each AXI master must complete
each burst transaction that is initiated. Each  burst transaction is complete when the LAST
signal is asserted, by the master of writes, and by the AXI BRAM Controller on reads.
The write enables presented to the block RAM are calculated based on burst type, address
offset of the write address, along with the AXI write data strobes. The write enables are
generated on a per byte basis to the block RAM. Write enables are 4 bits wide for 32-bit
BRAMs, 8 bits wide for 64-bit BRAMs, and 16 bits wide for 128-bit BRAM instantiations.
Cacheline
Cacheline operations are implemented as WRAP burst types on the AXI bus when presented
to the block RAM. The allowable burst sizes fo r WRAP bursts are 2, 4, 8, and 16 data
transfers. The AWBURST/ARBURST must be set to “10” for the WRAP burst type.
WRAP bursts are handled in the address genera tor logic of the controller to the block RAM.
The address seen by the block RAM must increment to the boundary, then wrap back
around to the beginning of the cacheline addre ss. For example, a processor issuing a target
word first cache line read request to addre ss, 0x04h. A 32-bit BRAM sees the following
sequence of address-requested reads: 0x04 h, 0x08h, 0x0Ch, 0x00h. This example is
illustrated in Cacheline Reads, page 56  for a cacheline read.
Pipelining
Each write and read channel interface to the AXI can hold two active  addresses/operations.
The AXI BRAM Controller IP allows two active wr ite and two active read transactions to be
captured and held (when C_SINGLE_PORT_BRAM = 0). The data provided with each address
channel operation must remain in  order. No out of order oper ations are allowed in the AXI
BRAM Controller. The pipelining capability allo ws the same master or another master to
request a subsequent write or read transact ion. With the storag e of multiple write
addresses in the AXI BRAM Controller, the write data may not be immediately captured and
stored by the controller. The write data cha nnel interface of the AXI BRAM Controller does
not assert WREADY until the block RAM is read y to accept the data of the pipelined write
transaction. On the write address channel interface, the AXI BRAM Controller keeps
AWREADY asserted, until the pipeline full conditio n is reached. At this point, the AWREADY
is negated and no further write addresses are a ccepted, until the first address data phase is
complete and the second pipelined address can be processed by the controller. An example
of the timing relationship is shown in Write Pipeline, page 49 .
On read transactions, two deep address pipelin ing is supported in the AXI BRAM Controller.
The AXI BRAM Controller issues the request to block RAM and provides data on the read
data channel, as long as the requesting master asserts RREADY.
When the IP core is configured for single port BRAM utilization
(C_SINGLE_PORT_BRAM = 1), a 2-de ep address pipeline exists in the core, but is shared
between requesting AR and AW address transactions.
Send Feedback

## Page 41

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 41
PG078 October 5, 2016
Chapter 3: Designing with the Core
ID Wrapping
The AXI BRAM Controller does not support data reordering. All ID values are wrapped back
around on the data channel du ring handshaking. The AWID (o n the write address channel)
is captured and returned as the BID signal (o f the write response channel) during the write
data transaction. The ARID (on the read address channel) is captured and returned as the
RID signal (of the read response channel) during the read data response transaction.
Power Considerations
To conserve power consumption on the BRAM interface, the BRAM enable signal is only
asserted during active read or write operatio ns. The enable signal on each port to block
RAM is negated when no acti vity exists on the AXI bus.
ECC
When C_ECC = 1, the AXI BRAM Controller implements a read-modify-write on all write
transfers. Read operation timing remains iden tical to transfers when ECC is disabled. The
read-modify-write latency must  be accounted for on all wr ite transfers to block RAM.
AXI4 Timing
The timing diagrams shown in the subsequent sections represent the timing relationships
of the AXI slave AXI BRAM Controller IP conne ction to the Xilinx AXI Interconnect. All write
operations are initiated on the Write Address Channel (AW) of the AXI bus which specifies
the type of write transaction and the corresponding address information. The handshaking
protocol follows a Valid and Ready mechanism. All address and control information is only
valid when the Valid signal is asserted. When the slave asserts the Ready signal, it captures
the signals and accepts the operation. The Wr ite Data Channel (W) communicates all write
data for the single or burst write operation. The Write Response Channel (B) is used as the
handshaking or response on the write operation.
On read operations, the Read Address Channe l (AR) communicates all address and control
information when the AXI master asserts the Valid signal. The slave IP (or AXI BRAM
Controller) asserts the Ready signal on the RA C when the read operation can be processed.
When the read data is available to send back to the AXI master, the Read Data Channel (R)
translates the data and status of the operation.
AXI4 Operations
Single Write
Figure 3-5  illustrates an example for the timing of an AXI single 32-bit write operation to a
32-bit wide BRAM. This exam ple illustrates the single write to BRAM address 0x1000h,
Send Feedback

## Page 42

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 42
PG078 October 5, 2016
Chapter 3: Designing with the Core
provided that C_S_AXI_BASEADDR is set to 0xA000 0000 and the C_S_AXI_HIGHADDR allows
space for more than 4k of addressable BRAM.
As recommended, the AXI BRAM Controller keeps the AWREADY signal asserted on the bus,
as the address can be captured in the clock cycle when the S_AXI_AWVALID and
S_AXI_AWREADY signals are both  asserted. Once the write address pipeline (two deep) is
full, then the slave AXI BRAM Controller negates the AWREADY registered output signal.
The same principle applies to the write data channel, WVALID and WREADY signals. The AXI
BRAM Controller negates the WREADY signal wh en the data pipeline writing to block RAM
is full. This condition may o ccur when the AXI BRAM Controller is processing a prior burst
write data operation.
When ECC is enabled on full data width BRAM write transfers, the timing of the transaction
is identical to when C_ECC = 0.
Send Feedback

## Page 43

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 43
PG078 October 5, 2016
Chapter 3: Designing with the Core
It is possible on the write data channel for the data to be presented to the AXI BRAM
Controller prior to the write address channe l (AWVALID). In this case, the AXI BRAM
Controller does not initiate the write transactions (the write da ta is ignored), until the write
address channel has valid information fo r the AXI BRAM Controller to accept.
Single Read
Figure 3-6  illustrates an example of the timing fo r an AXI single read operation from a
32-bit BRAM.
The registered ARREADY signal output on the AXI Read Address Channel interface defaults
to a high assertion. The AXI BRAM Controller can accept the read address in the same clock
cycle as the ARVALID signal is first valid. The AXI BRAM Controller registers in the read
X-Ref Target - Figure 3-5
Figure 3-5: AXI Single Write Timing Diagram
ACLK
AWID[3:0]
AWADDR[31:0]
AWLEN[7:0]
AWSIZE[2:0]
AWBURST[1:0]
AWVALID
AWREADY
WDATA[31:0]
WSTRB[3:0]
WLAST
WVALID
WREADY
BID[3:0]
BRESP[1:0]
BVALID
BREADY
BRAM_CLK
BRAM_Addr_A[10:0]
BRAM_WrData_A[31:0]
BRAM_WE_A[3:0]
BRAM_En_A
0
A0001000
00
2
0
D0000000
F
0
OKAY
1000
D0000000
F
PG078_c3_05_082912
Send Feedback

## Page 44

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 44
PG078 October 5, 2016
Chapter 3: Designing with the Core
address when the ARVALID and the ARREADY signals are both asserted. When the AXI
BRAM Controller read address pipe line is full (two-deep), it clears the ARREADY signal until
the pipeline is in a non full condition.
The AXI BRAM Controller can accept the same  clock cycle assertion of the RREADY by the
master, if the master can accept data immediat ely. When the RREADY signal is asserted on
the AXI bus by the master, the AXI BRAM Controller negates the RVALID signal.
For single read transactions, the RLAST is asserted with the RVALID by the AXI BRAM
Controller.
On AXI read transactions, the read data alwa ys follows the read address handshaking. The
AXI BRAM Controller does not assert RVALID until both the ARVALID and ARREADY signals
are asserted in the same clock cycle. In other wo rds, there is no ability for early access to the
AXI BRAM Controller nor internal cach ing ability in the AXI BRAM Controller.
X-Ref Target - Figure 3-6
Figure 3-6: AXI Single Read Timing Diagram
ACLK
ARID[3:0]
ARADDR[31:0]
ARLEN[7:0]
ARSIZE[2:0]
ARBURST[1:0]
ARLOCK[1:0]
ARVALID
ARREADY
RID[3:0]
RDATA[31:0]
RRESP[1:0]
RLAST
RVALID
RREADY
BRAM_Clk
BRAM_Addr_B[10:0]
BRAM_RdData_B[31:0]
BRAM_En_B
0
A0001000
00
2
0
0
0
D0000000
OKAY
1000
D0000000
PG078_c3_06_082912
Send Feedback

## Page 45

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 45
PG078 October 5, 2016
Chapter 3: Designing with the Core
AXI Burst Operations
Write Burst
Figure 3-7  illustrates an example of the timing for an AXI write burst of four words to a
32-bit BRAM. The address write channel handshaking stage communicates the burst type as
INCR, the burst length of 4 data transfers ( AWLEN  = 0011b). The write burst utilizes all byte
lanes of the AXI data bus to the block RAM ( AWSIZE  = 010b). The write burst shown in
Figure 3-7  is set to start at BRAM address 0x1000h, provided that the C_S_AXI_BASEADDR
design parameter is set to 0xA000 0000 and the C_S_AXI_HIGHADDR  allows space for
more than 4k of addressable block RAM.
On the AXI write transactions, the slave does not wait for the write data channel, WVALID
signal to be asserted prior to the asse rtion of the write address channel signal, AWREADY .
This could potentially cause a dead lock condition an d is not allowed.
X-Ref Target - Figure 3-7
Figure 3-7: AXI Burst Write Timing Diagram
ACLK
AWID[3:0]
AWADDR[31:0]
AWLEN[7:0]
AWSIZE[2:0
]
AWBURST[1:0 ]
AWLOCK[1:0]
AWVALID
AWREADY
WDATA[31:0]
WSTRB[3:0]
WLAST
WVALID
WREADY
BID[3:0]
BRESP[1:0]
BVALID
BREADY
BRAM_CLK
BRAM_Addr_A[10:0]
BRAM_WrData_A[31:0]
BRAM_WE_A[3:0]
BRAM_En_A
0
A0001000
03
2
INCR
0
D0 D1 D2 D3
F F F F
0
OKAY
1000 1004 1008 100C
D0 D1 D2 D3
F F F F
PG078_c3_07_082912
Send Feedback

## Page 46

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 46
PG078 October 5, 2016
Chapter 3: Designing with the Core
Narrow Write Bursting
Figure 3-8  illustrates an example of the AX I BRAM Controller supporting a narrow  burst
operation. A narrow  burst is defined as a master bursting a data size smaller than the BRAM
data width. If the burst type ( AWBURST ) is set to INCR or WRAP, then the valid data on the
BRAM interface to the AXI bus rotates for each  data beat. The AXI BRAM Controller handles
each data beat on the AXI as a corresponding da ta beat to the block RAM, regardless of the
smaller valid byte lanes. In this scenario, th e AXI WSTRB is translated to the BRAM write
enable signals. The BRAM address only increments when the full address (data) width
boundary is met with the narrow  write to block RAM.
Figure 3-8  illustrates an example of AXI narrow  bursting with a 32-bit BRAM and the AXI
master request is a halfword burst of 4 data beats. AWSIZE  is set to 001b.
X-Ref Target - Figure 3-8
Figure 3-8: AXI Narrow Burst Write Diagram
ACLK
AWID[3:0]
AWADDR[31:0]
AWLEN[7:0]
AWSIZE[2:0]
AWBURST[1:0]
AWLOCK[1:0]
AWVALID
AWREADY
WDATA[31:0]
WSTRB[3:0]
WLAST
WVALID
WREADY
BID[3:0]
BRESP[1:0]
BVALID
BREADY
BRAM_Addr_A[10:0]
BRAM_WrData_A[31:0]
BRAM_WE_A[3:0]
BRAM_En_A
0
A0001000
03
1
INCR
0
D0D1D2D3 D0D1D2D3 D4D5D6D7 D4D5D6D7
C 3 C 3
0
OKAY
1000 1000 1004 1004
D0D10000 0000D2D3 D4D50000 0000D6D7
C 3 C 3
PG078_c3_08_082912
Send Feedback

## Page 47

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 47
PG078 October 5, 2016
Chapter 3: Designing with the Core
Unaligned Write Bursting
The AXI BRAM Controller supports unaligned burs t transfers. Unaligned burst transfers for
example, occur when a 32-bit word burst size does not start on an address boundary that
matches a word memory location. The starti ng memory address is permitted to be
something other than 0x0h, 0x4h, 0x8h, etc.
The example shown in Figure 3-9 , illustrates an unaligned word burst transaction of 4 data
beats, that starts at address offset, 0x1002h (provided that C_S_AXI_BASEADDR  is set to
0xA000 0000 and C_S_AXI_HIGHADDR  allows more than 4k of  addressable memory). The
associated timing relationship is shown is Figure 3-10 .
TIP: Note the unaligned address corresponds to the BR AM_WE signals on the write port to reflect the
valid byte lanes.
X-Ref Target - Figure 3-9
Figure 3-9: AXI Unaligned Burst Write Transfers
D0
2     transfernd
3    transferrd
1    transferst
4    transferth
D3 D2 D1
D4D7 D6 D5
D8D11 D10 D9
D12D15 D14 D1 3
PG078_c3_09_082912
Send Feedback

## Page 48

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 48
PG078 October 5, 2016
Chapter 3: Designing with the Core
ECC Write Burst
Figure 3-11  illustrates the timing for an AXI write burst of two data beats.
TIP: Note the additional latency due to the read-modify -write sequence required to correctly update
the ECC check bits in block RAM.
X-Ref Target - Figure 3-10
Figure 3-10: AXI Unaligned Burst Write Timing
ACLK
AWID[3:0]
AWADDR[31:0]
AWLEN[7:0]
AWSIZE[2:0]
AWBURST[1:0]
AWLOCK[1:0]
AWVALID
AWREADY
WDATA[31:0]
WSTRB[3:0]
WLAST
WVALID
WREADY
BID[3:0]
BRESP[1:0]
BVALID
BREADY
BRAM_Addr_A[10:0]
BRAM_WrData_A[31:0]
BRAM_WE_A[3:0]
BRAM_En_A
0
A0001002
03
2
INCR
0
D3D2D1D0 D7D6D5D4 D11D10D9D8 D15D14D13D12
F F F F
0
OKAY
1000 1004 1008 100C
D3D20000 D7D6D5D4 D11D10D9D8 D15D14D13D12
C F F F
PG078_c3_10_082912
Send Feedback

## Page 49

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 49
PG078 October 5, 2016
Chapter 3: Designing with the Core
Write Pipeline
The AXI BRAM Controller IP core is capable of  supporting up to two active write operations.
Once the write address pipeline is full, the controller negates AWREADY  to the bus. Only
when the first pipelined operation is complete , may a new write transfer occur subsequently
(indicated by the assertion of AWREADY ).
The AXI BRAM Controller does not support write data interleaving, so the data on the write
data channel must be in the same order as th e addresses (for that data) presented on the
write address channel.
The write data channel responds to the write transfer with the assertion of WREADY . The AXI
BRAM Controller accepts data when the write data channel is not already busy from a
previous transaction. The AXI BRAM Co ntroller supports the early assertion of WREADY  to
WVALID  when asserted prior to AWVALID  and AWREADY . The AXI BRAM Controller only
accepts one data transfer before the write address is accepted.
X-Ref Target - Figure 3-11
Figure 3-11: AXI Write Burst w/ ECC
ACLK
AWADDR[31:0]
AWLEN[7:0]
AWSIZE[2:0]
AWBURST[1:0]
AWVALI D
AWREADY
WDATA[31:0]
WSTRB[3:0]
WLAST
WVALID
WREADY
BRESP[1:0]
BVALID
BREADY
BRAM_CLK
BRAM_Addr_A[10:0]
BRAM_WE_A[4:0]
BRAM_En_A
BRAM_WrData_A[31:0]
BRAM_RdData_A[31:0]
A0001000
01
2
INCR
00000001 00000002
F F
OKAY
1000
00 1F 00 1F
00000001 00000002
03020100 07060504
PG078_c3_11_082912
Send Feedback

## Page 50

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 50
PG078 October 5, 2016
Chapter 3: Designing with the Core
The AXI BRAM Controller can accept data on th e write data channel in the same clock cycle
when the write address is valid and accepted by the controller. The WREADY  signal remains
asserted to continually accept the burst, as the BRAM address counter is loaded and the
write data can pass to block RAM.
The AXI BRAM Controller ensures that  BREADY is not asserted prior to WVALID  and WREADY .
Figure 3-12  illustrates the capability to pipeline writ e addresses in the AXI BRAM Controller.
This example illustrates when a gap is seen on the write data channel by the AXI BRAM
Controller from the AXI Interconnect.
The AXI BRAM Controller can support back-to-back  write burst operations if supplied with
a continuous data stream from the AXI Intercon nect. In this case, there are no idle clock
cycles on the BRAM interface between the two pipelined write burst operations. Figure 3-13
illustrates the timing for back-to-back pipe lined write bursts of  four data beats.
To achieve 100% BRAM interface utilization on  the write port these conditions must be
satisfied:
•N o  s i n g l e  w r i t e  b u r s t s .
X-Ref Target - Figure 3-12
Figure 3-12: AXI Pipelined Burst Write Transfers
ACLK
AWID[3:0]
AWADDR[31:0]
AWLEN[7:0]
AWSIZE[2:0]
AWBURST[1:0]
AWLOCK[1:0]
AWVALID
AWREADY
WDATA[31:0]
WSTRB[3:0]
WLAST
WVALID
WREADY
BID[3:0]
BRESP[1:0]
BVALID
BREADY
BRAM_CLK
BRAM_Addr_A[10:0]
BRAM_WrData_A[31:0]
BRAM_WE_A[3:0]
BRAM_En_A
0 0
A0001000 A0002000
03 03
2 2
INCR INCR
0 0
D0 D1 D2 D3 D4 D5 D6 D7
F F F F F F F F
0 0
OKAY OKAY
1000 1004 1008 100C 2000 2004 2008 200C
F F
D0 D1 D2 D 3 D4 D5 D6 D7
PG078_c3_12_082912
Send Feedback

## Page 51

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 51
PG078 October 5, 2016
Chapter 3: Designing with the Core
• Write burst must be greater than two data beats.
• Write burst operation must be an INCR or WRAP burst type.
Delayed Write Address
The AXI BRAM Controller throttles the write da ta after one data beat prior to a provided
valid write address. The AXI BRAM  Controller only accepts early WVALID  and WDATA  when
configured in a dual port mode when ECC func tionality is disabled. The scenario timing is
shown in Figure 3-14 .
X-Ref Target - Figure 3-13
Figure 3-13: AXI Back to Back Write Burst Timing
ACLK
AWID[3:0]
AWADDR[31:0]
AWLEN[7:0]
AWSIZE[2:0]
AWBURST[1:0]
AWLOCK[1:0]
AWVALID
AWREADY
WDATA[31:0]
WSTRB[3:0]
WLAST
WVALID
WREADY
BID[3:0]
BRESP[1:0]
BVALID
BREADY
BRAM_CLK
BRAM_Addr_A[10:0]
BRAM_WrData_A[31:0]
BRAM_WE_A[3:0]
BRAM_En_A
0 0
A0001000 A0002000
03 03
2 2
INCR INCR
0 0
D0 D1 D2 D3 D4 D5 D6 D7
F F F F F F F F
0 0
OKAY OKAY
1000 1004 1008 100C 2000 2004 2008 200C
F F F F F F F F
D0 D1 D2 D 3 D4 D5 D6 D7
PG078_c3_13_082912
Send Feedback

## Page 52

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 52
PG078 October 5, 2016
Chapter 3: Designing with the Core
Read Bursting
Figure 3-15  illustrates the example timing for an AX I read burst with block RAM handled by
the AXI BRAM Controller. The memory read bu rst starts at address 0x1000h of the block
RAM, provided C_S_AXI_BASEADDR  = 0xA000 0000 and C_S_AXI_HIGHADDR  allows
more than 4k of addressable memory. The AXI Read Address Channel interface keeps the
ARREADY  signal asserted until the read address pi peline is full in the AXI BRAM Controller.
On the AXI Read Data Channel, the AXI BRAM Controller supports the AXI master/
Interconnect to respond to the RVALID  assertion with a same clock cycle assertion of
RREADY . If the requesting AXI master/Interconnect  throttles upon accepting the read burst
data (by negating RREADY ), the AXI BRAM Controller can manage this and holds the data
pipeline until RREADY  is asserted.
X-Ref Target - Figure 3-14
Figure 3-14: AXI Delayed Write Address
ACLK
AWID[3:0]
AWADDR[31:0]
AWLEN[7:0]
AWSIZE[2:0]
AWBURST[1:0]
AWLOCK[1:0]
AWVALID
AWREADY
WDATA[31:0]
WSTRB[3:0]
WLAST
WVALID
WREADY
BID[3:0]
BRESP[1:0]
BVALID
BREADY
BRAM_CLK
BRAM_Addr_A[10:0]
BRAM_WrData_A[31:0]
BRAM_WE_A[3:0]
BRAM_En_A
0
A0001000
03
2
INCR
0
D0 D1 D2 D3
F F F F
0
OKAY
1000 1004 1008 100C
D0 D1 D2 D3
F
PG078_c3_14_082912
Send Feedback

## Page 53

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 53
PG078 October 5, 2016
Chapter 3: Designing with the Core
Read Throttling
The AXI BRAM Controller must support read throttling. During a read operation, the AXI
BRAM issues read commands to the block RAM, but can only read ahead two addresses (the
amount of BRAM read data beats supported in the AXI BRAM Contro ller read data skid
buffer pipeline). The requesting AXI master is not required to capture all the data
immediately, but might throttle and only assert the RREADY  signal when data can be
accepted. The AXI BRAM Controller must halt the read operation and hold existing read
data when the requesting master negates RREADY . Figure 3-16  illustrates this behavior and
corresponding BRAM port operation. The two stage read data pipeline ensures that all
outputs to block RAM and outputs to the AXI read data channel are registered.
The behavior shown in Figure 3-16  reflects the condition when the master waits to assert
RREADY  until RVALID  is asserted. The AXI BRAM Controlle r can accept the master assertion
of RREADY  prior to the assertion of RVALID . Both signals must be asserted to advance the
read data skid buffer pipelin e in the AXI BRAM Controller.
X-Ref Target - Figure 3-15
Figure 3-15: AXI Read Burst Diagram
ACLK
ARID[3:0]
ARADDR[31:0]
ARLEN[7:0]
ARSIZE[2:0]
ARBURST[1:0]
ARLOCK[1:0]
ARVALID
ARREADY
RID[3:0]
RDATA[31:0]
RRESP[1:0]
RLAST
RVALID
RREADY
BRAM_Clk
BRAM_Addr_B[10:0]
BRAM_RdData_B[31:0]
BRAM_En_B
0
A0001000
03
2
INCR
0
0
D0 D1 D2 D3
OKAY
1000 1004 1008 100C
D0 D1 D2 D3
PG078_c3_15_082912
Send Feedback

## Page 54

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 54
PG078 October 5, 2016
Chapter 3: Designing with the Core
Read Address Pipeline
Figure 3-17  and Figure 3-18  illustrate examples of the ti ming for pipelined read burst
operations. The AXI BRAM Controller can handle  pipelined read addresses as a continuous
burst to block RAM. The master of the pipelined  read operation can accept data in the clock
cycle following the assertion of RLAST  (from the prior read operation) under these
conditions:
• The read operation is not a single data beat transfer
• The read burst is greater than two data beats
• The AXI burst operation size is equal to the data port size of the AXI Interconnect
• The requesting burst type is of type INCR or WRAP
• No throttling is detected (on the AXI read ch annel) for the current read burst after the
second to last BRAM address is registered out to memory
A continuous read burst to block RAM is suppor ted in both a dual port  configuration (using
the second port to block RAM), or in a single  port BRAM configuration (pending no active
pending write transfers).
X-Ref Target - Figure 3-16
Figure 3-16: AXI Read Burst Throttling
ACLK
ARID[3:0]
ARADDR[31:0]
ARLEN[7:0]
ARSIZE[2:0]
ARBURST[1:0]
ARLOCK[1:0]
ARVALID
ARREADY
RID[3:0]
RDATA[31:0]
RRESP[1:0]
RLAST
RVALID
RREADY
BRAM_Clk
BRAM_Addr_B[10:0]
BRAM_RdData_B[31:0]
BRAM_En_B
RdData_Buf_Ld
RdData_Buf
0
A0001000
03
2
INCR
0
0
D0 D1 D2 D3
OKAY
1000 1004 1008 100C
D0 D1 D2 D3
D0 D1 D2 D3
PG078_c3_16_082912
Send Feedback

## Page 55

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 55
PG078 October 5, 2016
Chapter 3: Designing with the Core
If any of these previously cited conditions exist on the pipelined read operations, the master
must wait until RVALID is reasserted to begi n reading data for the subsequent burst. The
expected delay is two AXI clock cycles until RVALID  is asserted after the prior RLAST  (when
any of these above conditions exist). Figure 3-18  illustrates the timing for this scenario.
Figure 3-17  illustrates the ability of the AXI BRAM Controller to accept pipelined read
request addresses and maintain 100% bus utilizati on to the block RAM. The data burst must
be greater than two data beats to reach a maximum 100% data throughput from the block
RAM with no idle clock cycles on the AXI read data channel. The requesting burst type must
be INCR or WRAP and the requesting read burst size must be equal to the size of the AXI
Interconnect read data port (no “narrow” burst type transactions) to achieve 100% bus
utilization on pipelined read bursts.
Utilization of the read data skid buffer illust rates the master capability to throttle on
accepting read data. The resulting BR AM transaction timing is shown in Figure 3-18 .
X-Ref Target - Figure 3-17
Figure 3-17: AXI 100% Bus Utilization on Pipelined Read Bursts
ACLK
ARID[3:0]
ARADDR[31:0]
ARLEN[7:0]
ARSIZE[2:0]
ARBURST[1:0]
ARLOCK[1:0]
ARVALID
ARREADY
RID[3:0]
RDATA[31:0]
RRESP[1:0]
RLAST
RVALID
RREADY
BRAM_Clk
BRAM_Addr_B[10:0]
BRAM_RdData_B[31:0]
BRAM_En_B
RdData_Buf_Ld
RdData_Buf
0 0
A0001000 A0002000
03 03
2 2
INCR INCR
0 0
0
D0 D1 D2 D3 D4 D5 D6 D7
OKAY
1000 1004 1008 100C 2000 2004 2008 200C
D0 D1 D2 D3 D4 D5 D6 D7
D0 D1 D2 D 3 D4 D5 D6 D7
PG078_c3_17_082912
Send Feedback

## Page 56

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 56
PG078 October 5, 2016
Chapter 3: Designing with the Core
Cacheline Reads
Figure 3-19  illustrates the timing on AXI WRAP or cacheline burst transactions. The address
generated to the block RAM starts at the targ et word and wraps around once the address
boundary is reached.
X-Ref Target - Figure 3-18
Figure 3-18: AXI Read Pipeline Throttling Timing
ACLK
ARID[3:0]
ARADDR[31:0]
ARLEN[7:0]
ARSIZE[2:0]
ARBURST[1:0]
ARLOCK[1:0]
ARVALID
ARREADY
RID[3:0]
RDATA[31:0]
RRESP[1:0]
RLAST
RVALID
RREADY
BRAM_Clk
BRAM_Addr_B[10:0]
BRAM_RdData_B[31:0]
BRAM_En_B
RdData_Buf_Ld
RdData_Buf
0 0
A0001000 A0002000
01 03
2 2
INCR INCR
0 0
0 0
OKAY OKAY
1000 1004 2000 2004 2008 200C
D0 D1 D4 D5 D6 D7
D0 D1 D4 D5 D6 D7
D0 D1 D4 D5 D6 D7
PG078_c3_18_082912
Send Feedback

## Page 57

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 57
PG078 October 5, 2016
Chapter 3: Designing with the Core
Dual Port BRAM Capability
Isolating the write and read ports to block RA M with each write and read channel interface
on the AXI bus, both BRAM port s can be utilized simultaneously. Figure 3-20  illustrates this
condition to provide no arbitrat ion on the write or read channels dependency on the other.
Single Port BRAM Capability
The AXI BRAM Controller can be configured (on an  AXI4 interface) to use only a single port
to block RAM. In this configuration, the AXI BRAM arbitrates on the AR and AW channels
and creates a single two-stage pipeline. The ar bitration scheme uses a least recently used
algorithm on ties of assertions between the S_AXI_ARVALID  and S_AXI_AWVALID
signals. For the illustration shown in Figure 3-21 , the AW channel won arbitration and
accesses the block RAM first.
X-Ref Target - Figure 3-19
Figure 3-19: AXI Cacheline Read
ACLK
ARID[3:0]
ARADDR[31:0]
ARLEN[7:0]
ARSIZE[2:0]
ARBURST[1:0]
ARLOCK[1:0]
ARVALID
ARREADY
RID[3:0]
RDATA[31:0]
RRESP[1:0]
RLAST
RVALID
RREADY
BRAM_Clk
BRAM_Addr_B[10:0]
BRAM_RdData_B[31:0]
BRAM_En_B
0
A0001004
03
2
WRAP
0
0
D1 D2 D3 D0
OKAY
1004 1008 100C 1000
D1 D2 D 3 D0
PG078_c3_19_082912
Send Feedback

## Page 58

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 58
PG078 October 5, 2016
Chapter 3: Designing with the Core
X-Ref Target - Figure 3-20
Figure 3-20: AXI Dual Port BRAM Capability
ACLK
AWID[3:0]
AWADDR[31:0]
AWLEN[7:0]
AWSIZE[2:0]
AWBURST[1:0]
AWLOCK[1:0]
AWVALID
AWREADY
WDATA[31:0]
WSTRB[3:0]
WLAST
WVALID
WREADY
BID[3:0]
BRESP[1:0]
BVALID
BREADY
ARID[3:0]
ARADDR[31:0]
ARLEN[7:0]
ARSIZE[2:0]
ARBURST[1:0]
ARLOCK[1:0]
ARVALID
ARREADY
RID[3:0]
RDATA[31:0]
RRESP[1:0]
RLAST
RVALID
RREADY
BRAM_Clk_A
BRAM_Addr_A[10:0]
BRAM_WrData_A[31:0]
BRAM_WE_A[3:0]
BRAM_En_A
BRAM_Addr_B[10:0]
BRAM_RdData_B[31:0]
BRAM_En_B
0
A0001000
03
2
INCR
0
F F F F
0
OKAY
0
A0002000
03
2
INCR
0
0
OKAY
1000 1004 1008 100C
F F F F
D0 D1 D2 D 3
D0 D1 D2 D 3
D0 D1 D2 D 3
2000 2004 200 8 200C
D0 D1 D2 D 3
BRAM_Clk_B
PG078_c3_20_082912
Send Feedback

## Page 59

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 59
PG078 October 5, 2016
Chapter 3: Designing with the Core
X-Ref Target - Figure 3-21
Figure 3-21: AXI4 Single Port BRAM Capability
ACLK
AWID[3:0]
AWADDR[31:0]
AWLEN[7:0]
AWSIZE[2:0]
AWBURST[1:0]
AWLOCK[1:0]
AWVALID
AWREADY
WDATA[31:0]
WSTRB[3:0]
WLAST
WVALID
WREADY
BID[3:0]
BRESP[1:0]
BVALID
BREADY
ARID[3:0]
ARADDR[31:0]
ARLEN[7:0]
ARSIZE[2:0]
ARBURST[1:0]
ARLOCK[1:0]
ARVALID
ARREADY
RID[3:0]
RDATA[31:0]
RRESP[1:0]
RLAST
RVALID
RREADY
BRAM_CLK
BRAM_Addr_A[10:0]
BRAM_En_A
BRAM_WE_A[3:0]
BRAM_WrData_A[31:0]
BRAM_RdData_A[31:0]
0
A0001000
03
2
INCR
0
D0000000
D1000000 D2000000
D3000000
F F F F
0
OKAY
0
A0001000
03
2
INCR
0
0
D0000000
D1000000 D2000000
D3000000
OKAY
1000 1004 1008 100C 1000 1004 1008 100C
F 0
D0000000
D1000000
D2000000
D3000000 D0000000
D1000000
D2000000
D3000000
PG078_c3_21_082912
Send Feedback

## Page 60

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 60
PG078 October 5, 2016
Chapter 3: Designing with the Core
Addressing Configurations
Table 3-1  illustrates the BRAM configuration (and  corresponding address assignment) for
targeting UltraScale, 7 series or Zynq-7000 SoC All Programmable device designs using the
36 Kb BRAM module.
Data Organization
The BRAM interface is designed to connect to the BRAM memory in a little-endian data
structure, in matching the AXI data structure.  The byte ordering and numbering for a 32-bit
BRAM is shown in Table 3-2  and Table 3-3  for a 64-bit BRAM.
Table 3-1: BRAM Configuration for UltraScale , 7 Series, or Zynq-7000 Devices
Supported Memory Sizes /
BRAM Memory Configuration
Number of
BRAM Primitives
(36k/each)
Size of
BRAM_Addr
(each port)
Typical BRAM_Addr Bit Usage
with BRAM Configuration
32-bit Data BRAM Data Width
4k / (1024 x 32) 11 0 BRAM_Addr [11:2]
8k / (2048 x 32) 21 1 BRAM_Addr [12:2]
16k / (4096 x 32) 41 2 BRAM_Addr [13:2]
32k / (8192 x 32) 81 3 BRAM_Addr [14:2]
64k / (16384 x 32) 16 14 BRAM_Addr [15:2]
128K / (32,768x32) 32 15 BRAM_Addr [16:2]
64-bit Data BRAM Data Width
8k / (1024 x 64) 21 0 BRAM_Addr [12:3]
16k / (2048 x 64) 41 1 BRAM_Addr [13:3]
32k / (4096 x 64) 81 2 BRAM_Addr [14:3]
64k / (8192 x 64) 16 13 BRAM_Addr [15:3]
128k / (16384 x 64) 32 14 BRAM_Addr [16:3]
128-bit Data BRAM Data Width
16k / (1024 x 128) 41 0 BRAM_Addr [13:4]
32k / (2048 x 128) 81 1 BRAM_Addr [14:4]
64k / (4096 x 128) 16 12 BRAM_Addr [15:4]
128k / (8192 x 128) 32 13 BRAM_Addr [16:4]
Table 3-2: Little Endian Byte Ordering (32-bit BRAM)
Byte Address n+3 n+2 n+1 n
Byte Label 3 21 0
Byte Significance MSByte LSByte
Send Feedback

## Page 61

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 61
PG078 October 5, 2016
Chapter 3: Designing with the Core
ECC
To mitigate the effect of BRAM Single Event Upsets, SEUs, the AXI BRAM Controller can be
configured to use Error Correction Codes, ECC. When writing to the block RAM, ECC bits are
generated and stored together with the written data. When reading from the block RAM,
the ECC bits are used to correct any single bit errors and detect any double bit errors in the
data read. Errors are either signaled on the AXI connection, AXI_RRESP (a SLVERR value) to
MicroBlaze™ processor (or the requesting AXI master device), or through an interrupt
signal.
ECC is available in both AXI4-Lite and AXI4  interface configurations of the AXI BRAM
Controller core, and for both single and dual port connection types to the BRAM block (the
setting of C_SINGLE_PORT_BRAM can be 0 or 1). ECC is supported on BRAM block data
widths of 32, 64, or 128 bits only. The only combination not allowed for ECC support is when
C_S_AXI_DATA_WIDTH = 256 or larger data widths.
The available ECC control and st atus registers described in ( ECC Register Details, page 24 )
are available when C_ECC = 1.
ECC is inserted on the write datapath in the AXI BRAM Controller for the data presented to
the BRAM block at each memory location. In a full AXI interface connection to support all
data transaction types (including narrow an d unaligned data transfers, the ECC logic
incorporates a read-modify-writ e sequence. The design ensures that each write to block
RAM stores the full data width, with the supporting ECC data bits. The AXI BRAM Controller
supports 32-bits of data, with 7 bits of ECC da ta generated. In a 64-bit configuration, 8 bits
of ECC data are created to store with the co rresponding data. For 128-bit BRAM data width
with ECC requires 9 bits of ECC to be stored with the data.
Each set of ECC bits are based (and calcul ated) on the full word (for 32-bit BRAM
configurations) or the full double word (in 64-bit BRAM configurat ions). For each AXI
transaction, a read-modify-write sequence is performed to read  the full word (or BRAM data
width) of data, merge in the new write data (i ndicated by the AXI_WSTRB signal) on the AXI
bus, and the write the new data (and ECC bits ) to block RAM. This sequence is shown in
Bit Label 31 0
Bit Significance MSBit LSBit
Table 3-3: Little Endian Byte Ordering (64-bit BRAM)
Byte Address n+7 n+6 ... n+1 n
Byte Label 7 6 ... 1 0
Byte Significance MSByte ... LSByte
Bit Label 63 0
Bit Significance MSBit LSBit
Table 3-2: Little Endian Byte Ordering (32-bit BRAM) (Cont’d)
Send Feedback

## Page 62

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 62
PG078 October 5, 2016
Chapter 3: Designing with the Core
Figure 3-4, page 38  (on the AXI4-Lite interface) and Figure 3-11, page 49  (for the AXI4
interface).
Table 3-4  summarizes the additional ECC data bits to the BRAM interface.
A hamming code algorithm is used to genera te the ECC bits for 32-bit and 64-bit BRAM
data widths. An HSIAO algorithm is used to generate the ECC bits for 32-bit, 64-bit and 128-
bit BRAM data widths.
The design parameter, C_ECC_ONOFF_RESET_VALU E (default on), determines the reset value
for the enable/disable setting of ECC. ECC ch ecking is on by default and can turned off
during reset.
Hsiao ECC
The Hsiao algorithm, which is utilized in the Xilinx MIG HDL and MPMC tools is
incorporated in the AXI BRAM Controller. The Hsiao algorithm provides an ECC encoding/
decoding for optimized resource utilization  and performance. The Hsiao algorithm is
designed such that an equal number of inputs are used to generate each check bit in the
ECC code. The number of inputs to generate each check bit depends on the overall data
width of the block RAM + required numbe r of ECC bits for that data width.
The AXI BRAM HDL generates the h-matrix as shown in Figure 3-22  for 32-bit BRAM data
width configurations. The same  methodology is applied to 64-bit and 128-bit data width
configurations with ECC enabled.  The h-matrix follows the rules of the Hsiao ECC algorithm.
See the IBM documentation by M.Y. Hsiao in References in Appendix D .
The dimensions of the h-matrix  is determined by the number of ECC bits and the overall
code width (which equals the BRAM data widt h + ECC code width). For 32-bit systems, the
h-matrix is 7 x 39. And filled by combinations of  (7 1) for the ECC bits, plus combinations of
(7 3). Not all (7 3) combinations are used  in the 32 data bits of the h-matrix.
For 64-bit systems, the h-matrix is 8 x 72. Th e h-matrix is constructed of all the (8 1)
combinations for the ECC bits, all (7 3) comb inations are used, and 8 combinations of the
weight-5 codes (8 5) are used.
The Hsiao generator creates the “one at a time ” column entries for the ECC parity bits. The
generator then starts at one end of the h-matrix (shown as the last entry in Figure 3-22 ),
and generates the combination of weight-3 code s. For 32-bit data widths, not all weight-3
Table 3-4: ECC Data Sizes
C_S_AXI_DATA_WIDTH Number of ECC data bits Number of ECC WEs
32 7 1
64 8 1
128 9 2
Send Feedback

## Page 63

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 63
PG078 October 5, 2016
Chapter 3: Designing with the Core
codes are used. For 64-bit h-ma trix generation, when all we ight-3 codes are used, it
generates weight-5 codes.
The previously described ECC encoding is no t unique; there are many other valid SEC-DEC
codes that can be utilized. Special consideratio n must be applied to systems in which port
B of the block RAM is used by a separate system or a different AXI BRAM Controller. The ECC
algorithms for encoding and decoding data  must be identical between both ports.
For ECC bit generation, the column of the h-matrix is merged with the data pattern written
to memory. The h-matrix bits pertaining to each check bit are XOR together to generate
each check bit.
Upon ECC decoding, the entire h-matrix (data bits + ECC bits) are used to generate the
syndrome value. For Hsiao ECC, when the syndro me value is equal to all zeros, no errors
exist in the data. When the syndrome value has at least one bit equal to ‘1’, and the number
of 1’s in the syndrome is an odd number, then  a single bit error is detected. The syndrome
value that matches the h-matrix indicates the bit position in error. When the syndrome
value has at least one bit equal to ‘1’, and the number of 1’s in the syndrome is an even
number, then a double bit error is detected.
The parity check matrix for 32-bit BRAM data (39, 32) Hsiao code is shown in Figure 3-22 .
Send Feedback

## Page 64

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 64
PG078 October 5, 2016
Chapter 3: Designing with the Core
X-Ref Target - Figure 3-22
Figure 3-22: 32-bit Hsiao Encoding
31
01
234
02
04
08
10
20
40
0E 0001110
0010011
0010101
0010110
30
29
28
35
34
33
38
37
36
32
4
5
6
1
2
3
7
27
26
25
24
23
22
21
20
19
18
17
16
15
14
13
12
11
10
9
8
7
6
5
4
3
2
1
0
H-Matrix
Bit
H-Matrix Value
(Hex) (6:0)
H-Matrix Value
(Binary) (6:0)
ECC Bit Positions
Set to '1' Notes
Again, finds next combination based on prior seed.
Starting point in H-matrix calculation. Three unique
bits of the ECC word are asserted.
Generates “1101000” based on initial
seed of prior combination, “111000”.
When the h-matrix reaches the data width, only
one bit in the the ECC word is asserted.
And so on...
PG078_c3_01_082812
0011001
0011010
0011100
0000010
0000100
0001000
0010000
0100000
1000000
0100011
0100101
0100110
0101001
0101010
0101100
1110000
1101000
1100100
1100010
1100001
1011000
1010100
1010010
1010001
1001100
1001010
1001001
1000110
1000101
1000011
0111000
0110100
0110010
0110001
13
15
16
19
1A
1C
23
25
26
29
2A
2C
31
32
34
38
43
45
46
40
4A
4C
51
52
54
58
61
62
64
68
70
125
135
235
145
245
345
126
136
236
146
246
346
156
256
356
456
127
137
237
147
247
347
157
257
357
457
167
267
367
467
567
0000001
Send Feedback

## Page 65

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 65
PG078 October 5, 2016
Chapter 3: Designing with the Core
The h-matrix generated for 64-bit ECC encoding in shown in Figure 3-23 .
X-Ref Target - Figure 3-23
Figure 3-23: 64-bit Hsiao Encoding
71 00000001
00000010
00000100
31
70
69
68
67
66
65
64
63
62
61
60
59
58
57
56
55
54
53
52
51
50
49
48
47
46
45
44
43
42
41
40
39
...
31
30
29
28
27
26
25
24
23
22
21
20
19
18
17
16
15
14
13
12
11
10
9
8
7
6
5
4
3
2
1
0
H-Matrix
Bit
H-Matrix
Value (Hex)
(7:0)
H-Matrix
Value
(Binary) (7:0)
H-Matrix
Value (Hex)
(7:0)
H-Matrix
Value
(Binary) (7:0)
Notes H-Matrix
Bit Notes
When the H-matrix reaches the
data width maximum, only one
bit of the ECC is asserted.
Starts with weight-5 codes.
Some implementations of Hsiao
dispurse the weight-5 codes
with the weight-3 codes, but
they are assigned to the upper
order data bits.
64-bit Hsiao uses all weight-3
code combinations.
Again, finds next combination
based on prior seed.
Starting point in H-matrix
calculation.
Generates “1101000” based on
initial seed of prior combination,
“111000”.
And so on...
PG078_c3_02_082812
00001000
00010000
00100000
01000000
10000000
11100110
11101001
11101010
11101100
11110001
11110010
11110100
11111000
00000111
00001011
00001101
00001110
00010011
00010101
00010110
00011001
00011010
00011100
00100011
00100101
00100110
00101001
00101010
00101100
01
02
04
08
10
20
40
80
E6
E9
Ea
Ec
F1
F2
F4
F8
07
0B
0d
0E
13
15
16
19
1A
1C
23
25
26
29
2A
2C
00110001
4A 01001000
01001100
01010001
01010010
01010100
01011000
01100001
01100010
01100100
01101000
01110000
10000011
10000101
10000110
10001001
10001010
10001100
10010001
10010010
10010100
10011000
10100001
10100010
10100100
10101000
10110000
11000001
11000010
11001000
11001000
11010000
11100000E0
D0
C8
C4
C3
C1
B0
A8
A4
A2
A1
98
94
92
91
8C
8A
89
86
85
83
70
68
64
62
61
58
54
52
51
4C
Send Feedback

## Page 66

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 66
PG078 October 5, 2016
Chapter 3: Designing with the Core
The Hsiao ECC encoding (137, 128) for 128-bit configurations is shown in Figure 3-24 . Not
all encodings are shown, but the concept is identical to the 32-bit and 64-bit
implementations. The 128-bit ECC algorithm is shown in Figure 3-24 .
Hamming Code
The ECC supports the BRAM data widths of 32-bit and 64-bits. The ECC used is a (32, 7)
Hamming code with the coding defined by Table 3-5 .
X-Ref Target - Figure 3-24
Figure 3-24: 128-bit Hsiao Encoding
H-Matrix
Bit
H-Matrix Value
(Hex) (8:0)
H-Matrix Value
Binary (8:0) Notes
136
135
134
133
132
131
130
129
128
127
126
125
124
123
122
121
120
119
118
117
116
85
84
83
...
...
7
6
5
4
3
2
1
0
001
002
004
008
010
020
040
080
100
165
166
169
16C
171
172
174
178
187
18B
18D
18E
1E8
1F0
007
160
181
182
184
188
190
1A0
1C0
000000001
000000010
000000100
000001000
000010000
000100000
001000000
010000000
100000000
101100101
101100110
101101001
101101100
101110001
101110010
101110100
101111000
110000111
110001011
110001101
110001110
111101000
111110000
000000111
101100000
110000001
110000010
110000100
110001000
110010000
110100000
111000000
When the H-matrix reaches the data width
maximum, the ECC bits have one bit asserted.
Weight-5 codes
Start of weight-5 codes
Last combination of a weight-3 code
Start with weight-3 code (MSB all 1s)
PG078_c3_03_082812
Table 3-5: ECC 32-bit Encoding
Participating
Data Bits ECC0 ECC1 ECC2 ECC3 ECC4 ECC5 ECC6
0 •• •
1 •• •
2 •• •
Send Feedback

## Page 67

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 67
PG078 October 5, 2016
Chapter 3: Designing with the Core
The ECC used in the AXI BRAM controller when  C_S_AXI_DATA_WIDTH is set to 64 is based
on (64, 8) Hamming code derived from the (32, 7) 32-bit hamming code methodology. The
generation of the 8-bit ECC check bits for a 64-bit BRAM data width is shown in Table 3-6 .
3 •••
4 •••
5 •• •
6 •• •
7 •• •
8 •• •
9 •••
10 •••• •
11 •• •
12 •• •
13 •• •
14 •••
15 •••
16 •• •
17 ••• • •
18 •• •
19 •• •
20 •• •
21 •• •• •
22 •••
23 • ••• •
24 •••• •
25 •••••
26 • ••
27 •• •
28 •• •
29 •• •
30 •• •
31 •• •
Table 3-5: ECC 32-bit Encoding
Participating
Data Bits ECC0 ECC1 ECC2 ECC3 ECC4 ECC5 ECC6
Send Feedback

## Page 68

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 68
PG078 October 5, 2016
Chapter 3: Designing with the Core
Table 3-6: ECC 64-bit Encoding
Participating
Data Bits ECC0 ECC1 ECC2 ECC3 ECC4 ECC5 ECC6
ECC7
(Overall
Parity =
Inverted)
0-31 Same as shown in Table 3-5 .S e t  t o  ‘ 0 ’
Holds
ECC6 bit
settings
from
Table 3-5 .
32 ••• • •
33 •• •
34 •• •
35 •••
36 • ••• •
37 •• •
38 •• •• •
39 ••• • •
40 •••• •
41 •• •
42 •• •
43 •• •
44 •• •• •
45 •• •
46 ••• • •
47 •• •• •
48 ••• ••
49 •••
50 •• • • •
51 •• • • •
52 •• •••
53 •••• •
54 •• • • •
55 •••••
56 •••••• •
57 • ••
58 •• •
59 •• •
60 •• •
61 •• •
Send Feedback

## Page 69

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 69
PG078 October 5, 2016
Chapter 3: Designing with the Core
Clocking
The AXI BRAM Controller is fully synchronou s with all clocked elements clocked with
S_AXI_ACLK . The BRAM_Clk_A  is the output clock used for clocking the BRAM Interface,
which is connected to S_AXI_ACLK  with same frequency and phase alignment.
Resets
The S_AXI_ARESETN  is the master reset input signal for the AXI BRAM Controller used in
both S_AXI  and S_AXI_CTRL . The BRAM_Rst_A  output signal is used to drive the BRAM
Interface.
62 •• •
63 ••• • •
Table 3-6: ECC 64-bit Encoding
Participating
Data Bits ECC0 ECC1 ECC2 ECC3 ECC4 ECC5 ECC6
ECC7
(Overall
Parity =
Inverted)
Send Feedback

## Page 70

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 70
PG078 October 5, 2016
Chapter 4
Design Flow Steps
This chapter describes customizing and generati ng the core, constraining the core, and the
simulation, synthesis and implementation steps that are specific to this IP core. More
detailed information about the standard Vivado® design flows and the IP integrator can be
found in the following Vivado  Design Suite user guides:
• Vivado Design Suite User Guide: Designing IP Subsystems using IP Integrator  (UG994)
[Ref 3]
• Vivado Design Suite User Guide: Designing with IP  (UG896) [Ref 8]
• Vivado Design Suite User Guide: Getting Started  (UG910) [Ref 9]
• Vivado Design Suite User Guide: Logic Simulation  (UG900) [Ref 10]
Customizing and Generating the Core
This section includes information about using Xilinx tools to customize and generate the
core in the Vivado Design Suite environment.
Vivado Integrated Design Environment (IDE)
You can customize the IP for use in your design by specifying values for the various
parameters associated with the IP  core using the following steps:
1. Select the IP from the IP catalog.
2. Double-click the selected IP or select th e Customize IP command from the toolbar or
right-click menu .
For details, see the Vivado Design Suite User Guide: Designing with IP  (UG896) [Ref 8]  and
the Vivado Design Suite User  Guide: Getting Started  (UG910) [Ref 9] .
Note:
Figures in this chapter are illustrations of the Vivado IDE. This layout might vary from the
current version.
The AXI BRAM Controller parameters are divided in three categories within the IDE: General
Protocol options, BRAM options and ECC Options.
Send Feedback

## Page 71

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 71
PG078 October 5, 2016
Chapter 4: Design Flow Steps
General Protocol Options
• AXI Protocol : AXI protocol connection type: AXI4, AXI3 or AXI4-Lite.
• Data Width : Data width of AXI slave (BRAM data width): 32, 64, 128, 256, 512 or 1024
bits. The maximum data width supported is 1024 bits.
• Memory Depth : Memory depth of AXI Slave: 1k, 2k, 4k, 8k, 16k, 32k, 64k, 128k, or
256k words. The maximum memory de pth supported is 128K words. See Table 1-1  for
more details.
Note: When using IP integrator, the value of this parameter is automatically propagated during
the design validation from the master.
In IP Integrator, AXI BRAM Controller supports the following Memory Width and Depth
values.
X-Ref Target - Figure 4-1
Figure 4-1: Customize IP - AXI BRAM Controller
Send Feedback

## Page 72

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 72
PG078 October 5, 2016
Chapter 4: Design Flow Steps
AXI BRAM Controller supports the following me mory width and memory depth values when
connected to Block Memory Generator IP.
• ID Width : Width of ID vectors in AXI system (inc ludes all master and slave devices). The
range of ID width supported is 0 to 32.
Note: When using IP integrator, the value of this parameter is automatically propagated during
the design validation from the master.
• Support AXI Narrow Bursts : Support of AXI4 narrow write or read operations.
Note: When using IP Integrator, you can set the value of this parameter or set it to Auto, in
which the value is propagated from the master.
Table 4-1: Memory Width and Depth values in IP Integrator
Memory Width Memory Depth
less than or equal to 128 512,1024,2048,4096,8192,16384,32768,65536,131072,262
144,524288,1048576,2097152,4194304,8388608,1677721
6,33554432,67108864,134217728,268435456,536870912,
1073741824
greater than 128 and less than or equal to
256
512,1024,2048,4096,8192,16384,32768,65536,131072,262
144,524288,1048576,2097152,4194304,8388608,1677721
6,33554432,67108864,134217728,268435456,536870912
greater than 256 and less than or equal to
512
512,1024,2048,4096,8192,16384,32768,65536,131072,262
144,524288,1048576,2097152,4194304,8388608,1677721
6,33554432,67108864,134217728,268435456
greater than 512 and less than or equal to
1024
512,1024,2048,4096,8192,16384,32768,65536,131072,262
144,524288,1048576,2097152,4194304,8388608,1677721
6,33554432,67108864,134217728
greater than 1024 and less  than or equal to
2048
512,1024,2048,4096,8192,16384,32768,65536,131072,262
144,524288,1048576,2097152,4194304,8388608,1677721
6,33554432,67108864
Table 4-2: Memory Width and Depth values when connected to Block Memory Generator IP
Memory Width Memory Depth
less than or equal to 128 1024,2048,4096,8192,16384,32768,65536,131072,262144
greater than 128 and less than or equal to
256
1024,2048,4096,8192,16384,32768,65536,131072
greater than 256 and less than or equal to
512
1024,2048,4096,8192,16384,32768,65536
greater than 512 and less than or equal to
1024
1024,2048,4096,8192,16384,32768
greater than 1024 and less  than or equal to
2048
1024,2048,4096,8192,16384
Send Feedback

## Page 73

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 73
PG078 October 5, 2016
Chapter 4: Design Flow Steps
• BRAM Instance : Specifies whether the BRAMs are available internally (with the AXI
BRAM CTRL IP) or externally.
Note: When using IP integrator, the value of the BRAM Instance parameter is set to External .
The Number of BRAM Interfaces can be set to ei ther single port (1) or dual port (2) BRAM
Interface.
• ECC Options :
° Enable ECC: Enables or disables the ECC checking.
° ECC Type: Select the ECC algorithm to be used: Hamming  (default) or HSIAO . This
option is available only when Enable ECC  is Yes.
° Enable Fault Injection: Specifies whether the fault is injected. When this option is
Yes, the errors can be injected in the data as well as in the generated ECC written to
the block RAM. This option is available only when Enable ECC  is Yes.
° ECC Reset Value: Determines the reset value for the enable/disable setting of ECC.
ECC checking can be turned on/off during reset using this option. This option is
available only when Enable ECC  is Yes.
Output Generation
For details, see “Generating IP Output Products” in the Vivado Design Suite User Guide:
Designing with IP  (UG896) [Ref 8] .
Constraining the Core
This section contains information about constr aining the core in the Vivado Design Suite.
Required Constraints
There are no required constraints for this core.
Device, Package, and Speed Grade Selections
The target technology is an FPGA listed in th e Supported Device Family field in the Vivado
IP Catalog.
Clock Frequencies
See Performance in Chapter 2  for information about clock frequencies.
Send Feedback

## Page 74

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 74
PG078 October 5, 2016
Chapter 4: Design Flow Steps
Clock Management
The AXI BRAM Controller is fully synchronou s with all clocked elements clocked by the
s_axi_aclk  input.
For MicroBlaze™ processor operation, the s_axi_aclk  must be the same as the
MicroBlaze clock.
Clock Placement
There are no clock placement requirements for this core.
Banking
There are no banking requirements for this core.
Transceiver Placement
There are no transceiver requirements for this core.
I/O Standard and Placement
There are no I/O requirements for this core.
Simulation
This section contains information about simulating  IP in the Vivado Design Suite.For details,
see the Vivado Design Suite User Guide: Logic Simulation (UG900) [Ref 10] .
Synthesis and Implementation
This section contains information about synthesis and implementation in the Vivado Design
Suite.
For details about synthesis and implementation, see the Vivado Design Suite User Guide:
Designing with IP  (UG896) [Ref 8] .
Send Feedback

## Page 75

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 75
PG078 October 5, 2016
Chapter 5
Test Bench
This chapter contains information about the test bench provided in the Vivado® Design
Suite. Figure 5-1  shows a block diagram of th e demonstration test bench.
The demonstration test bench is a straightforward VHDL file to  exercise the example design
and the core itself. The test be nch consists of the following:
•C l o c k  g e n e r a t o r s
• Stimulus generator module which includes the address and data generator module
• Data checker
• Protocol checks for the AXI4 protocol
The demonstration test bench in a core with an  AXI4 interface performs the following tasks:
• Input clock signals are generated.
• A reset is applied to the example design.
• Stimulus is generated only for incremente d burst, and narrow transactions are not
exercised.
• Address is generated in a linear incremented format.
• Pseudo-random data is generated for WDATA.
X-Ref Target - Figure 5-1
Figure 5-1: Test Bench Block Diagram
Test Bench Top
Test Bench Wrapper
Core Example Design
Checker
Stimulus
GeneratorClk &
Reset
Generator
User
Interface
IOBs
AXI BRAM
CORE
X12417
Send Feedback

## Page 76

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 76
PG078 October 5, 2016
Chapter 5: Test Bench
• Length (AWLEN/ARLEN) is  determined randomly.
• During read, RDATA is compared with anot her pseudo-random generator with the same
seed as WDATA random data generator.
• A basic AXI4 protocol checker checks the protocol violations.
• Core is exercised with 256 AXI4 write and read transactions.
Messages and Warnings
When the functional or timing simulation has completed successfully, the test bench
displays the following message, and it  is safe to ignore this message.
Failure: Test Completed Successfully
Send Feedback

## Page 77

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 77
PG078 October 5, 2016
Chapter 6
Example Design
This chapter contains information about th e example design provided in the Vivado®
Design Suite.The AXI BRAM Controller example design includes the following:
• HDL wrapper that instantiates the AXI BRAM Controller netlist
• AXI BRAM Controller constraint file
The AXI BRAM Controller example design has been tested with the Vivado Design Suite.
Send Feedback

## Page 78

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 78
PG078 October 5, 2016
Appendix A
Migrating and Upgrading
This appendix contains information about migrating a design from ISE ® to the Vivado ®
Design Suite, and for upgrading to a more re cent version of the IP core. For customers
upgrading in the Vivado Design Suite, import ant details (where appl icable) about any port
changes and other impact to user logic are included.
Migrating to the Vivado Design Suite
For information about migrating to the Vivado Design Suite, see the ISE to Vivado Design
Suite Migration Guide (UG911)  [Ref 11] .
Upgrading in the Vivado Design Suite
This section provides in formation about any changes to the user logic or port designations
that take place when you upgrad e to a more current version of this IP core in the Vivado
Design Suite.
Parameter Changes
The user parameter "ADDR_WIDTH" has been removed.
Port Changes
The ID ports ( s_axi_arid , s_axi_awid , s_axi_bid , and s_axi_rid ) are not
generated when the ID width is set to 0.
Send Feedback

## Page 79

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 79
PG078 October 5, 2016
Appendix B
Verification, Compliance, and
Interoperability
Simulation
The AXI BRAM Controller core delivered is rigo rously verified using advanced verification
techniques, including a constrained random configuration generator.
Send Feedback

## Page 80

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 80
PG078 October 5, 2016
Appendix C
Debugging
This appendix includes details  about resources available on the Xilinx Support website and
debugging tools.
Finding Help on Xilinx.com
To help in the design and debug process when using the AXI BRAM Controller, the Xilinx
Support web page  contains key resources such as pr oduct documentation, release notes,
answer records, information about known issues, and links for obtaining further product
support.
Documentation
This product guide is the main document asso ciated with the AXI BRAM Controller. This
guide, along with documentation related to all products that aid in the design process, can
be found on the Xilinx Support web page  or by using the Xilinx Documentatio n Navigator.
Download the Xilinx Documentation Navigator from the Downloads page . For more
information about this tool and the features available, open the online help after
installation.
Answer Records
Answer Records include information abou t commonly encountered problems, helpful
information on how to resolve these problems, and any known issues with a Xilinx product.
Answer Records are created and maintained da ily ensuring that users have access to the
most accurate information available.
Answer Records for this core are listed belo w, and can be located by using the Search
Support box on the main Xilinx support web page . To maximize your search results, use
proper keywords such as
• Product name
• Tool message(s)
• Summary of the issue encountered
Send Feedback

## Page 81

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 81
PG078 October 5, 2016
Appendix C: Debugging
A filter search is available after results are returned to further target the results.
Master Answer Record
AR: 54418
Technical Support
Xilinx provides technical support in the Xilinx Support web page  for this LogiCORE™ IP
product when used as described in the prod uct documentation. Xili nx cannot guarantee
timing, functionality, or support if you do any of the following:
• Implement the solution in devices that  are not defined in the documentation.
• Customize the solution beyond that allowed in the product documentation.
• Change any section of the de sign labeled DO NOT MODIFY.
Xilinx provides premier techni cal support for customers enco untering issues that require
additional assistance.
To contact Xilinx Technical Support, navigate to the Xilinx Support web page .
Note: Access to WebCase is not availabl e in all cases. Login to the WebC ase tool to see your specific
support options.
Debug Tools
There are many tools available to address AXI BR AM Controller design i ssues. It is important
to know which tools are useful for debugging various situations.
Vivado Design Suite Debug Feature
Vivado Design Suite debug feature inserts logic analyzer and virtual I/O cores directly into
your design. This feature allows you to set trigger conditions to capture application and
integrated block port signals in hardware. Ca ptured signals can then be analyzed. This
feature represents the functionality in the Viva do IDE that is used for logic debugging and
validation of a design running in  Xilinx FPGA devices in hardware.
The Vivado logic analyzer is used to interact with the logic debug LogiCORE IP cores,
including:
• ILA 2.0 (and later versions)
• VIO 2.0 (and later versions)
See Vivado Design Suite User Guid e: Programming and Debugging  (UG908) [Ref 12] .
Send Feedback

## Page 82

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 82
PG078 October 5, 2016
Appendix C: Debugging
Reference Boards
Various Xilinx development boards support theA XI BRAM Controller. These boards can be
used to prototype designs and establish that  the core can communicate with the system.
• 7 series FPGA evaluation boards
° KC705
° KC724
Hardware Debug
Hardware issues can range from link bring-up to problems seen  after hours of testing. This
section provides debug steps for common i ssues. The ChipScope debugging tool is a
valuable resource to use in hardware debug.  The signal names mentioned in the following
individual sections can be probed using the ChipScope debugging tool for debugging the
specific problems.
General Checks
Ensure that all the timing constraints for the core were properly incorporated from the
example design and that all constraints were met during implementation.
• Does it work in post-place and route timi ng simulation? If problems are seen in
hardware but not in timing simulation, this could indicate a PCB issue. Ensure that all
clock sources are active and clean.
• If your outputs go to 0, check your licensing.
Interface Debug
AXI4-Lite Interfaces
Read from a register that does not have all 0s as a default to verify that the interface is
functional. See Figure 3-3  for a read timing diagram. Output s_axi_arready  asserts when
the read address is valid, and output s_axi_rvalid  asserts when the read data/response
is valid. If the interface is unresponsive, en sure that the following conditions are met:
•T h e  S_AXI_ACLK and ACLK  inputs are connected and toggling.
• The interface is not being held in reset, and S_AXI_ARESET  is an active-Low reset.
Send Feedback

## Page 83

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 83
PG078 October 5, 2016
Appendix D
Additional Resources and Legal Notices
Xilinx Resources
For support resources such as Answers, Documentation, Downloads, and Forums, see Xilinx
Support .
References
These documents provide supplemental mate rial useful with this product guide:
1. AMBA AXI4-Stream Protocol Specification
2. LogiCORE IP AXI Interconnect  Data Sheet  (DS768 )
3. Vivado Design Suite User Guide: Designing IP Subsystems using IP Integrator  (UG994 )
4. 7 Series FPGA Overview  (DS180 )
5. 7 Series FPGAs Memory Interface Solutions User Guide  (UG586 )
6. IBM Technical Journal. M. Y. Hsiao. A Class of Optimal Minimum Odd-weight-column
SEC=DED Codes . July 1970.
7. Vivado Design Suite Migration Methodology Guide  (UG911 )
8. Vivado Design Suite User Guide: Designing with IP  (UG896 )
9. Vivado Design Suite User Guide: Getting Started  (UG910 )
10. Vivado Design Suite User Guide: Logic Simulation  (UG900 )
11. ISE to Vivado Design Suite Migration Methodology Guide  (UG911 )
12. Vivado Design Suite User Gu ide: Programming and Debugging  (UG908 )
Revision History
The following table shows the revision history for this document.
Send Feedback

## Page 84

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 84
PG078 October 5, 2016
Appendix D: Additional Resources and Legal Notices

Date Version Revision
10/05/2016 4.0 Updated the support of minimum dept h in supported memory size table.
04/06/2016 4.0 Minimum depth allowed for AXI BRAM Co ntroller is set to 512 for IPI designs.
11/18/2015 4.0 Added support for UltraScale+ families.
09/30/2015 4.0 Address range supported is increa sed to 2G in IP Integrator.
04/02/2014 4.0 Updated the behavior of the ID ports (s _axi_arid, s_axi_awid, s_axi_bid, and
s_axi_rid) when the ID width is set to 0.
12/18/2013 3.0 • Added support of Hamming code for the BRAM data widths of 32 and
64-bits.
• Added support for UltraScale™ devices.
10/02/2013 3.0 • Added details about the Supported  Memory Size in Chapter 1.
• Changed signal names to all use lowercase.
• Updated the data in Table 2-1.
• Added ECC options in the Vivado IDE.
• Added Simulation, Synthesis and Implem entation, Example Design and Test
Bench chapters.
• Added support for IP integrator.
03/20/2013 3.0 Updated core version. Updated core registers.
12/18/2012 2.0 Updated for Vivado Design Suite 2012.4. Added BRAM Instance option in the
GUI description in Chap ter 4, Customizing and Generating the Core.
10/16/2012 1.0 Initial Xilinx release as a product guide. Replaces DS777, LogiCORE IP AXI
BRAM Controller Data Sheet .
• Updated for Vivado Design Suite 2012.3.
• Removed support for ISE Desi gn Suite Embedded Edition.
Send Feedback

## Page 85

LogiCORE IP AXI BRAM Controller v4.0 www.xilinx.com 85
PG078 October 5, 2016
Appendix D: Additional Resources and Legal Notices
Please Read: Important Legal Notices
The information disclosed to you hereunder (the "Materials") is provided solely for the selection and use of Xilinx products. T o the
maximum extent permitted by appl icable law: (1) Materials are made available "A S IS" and with all faults, Xilinx hereby DISCLAI MS
ALL WARRANTIES AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and (2) Xilinx shall not be liable (whether
in contract or tort, including negligence, or under any other theo ry of liability) for any loss or damage of any kind or nature  related
to, arising under, or in connection with, the Materials (includi ng your use of the Materials), including for any direct, indire ct, special,
incidental, or consequential loss or damage (including loss of da ta, profits, goodwill, or any type of loss or damage suffered as a
result of any action brought by a third party) even if such damage or loss was reasonably foreseeable or Xilinx had been advise d
of the possibility of the same. Xilinx assumes no obligation to correct any errors contained in the Materials or to notify you of
updates to the Materials or to product spec ifications. You may not reproduce, modify, distribute, or publicly display the Mater ials
without prior written consent. Certain products are subject to th e terms and conditions of Xilinx's limited warranty, please re fer to
Xilinx's Terms of Sale which can be viewed at http://www.xilinx.com/legal.htm#tos
; IP cores may be subject to warranty and support
terms contained in a license issued to you by Xilinx. Xilinx products are not designed or intended to be fail-safe or for use i n any
application requiring fail-safe performance; you assume sole risk and liability for use of Xilinx products in such critical app lications,
please refer to Xilinx's Terms of Sale which can be viewed at http://www.xilinx.com/legal.htm#tos .
AUTOMOTIVE APPLICATIONS DISCLAIMER
AUTOMOTIVE PRODUCTS (IDENTIFIED AS “XA” IN THE PART NUMBER) ARE NOT WARRANTED FOR USE IN THE DEPLOYMENT OF
AIRBAGS OR FOR USE IN APPLICATIONS THAT AFFECT CONTROL OF A VEHICLE (“S AFETY APPLICATION”) UNLESS THERE IS A
SAFETY CONCEPT OR RE DUNDANCY FEATURE CONSISTENT WITH THE ISO 26262 AUTOMOTIVE SAFETY STANDARD (“SAFETY
DESIGN”). CUSTOMER SHALL, PRIOR TO USING OR DISTRIBUTI NG ANY SYSTEMS THAT INCORPORATE PRODUCTS, THOROUGHLY
TEST SUCH SYSTEMS FOR SAFETY PURPOSES. USE OF PRODUCTS IN  A SAFETY APPLICATION WITHOUT A SAFETY DESIGN IS FULLY
AT THE RISK OF CUSTOMER, SUBJECT ONLY TO APPLICABLE LAWS AND REGULATIONS GOVERNING LIMITATIONS ON PRODUCT
LIABILITY.
© Copyright 2012-2016 Xilinx, Inc. Xilinx, the Xilinx logo, Artix,  ISE, Kintex, Spartan, Virtex , Vivado, Zynq, and other design ated
brands included herein are trademarks of Xilinx in the United States and other countries. All other trademarks are the property  of
their respective owners.
Send Feedback
