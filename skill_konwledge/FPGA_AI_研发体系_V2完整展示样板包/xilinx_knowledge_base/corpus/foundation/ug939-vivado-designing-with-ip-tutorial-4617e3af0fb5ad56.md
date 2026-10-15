# ug939-vivado-designing-with-ip-tutorial

- Category: `foundation`
- Source: `F:\Xiliinx文档\ug939-vivado-designing-with-ip-tutorial.pdf`
- SHA-256: `4617e3af0fb5ad561cc307b7bd2f1bcf3dc4f8b35fe0e6d1161deac2eeb90a99`
- Extractor: `pypdf:81pages`
- Tags: `ip, vivado`
- Duplicate sources:
  - none

## Page 1

Vivado Design Suite
Tutorial
Designing with IP
UG939 (v2014.1) April 2, 2014

## Page 2

Notice of Disclaimer
The information disclosed to you hereunder (the “Materials”) is provided solely for the selection and use of Xilinx products. To the
maximum extent permitted by applicable law: (1) Materials are made available "AS IS" and with all faults, Xilinx hereby DISCLAIMS
ALL WARRANTIES AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and (2) Xilinx shall not be liable (whether
in contract or tort, including negligence, or under any other theory of liability) for any loss or damage of any kind or nature related
to, arising under, or in connection with, the Materials (including your use of the Materials), including for any direct, indirect, special,
incidental, or consequential loss or damage (including loss of data, profits, goodwill, or any type of loss or damage suffered as a
result of any action brought by a third party) even if such damage or loss was reasonably foreseeable or Xilinx had been advised of
the possibility of the same. Xilinx assumes no obligation to correct any errors contained in the Materials or to notify you of updates
to the Materials or to product specifications. You may not reproduce, modify, distribute, or publicly display the Materials without
prior written consent. Certain products are subject to the terms and conditions of Xilinx’s limited warranty, please refer to Xilinx’s
Terms of Sale which can be viewed at http://www.xilinx.com/legal.htm#tos; IP cores may be subject to warranty and support terms
contained in a license issued to you by Xilinx. Xilinx products are not designed or intended to be fail-safe or for use in any
application requiring fail-safe performance; you assume sole risk and liability for use of Xilinx products in such critical applications,
please refer to Xilinx’s Terms of Sale which can be viewed at http://www.xilinx.com/legal.htm#tos.
©Copyright 2012-2014 Xilinx, Inc. Xilinx, the Xilinx logo, Artix, Vivado, ISE, Kintex, Spartan, UltraScale, Virtex, Vivado, Zynq, and other
designated brands included herein are trademarks of Xilinx in the United States and other countries. All other trademarks are the
property of their respective owners.

Revision History
Date Version Revision
04/02/2014 2014.1 Validated with release.


Send Feedback

## Page 3

Designing with IP  www.xilinx.com  3
UG939 (v2014.1) April 2, 2014
Table of Contents
Revision History .................................................................................................................................................................................... 2
Table of Contents ................................................................................................................................................................................. 3
Designing with IP .................................................................................................................................................................................. 5
Overview ............................................................................................................................................................................................. 5
Tutorial Description ........................................................................................................................................................................ 6
Hardware and Software Requirements ................................................................................................................................... 6
Locating and Preparing the Tutorial Design Files .............................................................................................................. 7
Lab 1: Designing with the IP Catalog ........................................................................................................................................... 8
Step 1: Opening the Project ........................................................................................................................................................ 8
Launch Vivado ............................................................................................................................................................................. 8
Open the Project ........................................................................................................................................................................ 9
Step 2: Customizing the FIFO Generator ............................................................................................................................ 10
Step 3: Generate Output Products ........................................................................................................................................ 14
Step 4: Instantiating IP into the Design ............................................................................................................................... 16
Step 5: Synthesizing the Design ............................................................................................................................................. 19
Conclusion ....................................................................................................................................................................................... 21
Lab 2: Creating and Managing Reusable IP ............................................................................................................................ 22
Step 1: Starting a Manage IP session ................................................................................................................................... 22
Step 2: Customizing the FIFO Generator ............................................................................................................................ 24
Step 3: Using Third Party Simulators .................................................................................................................................... 28
Using Export Simulation ....................................................................................................................................................... 29
Getting Required Simulation Files .................................................................................................................................... 29
Structural Netlists for Simulation ...................................................................................................................................... 30
Step 4: Additional IP .................................................................................................................................................................... 31
Step 5: Using Third Party Synthesis Tools .......................................................................................................................... 32
Conclusion ....................................................................................................................................................................................... 34
Lab 3: Packaging an IP for Reuse ................................................................................................................................................ 35
Step 1: Create and Package IP Wizard ................................................................................................................................. 35
Send Feedback

## Page 4

Designing with IP www.xilinx.com  4
UG939 (v2014.1) April 2, 2014
Launch Vivado .......................................................................................................................................................................... 35
Step 2: Preparing Design Constraints .................................................................................................................................. 36
Analyzing the Current Constraints Files ......................................................................................................................... 37
Creating an Out-Of-Context (OOC) XDC file ................................................................................................................ 38
Step 3: Packaging IP .................................................................................................................................................................... 42
Modifying the IP Definition ................................................................................................................................................. 45
Review and Package the IP .................................................................................................................................................. 49
Sidebar: Packaging a Specified Directory ...................................................................................................................... 51
Step 4: Validating the New IP .................................................................................................................................................. 52
Conclusion ....................................................................................................................................................................................... 57
Lab 4: Scripting the Project Mode .............................................................................................................................................. 58
Step 1: Creating a Project .......................................................................................................................................................... 58
Step 2: Adding RTL Source Files ............................................................................................................................................. 59
Step 3: Adding XDC Constraints ............................................................................................................................................. 60
Step 4: Adding Existing IP ......................................................................................................................................................... 60
Step 5: Disabling an IP’s XDC .................................................................................................................................................. 62
Step 6: Upgrading an IP ............................................................................................................................................................. 63
Step 7: Setting up Design Runs for IP .................................................................................................................................. 64
Step 8: Launching Synthesis and Implementation .......................................................................................................... 65
Step 9: Running the Script ........................................................................................................................................................ 67
Conclusion ....................................................................................................................................................................................... 69
Lab 5: Scripting the Non-Project Mode .................................................................................................................................... 70
Step 1: Reading Design Source Files .................................................................................................................................... 70
Step 2: Adding Existing IP ......................................................................................................................................................... 72
Step 3: Disabling XDC Files ....................................................................................................................................................... 73
Step 4: Upgrading IP ................................................................................................................................................................... 74
Step 5: Creating DCP for IP....................................................................................................................................................... 76
Step 6: Running Synthesis ......................................................................................................................................................... 76
Step 7: Running Implementation ........................................................................................................................................... 77
Step 8: Running the Script ........................................................................................................................................................ 79
Launch Vivado .......................................................................................................................................................................... 80
Conclusion ....................................................................................................................................................................................... 81
Send Feedback

## Page 5

Designing with IP  www.xilinx.com  5
UG939 (v2014.1) April 2, 2014
Designing with IP
 IMPORTANT: This tutorial requires the use of the Kintex®-7 family of devices. You will
need to update your Vivado tools installation if you do not have this device family installed.
Refer to the Vivado Design Suite User Guide: Release Notes, Installation, and Licensing
(UG973) for more information on Adding Design Tools or Devices.
Overview
The Vivado® Design Suite provides multiple ways to use IP in a design. IP can be customized and
added from the IP Catalog into a project. A repository of customized IP can be created and
referenced in either a project or non-project based flow, with full scripting capabilities as well.
The Vivado Design Suite provides an IP-centric design flow that helps you quickly turn designs
and algorithms into reusable IP. As shown in Figure 1, the Vivado IP catalog is a unified IP
repository that provides the framework for the IP-centric design flow. This catalog consolidates
IP from all sources including Xilinx® IP, IP obtained from third parties, and end-user designs
targeted for reuse as IP into a single environment.

Figure 1: Vivado Design Suite IP Design Flow
The Vivado IP packager tool is a unique design reuse feature based on the IP-XACT standard.
The IP packager tool provides any Vivado user the ability to package a design at any stage of
the design flow and deploy the core as system-level IP.

VIDEO: You can also learn more about the creating and using IP cores in Vivado Design
Suite by viewing the quick take video at http://www.xilinx.com/training/vivado/configuring-
and-managing-reusable-ip-in-vivado.htm or
http://www.xilinx.com/training/vivado/customizing-and-instantiating-ip.htm.
Send Feedback

## Page 6

Tutorial Description
Designing with IP www.xilinx.com  6
UG939 (v2014.1) April 2, 2014
Tutorial Description
This tutorial contains several labs as described below:
 Lab 1: Open a modified version of the Xilinx wave_gen example design that is missing a
FIFO; locate and customize the IP in the catalog; and instantiate the IP into the design.
 Lab 2: You will learn how to create and customize IP using the Manage IP flow. Create a
project, include an IP from the IP catalog as the top-level source; customize and verify the IP.
Optionally, use the customized IP as a black box in a 3rd party synthesis flow.
 Lab 3: Package a design as an IP module and add it to the Vivado IP catalog. Open a
completed Vivado Design Suite project; package the design as an IP core and add it to the IP
catalog using IP packager; then verify the new IP through synthesis and implementation.
 Lab 4: Write and run a Tcl script using the Vivado Design Suite to create a project,  add IP,
upgrade IP, disable IP sources and generate output products including Synthesized Design
Checkpoints (.dcp).
 Lab 5: Write and run a Non-Project Tcl script using the Vivado Design Suite to read in IP
sources, upgrade IP, disable IP sources and generate output products including Synthesized
Design Checkpoint (.dcp).
Hardware and Software Requirements
This tutorial requires that the 2014.1 Vivado Design Suite software release or later is installed.
The following partial list describes the operating systems that the Vivado Design Suite supports
on x86 and x86-64 processor architectures:
Microsoft Windows Support:
 Windows 8.1 Professional (32-bit and 64-bit), English/Japanese
 Windows 7 and 7 SP1 Professional (32-bit and 64-bit), English/Japanese
Linux Support:
 Red Hat Enterprise Workstation 6.4 and 6.5 (32-bit and 64-bit)
 SUSE Linux Enterprise 11 (32-bit and 64-bit)
 Cent OS 6.4 and 6.5 (64-bit)
Refer to the Vivado Design Suite User Guide: Release Notes, Installation, and Licensing (UG973)
for a complete list and description of the system and software requirements.
Send Feedback

## Page 7

Locating and Preparing the Tutorial Design Files
Designing with IP www.xilinx.com  7
UG939 (v2014.1) April 2, 2014
Locating and Preparing the Tutorial Design Files
There are separate project files and sources for each of the labs in this tutorial. You can find the
design files for this tutorial under Vivado Design Suite -2014.1 Tutorials on the Xilinx.com
website.
 Download the ug939-design-files.zip file from the Xilinx website:  1.
https://secure.xilinx.com/webreg/clickthrough.do?cid=356056
 Extract the zip file contents into any write-accessible location on your hard drive, or 2.
network location.
The extracted ug939-design-files directory is referred to as <Extract_Dir> throughout this
Tutorial.

RECOMMENDED: You will modify the tutorial design data while working through
this tutorial. You should use a new copy of the ug939-design-files directory each
time you start this tutorial.


Send Feedback

## Page 8

Step 1: Opening the Project
Designing with IP www.xilinx.com  8
UG939 (v2014.1) April 2, 2014
Lab 1: Designing with the IP Catalog
In this exercise, you will learn how to use the IP catalog in the Vivado™ Integrated Design
Environment (IDE). You will be using a version of the Xilinx wave generator example project. The
design is lacking a FIFO, which you will locate in the IP catalog, customize, instantiate into the
design, and generate output products.
Step 1: Opening the Project

Figure 2: Vivado IDE - Getting Started Page
Launch Vivado
On Linux,
 Change to the directory where the lab materials are stored: 1.
cd <Extract_Dir>/lab_1
 Launch the Vivado IDE: vivado  2.

Send Feedback

## Page 9

Step 1: Opening the Project
Designing with IP www.xilinx.com  9
UG939 (v2014.1) April 2, 2014
On Windows,
 Launch the Vivado Design Suite IDE: 1.
Start > All Programs > Xilinx Design Tools > Vivado 2014.x > Vivado 2014.x1
 As an alternative, click the Vivado 2014.x Desktop icon to start the Vivado IDE.  2.
The Vivado IDE Getting Started page, shown in Figure 2, contains links to open or create
projects and to view documentation.
Open the Project
 Select Open Project from the Getting Started page and browse to:  1.
<Extract_Dir>/lab_1/project_wave_gen_ip
 Select project_wave_gen_ip.xpr, and click OK. 2.

Figure 3: Open Project
The design will load and you will see the Vivado IDE in the default layout view, with the Project
Summary information as shown in Figure 4.

1 Your Vivado Design Suite installation may be called something other than Xilinx Design Tools
on the Start menu.
Send Feedback

## Page 10

Step 2: Customizing the FIFO Generator
Designing with IP www.xilinx.com  10
UG939 (v2014.1) April 2, 2014

Figure 4: Default Layout
Since this is an RTL project, you can run behavioral simulation, elaborate the design, launch
synthesis and implementation, and generate a bitstream for the device. The Vivado IDE also
offers a one-button flow to generate a bitstream, which will automatically launch synthesis
and implementation. For more information, refer to the Vivado Design Suite User Guide:
Using the Vivado IDE (UG893).
Step 2: Customizing the FIFO Generator
 Select IP Catalog from the Flow Navigator in the Project Manager area. The Xilinx IP Catalog 1.
displays in a new tab.
You can work with the IP Catalog in a variety of ways. You can search using keywords in the
search box or browse through the catalog in the various categories.
 Type fifo in the search box. 2.
The search results narrow the list of IP definitions displayed in the catalog.
Send Feedback

## Page 11

Step 2: Customizing the FIFO Generator
Designing with IP www.xilinx.com  11
UG939 (v2014.1) April 2, 2014
 From the Memories & Storage Elements > FIFOs group select FIFO Generator, as shown 3.
in Figure 5.

Figure 5: Xilinx IP Catalog – FIFO Core
 Right-click to open the popup menu, and select Customize IP, or double-click on the 4.
selected IP.
The FIFO Generator customize window opens, as shown in Figure 6. There is a schematic
symbol for the selected core displayed on the left. The schematic symbol changes as you
customize the IP.
 Zoom into the schematic symbol using mouse strokes with the left mouse button, just like 5.
in the Device window.
 Uncheck the Show Disabled Ports checkbox to hide unused ports on the symbol. 6.
 Above the symbol, open the Documentation menu to examine the options for viewing 7.
available information.
The Documentation menu lets you open the PDF file datasheet for the IP, open the change
log to review the revision history of the core, or open an Internet browser to navigate to the
IP webpage, or view any Answer Records related to the IP.
Send Feedback

## Page 12

Step 2: Customizing the FIFO Generator
Designing with IP www.xilinx.com  12
UG939 (v2014.1) April 2, 2014
The IP Location is used to specify the location to save the IP customization (.xci) and any
generated output products. By default, these are saved inside the project structure.
The Switch to Defaults resets the configuration options back to the default settings.

Figure 6: Customize IP
 At the top of the Customize IP dialog box, change the Component Name to char_fifo from 8.
the default name.
The Basic tab defines the interface type, memory type, and other implementation options of
the IP.
 Select the Interface Type of Native, which is the default. 9.
 From the Fifo Implementation drop down menu, set Independent Clocks Block RAM. 10.
 Select the Native Ports tab.  11.
Here you can set the Read Mode, Data Port Parameters, ECC and Output Register Options,
and configure Initialization.
 Set the Read Mode to First Word Fall Through.  12.
 Set the Write Width to be 8 bits.  13.
Send Feedback

## Page 13

Step 2: Customizing the FIFO Generator
Designing with IP www.xilinx.com  13
UG939 (v2014.1) April 2, 2014
Setting the Write Width will automatically change the Read Width to match, if you click on
the Read Width field.
 Click on the Read Width field, it will automatically change to 8 bits as well.  14.
Leave everything else with the default settings on this tab.
 Examine the fields of the Status Flags and Data Counts tabs.  15.
These fields configure other options for the FIFO Generator. For this design, leave everything
with the default settings.
 Select the Summary tab.  16.
This displays a summary of all the options selected as well as listing resources used for this
configuration. The summary for the FIFO Generator customization should look like Figure 7.
For this configuration you are using one 18K BRAM.

Figure 7: Summary of FIFO Generator Core
 Verify that the information is correct as shown, and click OK to add the IP customization to 17.
your design.
Send Feedback

## Page 14

Step 3: Generate Output Products
Designing with IP www.xilinx.com  14
UG939 (v2014.1) April 2, 2014
Step 3: Generate Output Products
After the char_fifo IP customization completes, the Generate Output Products dialog box
opens as seen in Figure 8. The output products for an IP are the various files required to
support the use of the IP in synthesis, simulation, and implementation.

Figure 8: Generate Output Products
 Click Generate to generate the required output products.  1.
By default, the Synthesized Checkpoint (.dcp) is generated, and an Out-of-Context Module
Run for the char_fifo IP is added to the Design Runs window, and the run is launched to
synthesize the IP as shown in Figure 9.

Figure 9: Out-of-Context Synthesis Run
The Out-of-Context (OOC) run creates the Design Checkpoint File (DCP) for the specified IP
customization. This allows the IP to be complete with regard to synthesis, helps to insure
that the integrity of the core is preserved in the current design, and reduces synthesis time
for the top-level design in future iterations of the design flow. For more information on OOC
Send Feedback

## Page 15

Step 3: Generate Output Products
Designing with IP www.xilinx.com  15
UG939 (v2014.1) April 2, 2014
runs, and the use of DCP files, refer to the Vivado Design Suite User Guide: Designing with IP
(UG896).

IMPORTANT: Xilinx recommends that you generate the DCP file to reduce synthesis
time for the top-level design. It is also recommended that you do not change the
default synthesis setting for the IP Design Runs.


Figure 10: FIFO Generator Sources
The FIFO now appears in the Sources view. The IP Sources tab is shown in Figure 10.
 In the IP Sources tab of the Sources window, examine the output products produced for 2.
the FIFO Generator customization.
Because the FIFO IP is added to the design sources, but is not yet instantiated into your
design, it is added at the same level as the top-level wave_gen module in the Hierarchy tab,
and appears in the Block Sources folder in the Libraries and Compile Order tabs.
The FIFO Generator customization includes an instantiation template, char_fifo.veo,
synthesis constraints and VHDL entity and architecture definition, Verilog simulation files,
and the synthesized design checkpoint.
Since the FIFO IP was originally defined in VHDL, the entity and architecture are added as
VHDL source files. However, because Verilog is the target language for the current project,
the instantiation template is a VEO file for instantiating the VHDL FIFO entity into the Verilog
design.
You can also customize and add IP to your design, using TCL commands.
 Examine the Tcl Console in the Vivado IDE, as shown in Figure 11, and review the Tcl 3.
commands used to add the FIFO Generator core to your project.
Send Feedback

## Page 16

Step 4: Instantiating IP into the Design
Designing with IP www.xilinx.com  16
UG939 (v2014.1) April 2, 2014

Figure 11: Tcl Console Commands for Adding IP
 The create_ip command adds the IP into the current project.
 The set_property command defines the various configuration options of the
Customize IP dialog box.
 The generate_target command creates the specified output products for the IP
customized.
 The create_ip_run command defines the Out-of-Context synthesis run for the IP
customized.
 The launch_run command runs synthesis on the IP customization.
Refer to the Vivado Design Suite Tcl Command Reference Guide (UG835) for specific
information on the different Tcl commands used in this tutorial.
Step 4: Instantiating IP into the Design
You will now instantiate the IP customization into the design by copying and pasting the Verilog
Instantiation Template into the appropriate Verilog source file in your project and modifying the
signals.
 In the IP Sources tab of the Sources window, expand the Instantiation Template and 1.
double click on the char_fifo.veo file to open the template in the Vivado Text Editor.
 Scroll down to line 56 or 57 of the template file, and select and copy the module 2.
instantiation text, as seen in Figure 12.
Send Feedback

## Page 17

Step 4: Instantiating IP into the Design
Designing with IP www.xilinx.com  17
UG939 (v2014.1) April 2, 2014

Figure 12: FIFO Core Generator - Instantiation Template
Next, you will paste the instantiation template into the appropriate RTL source file. In this
case, you will paste the module into the top-level of the design, in the wave_gen source file.
 From the Hierarchy tab of the Sources view, double click on wave_gen.v to open this file 3.
for editing.

Figure 13: wave_gen.v
 Go down to line 337, which contains a comment stating the Character FIFO should be 4.
instanced at this point. Paste the template code into the file as shown in Figure 14.
However, since it is only a template for the module, you will need to do some local editing to
make the module work in your design.
Send Feedback

## Page 18

Step 4: Instantiating IP into the Design
Designing with IP www.xilinx.com  18
UG939 (v2014.1) April 2, 2014

Figure 14: Paste the FIFO IP into the Top-level Design
 Change the module name from your_instance_name to char_fifo_i0. 5.
 Change the wire names as follows, to connect the ports of the module into the design: 6.
  char_fifo char_fifo_i0 (
    .rst(rst_i), // input rst
    .wr_clk(clk_rx), // input wr_clk
    .rd_clk(clk_tx), // input rd_clk
    .din(char_fifo_din), // input [7 : 0] din
    .wr_en(char_fifo_wr_en), // input wr_en
    .rd_en(char_fifo_rd_en), // input rd_en
    .dout(char_fifo_dout), // output [7 : 0] dout
    .full(char_fifo_full), // output full
    .empty(char_fifo_empty) // output empty
  );
 In the Text Editor side-bar menu, click on the Save File button ( ) to save the changes to 7.
the wave_gen.v file.
Notice that the Hierarchy, Libraries, and Compile Order tabs are updated to indicate that the
IP has been instanced into the design, as seen in Figure 15.
Send Feedback

## Page 19

Step 5: Synthesizing the Design
Designing with IP www.xilinx.com  19
UG939 (v2014.1) April 2, 2014

Figure 15: IP Integrated into the Design
 Step 5: Synthesizing the Design
With the customized IP integrated into your design, you are now ready to proceed to synthesis.
All Xilinx IP in the Vivado Design Suite IP Catalog are delivered as RTL sources. This provides the
benefit of being able to perform behavioral simulation, which is much faster than netlist-based
simulation. However, having to synthesize each IP, along with the overall design, with every
design iteration, can add significant synthesis time to the project.
The design checkpoint file delivered with the IP output products, and generated by the Out-of-
Context synthesis run, can eliminate the need to re-synthesize the core over multiple iterations.
The default behavior of the Vivado Design Suite, when you add an IP to the project, is to
generate the necessary output products including the DCP file. However, you can disable
generation of the DCP file, or skip generating output products altogether. If you skip generation
during customization, the Vivado Design Suite will automatically generate the required output
products at the point in the design flow they become required, such as during synthesis or
simulation. By default, a DCP will also be generated during synthesis unless you disable and
generate the output products prior to synthesis.
 In the Sources window, under the IP Sources tab, look at the clk_core IP customization 1.
instantiated under wave_gen as seen in Figure 15.
Notice the clk_core icon lacks a check mark as seen on the char_fifo IP. This indicates that
this IP was customized, and added to the project, but no output product were generated for
the IP. These output products will be generated automatically at this time.

Send Feedback

## Page 20

Step 5: Synthesizing the Design
Designing with IP www.xilinx.com  20
UG939 (v2014.1) April 2, 2014
 In the Flow Navigator, click the Run Synthesis button.  2.
The Vivado Design Suite automatically generates the required output products for the
clk_core IP.

Figure 16: Clk Core Output Products
The Vivado tool creates a new Out-of-Context Module synthesis run for the clk_core, and
launches that synthesis run, as seen in Figure 17. This synthesis run creates the synthesized
checklist (.dcp) file for the IP customization. Now when the top-level of the design is
synthesized, a black box will be inferred for the FIFO generator IP (char_fifo) and the Clock
generator IP (clk_core) in the design.

Figure 17: Out-of-Context Synthesis Runs
With the required output products for the clk_core created, the Vivado synthesis tool is
run on the top-level of the design, as seen in Figure 18. Notice that the OOC synthesis runs
for both char_fifo and clk_core are complete.
Send Feedback

## Page 21

Conclusion
Designing with IP www.xilinx.com  21
UG939 (v2014.1) April 2, 2014

Figure 18: Top-level Synthesis
 When the Synthesis Completed dialog box opens, select the View Reports option and click 3.
OK.
This opens the Reports window at the bottom of the Vivado IDE.
 Switch to the Log window and open the Synthesis log.  4.
 Use the Show Find command, , to search the Log window for “blackbox”.  5.
 Use the Find Next command until you come to the following section, which summarizes the 6.
blackboxes found in the current design:
Report BlackBoxes:
+------+--------------+----------+
|      |BlackBox name |Instances |
+------+--------------+----------+
|1     |char_fifo     |         1|
|2     |clk_core      |         1|
+------+--------------+----------+
 Look in the project IP runs folder for the results of the out-of-context synthesis runs: 7.
<Extract_Dir>/lab_1/project_wave_gen_ip/project_wave_gen_ip.runs
The checkpoint files can also be used in other projects. It encapsulates the netlist and the
constraints for the out-of-context IP module.
Conclusion
You have successfully created a FIFO Generator IP customization, and instanced it in a design.
Close the project and exit the Vivado tool, or continue and implement the design if you wish to
explore further. This concludes Lab1.
In this Lab, you have learned how to select and customize an IP from the IP catalog, how to
instantiate the customized IP into an HDL design, and some details of the output products
required to support the IP in the design flow. You can add and manage IP in a design
interactively within the Vivado IDE, or via Tcl scripting.

Send Feedback

## Page 22

Step 1: Starting a Manage IP session
Designing with IP www.xilinx.com  22
UG939 (v2014.1) April 2, 2014
Lab 2: Creating and Managing Reusable IP
To simplify revision control, and to support the use of custom IPs across multiple projects and
designs, you can manage and store the customized IP in a repository, separate from any design
projects they are used in. The IP customization file (.xci), and the output products for
synthesis, simulation, examples, etc., should be contained together in a unique directory. You
can reference these IP customizations in new projects and designs, to simulate, synthesize, and
implement the IP as part of the design. Having all the generated output products available also
preserves that customized version of the IP for use in a future release of the Vivado Design
Suite, even if the IP is updated in the Xilinx IP Catalog. See the Vivado Design Suite User Guide:
Designing with IP (UG896) for more information on managing IP.
In this exercise, you will create and verify an IP customization in an IP repository, using the
Manage IP flow in the Vivado Design Suite. This flow allows you to browse the IP catalog to
create and manage IP customizations for use in either a Project or a Non-Project design flow.
You can create a repository of the customized IP for use in your design(s), managed and
maintained outside of a Vivado Project. A special IP project is created at the location specified
for the Manage IP flow, to facilitate the creation of a Synthesis Design Checkpoint (DCP) and
structural simulation models. When using a customized IP, in a project or non-project flow, all
output products, including a DCP if present, are used by the design flow. Using the synthesis
DCP files speed synthesis of the top level design.  A stub file is provided for use in third party
synthesis tools to infer a black box for IP.
Step 1: Starting a Manage IP session
On Linux,
 Change to the directory where the lab materials are stored: 1.
cd <Extract_Dir>/lab_2
 Launch the Vivado IDE: vivado  2.
On Windows,
 Launch the Vivado Design Suite IDE: 1.
Start > All Programs > Xilinx Design Tools > Vivado 2014.x > Vivado 2014.x2
 As an alternative, click the Vivado 2014.x Desktop icon to start the Vivado IDE.  2.
The Vivado IDE Getting Started page displays with links to open or create projects, and to
view documentation.

2 Your Vivado Design Suite installation may be called something different than Xilinx Design
Tools on the Start menu.
Send Feedback

## Page 23

Step 1: Starting a Manage IP session
Designing with IP www.xilinx.com  23
UG939 (v2014.1) April 2, 2014
 On the Getting Started page, click the Manage IP link. 3.

Figure 19: Manage IP from the Getting Started Page
A drop down menu displays letting you:
 Specify a New IP location for a new Manage IP project and generated output products.
 Open an existing IP location for prior Manage IP projects.
 Select New IP Location. 4.
 Press Next to move to the Manage IP Settings dialog box.  5.

Figure 20: Manage IP Settings

Send Feedback

## Page 24

Step 2: Customizing the FIFO Generator
Designing with IP www.xilinx.com  24
UG939 (v2014.1) April 2, 2014
 Configure the dialog box settings as follows: 6.
 Part: xc7k70tfbg484-2
Note: Use the browse button to select the specified target part.
 Target Language: Verilog
 Target Simulator: Vivado Simulator
 Simulator Language: Mixed
 IP location: <Extract_Dir>/lab_2/my_ip
 Press Finish to proceed.  7.
The IP Catalog displays in an IP Project, which is a simple interface for the creation and
management of IP customizations.
Step 2: Customizing the FIFO Generator
You can work with the IP catalog in two ways, either searching with a keyword, or browsing
through the categories.

Figure 21: Customize IP Window
Send Feedback

## Page 25

Step 2: Customizing the FIFO Generator
Designing with IP www.xilinx.com  25
UG939 (v2014.1) April 2, 2014
 Type fifo in the search bar. 1.
 Double-click the FIFO Generator from the Memories & Storage Elements group. 2.
The Customize IP dialog box opens, as shown in Figure 21.

TIP: For a complete description of the Customize IP dialog box, and its use, refer to Lab 1: Designing
with the IP Catalog. This Lab assumes that you have previously completed Lab 1, and are familiar
with the concepts covered in it.
 At the top of the Customize IP dialog box, change the Component Name to char_fifo. 3.
 In the Basic tab:  4.
 Select the Interface Type of Native, which is the default.
 From the Fifo Implementation drop down menu, set Independent Clocks Block RAM.
 In the Native Ports tab.  5.
 Set the Read Mode to First Word Fall Through.
 Set the Write Width to be 8 bits.
 Click on the Read Width field to adjust it automatically to 8 bits as well.
 Select the Summary tab.  6.
The Summary page displays a summary of all the options selected as well as listing resources
used for this configuration. The summary for the FIFO Generator core should look like Figure
22. For this configuration you will see you are using one 18K BRAM.

Figure 22: Summary of FIFO Generator Core
Send Feedback

## Page 26

Step 2: Customizing the FIFO Generator
Designing with IP www.xilinx.com  26
UG939 (v2014.1) April 2, 2014
 Verify that the information is correct as shown, and click OK to generate the customized IP 7.
core for use in your design.
The Generate Output Products popup appears, as seen in Figure 23. When creating a
repository of customized IPs using the Managed IP flow, you should generate all output
products, including the design checkpoint (DCP), for each IP. A specific release of the Vivado
tools only supports a single version of an IP core. You cannot re-customize or generate
outputs for a prior version of IP in the Vivado Design Suite. Instead, you would need to
update the IP to the latest version if you have not preserved the needed output products.

IMPORTANT: Only one version of an IP is supported in a given release of the Vivado
tools. To preserve older versions of an IP, ALL output products must be available in your
custom IP repository.
 Click the Generate button to create the output products.  8.

Figure 23: Generate Output Products
To reduce synthesis runtime for a design using one or more customized IP cores, the IP can
be pre-synthesized as a standalone module, with the netlist saved in a design checkpoint file
(DCP). During synthesis of the overall design, a black box is inferred for the IP. During
implementation the netlists from the DCP files are linked into the design. This method can
be scripted in Tcl for both Project and Non-Project Mode.
When the synthesis DCP is specified for an IP core, a corresponding Out-of-Context Module
Run is also created and launched, as seen in Figure 24.

Send Feedback

## Page 27

Step 2: Customizing the FIFO Generator
Designing with IP www.xilinx.com  27
UG939 (v2014.1) April 2, 2014
This run is automatically launched, and when synthesis is completed the char_fifo directory
contains a few additional files:
 char_fifo.dcp: The Synthesis Design Checkpoint which consists of both a netlist and
constraints for the IP.
 char_fifo_stub.v: A Verilog port module for use with Synplify Pro, to infer a black box for
the IP with no IO buffers inserted.
 char_fifo_funcsim.v/char_fifo_funcsim.vhd: A Verilog and VHDL netlist for functional
simulation of the IP core.

Figure 24: Out-of-Context Module Run to Create the DCP
If you are using a third party synthesis tool for the design, a Verilog stub file with the port
declarations, or a VHDL component declaration, is required for the black box to be inferred.
The Vivado Design Suite automatically creates this file along with the synthesis design
checkpoint (DCP) when the output products are generated.
Customized IPs can be referenced from both Project and Non-Project Mode. In a project-
based design, Xilinx recommends that you do not copy sources into the local project
structure, but rather reference them from your custom IP repository. For more information
on Project Mode and Non-Project Mode, refer to the Vivado Design Suite User Guide: Design
Flows Overview (UG892).
 Examine the <Extract_Dir>/lab_2/my_ip location.  9.
You will notice that two directories have been created, as shown in Figure 25.
 One is the IP customization (char_fifo) containing the XCI file, which has all the
customization information for the IP, and all the output products generated.
 The second is the IP Project (managed_ip_project) which you created in this Lab to
customize the char_fifo IP and manage the output products, including the synthesized
DCP.
Send Feedback

## Page 28

Step 3: Using Third Party Simulators
Designing with IP www.xilinx.com  28
UG939 (v2014.1) April 2, 2014

Figure 25: IP Directory and IP Project
 Examine the Sources window to see the generated output products in the Manage IP 10.
project.

Figure 26: IP Sources
The generated output products for the char_fifo core include the Instantiation Template,
Synthesis files, Simulation files, and the synthesized design checkpoint.
Step 3: Using Third Party Simulators
The purpose of the Managed IP project is to create and manage IP customizations; there is no
support for directly simulating IP in a Managed IP project. Customized IP can be instanced into a
standard design project for simulation, in either Project or non-Project Mode.
The Vivado Design Suite includes the Vivado simulator, for mixed language simulation, as well as
directly supporting Mentor Graphics® ModelSim/QuestaSim. Refer to the Vivado Design Suite
User Guide: Designing with IP (UG896) and the Vivado Design Suite User Guide: Logic
Send Feedback

## Page 29

Step 3: Using Third Party Simulators
Designing with IP www.xilinx.com  29
UG939 (v2014.1) April 2, 2014
Simulation (UG900) for more information on simulating with these simulators, including creating
scripts for running simulations outside of the Vivado Design Suite.
Xilinx IP delivered in the Vivado Design Suite are encrypted using industry standard IEEE P1735
encryption. Simulators such as Cadence® Incisive Enterprise Simulator (ies) and Synopsys® VCS
MX simulator (vcs_mx) support this encryption standard and can be used to run behavioral
simulation. A list of simulation files and the libraries they belong to is needed.
There are two options available:
 Use the export_simulation command to export a script and associated data files (if
needed) for driving simulation using Cadence IES or Synopsys VCS.
 Use query commands to get the simulation files for the IP and the libraries they are
associated with.
Using Export Simulation
To create scripts for Cadence/Synopsys simulators, use the export_simulation command:
export_simulation -simulator ies -of_objects [get_ips char_fifo] \
-directory "c:/Data/ug939-design-files/my_ip" -script_name test_ies.sh
This will create a file called “test_ies.sh” for simulating with Cadence IES. A default ".do" file that
is used in the compiler commands in the simulation script for the target simulator, will be
written to the output directory, in this case it is called “char_fifo.do”. For more on this command
type export_simulation –help at theTcl command line.
Getting Required Simulation Files
As an alternative to export_simulation, you can manually gather the required files to support
third-party simulation. To get all files that an IP delivers for simulation, use the get_files Tcl
command.
 In the Tcl Console, type the following command: 1.
get_files -compile_order sources -used_in simulation -of_objects \
[get_files char_fifo.xci]
The -used_in option lets you specify files that are marked for use in simulation, or marked
for use in synthesis. The -of_objects option lets you extract files that are associated with
the specified IP customization file.
This will produce a list of file names, including the full path, required to simulate the IP. In
this case, the list includes:
…/my_ip/char_fifo/fifo_generator_v12_0/simulation/fifo_generator_vhdl_beh.vhd
…/my_ip/char_fifo/sim/char_fifo.vhd
Each simulation file has a LIBRARY property that can be queried. For VHDL files, the library
associated with each file is required for simulation.
Send Feedback

## Page 30

Step 3: Using Third Party Simulators
Designing with IP www.xilinx.com  30
UG939 (v2014.1) April 2, 2014
 To extract the LIBRARY property, type the following Tcl command:  2.
get_property LIBRARY [get_files char_fifo.vhd]
This should return the xil_defaultlib library.
 Use the following Tcl script to print out each file used for simulation, including the path, and 3.
its associated library:
# Get the list of files required for simulation
set ip_files [get_files -compile_order sources -used_in simulation \
-of_objects [get_files <IP name>.xci]]
# For each of these files, get the library information
foreach file $ip_files {
puts "[get_property LIBRARY $file] $file"
}
In the preceding script, replace <IP_Name> with the name of the customized IP to extract
files from. In this case, you would use char_fifo.
Structural Netlists for Simulation
Depending on which Simulator Language you select during the Manage IP project creation
(see Figure 20) the results of the get_files commands above will differ. If you did not specify
support for a “Mixed” simulator and instead selected “Verilog” or “VHDL” then depending on the
IP you might not be able to do behavioral simulation. You will be required to do simulations
using a structural netlist, which the Vivado Design Suite produces automatically when a
synthesized design checkpoint is available.
If the IP can deliver behavioral simulation files based upon your selected simulator language,
when generating the output products you will see “Behavioral Simulation” listed as an output
product as shown in Figure 23. If however, the IP does not deliver simulation files for the
selected simulator language you will see “Structural Simulation” as shown in Figure 27.

Figure 27 Structural Simulation Output
Send Feedback

## Page 31

Step 4: Additional IP
Designing with IP www.xilinx.com  31
UG939 (v2014.1) April 2, 2014
If you queried the FIR IP customization shown in Figure 27 for simulation files using the
following command:
get_files -compile_order sources -used_in simulation -of_objects \
[get_files fir_0.xci]
The only file returned would be:
../my_ip/fir_0/fir_0_funcsim.v

TIP: Structural simulation output products, for both Verilog and VHDL, are always
created when a synthesized design checkpoint is available. Querying the simulation
files with get_files will vary depending on whether behavioral simulation was
possible with the selected simulator language setting.
Step 4: Additional IP
At this point in the tutorial, you can repeat some of the earlier steps to add some additional IP
cores to the Managed IP project, and customize them as well. In Figure 28, Tri Mode Ethernet
MAC and Complex Multiplier IP customizations have been added to the project.
 Explore the IP Catalog, and create customizations for a few additional IP cores.  1.
 Generate output products for the additional cores.  2.
In the IP Sources tab of the Sources window, you will see the various output products that
have been generated for the additional cores.

Figure 28: Output products of an IP
Send Feedback

## Page 32

Step 5: Using Third Party Synthesis Tools
Designing with IP www.xilinx.com  32
UG939 (v2014.1) April 2, 2014
When you create an IP customization, the Vivado Design Suite adds an Instantiation
Template to the project, even if you choose to skip generating other output products. The
Instantiation Template is the minimum output.
By default, the Vivado Design Suite creates a synthesized design checkpoint for each IP
customization added to the project, adding Out-of-Context Module Runs for each of the IP
cores. The progress of these synthesis runs can be viewed in the Design Run tab, as shown in
Figure 29.

Figure 29:Synthesis Runs for IP
Step 5: Using Third Party Synthesis Tools
Xilinx IP delivered with the Vivado Design Suite only supports synthesis using the Vivado
synthesis tool. Other logic can be synthesized using supported third party synthesis tools, such
as Synopsys® Synplify Pro. The Vivado Design Suite generates a Verilog stub file for each IP
customization so a third party synthesis tool can infer black boxes for the Xilinx IP. The stub file
is only created if a synthesized DCP has been generated for the IP, which is the default behavior
of the tool. It is important that the synthesis tool does not insert IO buffers for any Xilinx IP. The
stub file that is created, <ip_name>_ stub.v, contains synthesis directives to prevent this.
The following Tcl script, <Extract_Dir>/lab_2/run.tcl, reads a top-level design netlist
including the char_fifo IP, reads the synthesized DCP for the IP, reads the design constraints, and
implements the design, using the Vivado tool Non-Project Mode.
# Change directory to <Extract_Dir>/lab_2
cd <Extract_Dir>/lab_2

# Read top-level EDIF netlist produced by 3rd party synthesis tool
read_edif ./sources/wave_gen.edif

# Read the IP file, and any associated files.
# This command will add the netlist from the DCP and reference any
# required output products generated for the IP (XDC, Tcl, ELF, BMM, etc.)
add_files ./my_ip/char_fifo/char_fifo.xci

# read top level constraints
read_xdc ./sources/wave_gen_timing.xdc
Send Feedback

## Page 33

Step 5: Using Third Party Synthesis Tools
Designing with IP www.xilinx.com  33
UG939 (v2014.1) April 2, 2014

# Link the netlists to build the in-memory design database
link_design -top wave_gen -part xc7k70tfbg484-2

# Implement the design in Non-Project Mode
opt_design
place_design
route_design

# write out an implemented design checkpoint
write_checkpoint –force wave_gen_post_route.dcp


TIP: Refer to Lab 4: Scripting the Project Mode or Lab 5: Scripting the Non-Project Mode
for a more detailed discussion of the scripted IP flow.
Although there could be multiple instances of an IP customization in a design, the DCP file for
the IP only needs to be read once. All black boxes for that IP customization will be replaced with
the netlist from the synthesized DCP when the design is linked, and the design constraints will
be applied to each instance.
 Close the Manage IP project which is now open in the Vivado IDE. 1.
 In a Text Editor like Notepad or Emacs, open the file <Extract_Dir>/lab_2/run.tcl. 2.
 Edit the file to change <Extract_Dir> to the actual location of the extracted files. 3.
 Using the Tools > Run Tcl Script command from the main menu, source the run.tcl script. 4.
The netlist from the synthesis DCP of the IP core is linked to the top-level EDIF netlist, and
implementation is run.
 Examine the Netlist window to see that the char_fifo IP was correctly linked to the top-5.
level design.

Figure 30: Netlist Window
Send Feedback

## Page 34

Conclusion
Designing with IP www.xilinx.com  34
UG939 (v2014.1) April 2, 2014
Conclusion
This concludes Lab #2. You can continue examining the design, and create additional reports, or
exit the Vivado Design Suite.
In this lab, you learned how to use the Manage IP flow to browse the IP Catalog and create IP
customizations to store in an IP repository for later reuse. It is a convenient method for creating
custom IPs to manage under revision control for use in future designs. From the Manage IP Flow
you can easily create a synthesis design checkpoint (DCP) to use the custom IP in Vivado Project
Mode or Non-Project Mode, or for inferring a black box for use with a third-party synthesis tool.
You can also generate a structural netlist for simulation if needed.
To perform behavioral simulation with a custom IP, you would use the IP in a project, or
generate scripts for Vivado simulator or ModelSim/QuestaSim for standalone simulation. To use
third party simulators, you will need to either query the HDL files required for simulation, and
the libraries with which the files are associated or use the export_simulation Tcl command.

Send Feedback

## Page 35

Step 1: Create and Package IP Wizard
Designing with IP www.xilinx.com  35
UG939 (v2014.1) April 2, 2014
Lab 3: Packaging an IP for Reuse
In Lab #3, you will define a new IP from an existing design, using the Create and Package IP
wizard. You will start with an existing design project in the Vivado IDE, define identification
information for the new IP, add documentation to support its use, and add the IP to the IP
Catalog. After packaging, you will verify the new IP through synthesis and implementation in a
separate design project.
The Lab #3 project contains Verilog source files for a simple UART interface. The project consists
of seven source files as well as an XDC file with timing information.
Step 1: Create and Package IP Wizard
Launch Vivado
On Linux,
 Change to the directory where the lab materials are stored: 1.
cd <Extract_Dir>/lab_3
 Launch the Vivado IDE: vivado  2.
On Windows,
 Launch the Vivado Design Suite IDE: 1.
Start > All Programs > Xilinx Design Tools > Vivado 2014.x > Vivado 2014.x3
 As an alternative, click the Vivado 2014.x Desktop icon to start the Vivado IDE.  2.
The Vivado IDE Getting Started page displays with links to open or create projects, and to
view documentation.
For either Windows or Linux, continue the lab from this point.
 Click Open Project, and browse to: <Extract_Dir>/lab_3/my_simple_uart 3.
 Select the my_simple_uart.xpr project and click OK. 4.
The design will load and you will see the Vivado IDE in the default layout view, with the
Project Summary information as shown in Figure 31.

3 Your Vivado Design Suite installation may be called something different than Xilinx Design
Tools on the Start menu.
Send Feedback

## Page 36

Step 2: Preparing Design Constraints
Designing with IP www.xilinx.com  36
UG939 (v2014.1) April 2, 2014

Figure 31: Project Default View Layout
Step 2: Preparing Design Constraints
The existing design includes timing constraints defined in an XDC file (uart_top.xdc). These
constraints were defined for the UART design as a standalone design. However, when it is
packaged as an IP, the design will inherit some of the needed constraints from the parent
design. In this case the XDC file must be modified to separate constraints the IP requires when
used in the context of a parent design, and the constraints the IP requires when used out-of-
context (OOC) in a standalone capacity. This requires splitting the current XDC file.
You should prepare the design constraints prior to packaging the design for inclusion in the IP
catalog; however, these steps can also be done after packaging the IP.

IMPORTANT: Starting with the Vivado 2013.3 release, a synthesized design checkpoint
(DCP) is created as part of the default Out-of-Context (OOC) design flow for IP
packaging and use.
Send Feedback

## Page 37

Step 2: Preparing Design Constraints
Designing with IP www.xilinx.com  37
UG939 (v2014.1) April 2, 2014
To ensure that the packaged IP will function properly in the default Out-of-Context (OOC)
design flow, the IP packaging should include a standalone XDC file to define all external clocking
information for the IP. These constraints would normally be provided by any top-level, or parent
design the IP is used in. The standalone or OOC XDC file is used by the Out-of-Context synthesis
run to properly constrain the IP to the recommended clock frequency. When the IP is used in the
context of a parent design, the standalone XDC file is not needed.
For more information on the Out-Of-Context (OOC) design flow, and the use of the DCP file,
please refer to the Vivado Design Suite User Guide: Designing with IP (UG896).

TIP: Depending on the function and use of the packaged IP, the design constraints may
also have to be adjusted to ensure proper scoping. For more information refer to
Constraints Scoping in the Vivado Design Suite User Guide: Using Constraints (UG903).
 Analyzing the Current Constraints Files
 Open the target XDC file (uart_top.xdc) listed under the Constraints folder in the 1.
Hierarchy pane of the Sources window.

Figure 32: File Contents of uart_top.xdc
There are two items to take note of in the XDC file, as seen in Figure 32:
 create_clock constraints (Lines 1 and 2)
 set_max_delay constraint relying on the clock object period value (line 18).
Send Feedback

## Page 38

Step 2: Preparing Design Constraints
Designing with IP www.xilinx.com  38
UG939 (v2014.1) April 2, 2014
Note: The line numbers referenced in Figure 32 may differ from the line numbers in your XDC
file because the constraints have been edited for easier viewing in this tutorial.
You should examine all create_clock constraints prior to packaging the new IP definition. If
the created clock is internal to the IP (GT), or if the IP contains an input buffer (IBUF), the
create_clock constraint should stay in the IP XDC file because it is needed to define local
clocks. Clocks that are not internal, or local, to the IP should be moved from the IP XDC file to an
OOC XDC file, because they will normally be provided by the parent design.
For this example, you will move the create_clock constraints on line 1 and 2 from the design
XDC file to an OOC XDC file. When a user instantiates the IP you are packaging, from the IP
catalog into a design, the IP will inherit the clock definitions from the parent design.
The set_max_delay constraint is also noteworthy in that it has a dependency on the PERIOD
property of defined clocks, (get_clocks –of_objects). This dependency is affected by the
order of processing of the constraints of the IP and top-level design.
By default, when IP customizations are instantiated into a design, the Vivado Design Suite
processes the XDC files of an IP before the XDC files of the top-level design. This is known as
EARLY processing, and is defined by the PROCESSING_ORDER property on the XDC file.
The XDC files of the top-level design are marked for NORMAL processing by default. This means
that the processing of XDC files for IP constraints will happen before the top-level design
constraints created by the user. However, in this case, the dependency on the clock definition
will cause errors in processing the IP constraints early. To resolve this issue, you will mark the
XDC files of the UART IP for LATE processing.

TIP: Xilinx delivered IP with “_clock” appended to the XDC filename are all marked for LATE
processing.
Creating an Out-Of-Context (OOC) XDC file
 Select the Add Sources button in the Flow Navigator panel or from the File menu, select 1.
Add Sources.
The Add Sources dialog box opens.
 Select Add or Create Constraints, click Next.  2.
 In the Add or Create Constraints pane, click the Create File button. 3.
 In the Create Constraints File dialog box, fill in the constraints file information with the 4.
following, as shown in Figure 33:
 File type: XDC
 File name: uart_top_ooc.xdc
 File location: <Local to Project>
 Click OK. 5.
Send Feedback

## Page 39

Step 2: Preparing Design Constraints
Designing with IP www.xilinx.com  39
UG939 (v2014.1) April 2, 2014

Figure 33: Create Constraints File dialog box

TIP: For Xilinx delivered IPs, the Out-of-Context XDC file has “_ooc” appended to the
filename. However, it is the USED_IN property of the file, not the filename, that
determines if it is an OOC XDC file.
 Click Finish to complete the Add Sources dialog box. 6.
The new XDC file will be created in the project and display under the Constraints section in
the Hierarchy pane of the Sources window.
You will now move the create_clock constraints from the XDC file of the original design
(uart_top.xdc) into the OOC XDC file (uart_top_ooc.xdc).
 Open the new OOC XDC file (uart_top_ooc.xdc) by double-clicking the file in the 7.
Sources window.
The file is empty.
 Cut and paste the create_clock constraints, from lines 1 and 2 of the IP XDC file 8.
(uart_top.xdc) into the empty OOC XDC file.
The OOC XDC file should now contain only those two create_clock constraints.

Figure 34: OOC XDC

 Select the Save File button, , to save the updated contents of the OOC XDC file. 9.
Send Feedback

## Page 40

Step 2: Preparing Design Constraints
Designing with IP www.xilinx.com  40
UG939 (v2014.1) April 2, 2014
 Check to be sure that the create_clock commands are removed from the IP XDC file 10.
(uart_top.xdc), and save the file.
As previously mentioned, the create_clock constraints are no longer needed because the
clocks will be defined by the parent design. The IP XDC file should now only contain the
constraints as shown in Figure 35. The OOC XDC file defines the clocks needed for
standalone processing.

Figure 35: Updated uart_top.xdc
 Close the two open XDC files.  11.
With the OOC and IP XDC files defined, you must set the USED_IN and PROCESSING_ORDER
properties on the XDC files so that the Vivado Design Suite correctly processes the
constraint files for the IP.
 Select the IP XDC file (uart_top.xdc) listed under the Constraints section in the Hierarchy 12.
pane of the Sources window.
 Right-click on the file, and select Source File Properties from the popup menu.  13.
 From the Source File Properties window, scroll down and change the PROCESSING_ORDER 14.
property value to LATE, as shown in Figure 36.
Send Feedback

## Page 41

Step 2: Preparing Design Constraints
Designing with IP www.xilinx.com  41
UG939 (v2014.1) April 2, 2014

Figure 36: Source File Properties
The property value can also be changed in the Tcl Console with the following Tcl command:
set_property PROCESSING_ORDER LATE [get_files uart_top.xdc]
 In the Tcl console, set the USED_IN property of the OOC XDC file to include the 15.
“out_of_context” using the following Tcl command:
set_property USED_IN {synthesis implementation out_of_context} \
[get_files uart_top_ooc.xdc]
When the USED_IN property includes the out_of_context setting, the XDC file is only
used for synthesis or implementation in Out-of-Context runs (-mode out-of-context).

IMPORTANT: The USED_IN property for an OOC XDC file should be {synthesis
implementation out_of_context}. If it is just out_of_context then it will not be used
during synthesis or implementation.
After completing the above steps, the XDC files are correctly prepared for packaging and the
Out-Of-Context (OOC) design flow.

Send Feedback

## Page 42

Step 3: Packaging IP
Designing with IP www.xilinx.com  42
UG939 (v2014.1) April 2, 2014
Step 3: Packaging IP
After setting up the design and supporting constraint files, the next step will be to create and
package the new IP Definition, and add it to the IP Catalog.
 From the Tools menu, select the Create and Package IP command to open the Create and 1.
Package IP Wizard.
The Welcome window opens for the Create And Package New IP dialog box.
 Click Next. 2.
The Choose Create Peripheral or Package IP dialog box appears.

Figure 37: Choose Create Peripheral or Package IP Window
As seen above, there are three choices:
 Package your current project: Package the open project in the Vivado Design Suite as an
IP core to add to the IP repository for future use.
 Package a specified directory: Package a directory of design files that is not currently
open in the Vivado Design Suite. See Sidebar: Packaging a Specified Directory for more
information on this feature.
 Create an AXI4 peripheral: Create a template AXI4 peripheral that includes the HDL,
drivers, a test application, a Bus Functional Model (BFM), and an example template. Refer
to the Vivado Design Suite User Guide: Designing IP Subsystems with IP Integrator
(UG995) for more information.
Send Feedback

## Page 43

Step 3: Packaging IP
Designing with IP www.xilinx.com  43
UG939 (v2014.1) April 2, 2014
 Select the Package your project option to use the current project as the source for creating 3.
the new IP Definition.
 Select Next. 4.

Figure 38: Package Current Project
The Package Your Current Project dialog box opens with the following fields:
 IP Location: Specify the path to the current project as the IP location. This field is
automatically populated by the open project.
 Include .xci files: Use this switch to define and package an XCI file for the newly created
IP core, and generate the needed output products when the IP is used in a design. This is
the default.
 Include IP generated files: Select this switch if you already have generated HDL for IP in
the project.
 Click Next to accept the defaults.  5.
The New IP Creation dialog box, as shown in Figure 39, opens to summarize the information
the wizard will automatically gather from the project.
Send Feedback

## Page 44

Step 3: Packaging IP
Designing with IP www.xilinx.com  44
UG939 (v2014.1) April 2, 2014

Figure 39: Begin IP Creation
 Click Finish. 6.
After the Vivado Design Suite has packaged the current project as an IP for inclusion in the
IP repository, the Package IP dialog box opens to report success.
 Click OK. 7.
The IP Packager feature creates a basic IP package in a staging area for editing and saving to
the IP repository, as seen in Figure 40.
Send Feedback

## Page 45

Step 3: Packaging IP
Designing with IP www.xilinx.com  45
UG939 (v2014.1) April 2, 2014

Figure 40: Editing the Default IP Definition
Modifying the IP Definition
The Package IP window shows the current IP identification information, including Vendor,
Library, Name, and Version (VLNV) attributes of the newly packaged IP.
 In the Package IP window, select the IP Identification pane in the left side panel, and fill in 1.
the right side with the following information:
 Vendor: my_company
 Name: my_simple_uart
 Display name: My Simple UART
 Description: My simple example UART interface
 Vendor display name: My Company
 Company url: http://www.my_company_name.com
 For the Categories option, select the browse button, , to open the Choose IP Categories 2.
dialog box, as shown in Figure 41.
The Choose IP Categories dialog box lets you select various appropriate categories to help
classify the new IP definition. When the IP definition is added to the IP Catalog, the IP will be
listed under the specified categories.
Send Feedback

## Page 46

Step 3: Packaging IP
Designing with IP www.xilinx.com  46
UG939 (v2014.1) April 2, 2014
 Select the Serial Interfaces box under Communications & Networking as the IP is a UART 3.
interface.
 Click OK. 4.

Figure 41: Choose IP Categories
 On the left side of the Package IP window, select the IP File Groups item to display the IP 5.
File Groups panel on the right side.
The IP File Groups panel provides a listing of the files that will be packaged as part of the IP.

Figure 42: IP File Groups
 Open the Messages window, and review the IP Packager messages as seen in Figure 43.  6.
Send Feedback

## Page 47

Step 3: Packaging IP
Designing with IP www.xilinx.com  47
UG939 (v2014.1) April 2, 2014
The IP Packager messages inform you of the state of the IP. The IP File Groups Wizard
message indicates that the IP definition does not include any documentation. The IP GUI
Customization Wizard informs you that specific parameters of the IP do not have range
values. As INFO messages, these are quick checks of the IP definition that do not prevent
you from moving forward if you choose. However, in the next step you will add the product
guide to the IP definition.

Figure 43: IP Packager Messages
 In the Package IP window, right click in the IP File Groups panel and select Add File Group 7.
from the popup menu.

Figure 44: Add IP File Group – Product Guide
Send Feedback

## Page 48

Step 3: Packaging IP
Designing with IP www.xilinx.com  48
UG939 (v2014.1) April 2, 2014
 In the Add IP File Group dialog box, select Product Guide from the Standard File Groups 8.
section, as shown in Figure 44.
 Click OK to add the Product Guide file group. 9.
The IP File Groups pane will now be updated with the Product Guide group in the list. There
will be a 0 next to the Product Guide name as there are 0 files added to the newly created
group.
Note: A critical warning will appear when the Product Guide file group is added, noting that
the file group is empty.
 In the IP File Groups panel, right click on the Product Guide file group and select Add Files 10.
from the popup menu.
 Click Add Files in the opened Add IP Files (Product Guide) dialog box. 11.
 Browse to <Extract_Dir>/lab_3/my_simple_uart/docs, and select All Files in the 12.
Files of type: entry line.
 Select my_simple_uart_product_guide.pdf and click OK. 13.
 In the Add IP Files (Product Guide) dialog box, ensure that Copy sources into project is 14.
selected.

Figure 45: Add Product Guide
 Click OK. 15.
The PDF file of the Product Guide is added to the files defined as part of the IP. The Critical
Warning has been resolved.

Send Feedback

## Page 49

Step 3: Packaging IP
Designing with IP www.xilinx.com  49
UG939 (v2014.1) April 2, 2014
Review and Package the IP
 On the left side of the Package IP window, select the Review and Package panel.  16.
The Review and Package panel provides a Summary of the IP being packaged, as shown in
Figure 46.

Figure 46: Review and Package IP
Based on the settings of the current project, Vivado will not generate an archive for this IP
after packaging. This is reflected in the After Packaging section of the Review and Package
panel of the Package IP window.
 Click the edit packaging settings link next to After Packaging heading, as seen in Figure 46, 17.
to change the setting.
The settings link will open the Tools > Project Settings > IP dialog box.
 Enable the Create archive of IP checkbox under the Automatic Behavior section of the 18.
Packager tab, as seen in Figure 47.
 Click OK to close the Project Settings dialog box. 19.
Send Feedback

## Page 50

Step 3: Packaging IP
Designing with IP www.xilinx.com  50
UG939 (v2014.1) April 2, 2014

Figure 47: Project Settings – Package IP
After closing the Project Settings dialog box, the Review and Package pane will refresh with
the updated settings. The default location of the IP archive is the current project directory.

TIP: You can click the edit link next to the Archive name and location to change the
default if needed.
 In the Package IP window, click Package IP, , to package the current project, 20.
add it to the IP catalog, and create a Zip file archive of the IP.
 After the packaging process completes, close the Vivado project.  21.


Send Feedback

## Page 51

Step 3: Packaging IP
Designing with IP www.xilinx.com  51
UG939 (v2014.1) April 2, 2014
Sidebar: Packaging a Specified Directory
In Figure 37, the option to Package a specified directory lets you take a directory of files,
whether as a Vivado Design Suite project, or just a series of related folders, and package them as
an IP for inclusion in the IP repository.
The IP Packager feature will examine the structure of the specified directory for various file types
to populate the contents for the created IP core. The tool will try to identify synthesizable source
files by filtering the directory structure for design source (*.v*) and design constraints (*.xdc)
files. All of the files in the specified directory and subdirectories are examined to be packaged as
part of the IP definition.
In the case of a Vivado tools project, the project structure lets the IP Packager feature identify
the design sources, simulation sources, and design constraints for the IP. However, when
packaging a specified directory, the Vivado Design Suite will infer a packaged IP from the
following directory structure:
 Synthesizable source files are located in /src or /hdl.
 Simulation source files are located in /sim or /simulation.
 Example source files are found in /example, /ex, or /examples.
 Testbench is found in /testbench, /tb, or /test.
 C-level simulation models are found in /cmodel or /c.
 Documents are located in /docs, /doc, or /documents.
 A Peripheral Analyze Order (*.pao) file from a Xilinx EDK project in /data will be used to
acquire additional library information.
The use of the described directory structure lets you gather the various source files for inclusion
into a packaged IP to automate much of the IP packaging process. As noted previously, if the
specified directory does not adhere to the described structure, the directories and subdirectories
will be searched recursively for the appropriate files to add to the IP definition.


Send Feedback

## Page 52

Step 4: Validating the New IP
Designing with IP www.xilinx.com  52
UG939 (v2014.1) April 2, 2014
Step 4: Validating the New IP
With the new IP definition packaged and added to the IP Catalog, you can validate that the IP
works as expected when added to designs. To validate the IP, you will add a new customization
of the UART IP to a project, and synthesize the design.
 From the Vivado IDE Getting Started page, select Manage IP > New IP Location to create a 1.
new project.

Figure 48: New Manage IP Project

TIP: You can use either an RTL project or a Manage IP project to validate IP.
 Click Next at the New IP Location dialog box that opens. 2.

Figure 49: Manage IP Settings

Send Feedback

## Page 53

Step 4: Validating the New IP
Designing with IP www.xilinx.com  53
UG939 (v2014.1) April 2, 2014
 In the Manage IP Settings dialog box, set the following options as they appear in Figure 49. 3.
 Part: xc7k325tffg900-2
 Target language: Verilog
 Target Simulator: Vivado Simulator
 Simulator Language: Mixed
 IP Location: <Extract_Dir>/lab_3
 Click Finish to create the Manage IP project. 4.
A new Manage IP project opens in the Vivado IDE. The IP Catalog will open automatically in
a Manage IP project; however, the IP catalog will not contain the repository used to package
the UART IP. You will add the IP repository to the catalog at this time.
 In the IP Catalog window, right-click and select IP Settings from the popup menu.  5.
The Tools > Project Settings > IP dialog box opens.
 In the Repository Manager tab, click the Add Repository button to open the IP Repositories 6.
dialog box.
 In the IP Repositories dialog box, browse to and select the following location: 7.
<Extract_Dir>/lab_3/my_simple_uart
 Click Select to add the selected repository. 8.

Figure 50: Manage IP Repository
Send Feedback

## Page 54

Step 4: Validating the New IP
Designing with IP www.xilinx.com  54
UG939 (v2014.1) April 2, 2014
As seen in Figure 50, the added location displays in the IP Repositories section, and any
packaged IP found in the repositories is listed under the IP in Selected Repository. The My
Simple UART IP definition which you packaged in Step #3 is listed.
 Press OK to add the IP repository to the IP Catalog and close the dialog box.  9.

TIP: To define a custom IP repository for use across multiple design projects, or for
use by multiple designers, you can add the repository to your init.tcl script using
the following commands:
set_property ip_repo_paths <Repository_Dir> [current_fileset]
update_ip_catalog
The Vivado Design Suite sources the init.tcl file when it is launched. Refer to
Vivado Design Tcl Command Reference Guide (UG835) for more information on the
init.tcl script.
 In the IP Catalog, type UART in the Search at the top of the window. 10.
The My Simple UART that is reported under the BaseIP and Serial Interfaces categories that it
was previously assigned to during packaging.

Figure 51: Search IP Catalog for UART
 Select the My Simple UART by clicking on it under either the BaseIP or Serial Interface 11.
category.
Examine the Details pane of the IP Catalog window, as shown in Figure 52. Notice the details
match the information provided when you packaged the IP.
Send Feedback

## Page 55

Step 4: Validating the New IP
Designing with IP www.xilinx.com  55
UG939 (v2014.1) April 2, 2014

Figure 52: My Simple UART - Details
 Double click on My Simple UART in the IP Catalog to open the Customize IP dialog box, as 12.
seen in Figure 53.

Figure 53: Customize IP – My Simple UART
 In the Customize IP dialog box, click on Documentation and open the Product Guide. 13.
 Click OK, accepting the default Component Name and other options.  14.
The customized IP is added to the current project, and is shown in the IP Sources window. In
addition, the Generate Output Products dialog box opens, as shown in Figure 54.
Send Feedback

## Page 56

Step 4: Validating the New IP
Designing with IP www.xilinx.com  56
UG939 (v2014.1) April 2, 2014

Figure 54: Generate Output Products
 Click Generate. 15.
This will generate the various files required for this IP in the current Manage IP project, and
launch an Out-of-Context synthesis run for the IP to create a DCP. Recall this OOC synthesis
run will use the OOC XDC file that defines the needed clocks for the standalone IP.
Examine the IP Sources window and the various design and simulation source files that are
added to the project. In the Design Runs window, verify that the Out-Of-Context synthesis
run was successful.
Send Feedback

## Page 57

Conclusion
Designing with IP www.xilinx.com  57
UG939 (v2014.1) April 2, 2014

Figure 55: Validate IP in Managed IP Project
Conclusion
In this Lab, you used the Create and Package IP Wizard to create an IP definition for the
tutorial project, my_simple_uart. You setup the XDC files to support the processing order
requirements as well as Out-Of-Context synthesis. You created an archive of the newly packaged
IP definition which contains all the source files and documentation for the IP.
You then validated the packaged IP by creating a Managed IP project, and then adding the new
IP repository to the IP Catalog. Finally, you created a customization of the IP, and generated a
DCP of the IP to validate that the IP definition was complete and included all the necessary files
to support using the IP in other designs.

Send Feedback

## Page 58

Step 1: Creating a Project
Designing with IP www.xilinx.com  58
UG939 (v2014.1) April 2, 2014
Lab 4: Scripting the Project Mode
In this exercise, you will write a Project Mode Tcl script, creating a new project and adding
source RTL and IP definitions. When working in Project Mode, a directory structure is created on
disk in order to manage design source files, run results, and track project status. A runs
infrastructure is used to manage the automated synthesis and implementation process and to
track run status.
In Lab 5: Scripting the Non-Project Mode, you will explore creating Tcl scripts to run the Vivado
tools in Non-Project Mode, which does not rely on project files and managed source files. For
more information on Project Mode and Non-Project Mode, refer to the Vivado Design Suite User
Guide: Design Flows Overview (UG892).
The best way to become familiar with scripting the Project Mode design flow is by first running
the design flow interactively in the Vivado IDE, and then referencing the journal file,
vivado.jou, that the Vivado Design Suite creates. By editing the journal file, you can create a
Tcl script that encompasses the entire Project Mode design flow. In this lab, you will build the
script by hand. For more information on writing and using Tcl scripts, see the Vivado Design
Suite User Guide: Using Tcl Scripting (UG894).

CAUTION! When copying Tcl commands and script examples from this Tutorial document
and pasting them into the Vivado Design Suite Tcl shell, or Tcl Console, the dash “-“
character can sometimes be converted to an em-dash “–“ which will result in errors when
the commands are run.
Step 1: Creating a Project
 Invoke a text editor of your choice, such as Emacs, vi, or Notepad; or launch the Text Editor 1.
from within the Vivado IDE.
 Save a new file called project_run.tcl in <Extract_Dir>/lab_4. 2.
You will start your script by creating a new project using the create_project command. This
results in a new project directory being created on disk. However, you want to make sure
that the project is created in the right location to find source files referenced by the script.
 Add the following line to your Tcl script to change to the appropriate directory for this lab: 3.
cd <Extract_Dir>4/lab_4
Now you are ready to create your project.

4 Replace the <Extract_Dir> variable with the actual path to your tutorial data. For example:
C:/Data/ug939-design-files/lab_4
Send Feedback

## Page 59

Step 2: Adding RTL Source Files
Designing with IP www.xilinx.com  59
UG939 (v2014.1) April 2, 2014
 Add the following Tcl command to your project_run.tcl script: 4.
create_project –force -part xc7k70t-fbg484-3 my_project my_project
A directory called my_project is created, and a project named my_project is added to it.
The directory and project are created at the location where the script is run. You can specify
a different directory name with the -dir option of the create_project command.
All the reports and log files, design runs, project state, etc. are stored in the project directory,
as well as any source files that you import into the project.
The target Xilinx part for this project is defined by the –part xc7k70t option. If –part is
not specified, the default part for the Vivado release is used.

TIP: You can use the set_property command to change the part at a later time, for
example: set_property part xc7k325tfbg900-2 [current_project]
The -force option is technically not required, since the project directory should not exist
prior to running this script. However, if the project directory does exist, the script will error
out unless the -force option is specified.
Refer to the Vivado Design Suite Tcl Command Reference Guide (UG835), or at the Tcl prompt
type help <command_name>, for more information on the create_project command,
or any other Tcl command used in this tutorial.
Step 2: Adding RTL Source Files
For this script, you will be copying all the RTL source files into the local project directory.
Since all the HDL files that you need are located in <Extract_Dir>/lab_4/sources, you
can add the entire directory directly.
 Add the following two lines to your script: 1.
add_files -scan_for_includes ./sources/HDL
import_files
The -scan_for_includes option scans the Verilog source files for any `include
statements, and also adds these referenced files as source files to the project. By default,
`include files are not added to the fileset.
The specification of ./sources provides a relative path for locating the source files from
where the Tcl script is being run. You will recall that the project_run.tcl script is being
created in the <Extract_Dir>/lab_4 directory, so the ./sources folder is found within
that directory.
The import_files command copies the files into the local project directory. When no files
are specified, as is the case here, the Vivado Design Suite imports files referenced in the
source fileset for the current project.
Send Feedback

## Page 60

Step 3: Adding XDC Constraints
Designing with IP www.xilinx.com  60
UG939 (v2014.1) April 2, 2014

TIP: You can reference source files from their original location by not importing the files
with the import_files command.
Step 3: Adding XDC Constraints
For this design, there are two XDC files that are required: top_physical.xdc and
top_timing.xdc.
 Add the following lines to your script to import the XDC files into your project: 1.
import_files -fileset constrs_1 \
   {./sources/Constraints/top_timing.xdc \
   ./sources/Constraints/top_physical.xdc}


TIP: The “\” character in the preceding text is used to split Tcl commands across multiple
lines. This is useful for making scripts that are more readable and easier to edit.
By default, all XDC files are used in both synthesis and implementation. However, in this
case, you will assign the XDC files for use as follows:
 top_timing.xdc is used in both synthesis and implementation.
 top_physical.xdc is used only in implementation.
 To disable the use of top_physical.xdc during synthesis, add the following line to your 2.
script:
set_property used_in_synthesis false [get_files top_physical.xdc]
This disables the used_in_synthesis property on the specified XDC file.
The property for implementation is used_in_implementation, though you will leave that
enabled (true).
Step 4: Adding Existing IP
You will also import IP cores into the project. There are four IP cores used in this design:
 Accumulator:  A legacy CORE Generator IP, with the associated NGC.
 Block memory generator:  A 2014.1 version of a native Vivado Design Suite IP with no output
products generated.
 FIFO Generator:  Vivado 2014.1 version with all output products, including DCP.
 Clock Wizard:  Vivado 2014.1 version with no output products.
All of these IPs, with the exception of the Accumulator IP, are native Vivado cores. They have
already been customized, and have a Xilinx Core Instance (XCI) file.
Send Feedback

## Page 61

Step 4: Adding Existing IP
Designing with IP www.xilinx.com  61
UG939 (v2014.1) April 2, 2014
In the case of the Accumulator IP, the imported file is a CORE Generator log file (.xco). This is a
legacy IP.
 To import these IP cores into the project, add the following lines to your script: 1.
import_ip -files {./sources/IP/Accumulator/Accumulator.xco \
 ./sources/IP/blk_mem/blk_mem_gen_v7_3_0.xci \
 ./sources/IP/clk_wiz/clk_wiz_0.xci \
 ./sources/IP/char_fifo/char_fifo.xci}
When this line is processed, warning messages for most of the imported IP are returned by
the Vivado Design Suite:
WARNING: [IP_Flow 19-2162] IP 'Accumulator' is locked:
* IP definition 'Accumulator (11.0)' for IP 'Accumulator' has a newer
major version in the IP Catalog.
Please select 'Report IP Status' from the 'Tools/Report' menu or run Tcl
command 'report_ip_status' for more information.

WARNING: [IP_Flow 19-2162] IP 'blk_mem_gen_v7_3_0' is locked:
* IP definition 'Block Memory Generator (7.3)' for IP 'blk_mem_gen_v7_3_0'
has a newer major version in the IP Catalog.
Please select 'Report IP Status' from the 'Tools/Report' menu or run Tcl
command 'report_ip_status' for more information.

WARNING: [IP_Flow 19-3197] Could not import any simulation or synthesis
outputs for IP 'blk_mem_gen_v7_3_0'

WARNING: [IP_Flow 19-3197] Could not import any simulation or synthesis
outputs for IP 'clk_wiz_0'
The problem with the Accumulator is that the version in the design does not match the
latest version in the IP catalog. However, there is a netlist output product (.ngc) so you can
work with the version in the design, or upgrade it to the latest version from the IP catalog.
The blk_mem_gen_v7_3_0 core is also not the latest version in the IP catalog, however,
there are no output products to drive synthesis or simulation, so it will have to be upgraded
to the latest version. You will upgrade this IP in a subsequent step. If no upgrade path is
available, you will have to recreate the IP.
For the clk_wiz_0, no output products were found with the customization (.xci), but the IP
is the current version in the IP catalog. You will manually generate the output products for
this IP in the next step.
The char_fifo version is current and all output products are present so no warning
messages are produced when importing.


RECOMMENDED: When there is a major version change to an IP core in the
catalog, changes to the IP such as parameter or port name changes, may make
upgrading the IP to the latest version require changes to the design.
Send Feedback

## Page 62

Step 5: Disabling an IP’s XDC
Designing with IP www.xilinx.com  62
UG939 (v2014.1) April 2, 2014
Step 5: Disabling an IP’s XDC
For this design, you will disable the XDC files that are included with the Clock Wizard IP, so that
you can apply the top-level timing constraints to the clk_wiz_0 module. This IP has not had
the output products generated, so you will first generate the synthesis targets, which includes
the XDC files.
In a project mode you are not required to generate output products manually. The output
products from IP are generated automatically as needed in the design flow, including the
generation of a Synthesis design checkpoint. However, since you are changing a property on the
XDC files delivered with the clk_wiz IP, you must manually generate the output products to
create the constraints file or files to change the property. Also, since you want to disable the use
of an IP XDC file and provide the constraints during synthesis of the top-level design, you need
to disable to generation of the clk_wiz synthesis DCP (or netlist) as well.
 To Disable the automatic generation of a Synthesis Design Checkpoint file Add the 1.
following to your script:
set_property generate_synth_checkpoint false [get_files clk_wiz_0.xci]
Now when the design is synthesized, an Out-of-Context Module (OOC) synthesis run will not
be automatically created and launched for the clk_wiz_0 IP. Instead, the clk_wiz_0 IP will
be synthesized as part of the top-level design.
 Add the generate_target command to your Tcl script: 2.
generate_target synthesis [get_files clk_wiz_0.xci]
Multiple output products can be generated by passing a list to the command, such as
{synthesis instantiation_template}, or you can generate all the available output products by
specifying {all}.

TIP: To find out what output products an IP supports, use either the report_property
command on the IP, or get_property to get the KNOWN_TARGETS property from the
IP. For example (do not add these to your script):
report_property [get_ips clk_wiz_0]
get_property KNOWN_TARGETS [get_ips clk_wiz_0]
To disable the XDC constraints delivered with the Clock Wizard, you need the names of the
files. You can query the XDC files(s) that are delivered with an IP, by using the get_files
command with the –of_objects and –filter options.
 To capture the XDC file names of the Clock Wizard IP in a Tcl variable, add the following 3.
lines to your script:
set clk_wiz_xdc [get_files -of_objects [get_files \
clk_wiz_0.xci] -filter {FILE_TYPE == XDC}]
This will return the names of the XDC files that are delivered with the Clock Wizard.

Send Feedback

## Page 63

Step 6: Upgrading an IP
Designing with IP www.xilinx.com  63
UG939 (v2014.1) April 2, 2014
 To disable the XDC files, add this line to your script as well: 4.
set_property is_enabled false [get_files $clk_wiz_xdc]
The XDC files delivered with clk_wiz IP are disabled when you run your script.

TIP: To check what XDC files are evaluated in a project, and in what order, you can
use the report_compile_order command with the -constraints option.
Step 6: Upgrading an IP
As mentioned earlier, the block memory generator IP in the design has a newer version available
in the IP catalog. The IP is locked as a result, because it cannot be re-customized from the IP
catalog unless you upgrade it to the latest version. When adding the XCI to a project this
warning appears:
WARNING: [IP_Flow 19-2162] IP 'blk_mem_gen_v7_3_0' is locked:
* IP definition 'Block Memory Generator (7.3)' for IP 'blk_mem_gen_v7_3_0'
has a newer major version in the IP Catalog.
Please select 'Report IP Status' from the 'Tools/Report' menu or run Tcl
command 'report_ip_status' for more information.
In an interactive session this message can be helpful, but in a batch mode script this would not
be seen until after synthesis or implementation fails. To anticipate and prevent this, you can use
your script to:
 Determine if an IP is locked.
 Check for a newer version of the IP in the catalog.
 Upgrade an IP if it is locked, and a new version is available.
The following sequence shows you how to do this.
 First, you will check to see if the IP is locked, and store the state in a Tcl variable. Add the 1.
following line to your Tcl script:
set locked [get_property IS_LOCKED [get_ips blk_mem_gen_v7_3_0]]
 Next, you will check to see if there is an upgrade available in the IP catalog, and store that 2.
information in a Tcl variable as well. Add the following line to your Tcl script:
set upgrade [get_property UPGRADE_VERSIONS [get_ips blk_mem_gen_v7_3_0]]
This will return the VLNV (Vendor:Library:Name:Version) identifier of the upgrade, if there is
one available. If there is no upgrade, the variable will contain an empty string (””). In the case
of the blk_mem_gen_v7_3_0 IP, there is an upgrade available.
 Now you can check the stored Tcl variables, $locked and $upgrade, to see if the IP is 3.
locked AND if there is an upgrade version for the IP. If so, you can upgrade the IP. Add the
following lines to your Tcl script:
if {$upgrade != "" && $locked} {
  upgrade_ip [get_ips blk_mem_gen_v7_3_0]}
Send Feedback

## Page 64

Step 7: Setting up Design Runs for IP
Designing with IP www.xilinx.com  64
UG939 (v2014.1) April 2, 2014
This will result in upgrading the block memory generator IP from the current version in the
design, to the latest version in the IP catalog.
The Accumulator core is legacy IP that was created with CORE Generator, rather than native
IP created in the Vivado Design Suite. The IP has all the necessary output products, for
instantiating the HDL module into a design, for synthesis, and for simulation. So it can be
used in its current form though it will not have any timing constraints.
However, you should upgrade legacy IP to native Vivado IP whenever possible. This will
ensure you have the latest updates and fixes for an IP, and any XDC constraints delivered
with it.
 Following the steps in 1-3 above, add a sequence of commands to your Tcl script to check if 4.
the Accumulator IP is locked, has an available upgrade, and upgrade the IP if so.

TIP: You could create a foreach loop in your Tcl script that will perform these checks for all
IPs in a design:
foreach design_IP [get_ips] {
   add code here…
}
Refer to the Vivado Design Suite User Guide: Using Tcl Scripting (UG894) for more
information.
Step 7: Setting up Design Runs for IP
Now that all the IP have been upgraded to the latest version you can optionally setup and
launch out-of-context synthesis runs for the IP. You already configured the Clocking Wizard IP
to not use the out-of-context flow in Step 5: Disabling an IP’s XDC. The FIFO Generator IP
already had all the output products, including the DCP, generated when it was imported.
However, the Block Memory Generator and Accumulator IP have not had any output products
generated.
In a project flow if the IP is current then all the output products, including the DCP, will be
generated automatically. However, you can also script this step. One reason to manually create
and launch design runs for the IP cores in a project is to have the out-of-context synthesis
processes run concurrently. By default they will be launched serially.
Create a design run for the Accumulator IP and launch it. For a Synthesis Design Checkpoint to
be generated an IP Design Run must first be created.
 Add the following to your Tcl script: 1.
create_ip_run [get_ips Accumulator]
A new run is created for the IP, with the name <IP_name>_synth_1. The IP design run is
launched using the launch_runs command.

Send Feedback

## Page 65

Step 8: Launching Synthesis and Implementation
Designing with IP www.xilinx.com  65
UG939 (v2014.1) April 2, 2014
 Add the following to your script: 2.
launch_runs [get_runs Accumulator_synth_1]
The run is now launched and when completed a Synthesis Design Checkpoint will be added
to the project. If you do not launch the IP run it will automatically be launched when
synthesizing the top level. If you have multiple IP runs that you created they will then get
launched serially. To launch in parallel you need to use the launch_runs command.
During synthesis of the top level logic a black box will be inferred for the IP. During
implementation the DCP will be opened and the netlist read and constraints applied.
When launching the top level synthesis run it will automatically wait for any IP runs to
complete so there is no need to put wait_on_run commands for each IP run.
Note: If you wanted to have a number of IP generate DCPs in parallel you can either:
 Create all the runs first and then launch all the runs
 Create an IP run and then launch it, create another IP run and then launch it
Step 8: Launching Synthesis and Implementation
The project is now ready for synthesis and implementation. The Vivado Design Suite
automatically generates the necessary output products for the various IP in your project, as
needed. You do not need to manually generate the output products unless you want to make
changes to the generated output products prior to using them in synthesis, simulation, or
implementation.
In the Project Mode, the Vivado Design Suite manages the details of synthesis and
implementation runs, using run strategies and maintaining the state of the design. Therefore,
you will use the launch_runs command to run synthesis and implementation in project-based
designs.
 Add the following line to your Tcl script: 1.
launch_runs synth_1
By default, a synthesis run called synth_1 is created for every project. You can also
manually create new runs using the create_run command, and configure run properties
using the set_property command. See the Vivado Design Suite User Guide: Design Flows
Overview (UG892) for more information on creating and configuring runs.
After the synthesis run has completed, you can launch an implementation run. However,
since the implementation run is dependent on the completion of the synthesis run, you must
use the wait_on_run command to hold your Tcl script until synthesis is complete.
 Add these two lines to your script: 2.
wait_on_run synth_1
launch_runs impl_1 –to_step write_bitstream
When the synthesis run, synth_1, completes, the implementation run, impl_1, begins.
Send Feedback

## Page 66

Step 8: Launching Synthesis and Implementation
Designing with IP www.xilinx.com  66
UG939 (v2014.1) April 2, 2014
Implementation is a multi-step process that begins with netlist optimization, runs through
placement and routing, and can even include generating the bitstream for the Xilinx FPGA.
The -to_step option that you added to your Tcl script, indicates that implementation
should include generating the bitstream for the device. By default, implementation does not
include that step. Refer to the Vivado Design Suite User Guide: Implementation (UG904) for
more information.

TIP: Alternatively, you can use the write_bitsteam command; this requires that
you open the implementation run first using the open_run command.
Just as implementation needed to wait on synthesis to complete, you will want your Tcl
script to wait on implementation to complete before generating any reports, or exiting.
 Add the wait_on_run command to your Tcl script, to wait for the implementation run to 3.
complete:
wait_on_run impl_1
The script will wait until the implementation run completes before continuing.

Send Feedback

## Page 67

Step 9: Running the Script
Designing with IP www.xilinx.com  67
UG939 (v2014.1) April 2, 2014
Step 9: Running the Script
You are now ready to run the script. Your script should be similar to the following:
#Step 1: Create Project
cd C:/Data/ug939-design-files/lab_4
create_project -force -part xc7k70t-fbg484-3 my_project my_project

#Step 2: Adding RTL Files
add_files -scan_for_includes ./sources/HDL
import_files

#Step 3: Adding XDC Files
import_files -fileset constrs_1 \
   {./sources/Constraints/top_timing.xdc \
   ./sources/Constraints/top_physical.xdc}
set_property used_in_synthesis false [get_files top_physical.xdc]

#Step 4: Importing IP
import_ip {./sources/IP/Accumulator/Accumulator.xco \
 ./sources/IP/blk_mem/blk_mem_gen_v7_3_0.xci \
 ./sources/IP/clk_wiz/clk_wiz_0.xci \
 ./sources/IP/char_fifo/char_fifo.xci}

#Step 5: Disable XDC
set_property generate_synth_checkpoint false [get_files clk_wiz_0.xci]
generate_target synthesis [get_files clk_wiz_0.xci]
set clk_wiz_xdc [get_files -of_objects [get_files \
   clk_wiz_0.xci] -filter {FILE_TYPE == XDC}]
set_property is_enabled false [get_files $clk_wiz_xdc]

#Step 6: Upgrade IP
set locked [get_property IS_LOCKED [get_ips blk_mem_gen_v7_3_0]]
set upgrade [get_property UPGRADE_VERSIONS [get_ips blk_mem_gen_v7_3_0]]
if {$upgrade != "" && $locked} {
  upgrade_ip [get_ips blk_mem_gen_v7_3_0]}

set locked [get_property IS_LOCKED [get_ips Accumulator]]
set upgrade [get_property UPGRADE_VERSIONS [get_ips Accumulator]]
if {$upgrade != "" && $locked} {
  upgrade_ip [get_ips Accumulator]}

#Step 7: Launch IP run
create_ip_run [get_ips Accumulator]
launch_runs [get_runs Accumulator_synth_1]

#Step 8: Launching Synthesis and Implementation
launch_runs synth_1
wait_on_run synth_1
launch_runs –to_step write_bitstream impl_1
wait_on_run impl_1


Send Feedback

## Page 68

Step 9: Running the Script
Designing with IP www.xilinx.com  68
UG939 (v2014.1) April 2, 2014
Sourcing the Tcl Script
You can run the project_run.tcl script in Vivado Design Suite batch mode or Tcl mode.
 Batch mode will run the sourced script, and then automatically exit the tool after the script
has finished processing.
 Tcl mode will run the sourced script, and return to the Tcl command prompt when finished.
On Linux,
 Change to the directory where the lab materials are stored: 1.
cd <Extract_Dir>/lab_4
 Launch the Vivado Design Suite Tcl shell, and source a Tcl script to create the tutorial design:  2.
vivado -mode tcl -source project_run.tcl
 On Windows,
 Launch the Vivado Design Suite Tcl shell: 1.
Start > All Programs > Xilinx Design Tools > Vivado 2014.x >
Vivado 2014.x Tcl Shell5
 In the Tcl shell, change to the directory where the lab materials are stored: 2.
Vivado% cd <Extract_Dir>/lab_4
 Source the Tcl script to create the design: 3.
Vivado% source project_run.tcl
After the sourced script has completed, the Tcl shell displays the Vivado% prompt.

Figure 56: Vivado Tcl Mode and Sourced Tcl Script

5 Your Vivado Design Suite installation may called something different than Xilinx Design Tools
on the Start menu.
Send Feedback

## Page 69

Conclusion
Designing with IP www.xilinx.com  69
UG939 (v2014.1) April 2, 2014

IMPORTANT: If your Tcl script has an error in it, the script will halt execution at the point
of the error. You will need to fix the error, and re-source the Tcl script as needed. If you are
running in Tcl mode, you may need to close the current project with close_project, or exit
the Vivado tool with exit to source the Tcl script again.
After the script executes, a project directory structure is created, default log and reports are
generated, a synthesized netlist is produced, design is fully implemented, and a bitstream is
created. You can use the Vivado IDE to examine the design, the various reports, and to
perform analysis on the design.
To open the GUI from the Tcl prompt type start_gui.
Conclusion
Creating a design project does not require the use of the Vivado IDE. The benefits of the Project
Mode, such as automatic report generation, design runs infrastructure, and managed source
files, are available from a Tcl script. The result of the script is a design project, which you can
open in the Vivado IDE for interactive timing analysis and design exploration.
Specific areas covered in this lab are:
 Creating a project and adding HDL sources.
 Adding IP sources to a project, both native XCI files and legacy XCO files.
 Generating IP Output Products.
 Disabling IP Output Products, such as an XDC file.
 Disabling the creation of a Synthesis Design Checkpoint (DCP) file.
 Creating and launching IP design runs.
 Querying an IP’s properties.
 Updating an IP to the latest version.
 Launching synthesis and implementation runs, and generating a bitstream.


Send Feedback

## Page 70

Step 1: Reading Design Source Files
Designing with IP www.xilinx.com  70
UG939 (v2014.1) April 2, 2014
Lab 5: Scripting the Non-Project Mode
In Lab 4: Scripting the Project Mode, you created a Tcl script to run the Vivado Design Suite in
Project Mode. In this lab, you will create a Tcl script to run the Vivado tools in Non-Project
Mode. Many of the commands used in this lab are the same commands used in Lab 4. The main
difference between Project Mode and Non-Project Mode is that there is no project file or
directory structure created on disk. Instead, Vivado Design Suite manages the design directly in
an in-memory database.
In Non-Project Mode, you do not have a project file to add source file references to, or a project
directory to manage source files. In Non-Project Mode, you read source files into the Vivado
Design Suite to create the in-memory design. In addition, there is no design runs infrastructure
to store run strategies and results. Instead, you directly call the various commands to run the
different stages of synthesis and implementation. Unlike Project Mode, you must manually write
out design checkpoints, netlists, and reports. These items are not created automatically for you
in Non-Project Mode. For more information on Project Mode and Non-Project Mode, refer to
the Vivado Design Suite User Guide: Design Flows Overview (UG892).
When working with IP in Non-Project Mode you must manually generate output products,
including synthesis Design Checkpoints if desired.


CAUTION! When copying Tcl commands and script examples from this Tutorial document
and pasting them into the Vivado Design Suite Tcl shell, or Tcl Console, the dash “-“
character can sometimes be converted to an em-dash “–“ which will result in errors when
the commands are run.
Step 1: Reading Design Source Files
 Invoke a text editor of your choice, such as Emacs, vi, or Notepad; or launch the Text Editor 1.
from within the Vivado IDE.
 Save a new file called nonproject_run.tcl in <Extract_Dir>/lab_5. 2.
In Lab 4, you started your project by creating a project; here you will begin by creating an in-
memory design, and reading source files. However, you want to first make sure that the Tcl
script is in the right location to find source files referenced by the script.
 Add the following line to your Tcl script to change to the appropriate directory for this lab: 3.
Send Feedback

## Page 71

Step 1: Reading Design Source Files
Designing with IP www.xilinx.com  71
UG939 (v2014.1) April 2, 2014
cd <Extract_Dir>6/lab_5
Even though this is a non-project flow script, it is advised that an in-memory project be
created to set the target part for the design. This target part will be used for all IP that are
added to the design, otherwise the default part for the Vivado Design Suite is used.
Additionally, setting the target part removes the need to specify a part when synthesizing
the top-level design, or any IP for out-of-context synthesis.
 Add the following to your script to create the in-memory project: 4.
create_project -in_memory -part xc7k70t-fbg484-3
Creating an in-memory project does not result in a project being created on disk.

RECOMMENDED: In Non-Project Mode, there is no project part unless you create
an in-memory project. If you do not create an in-memory project, the IP output
products are generated using the default part of the Vivado Design Suite release.
This default part might not be the intended target part specified by the synth_design
command, and can result in mismatched synthesis results between the IP and the
top-level design in Non-Project Mode designs. See Lab 2: Creating and Managing
Reusable IP for more information on managing IP customizations.
Now you are ready to read the source files for the design. In Project Mode, you use
commands such as add_files and import_files to add source files to the project. In
Non-Project Mode, you can use add_files, which will call the appropriate lower-level
command, but it is more typical to directly read the file. This is similar to an ASIC tool flow.
For this lab, you are working with Verilog source files and will use read_verilog to read
them.
 Add the following line to your script to read all the Verilog source for this project: 5.
read_verilog [glob ./sources/HDL/*.v]


TIP: The glob command is a built-in Tcl command that creates a list out of the
specified objects. Alternatively, you can make a Tcl list to pass to read_verilog, or
use a separate read_verilog command for each file.


6 Replace the <Extract_Dir> variable with the actual path to your tutorial data. For example:
C:/Data/ug939-design-files/lab_5
Send Feedback

## Page 72

Step 2: Adding Existing IP
Designing with IP www.xilinx.com  72
UG939 (v2014.1) April 2, 2014
Step 2: Adding Existing IP
You will also read the following IP cores into the design:
 Accumulator: A legacy CORE Generator IP, with no output products or NGC.
 FIFO Generator: 2014.1 version native IP with all output products, including a DCP.
 Clock Wizard: 2014.1 version native IP with no output products.
 Block memory generator: A 2014.1 version of a native Vivado Design Suite IP with no output
products generated.
All of these IPs, with the exception of the Accumulator IP, are native Vivado cores. They have
already been customized, and have Xilinx Core Instance (XCI) files. The Accumulator IP is a
legacy CORE Generator log file (XCO).
The FIFO Generator IP already has all required output products available, and can be read and
used directly from its current location. Whenever you create an IP customization, you should
always generate all available output products.
 To read the FIFO Generator IP, including all the output products that are present, add the 1.
following line to your script:
read_ip ./sources/IP/char_fifo/char_fifo.xci
 Add the following to your Tcl script to create a local directory, with sub-directories for the 2.
block memory, accumulator and the clock wizard IP:
file mkdir IP/blk_mem
file mkdir IP/clk_wiz
file mkdir IP/accum
 Add the following to your Tcl script to copy the needed XCI files from the current IP 3.
repository into the local directory:
file copy -force ./sources/IP/blk_mem/blk_mem_gen_v7_3_0.xci ./IP/blk_mem
file copy -force ./sources/IP/clk_wiz/clk_wiz_0.xci ./IP/clk_wiz
file copy -force ./sources/IP/Accumulator/Accumulator.xco ./IP/accum
The -force option causes the file to be overwritten if it already exists. Without –force an
error could be returned and the script will quit.
For the clocking wizard IP, you will need to generate the output products before you can
synthesize the design. In Non-Project Mode, the Vivado Design Suite will not automatically
generate output products, and errors will be encountered if you do not do this prior to
launching synthesis.
Generating output products results in files and directories being written to the location the
IP XCI files are read from. In a managed IP repository, these locations may be read-only or
under revision control. In this case, you would copy the needed XCI files to a local directory
before reading them into the in-memory design.
Send Feedback

## Page 73

Step 3: Disabling XDC Files
Designing with IP www.xilinx.com  73
UG939 (v2014.1) April 2, 2014

IMPORTANT: It is important to have each XCI file stored in its own directory. When
output products are generated, they are written to the same directory as the XCI file. If IP
files are written to the same directory, it is possible that output products from different IPs
could overwrite each other.
 Add these lines to your Tcl script to read in the needed XCI files: 4.
read_ip ./IP/blk_mem/blk_mem_gen_v7_3_0.xci
read_ip ./IP/clk_wiz/clk_wiz_0.xci
read_ip ./IP/accum/Accumulator.xco
The specified XCI files are read into the in-memory design.
Unlike in Lab 4, the warnings related to locked IP do not display when the IP are processed
into the design using the read_ip command. In Project Mode, the Vivado Design Suite
performs checks as an IP is added to a project, resulting in the warning messages seen in
Lab 4, Step 4: Adding Existing IP. In Non-Project Mode, the checks are only performed when
the IP are processed during synthesis.
Step 3: Disabling XDC Files
As in Project Mode, if an IP delivers XDC constraints, they are automatically processed and
added to the in-memory design. For this design, you will disable the XDC files that are included
with the Clock Wizard IP as you have constraints in the top-level XDC file that you will apply
instead. However, the Clock Wizard IP has not had the output products generated, so you will
first need to generate the output products, which include the XDC files.
When generating the output products for an included XCI file IP, you must decide whether to
use an out-of-context flow, including the creation of a synthesis Design Checkpoint (DCP), or to
let the IP be synthesized as part of the top-level design.
Since for the Clocking Wizard you want to disable the use of an XDC you need to also configure
the IP to not use a DCP.
 Add the following to your script to configure the IP to not use a Synthesis Design 1.
Checkpoint:
set_property generate_synth_checkpoint false [get_files clk_wiz_0.xci]
Now when synthesis is done of the top level the RTL output products will be used and a DCP
will not be expected. Unlike in a Project Flow, output products are not automatically
generated as needed, and need to be manually created.
 Add the generate_target command to your Tcl script: 2.
generate_target all [get_ips clk_wiz_0]
Since you copied the XCI file from the source IP repository into a local directory, the output
products will be written to the local directory.
Send Feedback

## Page 74

Step 4: Upgrading IP
Designing with IP www.xilinx.com  74
UG939 (v2014.1) April 2, 2014

TIP: To find out what output products an IP supports, use either the report_property
command on the IP, or get_property to get the KNOWN_TARGETS property from the IP. For
example (do not add these to your script):
report_property [get_ips clk_wiz_0]
get_property KNOWN_TARGETS [get_ips clk_wiz_0]
Multiple output products can be generated by passing a list to the command, such as
{synthesis instantiation_template}.
To disable the XDC files delivered with the Clock Wizard, you need the names of the files.
You can query the XDC file(s) that are delivered with an IP, by using the get_files
command with the –of_objects and –filter options.
 To capture the XDC file names of the Clock Wizard IP in a Tcl variable, add the following 3.
lines to your script:
set clk_wiz_xdc [get_files -of_objects \
[get_files clk_wiz_0.xci] -filter {FILE_TYPE == XDC}]
This will return the names of the XDC files delivered with the Clock Wizard.
 To disable the XDC files, add this line to your script as well: 4.
set_property is_enabled false [get_files $clk_wiz_xdc]
The XDC files delivered with clk_wiz IP will be disabled when you run your script.
To check what XDC files are evaluated, and in what order, you can use the
report_compile_order command with the -constraints option.
Step 4: Upgrading IP
If you attempt to run synthesis at this time, you will see this warning for the Block Memory
Generator IP:
WARNING: [IP_Flow 19-2162] IP 'blk_mem_gen_v7_3_0' is locked. Locked
reason: IP definition 'Block Memory Generator' for IP 'blk_mem_gen_v7_3_0'
has a newer major version in the IP Catalog. No useable outputs are
available for this IP. Please select 'Report IP Status' from the
'Tools/Report' menu.
The Block Memory Generator is locked because it is not the most recent version of the IP. It also
does not have any output products and so must be upgraded before output products can be
generated.
Similar messages would be seen for the Accumulator. Both the Block Memory Generator and
Accumulator have updated versions in the Xilinx IP Catalog. In an interactive design session,
these messages can be helpful; but in a batch mode Tcl script these messages would not be
seen until after synthesis or implementation fails.

Send Feedback

## Page 75

Step 4: Upgrading IP
Designing with IP www.xilinx.com  75
UG939 (v2014.1) April 2, 2014
To anticipate and prevent this, you can use your script to:
 Determine if an IP is locked.
 Check for a newer version of the IP in the catalog.
 Upgrade an IP if it is locked, and a new version is available.
 Generate the output products for the IP.
You will do this for the blk_mem_gen_v7_3_0 IP using following sequence:
 First, you will check to see if the IP is locked, and store the state in a Tcl variable. Add the 1.
following line to your Tcl script:
set locked [get_property IS_LOCKED [get_ips blk_mem_gen_v7_3_0]]
 Next, you will check to see if there is an upgrade available in the IP catalog, and store that 2.
information in a Tcl variable as well. Add the following line to your Tcl script:
set upgrade [get_property UPGRADE_VERSIONS [get_ips blk_mem_gen_v7_3_0]]
This will return the VLNV (Vendor:Library:Name:Version) identifier of the upgrade, if there is
one available. If there is no upgrade, the variable will contain an empty string (””). In the case
of the blk_mem_gen_v7_3_0 IP, there is an upgrade available.
 Now you can check the stored Tcl variables, $locked and $upgrade, to see if the IP is 3.
locked AND if there is an upgrade version for the IP. If so, you can upgrade the IP. Add the
following lines to your Tcl script:
if {$locked && $upgrade != ""} {
  upgrade_ip [get_ips blk_mem_gen_v7_3_0]}
This will result in upgrading the block memory generator IP from the current version in the
design, to the latest version in the IP catalog.
 Now that the IP is current, add the following to your script: 4.
generate_target all [get_ips blk_mem_gen_v7_3_0]
The Accumulator core is legacy IP created with CORE Generator, rather than native IP
created in the Vivado Design Suite. If the IP had the necessary output products, for
instantiating the HDL module into a design, for implementation, and for simulation it could
be used in its current form.
However, you should upgrade legacy IP to native Vivado IP whenever possible. This will
ensure you have the latest updates and fixes for an IP, and any XDC constraints delivered
with it.
 Following the steps in 1-4 above, add a sequence of commands to your Tcl script to check if 5.
the Accumulator IP is locked, has an available upgrade, upgrade the IP if so, and generate
output products for it.

Send Feedback

## Page 76

Step 5: Creating DCP for IP
Designing with IP www.xilinx.com  76
UG939 (v2014.1) April 2, 2014

TIP: You could create a foreach loop in your Tcl script that will perform these checks for all
IPs in a design:
foreach design_IP [get_ips] {
   add code here…
}
Refer to the Vivado Design Suite User Guide: Using Tcl Scripting (UG894) for more
information.
Step 5: Creating DCP for IP
The default flow for Vivado is to use a Synthesis Design Checkpoint for IP. Typically when
referencing IP in a Non-Project Flow you would have created the IP customizations using a
Manage IP project. At that point, you would have created the output products and decided to
disable DCP use or generated the DCP. This is the case with the FIFO Generator IP (char_fifo); it
has all the output products generated including a DCP. The other three IP all consist of just an
XCI or XCO file and thus you need to configure the synthesis option. Either create a DCP for the
IP or configure it to be synthesized with the top-level logic.
In Step 3, you configured the Clocking Wizard to not use a DCP by setting a property on the IP
XCI file. At this point, you will generate a DCP for the Accumulator and Block Memory Generator
IP.
1. Add the following two lines to your script to create DCP for the Accumulator and Block
Memory Generator IP:
synth_ip [get_ips Accumulator]
synth_ip [get_ips blk_mem_gen_v7_3_0]
This results in a DCP file being created and stored in the directory containing the IP XCI file.
Step 6: Running Synthesis
For this design, there are two XDC files that are required, top_timing.xdc and
top_physical.xdc. One of the XDC files is used in both synthesis and implementation
(top_timing.xdc) while the other is used only during implementation (top_physical.xdc).
At this point in your Tcl script, you want to read the XDC file, using read_xdc, which is used in
both synthesis and implementation.
 Add the following to your Tcl script: 1.
read_xdc ./sources/Constraints/top_timing.xdc
The design is now ready for synthesis.
Send Feedback

## Page 77

Step 7: Running Implementation
Designing with IP www.xilinx.com  77
UG939 (v2014.1) April 2, 2014
In Non-Project Mode, unlike Project Mode, there are no design runs to launch, and no runs
infrastructure managing the strategies used and the state of the design. You will manually
launch the various stages of synthesis and implementation.
 For synthesis, you use the synth_design command. Add the following to your Tcl script: 2.
synth_design -top sys_integration_top
Since you created an in-memory project and set the target part, defining the target part is
not needed here. However, you must provide the top-level module name with the
synth_design command.
The various Verilog files read into the in-memory design in Step 1: Reading Design Source
Files do not reference other files via an `include statement. If they did, you would need to
define the `include search directories with the -include_dirs option.
After synthesis, you should generate a design checkpoint to save the results. This way you
can restore the synthesized design at any time without running synthesis again.
 Add the following write_checkpoint command to your Tcl script: 3.
write_checkpoint -force post_synth.dcp
The -force option is used to overwrite the checkpoint file if it already exists.
 You can also generate any needed reports at this point, such as a post-synthesis timing 4.
summary report. Add the following line to your Tcl script
report_timing_summary -file timing_syn.rpt
This command creates a comprehensive timing report for the design and writes the report to
a file.
Step 7: Running Implementation
With synthesis completed, you are now ready to script implementation. There are many steps to
implementation, in both Project Mode and Non-Project Mode. However, in Project Mode, you
select a design run strategy that controls all of the various steps, and launch that run. In Non-
Project Mode, without a design run, you must determine your implementation strategy by
manually running each step of implementation, and selecting the Tcl command options to use
at each step. You can also choose to skip some steps, such as logic optimization, power
optimization, and physical synthesis.
For this lab, you will run the following steps:
 Logic optimization: opt_design
 Placement: place_design
 Physical synthesis: phys_opt_design
 Routing: route_design
 Bitstream generation: write_bitstream
Send Feedback

## Page 78

Step 7: Running Implementation
Designing with IP www.xilinx.com  78
UG939 (v2014.1) April 2, 2014
For a complete description of each of these steps, see the Vivado Design Suite User Guide:
Implementation (UG904). Between each of these steps, you can generate reports, and write
checkpoints to save the design in different stages of implementation.
Before launching implementation, you must read the design constraints that are only used in
implementation. The XDC file, top_physical.xdc, contains physical constraints that are used
in implementation, but do not apply to synthesis. In this case, these constraints could have been
read into the in-memory design prior to synthesis, because synthesis will simply ignore them.
However, this file may also contain different timing constraints, not to be used in synthesis, that
must be read in after synthesis and just prior to implementation.
 Add the following line to your Tcl script: 1.
read_xdc ./sources/Constraints/top_physical.xdc
 Add optimization and placement commands to your Tcl script: 2.
opt_design
place_design
write_checkpoint -force post_place.dcp
report_timing -file timing_place.rpt
After placement completes, your script writes a post-placement checkpoint and create a
custom timing report, which provides a detailed timing report for the single worst timing
path in the design.
 Add physical synthesis and routing commands to your Tcl script: 3.
phys_opt_design
route_design
write_checkpoint -force post_route.dcp
report_timing_summary -file timing_summary
After routing completes, your script writes a post-routing design checkpoint and creates a
timing summary report.
 Finally, write out a bitstream by adding: 4.
write_bitstream -force sys_integration_top.bit
This is the complete Non-Project Mode design flow for implementing a design from RTL
source files, including designing with IP, through bitstream generation.

Send Feedback

## Page 79

Step 8: Running the Script
Designing with IP www.xilinx.com  79
UG939 (v2014.1) April 2, 2014
Step 8: Running the Script
You are now ready to run the Tcl script. Your script should be similar to the following:
#Step 1: Reading RTL
cd C:/Data/ug939-design-files/lab_5
create_project -in_memory -part xc7k70t-fbg484-3
read_verilog [glob ./sources/HDL/*.v]

#Step 2: Adding Existing IP
read_ip ./sources/IP/char_fifo/char_fifo.xci
file mkdir IP/blk_mem
file mkdir IP/clk_wiz
file mkdir IP/accum
file copy -force ./sources/IP/blk_mem/blk_mem_gen_v7_3_0.xci ./IP/blk_mem
file copy -force ./sources/IP/clk_wiz/clk_wiz_0.xci ./IP/clk_wiz
file copy -force ./sources/IP/Accumulator/Accumulator.xco ./IP/accum
read_ip ./IP/blk_mem/blk_mem_gen_v7_3_0.xci
read_ip ./IP/clk_wiz/clk_wiz_0.xci
read_ip ./IP/accum/Accumulator.xco

#Step 3: Disable DCP and XDC
set_property generate_synth_checkpoint false [get_files clk_wiz_0.xci]
generate_target all [get_ips clk_wiz_0]
set clk_wiz_xdc [get_files -of_objects [get_files \
   clk_wiz_0.xci] -filter {FILE_TYPE == XDC}]
set_property is_enabled false [get_files $clk_wiz_xdc]

#Step 4: Upgrade IP
set locked [get_property IS_LOCKED [get_ips blk_mem_gen_v7_3_0]]
set upgrade [get_property UPGRADE_VERSIONS [get_ips blk_mem_gen_v7_3_0]]
if {$upgrade != "" && $locked} {
  upgrade_ip [get_ips blk_mem_gen_v7_3_0]}
generate_target all [get_ips blk_mem_gen_v7_3_0]

set locked [get_property IS_LOCKED [get_ips Accumulator]]
set upgrade [get_property UPGRADE_VERSIONS [get_ips Accumulator]]
if {$upgrade != "" && $locked} {
  upgrade_ip [get_ips Accumulator]}
generate_target all [get_ips Accumulator]

#Step 5: Creating DCP for IP
synth_ip [get_ips Accumulator]
synth_ip [get_ips blk_mem_gen_v7_3_0]

#Step 6: Running Synthesis
read_xdc ./sources/Constraints/top_timing.xdc
synth_design -top sys_integration_top
write_checkpoint -force post_synth.dcp
report_timing_summary -file timing_syn.rpt

#Step 7: Running Implementation
read_xdc ./sources/Constraints/top_physical.xdc
opt_design
place_design
write_checkpoint -force post_place.dcp
Send Feedback

## Page 80

Step 8: Running the Script
Designing with IP www.xilinx.com  80
UG939 (v2014.1) April 2, 2014
report_timing -file timing_place.rpt
phys_opt_design
route_design
write_checkpoint -force post_route.dcp
report_timing_summary -file timing_summary
write_bitstream -force sys_integration_top.bit
Sourcing the Tcl Script
You can run the nonproject_run.tcl script in Vivado Design Suite batch mode or Tcl mode.
 Batch mode will run the sourced script, and then automatically exit the tool after the script
has finished processing.
 Tcl mode will run the sourced script, and return to the Tcl command prompt when finished.
On Linux,
 Change to the directory where the lab materials are stored: 1.
cd <Extract_Dir>/lab_5
 Launch the Vivado Design Suite Tcl shell, and source a Tcl script to create the tutorial design:  2.
vivado -mode tcl -source nonproject_run.tcl
On Windows,
 Launch the Vivado Design Suite Tcl shell: 1.
Start > All Programs > Xilinx Design Tools > Vivado 2014.x >
Vivado 2014.x Tcl Shell7
 In the Tcl shell, change to the directory where the lab materials are stored: 2.
Vivado% cd <Extract_Dir>/lab_5
 Source the Tcl script to create the design: 3.
Vivado% source nonproject_run.tcl
After the sourced script has completed, the Tcl shell displays the Vivado% prompt.

IMPORTANT: If your Tcl script has an error in it, the script will halt execution at the
point of the error. You will need to fix the error, and re-source the Tcl script as
needed. If you are running in Tcl mode, you may need to close the current project
with close_project, or exit the Vivado tool with exit to source the Tcl script again.


7 Your Vivado Design Suite installation may called something different than Xilinx Design Tools
on the Start menu.
Send Feedback

## Page 81

Conclusion
Designing with IP www.xilinx.com  81
UG939 (v2014.1) April 2, 2014


Figure 57: Vivado Tcl Mode and Sourced Tcl Script
Running the script results in the creation of a directory called “IP”. Output products for the
various IPs used in the design are written to this directory. Reports, design checkpoints, and a
bitstream for the design are also written to disk.
You can open the design in the Vivado IDE to perform further analysis. To open the Vivado IDE
from the Tcl prompt type start_gui.
Conclusion
Using the Non-Project Mode gives you the greatest control over the Vivado Design Suite, and
gives you access to advanced features that may not be available in Project Mode. However,
Non-Project Mode also requires manually managing source files, updating the design when
source files have changed, and manually planning and running synthesis and implementation
strategies. Specific areas covered in this lab are:
 Reading in Verilog source files and reading IP sources.
 Generating required IP output products for synthesis and implementation, and disabling
them as needed.
 Querying an IP’s upgradability, and updating to a newer version when appropriate.
 Creating Synthesis Design Checkpoints for IP.
 Manually running synthesis and individual steps of implementation.
 Generating custom reports
Send Feedback
