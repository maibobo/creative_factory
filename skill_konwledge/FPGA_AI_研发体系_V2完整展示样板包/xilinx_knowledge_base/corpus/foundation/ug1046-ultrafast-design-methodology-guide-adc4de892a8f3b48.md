# ug1046-ultrafast-design-methodology-guide

- Category: `foundation`
- Source: `F:\Xiliinx文档\ug1046-ultrafast-design-methodology-guide.pdf`
- SHA-256: `adc4de892a8f3b48a8723452551580a30bdb5f2a1556f5090359a4cca74b6a79`
- Extractor: `pypdf:233pages`
- Tags: `methodology, vivado`
- Duplicate sources:
  - none

## Page 1

UltraFast Embedded
Design Methodology
Guide

UG1046 (v2.3) April 20, 2018

## Page 2

UltraFast Embedded Design Methodology Guide 2
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Revision History
The following table shows the rev ision history fo r this documen t.
Date Version Revision
04/20/2018 2.3 • Added a note  in the Overvie w section of Chapter 5.
• Replaced BFM terminology with VIP across the user guide.
07/27/2017 2.2 • Vivado IDE updates and minor editorial changes.
04/22/2015 2.1 • Added Embedded Design Methodology Checklist .
• Added Accessing Documentation and Training .
03/26/2015 2.0 • Added SDSoC Environment .
• Added Related Design Hubs .
10/20/2014 1.1 • Removed outdated information.
•I n  System Level Considerations, added information to t he foll owing sections:
° Performance
° Clocking and Reset
10/08/2014 1.0 Initial Release of document.
Send Feedback

## Page 3

UltraFast Embedded Design Methodology Guide 3
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Table of Contents
Chapter 1: Introduction
Embedded Design Methodology Checklist. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  9
Accessing Documentation and Training . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  10
Chapter 2: System Level Considerations
Performance. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  13
Power Consumption  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  18
Clocking and Reset . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  36
Interrupts . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  41
Embedded Device Security  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  45
Profiling and Partitioning  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  51
Chapter 3: Hardware Design Considerations
Configuration and Boot Devices . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  63
Memory Interfaces  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  69
Peripherals . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  76
Designing IP Blocks  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  94
Hardware Performance Considerations . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  1 0 2
Dataflow . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  108
PL Clocking Methodology  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  112
ACP and Cache Coherency. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  116
PL High-Performance Port Access . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  120
System Management Hardware Assistance. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  12 4
Managing Hardware Reconfiguration  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  127
GPs and Direct PL Access from APU . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  133
Chapter 4: Software Design Considerations
Processor Configuration  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  137
OS and RTOS Choices . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  142
Libraries and Middleware . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  152
Boot Loaders  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  156
Software Development Tools . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  162
Send Feedback

## Page 4

UltraFast Embedded Design Methodology Guide 4
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 5: Hardware Design Flow
Overview  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  171
Using the Vivado IDE to Build IP Subsystems. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  1 7 1
Rule-Based Connection . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  173
Creating Hierarchical IP Subsystems. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  173
Board Window . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  173
Generating Block Designs  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  174
Creating and Packaging IP for Reuse  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  174
Creating Custom Interfaces . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  176
Managing Custom IP  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  176
Vivado High-Level Synthesis (HLS)  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  177
Summary. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  178
Chapter 6: Software Design Flow
Board Bring-Up Development . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  181
Driver Development  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  184
Application Developer . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  192
Xilinx SDK Tools and Packages  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  197
Xilinx Software Development Tools . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  201
Chapter 7: Debug
Overview  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  203
Software-Only Debug  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  204
Simulation-Based Debug . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  209
Board Debug. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  210
Hardware and Software Co-Debug . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  211
Virtual Platforms  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  212
Chapter 8: SDSoC Environment
Introduction . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  215
Overall Usage Flow  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  216
Profiling  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  219
Performance Estimation  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  220
Generating and Running a Complete Software-Hardware System  . . . . . . . . . . . . . . . . . . . . . . . .  220
Optimizing Performance Using C-Callable RTL IP Library  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  220
Optimizing IP Performance Using HLS  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  221
Optimizing System Performance  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  221
Debugging the System . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  223
Performance Measurement and Analysis  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  224
Expert Use Models . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  224
Send Feedback

## Page 5

UltraFast Embedded Design Methodology Guide 5
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Appendix A: Additional Resources and Legal Notices
Xilinx Resources . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  226
Solution Centers. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  226
Documentation Navigator and Design Hubs  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  2 26
Xilinx Documentation Navigator. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  227
References  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  227
Training Resources. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  232
Please Read: Important Legal Notices  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  233
Send Feedback

## Page 6

UltraFast Embedded Design Methodology Guide 6
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 1
Introduction
With the introduction of an All Programmable SoC product, Xilin x provides designers a
powerful way to build smarter systems quickly, effectively, and  reliably. Smarter systems are
typically associated with increa sed complexity. This is both a benefit and a challenge. It is a
benefit because customers can cr eate products that were previou sly impossible or
incredibly difficult to build. It  is a challenge because produc t complexity increases the
importance of making good design decisions, particularly early in the product life cycle. The
interplay of system software, a pplications, and hardware requir es new ways of thinking
about and solving system level p roblems. Xilinx has addressed t he challenge by providing
customers with a comprehensive t ool box, including software too ls, user guides, reference
manuals and reference designs, to  help accelerate product devel opment with All
Programmable SoCs.
A typical embedded development team consists of system architec ts, software engineers,
and hardware engineers. Each team  member often starts a design with familiar tools, and
this approach has typi cally worked for embedded development pro jects in the past.
However, the broad capabilities of the All Programmable SoC can  cause problems for a
development team that does not c onsider the development approac h up front. To make
teams more effective, Xilinx has created this met hodology guide  for embedded system
developers. This guide complements the UltraFast Design Methodology Guide for the Vivado
Design Suite  (UG949) [Ref 16], targeted primarily at FPGA designers.
The term methodology  can mean different things to different people. Flow charts, me thods,
principles, rules, and policies are among several possible them es. This methodology guide
does not illustrate a step-by-ste p process for success. Instead , the goal is to equip
designers with information and guidance on designing embedded s ystems so that they can
make informed decisions when usi ng the tool box. Some content a pplies generally to
embedded systems, while other co ntent is specific to the Xilinx ® All-Programmable SoC
products. The content is a refle ction of user experiences and l earning gained from system
development inside and outside o f Xilinx. The content covers ke y principles, specific do's
and don'ts, best practices, and avoiding pitfalls. In some topi cs, use cases are provided to
illustrate concepts.
Send Feedback

## Page 7

UltraFast Embedded Design Methodology Guide 7
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 1: Introduction
This guide is organized around i mportant functional areas that map to specific skill sets
within development teams. The sections are:
• System Level Considerations
• Hardware Design Considerations
• Software Design Considerations
• Hardware Design Flow
• Software Design Flow
• Debug
• SDSoC Environment
A typical mapping of chapter relevance to team members is shown  in Table 1-1. However, it
is recommended that the entire team read the complete methodolo gy guide before
beginning development. It is bene ficial to understand the chall enges described and
guidance provided in other chapters, even if the content is out side the engineer's direct
area of responsibility. The line between software engineers and  hardware engineers is
continuing to blur, and engineer s should reach beyond their pri mary responsibilities to
effectively work with the entire  team. For example, a software engineer needs to understand
how the underlying hardware work s, while a hardware engineer sh ould understand the
software implications of hardwa re decisions that are made.
Typically, embedded design is don e in the order listed in this guide–starting with
system-level design and ending w ith test and debug. The chapter s are written such that
they can be read in any particul ar order. This is demonstrated in Figure  1-1, showing the
interdependencies between the chapters in this guide.
Table 1-1:  Chapters Relevant to Design Team Members
Book Chapters System
Architects
Hardware
Designers
Software
Designers
System Level Considerations XXX
Hardware Design Considerations XX
Software Design Considerations XX
Hardware Design Flow X
Software Design Flow X
Debug XX
SDSoC Environment X
Send Feedback

## Page 8

UltraFast Embedded Design Methodology Guide 8
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 1: Introduction
Note: SDSoC Environment  is not shown in Figure 1-1  because it is a tool that aids the user in
building a system using all of the principles and methodologies  described in Chapters 2-7.
Additionally, Chapter 8  describes recommendations s pecific to the SDSoC flow.
After reading this guide, designers will be able to navigate th e various tools and collateral
provided by Xilinx in a more info rmed and effective manner. The  key takeaways in each
topic area should enable a desig ner to read the All-Programmabl e SoC detailed
documentation with greater understanding.
Users who are familiar with the Zynq-7000 All Programmable SoC Technical Reference
Manual  (UG585) [Ref 4] and the Zynq-7000 All Programmable SoC Software Developers
Guide  (UG821) [Ref 7] will benefit from readi ng this guide first.
Readers unfamiliar with the Zynq®-7000 AP SoC architecture shou ld refer to the Zynq-7000
All Programmable SoC Overview  (DS190) [Ref 31] for more information. Overall, this guide
enables an Embedded Design team to quickly assess trade-offs an d avoid bottlenecks and
problems, thereby enabling the team to make the right decisions  for successful embedded
system development.
X-Ref Target - Figure 1-1
Figure 1-1:  Interdependence of Methodology Guide Chapters
System Level
Considerations
Debug
Hardware Design
Consideration
Software Design
Consideration
Vivado Design
Suite Hardware
Design Flow
Software Design
Flow Overview
X14202-
073117
Send Feedback

## Page 9

UltraFast Embedded Design Methodology Guide 9
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 1: Introduction
Embedded Design Methodology Checklist
To take full advantage of the UltraFast Embedded Design Methodo logy, Xilinx recommends
that you use this guide along with the Embedded Design Methodol ogy Checklist. The
checklist includes common questi ons and recommended actions to consider during the
design process, starting with pl anning and continuing through a ll subsequent stages of
design. The checklist questions highlight typical areas in whic h design decisions are likely to
have downstream ramifications an d draw attention to issues that  are often unknown or
ignored.
Xilinx recommends readin g the guide first before proceeding to the checklist. Most links
provide cross references to this  guide and links to other Xilin x documentation. These
references offer guidance on addr essing the design concerns rai sed by the questions.
The checklist is part of the Xilinx Documentation Navigator, a free tool that you can use to
access documentation while using  Xilinx products. You can downl oad Documentation
Navigator as a standalone product or as part of your SDK or Viv ado installation (see Using
the Documentation Navigator ).
To access the checklist feature, use Documentation Navigator ve rsion 2015.1 or later. From
within Documentation Navigator, use these steps to begin using the Design Methodology
Checklist:
1. Click the Design Hub View  tab.
2. At the top of the menu on the left side, click Create Design Checklist .
3. Fill out the information in th e New Design Checklist Dialog a nd click OK.
4. The new checklist opens. Tabs across the top of the checklist  (see Figure 1-2 ) provide
navigation. The Title Page tab provides some basic information on using the checklist.
Click the other tabs to see the checklist questions and guidanc e.
A spreadsheet version of the Desi gn Methodology Checklist is al so available in the
following zip file:
xtp397-embedded-design-methodology-checklist.zip
X-Ref Target - Figure 1-2
Figure 1-2:  Embedded Design Methodology Check list Tabs in Documentation Nav igator
Send Feedback

## Page 10

UltraFast Embedded Design Methodology Guide 10
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 1: Introduction
Accessing Documentation and Training
Access to the right information at the right time is critical f or timely design closure and
overall design success. Reference guides, user guides, tutorial s, and videos get you up to
speed as quickly as possible wi th Xilinx tools. This section li sts some of the sources for
documentation and training.
Using the Documentation Navigator
The Xilinx embedded tools ship w ith the Xilinx Documentation Na vigator, which provides an
environment to access and manage  the entire set of Xilinx softw are and hardware
documentation, training, and sup port materials. Documentation N avigator allows you to
view current and past Xilinx doc umentation. The documentation d isplay can be filtered
based on release, document type,  or design task. When coupled w ith a search capability,
you can quickly find the right information.
Documentation Navigator scans th e Xilinx website to detect and provide documentation
updates. The Update Ca talog feature alerts you to available upd ates, and gives details
about the documents that are inv olved. Xilinx recommends that y ou always update the
catalog when alerted to keep it current. You can establish and manage local documentation
catalogs with specified documents.
The Documentation Navigator has a tab called the Design Hub View . Design hubs are
collections of documentation rela ted by design activity, such a s Zynq-7000 Design
Overview, PetaLinux Tools, and S DK. Documents and videos are or ganized in each hub in
order to simplify the learning c urve for that area. Each hub co ntains an Embedded
Processor Design section, a Desi gn Resources section, and a lis t of support resources. For
new users, the Embedded Processo r Design section provides a goo d place to start.
Send Feedback

## Page 11

UltraFast Embedded Design Methodology Guide 11
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 1: Introduction
Accessing the QuickTake Video Tutorials
Xilinx QuickTake video tutorials provide guidance on using the features of Xilinx tools,
including SDK, SDSoC, and PetaLinux Tools. These tutorials are short and succinct training
tools. They can be viewed from the Video Tutorials page on xilinx.com  or the Xilinx YouTube
channel and can be downloaded locally.
TIP: The QuickTake video tutorials are available through Documentation Navigator.
X-Ref Target - Figure 1-3
Figure 1-3:  Xilinx Documentation Navigator, Catalog Viewer
Send Feedback

## Page 12

UltraFast Embedded Design Methodology Guide 12
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2
System Level Considerations
This chapter covers the following  system-level design issues to  be considered when
designing with a Zynq ®-7000 AP SoC:
• Performance : The target application generally  determines the overall syste m
performance. System performance objectives are a llocated betwee n hardware and
software, and further allo cated to sub-components.
• Power Consumption : System performance is a primary driver of power consumption.
The design team is often faced with difficult trade-off choices  to make between the two
issues. This section describes d esign considerations for optimi zing power consumption
on a Zynq-7000 AP SoC.
• Clocking and Reset : It is important to understand what clocking resources are ava ilable
so that you can plan how to best  use those resources. Similarly , the reset system has
many different sources and it is  important that you understand how they affect the
different reset destinations.
• Interrupts : The system-level interrupt env ironment provides a comprehensi ve set of
capabilities for you to prioritize hardware and software resour ces in your application.
• Embedded Device Security : The security level required fr om application to application
can vary greatly. Understanding the various security features o f the Zynq-7000 AP SoC
will help you implement the righ t level of security for your ap plication.
• Profiling and Partitioning : An important system-level decision you make is how to
partition the functions of an ap plication between hardware and software. Profiling
tools help in making those decisions.
Send Feedback

## Page 13

UltraFast Embedded Design Methodology Guide 13
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Performance
With a Zynq-7000 AP SoC device, system performance depends on t he final application
goals. For example, a real-time application's system performanc e might depend on the
interrupt service routine laten cy, while a video  application's system performance might
depend on maintaining 60 frames per second over an off-chip int erface. In this section, the
division of performance goals across different design team memb ers is described, followed
by considerations for implementing those performance goals thro ugh data movement and
computation design choices. The section concludes with a discus sion of Zynq-7000 AP SoC
device monitoring opti ons, allowing designers to build custom p erformance monitoring
capabilities in software and  programmable logic (PL).
System Performance Design Goals
System performance goals are divided across the different engin eering disciplines on a
Zynq-7000 AP SoC device design t eam. The three engineering disc iplines discussed in this
document are hardware, software, and system.
Hardware Engineer
Hardware engineers working with Zynq devices implement designs using a mixture of PL
components, AXI-connected IP, high speed off-chip interfaces, a nd custom logic. PL choices
are driven by performance requir ements, such as throughput and latency, but can also be
driven by the performance constr aints of system software and ha rdware interactions.
Hardware engineers must consider  interactions with the processi ng system (PS), because
data movement and synchronization can have a large effect on PL  throughput and latencies.
PL data movement and m onitoring points can b e used to guide des ign decisions and are
discussed later in this section.  Traditional PL metrics, such a s maximum frequency and
resource utilization, ar e not covered. See the UltraFast Design Methodology Guide for the
Vivado Design Suite  (UG949) [Ref 16] for more information.
Software Engineer
Software engineers focus on system software running within the PS and its interaction with
memory, I/O, and PL. For example , user software that communicat es with PL has multiple
communication options, each with advantages and d isadvantages. The software
performance monitoring capabiliti es unique to Zynq devices can be used by software
engineers to tune performance and are described later in this s ection. Also, the rich
ecosystem of existing ARM perfo rmance profiling and monitoring tools can be used with
the dual-core Cortex-A9 processo rs for optimizing performance. For more information on
the performance monitoring capab ilities, see the ARM DS-5 Devel opment Studio
Streamline Performance Analyzer documentation [Ref 74].
Send Feedback

## Page 14

UltraFast Embedded Design Methodology Guide 14
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
System Engineer
Performance goals for designs im plemented using Zynq devices ca n be partitioned across
hardware and software.  This partitioning should be considered t hroughout all design
stages. During the initial stage s, hardware and software engine ers can work relatively
independently, but early performance estimates are needed to se t realistic performance
goals and make initial partition  choices. The system engineer m ust consider all hardware
and software performance bottlenecks and make trade-offs. The s ystem architect can make
early performance estimates of d ata and communication paths, an d fine tune them later
using the system performance-m onitoring points and tools.
All design team members generally consider the impact on perfor mance of data movement
and data computation. The ability to monitor system events is u seful in designing and
optimizing performance of a Zynq device. These considerations a re described in the
following sections, including su ggested design me thodologies to  help guide Zynq device
design flows.
System Data Movement
Moving data through a system is a common system-level performan ce problem. A Zynq
device has several AXI masters t hat can drive tr ansactions eith er directly or with assistance
from DMAs. This section describe s the various options and trade -offs for addressing data
movement in a Zynq device.
The ARM CPUs can move data using direct memory transfers, such as memcpy. Such
transfers are useful for small tr ansfers of 4 KB or less, while  larger transfers benefit from
DMA assistance. The data's sourc e and destination buffer locati ons should also be
considered. For example, a PS DM A data transfer to PL will typi cally go through the 32-bit
master GP ports. The Zynq-7000 All Programmable So C Technical Reference Manual  (UG585)
[Ref 4] contains techniques for using the PS DMA controller. The PS DM A controller runs its
own microcode. An alternative me thod would use a DMA in PL to m ove data across the
64-bit ACP or HP ports, which is  a higher-performing option and  uses PL resources.
Other AXI masters within the PS should be considered when deter mining system data
movement performance. IOP DMAs ex ist in several IP blocks: the GigE controller, SDIO
controller, USB controller, and device configuration interface (DevC). The IP block functions
are described in the Zynq-7000 All Programmable SoC Technical Reference Manual  (UG585)
[Ref 4], and drivers are provided for t heir use in operating systems s uch as Linux and
stand-alone designs. The GigE controller performance characteri stics are further described
in PS and PL Ethernet Performance and Jumbo Frame Support with PL  Ethernet in the
Zynq-7000 AP SoC  (XAPP1082) [Ref 40]. The remaining cores have driver layers that provide
additional function, but their pe rformance characteristics are not described here.
Send Feedback

## Page 15

UltraFast Embedded Design Methodology Guide 15
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
From the PL, AXI masters can drive data movement on the ACP, HP , or slave GP ports. These
ports and associated performance  are described further in the f ollowing sections:
• ACP and Cache Coherency
• PL High-Performance Port Access
• GPs and Direct PL Access from APU
DMAs attached to these ports are  best used to translate between  AXI4 Memory-Mapped
and AXI4-Streaming interfaces, p roviding a clean separation of memory-mapped accesses
to data-centric processing (such  as video pipelines). DMA is no t always the preferred
method, however. If the streamin g interface performance is low and not a concern, then the
AXI4-Stream FIFO core is a simpl e way to source and synchronize  an AXI-Stream interface
from a processor. User applications can have custom AXI masters  that do direct data
movement using standard AXI Memory-Mapped transactions. The thr oughput and latency
performance characteristics of such custom data transfers may e nd up being very similar to
standard PL DMA data transfers. Performance comparisons can be made using the counters
and timers described in System Monitoring .
DMA moves data from a source to a destination location. Memory is often used as data
buffers to match the differences in rate of data source, proces sing, or data sink, therefore
ensuring that the processing sta ge can achieve maximum throughp ut.
Off-chip data buffer location can  be implemented using off-chip  memory attached to
customizable MIO or EMIO pins. T he memory characteristics affec t the performance of
moving large buffers, such as file systems on SD cards or netwo rk-attached storage over the
GigE controller.
For on-chip buffering, the OCM, L2 cache, and DDR controller ar e the three main sources of
sharable buffer space within the PS. The L2 cache and DDR contr oller provide excellent
buffer-access latency for sharing  data between the processor an d ACP port. Only the ACP
can access the L2 cache from PL. For high-bandwidth accesses to  DDR, the HP ports are
better suited than ACP. The OCM can be used by software applica tions as a 256 KB
scratchpad accessible by all mast ers in the PL. A benefit to us ing OCM is its excellent
random-access latency, whereas the L2 cache and DDR memory bene fit from
memory-access locality.
System Computation
Computation can be don e in either the ARM cores or within the P L. Typical Zynq devices
have the control plane written i n software executing on the ARM  cores. Data-centric
computation is done in the PL us ing a mix of existing and custo m IP. In high-performance
situations such as line-rate pac ket processing, computation and  control can be moved
closer to the data. This typical ly requires custom PL IP to man age data flow.
Send Feedback

## Page 16

UltraFast Embedded Design Methodology Guide 16
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Moving computations from softwar e into the PL is an important b enefit of the Zynq-7000
AP SoC platform. Not all software can be moved to the PL, in pa rticular pre-compiled code,
complex library routines, and OS services. If it is possible to  move software components to
PL, performance metrics such as the full application runtime sh ould consider the trade-off
between data movement costs and acceleration benefits. This cos t and benefit analysis can
be done using software profiling  tools to determine potential s peedups according to
Amdahl's law:
In the equation above, S is the overall performance improvement and α is the percentage of
the algorithm that can be sped u p with hardware acceleration. T herefore 1- α is the
percentage of the algorithm that cannot be improved. The variab le p is the speedup due to
acceleration. For example, to a ccelerate a computational algori thm implemented entirely in
software, you can use profiling t ools such as TCF profiler to h elp identify the particular
function that is frequently used . The percentage of time with w hich this function is used
corresponds to a high α number. The function can then be  sped up by implementing it in
hardware. The speed up of the function maps to p. Dividing a frequently used function by a
large multiplier will result in the most improvement in perform ance in the computation of
the algorithm due to hardware acceleration.
The speed up of a particular function has two components: the t ransfer of data to and from
the acceleration block and the a ctual computation performed by the accelerator. When a
DMA is used to perform the data transfer, the overhead for sett ing up and managing the
DMA must be taken into account when measuring the multiplier fa ctor, p. If the overhead is
large, it can bound the value of p and may result in a low p factor, and therefore low
improvement in performance. For more information, see the Profiling and Partitioning
section.
High-level synthesis provides an excellent way of moving softwa re components to PL for
exploring acceleration options. If candidate software is not a good fit for high-level
synthesis, Xilinx also provides a rich library of programmable logic IP with corresponding
drivers which can replace functi ons implemented in software to improve overall system
performance.
Send Feedback

## Page 17

UltraFast Embedded Design Methodology Guide 17
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
System Monitoring
A rich tool ecosystem exists for monitoring the ARM processors.  In a Zynq device, full
system-level performance monitoring also uses blocks available in the PS and PL. These are:
• SCU Global Timer (PS).  The SCU global timer can be used to timestamp system events
in a single clock doma in. Alternatively, operating systems ofte n provide high accuracy
timers for software event tracin g, such as Linux clock_nanoslee p.
• ARM Performance Monitoring Units (PS).  Each ARM core has a performance
monitoring unit (PMU) that is us ed to count micro-architectural  events. These counters
can be accessed directly by softwa re, through operating system utilities, or with chip
debuggers such as Linux Perf or ARM Streamline. The counters ar e viewable in the
Performance View of SDK 2014.2. S ee the Performance Monitoring Unit section in the
ARM Cortex-A9 Technical Reference Manual  [Ref 77]  for more information.
• L2 Cache Event Counters (PS).  The L2 cache has event co unters that can be accessed
to measure cache performance. The counters are viewable in the Performance Counters
View of SDK. See the Zynq-7000 All Programmable So C Technical Reference Manual
(UG585) [Ref 4]  for more information.
• GigE Controller (PS).  The gigabit Ethernet controller has statistical counters to tr ack
bytes received and transmitt ed on its interface. See the Zynq-7000 All Programmable
SoC Technical Reference Manual  (UG585) [Ref 4]  for more information.
• AXI Performance Monitor (PL).  This core can be added in PL to monitor AXI
performance metrics such as thro ughput and latency. Trace funct ions enable
time-stamped AXI traces, such as  time-stamped start and end of AXI transactions to
observe per-transaction latency.  See the AXI Performance Monito r web page [Ref 45]
for more information.
• AXI Timer (PL).  This core can be added in PL to provide a free-running timer i n PL. This
timer is useful for time-stampin g events in PL clock domains. S ee the AXI
Timer/Counter web page [Ref 46]  for more information.
• AXI Traffic Generator (PL).  This core can generate a vari ety of traffic patterns to the
PS interfaces. When used with an  AXI performance monitor, the t raffic generator can
help provide early system-level performance estimates. The core  can be used to
estimate data-movement costs and  validate design partition choi ces. For more
information, refer to t he LogiCORE™ AXI Traffic Generator web p age [Ref 47] .
These monitor blocks provide vis ibility into the full system pe rformance behavior. Event
counters and PL monitoring blocks  can be customized for specifi c design performance
goals or used to get a high-level view of system performance. E arly use of built-in
performance monitoring  allows performance f eedback throughout t he design cycle,
resulting in data-driven sys tem architecture decisions.
Send Feedback

## Page 18

UltraFast Embedded Design Methodology Guide 18
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
There are different ways of exerc ising or acquiring monitoring data from the various blocks.
Most peripherals come with an ex ample application packaged with  the corresponding
bare-metal driver shipped with Xilinx SDK. A list of available Linux drivers is provided in the
Xilinx Linux Drivers wiki page [Ref 52].
Xilinx SDK provides built-in Sy stem Performance Modeling and An alysis functionality.
Performance monitors gather data  from the system, either live d ata or data created by
traffic generators which are use d to model real world transacti ons. This data is displayed
using the Xilinx SDK vi sualization tools with statistics for nu mber of transactions,
bandwidth, and latency from an A PM (profile mode) connected to the HP and ACP ports.
For more information, refer to Xilinx SDK System Debugger .
Power Consumption
The power consumption of Zynq-70 00 AP SoCs is an important cons ideration for system
architects and board designers. Power consumption is a critical  concern for most
applications, and some applicati ons specify maximum power per c ard or per system. Thus,
designers must consider power co nsumption early in the design p rocess, often starting with
device selection.
Reducing SoC power consumption can improve board design by lowe ring supply-rail
power, simplifying power supply design and thermal management, and easing the
requirements on the power distri bution planes. Low power also c ontributes to longer
battery life and high er reliability, becau se cooler-running sys tems last longer.
Reducing system power consumptio n requires a comprehensive and focused approach to
achieve optimal results. This se ction covers several aspects of  Zynq-7000 AP SoC power
consumption, including PS and PL  architecture and features, the  power components
associated with PL, and the process technology. It also covers power dissipation, and
traditional methods of estim ating and measuring power.
Power Challenges
According to Moore's Law, transis tor size decreases with each p rocess technology
generation. As size decreases the amount of current each transi stor leaks increases, causing
an increase in static power cons umption, which is the amount of  current the device draws
when not switching. Increasing S oC performance requires higher- frequency clocks,
resulting in increased dynamic p ower consumption. Thus, static power is driven by
transistor leakage current and d ynamic power is driven by the t ransistor switching
frequency. Compounding the proble m, decreasing transistor sizes  allow more transistors to
be packed on FPGAs with each product generation. More transisto rs results in more leakage
current and more transistors swi tching at higher clock frequenc ies on each FPGA device.
Send Feedback

## Page 19

UltraFast Embedded Design Methodology Guide 19
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
These issues require designers t o address power supply and ther mal-management issues
earlier in the design cycle. Using a heat sink on a device may not adequately resolve these
issues. Instead, designers must look for opportunities to reduc e the impact of the design
logic.
Figure  2-1 illustrates actions that can be taken at various points in the  design cycle to
reduce power consumption. Addressing power issues early in the design process yields the
greatest benefits.
Power and Signaling
Zynq-7000 AP SoC devices  are divided into se veral power domains , as illustrated in
Figure  2-2.
X-Ref Target - Figure 2-1
Figure 2-1:  Managing Power Issues Throughout the Design Cycle
X-Ref Target - Figure 2-2
Figure 2-2:  Zynq-7000 AP SoC Power Domains
Use of Hard IP, Proper
use of control signals
Reducing Clock and Block
Activity, Partial
Reconfiguration
Intelligent Clock-Gating
Options
XPE, PlanAhead,
Power Estimator, XPA
Unified Architecture,
Stacked-Silicon
Interconnect
28-nm HPL
SW
SW Power
Optimization
Power Estimation Tools
Architecture
Process
HW
Static Power
Dynamic Power
Low-
Power
Design
Techniques
X14194-073117
X14195-073117
Programmable Logic
VCCINT
VCCAUX
VCCO0 VCCO1 VCCOn
Processing System (PS)
VCCPINT
VCCPAUX
VCCPLL
VCCO_MIO0 VCCO_DDR VCCO_MIO1
Send Feedback

## Page 20

UltraFast Embedded Design Methodology Guide 20
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
The PS and PL power supplies are independent; however, the PS p ower supply must be
present when the PL power supply is active. The PL can be power ed off in applications that
do not require the PL. The PS and PL power pins are summarized in Table 2-1. The voltage
sequencing and electrical specifications are described in Zynq-7000 All Programmable SoC
(Z-7010, Z-7015, and Z-7020): DC an d AC Switching Characteristics  (DS187) [Ref 30].
PS Power Domains
For more information on Zynq-7000 AP SoC PS power domains, refe r to Chapter 5:
Processing System (PS) Power and signaling of Zynq-7000 All Programmable SoC PCB
Design Guide  (UG933) [Ref 14].
PL Power Domains
Multiple power supplies are required to power the different PL resources in a Zynq-7000 AP
SoC. The different resources ope rate at different voltage level s for increased performance
or signal streng th while preserving impr oved immunity to noise and parasitic effects.
PL Power Sources  lists the power sources typical ly used by PL resources availab le in
Zynq-7000 AP SoC. This table is pr ovided only as a guide becaus e the specifics can vary
across Zynq-7000 AP SoC families.
Table 2-1:  Power Pins
Type Pin Name Nominal Voltage Power Pin Description
PS Power VCCPINT 1.0V Internal logic
VCCPAUX 1.8V I/O buffer pre-driver
VCCO_DDR 1.2V to 1.8V DDR memory interface
VCCO_MIO0 1.8V to 3.3V MIO bank 0, pins 0:15
VCCO_MIO1 1.8V to 3.3V MIO bank 1, pins 16:53
VCCPLL 1.8V Three PLL clocks, analog
PL Power VCCINT 1.0V Internal core logic
VCCAUX 1.8V I/O buffer pre-driver
VCCO_# 1.8V to 3.3V I/O buffers drivers (per bank)
VCC_BATT 1.5V PL decryption key memory backup
VCCBRAM 1.0V PL block RAM
VCCAUX_IO_G# 1.8V to 2.0V PL auxiliary I/O circuits
XADC VCCADC 1.8V Analog power and ground.
Ground GND Ground Digital and analog grounds
Send Feedback

## Page 21

UltraFast Embedded Design Methodology Guide 21
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Board-Level Power-Distribution System
On a printed circuit board, the power distribution system (PDS)  distributes power from the
source to the various chips and devices requiring power. Althou gh the PDS design can vary
from simple to complex, there are three primary requirements it  must satisfy:
• The PDS must deliver a well-regu lated voltage. Power regulatio n is done at the
regulated power-supply circuit, s upported by one or more bulk c apacitors and LC
filtering circuits.
• The PDS must be stable at all points on the board under all cu rrent loading conditions.
Stability under all loading condit ions has two sub-requirements :
° The distribution system must hav e low resistance and inductance . This usually
requires a system of power and r eturn planes for distribution, and low inductance
pads and vias at the var ious device connections.
° The charge must be available whe re and when needed. The require d charge is
typically stored in bypass capaci tors that are placed around th e board, and to a
lesser extent from distributed planar capacitance.
• The PDS must be quiet, meaning that when devices switch, noise  is not generated that
interferes with other devices or generates EMI.
Table 2-2:  PL Power Sources
Power Supply Resources Powered
VCCINT
and
VCCBRAM
• All CLB resources
• All routing resources
• Entire clock tree, including all clock buffers
•B l o c k  R A M / F I F O
• DSP slices
• All input buffers
• Logic elements in the IOB (ILOGIC/OLOGIC)
• ISERDES/OSERDES
• Tri-Mode Ethernet MAC
• Clock Managers (DCM, PLL, etc.)(minor)
• PCIE and PCS portion of MGTs
VCCAUX
and
VCCAUX_IO
• Clock Managers (MMCM, PLL, DCM, etc.)
• IODELAY/IDELAYCTRL
• All output buffers
• Differential Input buffers
•V REF-based, single-ended I/O standards, such as HSTL18_I
•P h a s e r
VCCO • All output buffers
• Some input buffers
• Digitally Controlled Impedance (DCI) circuits, also referred t o as On-Chip
Termination (OCT)
MGT • PMA circuits of transceivers
Send Feedback

## Page 22

UltraFast Embedded Design Methodology Guide 22
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
For more information on power di stribution systems for Zynq dev ices, refer to “Chapter 3:
Power Distribution System” in the Zynq-7000 All Programmable SoC PCB Design Guide
(UG933) [Ref 14].
Power Management
Using a Zynq-7000 AP SoC  can help reduce a system's static powe r consumption. The
Zynq-7000 AP SoC PS is an optimi zed silicon element consisting of dual-core ARM
Cortex-A9 CPUs plus integrated p eripherals. The PL is based on the Xilinx ® 7-Series
architecture built on the 28nm h igh-performance, low-power (HPL ) process, providing
high-performance operation while e nabling significant power red uction. Choosing a device
built on the HPL process eliminat es the need for complex and ex pensive
static-power-management schemes.
There are different ways to reduce system power. The following sections provide tips that
can be used to optimize a design  to meet system power requireme nts.
PS Power Management
This section describes the design considerations needed to opti mize power consumption of
a Zynq-7000 AP SoC PS. This includes power management of the AP U unit, PS peripherals,
clocks and PLLs, caches, SCU, and  OCM. It is assumed that the d esigner understands the
impact of power management tra de-offs on the overall system.
System Design Considerations
The PS components can be p ower managed as follows:
• Application Processing Unit (APU).  The Zynq-7000 AP SoC APU supports dynamic
clock gating. This feature can be enabled using the CP15 power control register. If
enabled, the clocks to several CPU internal blocks are dynamica lly disabled during idle
periods. The gated blocks are:
° Integer core
° System control block
° Data engine
By reducing the processor core voltages and operating frequency , as much as a two-fold
decrease in power consumption ca n be realized. Refer to the pow er-management
section of the Zynq-7000 All Programmable SoC Technical Reference Manual  (UG585)
[Ref 4]  for more information.
Send Feedback

## Page 23

UltraFast Embedded Design Methodology Guide 23
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
• PS Peripherals.  The PS supports several clock d omains, each with independent
clock-gating control. When the s ystem is in run mode, the user can shut down unused
clock domains to reduce dynamic power dissipation. Clocks for P S peripherals such as
timers, DMA, SPI, QSPI, SDIO, an d the DDR controller can be ind ependently gated to
save power. Refer to Chapter 25, Clocks, in the Zynq-7000 All Programmable SoC
Technical Reference Manual  (UG585) [Ref 4]  for more information on the system clocks
and how they can be controlled u sing dividers, gates, and multi plexers.
• Caches.  The L2 cache controlle r supports the following dynamic-power r eduction
features. These features are controlled by a corresponding enab le bit in the
l2cpl310.reg15_power_ctrl register.
° Dynamic Clock Gating.  When the dynamic high-level clock-gating feature is
enabled, the cache controller clock stops when the controller i s idle. The
clock-gating feature waits sever al cycles after the controller is idle before it stops
the clock.
° Standby Mode.  The L2 cache contro ller standby mode can be used with the
processor's wait-for-interrupt (WFI) mode that drives the L2 ca che controller. When
a processor is in WFI mode and s tandby mode is enabled, the L2 cache controller
internal clocks are stopped. Ref er to Chapter 3, Application Pr ocessing Unit, in the
Zynq-7000 All Programmable So C Technical Reference Manual  (UG585) [Ref 4]  for
more information on using WFI.
The dynamic clock gating feature  is a superset of the standby m ode. In standby mode,
clock gating is limited to WFI st ates, thus making L2 cache acc esses more predictable
under normal run conditions.
• On-Chip Memory (OCM).  In general, OCM can be used to reduce overall power during
low-power modes such as Linux standby mode. For example, OCM ca n be used to store
executable code when the DDR is in low power mode.
• Snoop Control Unit (SCU).  The SCU has a standby mode that is enabled by setting the
corresponding bit in the mpcore.SCU_CONTROL_REGISTER. When enab led, the internal
SCU clocks are stopped when the following conditions are met:
° The CPUs are in WFI mode.
° There are no pending requests on the ACP.
° There is no remaining activity in the SCU.
The SCU resumes normal operation  when a CPU leaves WFI mode or a request on the
ACP occurs.
Send Feedback

## Page 24

UltraFast Embedded Design Methodology Guide 24
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
• PLL. PLL power consumption is depende nt on the PLL output frequency , thus power
consumption can be reduced by using a lower PLL output frequenc y. Power can also be
reduced by powering down unused P LLs. For example, if all clock  generators can be
driven by the DDR PLL, then the A RM core and I/O PLLs can be di sabled to reduce
power consumption. The DDR PLL is  the only unit that can drive all of the clock
generators. Each clock can be in dividually disabled when not in  use. In some cases,
individual subsystems contain additional clock disable capabili ties and other power
management features.
• Physical Memory. Zynq-7000 AP SoCs support differe nt types of physical memory,
such as DDR2, DDR3, and LPDDR2. The supported DDR memory types can operate with
both 16-bit and 32-bit data. DDR power consumption can be a sig nificant component
of total power, so minimizing DDR power consumption is an impor tant way of reducing
system power. Items to consider when reducing DDR power consump tion include:
° The DDR controller operating speed.
° The choice of DDR width and wheth er ECC is enabled or disabled.
° The number of DDR chips used.
° The DDR type, such as using LPDDR  for significant voltage reduc tions.
° The use of different DDR modes d uring low power operation, such  as DDR
self-refresh mode. Refer to the appropriate DDR standards for m ore information
about power consumption during D DR low-power operating modes.
Refer to the “Clocks” chapter in the Zynq-7000 All Programmable SoC Technical
Reference Manual  (UG585) [Ref 4]  for more information on implementing DDR controller
clock gating.
• I/O. I/O devices such as MIOs and DDR IOs also contribute to overal l power. Refer to
the “SelectIO Signaling” chapter of the Zynq-7000 All Programmable SoC PCB Design
Guide  (UG933) [Ref 14]  for more information on I/O buffer control power management.
Software Support
The Linux kernel supports the following power management states :
• S0: Freeze or low-power idle. T his is a generic, pure software , light-weight, low-power
state.
• S1: Standby or power-on suspend . All processor caches are flus hed and instruction
execution stops. Power to the pr ocessor and RAM is maintained.
• S3: Suspend-to-RAM. System and device state is saved to memory . All devices are
suspended and powered off. RAM remains powered.
Refer to the Zynq Power Management wiki page [Ref 66] for more information about Linux
power management support  for Zynq-7000 AP SoCs.
Send Feedback

## Page 25

UltraFast Embedded Design Methodology Guide 25
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
The link also provides informati on about the CPU-scaling framew ork implemented for
Zynq-7000 AP SoCs. The CPU-scaling framework is used to scale C PU frequency at run time.
For applications that do not req uire high processing performanc e, the CPU frequency can
be reduced to meet application needs. A lower clock frequency c an significantly reduce the
operating power when compared to  operating at a higher frequenc y.
PL Power Management
The PL can be powered off in app lications that do not require t he PL. To do this,
independently-connected power supplies are needed for the PS an d PL. The PL supplies
that can be powered off include VCCINT, VCCAUX, VCCBRAM, and VC CO. Refer to the
appropriate data sheet to determ ine the correct power sequencin g.
The configuration is lost when t he PL is powered down and must be reconfigured when it
is powered on again. Software sh ould determine w hen it is safe to power down the PL.
This section describes design co nsiderations for optimizing PL power consumption on a
Zynq-7000 AP SoC.
Logic Resource Utilization
PL resource utilization is an impo rtant contributo r to the tota l power consumed by
Zynq-7000 AP SoCs. The amount of CLB resources, dedicated hardw are, and routing used is
design dependent and adds to both  static and dynamic power cons umed by the PL. A
thorough understanding of the PL architecture enables the desig ner to leverage silicon
resources.
To reduce power, designers must look for opportunities to reduc e the logic in a design. This
allows use of smaller devices an d reduces static power consumpt ion. One option is to use
dedicated hardware blocks rather  than implementing the function  in CLBs. This can help
lower both static and dynamic po wer consumption and make it eas ier to meet timing
requirements. Blocks lower static power consumption because the  total transistor count is
less than an equivalent comp onent built using CLB logic.
Designers can use the IP catalog  to customize th e dedicated har dware for instantiating a
specific resource. Unused PS IP can be re-purposed for other ta sks that may not be obvious.
For example, DSP48 slices have ma ny logic functions, such as mu ltipliers, adders and
accumulators, wide logic compara tors, shifters, pattern matcher s, and counters. Block RAMs
can be used as state machine s, math functions, and ROMs.
Most of the coding techniques needed are described in the UltraFast Design Methodology
Guide for the Vivado Design Suite  (UG949) [Ref 16].
Send Feedback

## Page 26

UltraFast Embedded Design Methodology Guide 26
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Managing Control Sets
Control signals (signals that co ntrol synchronous elements such  as a clock, set, reset, and
clock enable) can affect device density, utilization, and perfo rmance. Some guidelines
follow for keeping the power impa ct of these signals to a minim um.
Avoid using both a set and reset on a register or latch. The fl ip-flops in Xilinx FPGAs can
support both asynchronous and synchronous reset and set control s. However, the
underlying flip-flop can natively  implement only one set, reset , preset, or clear at a time.
Specifying more than one of these functions in the RTL code res ults in the implementation
of one condition using the SR port of the flip-flop and the oth er condition implemented in
the PL, thus using more PL resources.
If one of the conditions is sync hronous and the other is asynch ronous, the asynchronous
condition is the one implemented  using the SR port, and the syn chronous condition is
implemented in the PL. In general, avoid more than one set, res et, preset, or clear condition.
Also, only one attribute for each group of four flip-flops in a  slice determines whether the
SR ports of flip-flops are synchronous or asynchronous.
Use active-high control signals,  because the control ports on r egisters are active high.
Active-low signals use more look up tables because they require an inversion before they
drive the register control port.  The LUT may already have other  inputs such that the
inversion could requir e another LUT. Using a ctive-low control s ignals can lead to longer
implementation runtimes and result in poor device utilization, affecting timing and power.
Therefore, active-low resets in an FPGA design are not recommen ded.
Use active-high control signals where possible in the HDL code or instantiated components.
When it's impossible to specify control signal polarity within the design, invert the signal in
the top-level code hierarchy. Th e I/O logic can absorb the infe rred inverter without using
additional FPGA logic or routing , resulting in better utilizati on, performance, and power.
Managing Sets and Resets
Coding unnecessary sets and resets can prevent the inference of  shift-register LUTs (SRLs),
LUT RAMs, block RAMs, and other logic structures. Although codi ng can be awkward, many
circuits can be made to self-reset, or simply do not need a res et. For example, considering
flip-flops within a data pipelin e, there is little point in hav ing a reset at all. After a few cycles,
the entire pipeline is operation al, and any incorrect data is f lushed out of the system.
Reducing the use of sets and res ets improves device utilization , resulting in better
placement, improved performance, and reduced power.
Refer to the Get Smart about Reset: Think Local, Not Glo bal Whitepaper  (WP272) [Ref 34] for
more information on designing resets.
Send Feedback

## Page 27

UltraFast Embedded Design Methodology Guide 27
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Clock Gating
The PL dynamic power consumption is determined by the operating  clock frequency (fclk),
node capacitance (C), FPGA operating voltage (V), and the switc hing activity ( α ) on various
design nodes. The equation for dynamic power is:
Dynamic Power = α x fclk x C x V2 Equation 2-1
For most designs, some parameter s are determined either by the FPGA technology (for
example, operating voltage) or by design requirements (for exam ple, operating frequency).
Gating the clock or data paths is a common technique used to st op switching activity when
the results of those paths are n ot used. Clock gating stops all  synchronous activity,
preventing data path signals a nd glitches from propagating.
The Vivado ® tool analyzes the description and netlist to detect unwanted c onditions.
However, designer knowledge of the application, data flow, and dependencies are not
available to the tool, but should  be specified by the designer to further remove unwanted
conditions.
There are several design nodes t hat do not affect the PL output , but continue to toggle.
Every flip-flop, block RAM and D SP48 has a local clock-enable. Designers can gate the local
clock-enable to eliminate unnecessary flip-flop, block RAM, and  DSP toggling, as shown in
Figure  2-3.
Designers should ensure the maxi mum number of elements are cont rolled by the gating
signal when possible. For example, it is more power efficient t o gate a clock domain at its
source rather than gate each loa d with a clock-enable signal. D esigners can use the
different clock buffer primitives  in the PL to gate clocks, dep ending on the application.
The BUFGCE primitive is a global  clock buffer with a clock enab le. BUFGCE can be used to
dynamically gate a global clock o r clock domain, glitch free. U sing this resource also
reduces high clock enable fanout and saves PL fabric routing re sources.
If gating is needed for a specific logic function or a clock do main in the PL, the BUFHCE or
BUFRCE primitive can be used. These primitives reduce loading a nd capacitance, lowering
the PL dynamic power consumption.
X-Ref Target - Figure 2-3
Figure 2-3:  Gating the Local Clock-Enable to  Eliminate Unnecessary Toggling
Before
sig
Power
Consumption
After
sig
Power
Consumption
CE
X14196-073117
Send Feedback

## Page 28

UltraFast Embedded Design Methodology Guide 28
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
The BUFGMUX_CTRL primitive can be used to distribute clocks to specific regions and avoid
unwanted PL fabric dynamic switching. It can also be used to sw itch between fast and slow
clocks in order to reduce power.
There are often several design nodes that do not affect the PL output but continue to
toggle, resulting in unwanted dyna mic power consumption. The FP GA clock enables can be
used to gate those nodes.
Making the best use of  timing constraints is also important in low-power design. If an
application operates in a temper ature-controlled environment, t he application can be
derated to meet timing. The desig n should be constrained to use  the maximum specified
clock rate. Using a faster clock  rate than necessary typically has the following negative
effects:
• More PL resources are used due to reduced resource sharing.
• Logic and registers are often d uplicated to meet  tight timing constraints.
• The amount of routing increases.
• There are fewer inferences of PL dedicated features.
All of these negative effects ca n significantly impact dynamic power consumption.
Block RAM
The power block RAM consumes is directly proportional to the ti me it is enabled. To save
power, the block RAM enable can be driven low when the block RA M is not used. Both the
block RAM enable rate and the clock rate are important to consi der when optimizing power.
The block RAM should be enabled during an active read or write cycle. Synthesis tools
might not infer these primitives , so if they are needed their i nference should be verified
with a schematic viewer and instantiated if necessary to save p ower.
Send Feedback

## Page 29

UltraFast Embedded Design Methodology Guide 29
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Floorplanning
Designs that span multiple clock  regions use more clocking reso urces and consume more
power. When possible, place any i ntermittently used logic in a single clock region to help
reduce power, as shown in Figure  2-4. While the tools attempt t o do this automatically,
some designs may require manual effort like applying an area co nstraint to achieve this.
Limiting data motion i s another power-reduction technique. Inst ead of moving operands
around the PL, move only the results, as shown in Figure  2-5. Using fewer and shorter buses
lowers capacitance, improves per formance, and consumes less pow er. The pinout
placement and corresponding logic design must be considered dur ing floorplanning.
X-Ref Target - Figure 2-4
Figure 2-4:  Constraining Intermittently Used Logic to a Single Clock Region
X-Ref Target - Figure 2-5
Figure 2-5:  Limiting Data Motion
X14197-073117
X14198-073117
Send Feedback

## Page 30

UltraFast Embedded Design Methodology Guide 30
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
IO Power
I/O power can be a major contrib utor to total power consumption . In some designs, as
much as half of the total power consumption comes from the I/Os , particularly in
memory-intensive systems.
Some interfaces do not require f ast, differential I/O capabilit ies. I/O standards such as
HSLVDCI can save considerable po wer in FPGA-to-FPGA communicati ons and in
lower-speed memory interfaces.
All Zynq-7000 AP SoCs offer prog rammable slew rate and drive st rength that can be used to
reduce I/O dynamic power. The de vices support digitally control led impedance (DCI)
technology, and can be tri-stated. DCI eliminates termination p ower when the I/O’s output
is enabled, so that the device c onsumes termination power only during ingress cycles.
Zynq-7000 AP SoCs incorporate a us er-programmable receiver powe r mode for HSTL and
SSTL. By controlling the programm able power modes on each I/O, DC power can be
reduced by making trade-offs b etween power and performance.
Zynq-7000 AP SoCs have transceiv ers optimized for high performa nce and low jitter. The
transceivers offer several low-po wer operating features, enabli ng designers to customize
the flexibility of operation and  granularity to make power and performance trade-offs.
In the transceivers, you can use the shared LC PLL to save powe r. In four-lane designs with
an identical line rate (XAUI, fo r example), you can use a quad PLL instead of an individual
channel PLL. Similarly, because a PLL can run at higher and low er rates within the range, a
lower operating range can be selected to save power.
The RXPOWERDOWN and TXPOWERDOWN options can be enabled. PLL pow er down can
be enabled in the lowest-power m ode, such as in a system D3 sta te, which is mostly used in
PCIe systems.
You can also save I/O powe r in the following ways:
• Using time-multiplexing tec hniques to reduce I/O count.
• Using minimal I/O count design partitioning that can help swit ch off an I/O bank when
not used.
• Reducing the number of I/O st andards used within a bank.
Partial Reconfiguration
One way to reduce static power i s to simply use a smaller devic e. With partial
reconfiguration, designers can essentially time-slice a block o f logic in the PL and run parts
of their design independently. The design then requires a much smaller device because not
every part of the design is n eeded 100 percent of the time.
Send Feedback

## Page 31

UltraFast Embedded Design Methodology Guide 31
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Partial reconfiguration has the potential to reduce dynamic pow er as well as static power.
For example, many designs must run very fast, but that maximum performance might only
be needed a small percentage of the time. To save power, design ers can use partial
reconfiguration to swap out a hi gh-performance design with a lo w-power version of the
same design-instead of designing for maximum performance 100 pe rcent of the time. You
can switch back to the high-perf ormance design when the system needs it.
This principle can also apply to  I/O standards, specifically wh en a design does not need a
high-power interface all the time. LVDS is a high-power interfa ce, regardless of activity, due
to the high DC currents required to power it. You can use parti al reconfiguration to change
the I/O from LVDS to a low-power  interface, such as LVCMOS, at times when the design
does not need the highest perform ance, and then switch back to LVDS when the system
requires high-speed transmissions.
Power Estimation
Power calculations can be performed at three distinct phases of  the design cycle.
• Concept phase:  In this phase a rough estimate of power can be calculated base d on
estimates of logic capac ity and activity rates.
• Design phase:  Power can be calculated more accurately based on detailed info rmation
about how the design is implemented in a Zynq-7000 AP SoC.
• System integration phase:  Power is measured in a lab environment.
Xilinx provides a suite of tools and documentation to help eval uate the thermal and power
supply requirements of the system throughout the design cycle. Figure  2-6 shows the tools
available at each stag e of the design cycle.
Some tools are stand-alone, whil e others are integrated into th e implementation process,
using information available at ea ch stage of the design process . All tools can exchange
information back and forth for efficient analysis.
X-Ref Target - Figure 2-6
Figure 2-6:  Vivado Power Estimation and Anal ysis Tools in the FPGA Design P rocess
XPower Estimator (XPE) Vivado Power Analysis
Specification Synthesized
Design
Placed
Design
Routed
Design Closure Validation
X14199-073117
Send Feedback

## Page 32

UltraFast Embedded Design Methodology Guide 32
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
The final power consumption is d etermined after the system has been implemented and
measured in the lab. This is done by manually probing the devel opment-board power lines,
or by providing a mechanism to read the voltage and current fro m external programmable
voltage regulators. Accurate pow er calculations in early design  stages result in fewer
problems later.
Xilinx Power Estimator (XPE)
The Xilinx Power Estimator (XPE) spreadsheet is a power estimat ion tool typically used
during a project's concept phase . XPE assists with architecture  evaluation and device
selection, and helps with select ing the appropriate power suppl y and thermal management
components for the application.  The XPE interface for Zynq-7000  AP SoCs is shown in
Figure  2-7. Designers can use the tool to specify design resource use, ac tivity rates, I/O
loading, CPU clock frequency, an d many other design parameters.  XPE combines the
parameters with the device model s to calculate an estimated pow er distribution.
X-Ref Target - Figure 2-7
Figure 2-7:  Xilinx Power Estimator for Zynq-7000 AP SoCs
Send Feedback

## Page 33

UltraFast Embedded Design Methodology Guide 33
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
XPE is also commonly used later in the design cycle during impl ementation and power
closure, such as evaluating the power implications of engineeri ng change orders. For large
designs implemented by multiple teams, the project leader can u se XPE to import the
utilization and activity of each  team's module, then monitor th e total power and reallocate
the power budget to ensu re constraints are met.
System-Level Power Analysis
The final system power consumption is determined after the desi gn has been implemented
and measured in the lab. This is done by manually probing the d evelopment-board power
lines, or by providing a mechanis m to read the voltage and curr ent of voltage regulators.
The Zynq-7000 AP SoC Low Power T echniques part 1 - Installing a nd Running the Power
Demo Tech Tip wiki page [Ref 63] provides a reference design demonstrating system-level
power consumption while executing  different application scenari os on Zynq-7000 AP SoC
PS and PL sections. You can refe r to this technical article whe n performing system-level
power measurements on your design.
Vivado Power Analysis
Vivado Power Analysis is a tool used to analyze power consumpti on of placed and routed
designs during the design phase. It provides a comprehensive GU I that allows a detailed
analysis of the power consumed a s well as thermal information f or the specified operating
conditions. Figure  2-8 shows an example report f rom Vivado Power Analysis.
X-Ref Target - Figure 2-8
Figure 2-8:  Vivado Power Analysis Example Report
Send Feedback

## Page 34

UltraFast Embedded Design Methodology Guide 34
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
The tool provides two different  views of power consumption:
• Power consumed by type of block s found in the design, includin g clock trees, logic,
signals, I/Os, and PS IP such as block RAMs and DSP blocks.
• Power consumed throughout the design hierarchy.
Designers can toggle between the two views to perform a detaile d power analysis. The
views provide an efficient metho d for locating the blocks or de sign parts that consume the
most power, thus identifying pla ces to focus power optimization  efforts.
Switching activity information f rom Value Change Dump (VCD) and  Switching Activity
Interchange format (SAIF) files can be entered into the Vivado Power Analysis tool for more
accurate power estimation. VCD files contain header information , variable definitions, and
value change details for each st ep of a simulation. SAIF files contain signal toggle counts
and timing attributes specifying  the time duration of signals a t level 0, 1, X, or Z.
PL Power Optimization in Vivado
Although designers can use clock  gating to optimize power as de scribed previously, it is
rarely done. This is either beca use the design contains intelle ctual property from other
sources or because of the effort involved in doing such fine-gr ained clock gating. The
Vivado tools automate such power  optimizations to maximize powe r savings while
minimizing effort.
The Vivado design tools offer a variety of power optimizations enabling you to minimize
dynamic power consumption by up to 30%.
Vivado performs an analysis on t he entire PL design, including legacy and third-party IP
blocks, for potential power savi ngs. It examines the output log ic of sourcing registers that
do not contribute to the result during a given clock cycle, and  then creates fine-grained
clock gating and logic -gating signals that  eliminate unnecessar y switching activity.
Power optimizations are also applied to dedicated block RAMs. M ost of the power savings
is realized by disabling the dedicated block RAM's enable when no data is written and when
the output is not being used.
Refer to the Vivado Design Suite User Guide:  Power Analysis and Optimization  (UG907)
[Ref 10] for more information on using t he power optimization options a nd extracting the
power consumption inform ation from the design.
Send Feedback

## Page 35

UltraFast Embedded Design Methodology Guide 35
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Correcting Over-Budget PL Power Consumption
Late in the design cycle there i s pressure to get the system to  market, and most system
parameters are well defined, suc h as the board environment and cooling solution. Even
though this limits the engineerin g rework you can do, further p ower reduction might be
possible in the PL. The following process can help focus your e fforts on the areas in the PL
with the highest potential for power reduction.
1. Determine which Power Budget is Exceeded
Vivado GUI users can review the summary view in the Vivado Powe r Analysis report, and
command line users can use the summary section of the power rep ort file. The on-chip
and supply power tables provide a high-level view of the power distribution. Use the
summary view to determine the typ e and amount of power that exc eeds your budget.
2. Identify the Focus Areas
Review the different detailed views in the Vivado Power Analysi s report or Xilinx Power
Estimator. Analyze the environme nt parameters and the power dis tribution across the
different resources used, the design hierarchy, and clock domai ns. When an area of the
design is found where power seems  high, the information present ed should help in
determining the likely contributing factors.
3. Experiment
After developing a list of focus areas for power optimization, sort the list from easiest to
most difficult and decide which optimization or experiment to p erform next. The power
tools allow what-if analysis so that design changes can be made  quickly and power
estimates produced without requi ring edits to code or constrain s, and without
rerunning the imple mentation tools.
While power optimization techniques that can be used are listed  in this document, more
information can be found in the Vivado Design Suite User Guide: Power Analysis and
Optimization  (UG907) [Ref 10] .
Experiment Using the Vivado Power Optimizer Feature
To maximize power savings when running the power optimizer in t he Vivado tools, run
power optimization on the entire  design and do not exclude port ions of the design. If
power savings are not realized a fter enabling power optimizatio n, there are three areas that
should be examined more closely:
• Global set and reset signals
•B l o c k  R A M  e n a b l e  g e n e r a t i o n
• Register clock gating
A low number of enables generated  by power optimization in any of those areas could
indicate a need to review coding  practices, or t he options and properties set for design.
Send Feedback

## Page 36

UltraFast Embedded Design Methodology Guide 36
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Experiment with the Vivado Power Analysis Feature
In the Vivado Report Power dialo g box, adjustments can be made before rerunning the
analysis to review the power implications. Refer to the Vivado Design Suite User Guide:
Power Analysis and Optimization  (UG907) [Ref 10] for more information on how to use the
different options in th e Vivado Power Analyzer tool to produce optimal results.
Experiment with Xilinx Power Estimator (XPE)
The Vivado power analysis result s from modules developed by mul tiple sources can be
imported into XPE. This permits a review of total power once th e separate IP blocks are
implemented in the device. You c an estimate the implications of  design changes on power
consumption without requiring code or netlist changes. The esti mation done by XPE is not
as accurate as that done by the Vivado Power Analysis tool beca use adjustments cannot be
made at the individual logic e lement or signal level in XPE.
Conclusion
Understanding and implementing p ower-sensitive design technique s before coding is the
single-largest method for reduci ng system power. Using the vari ous Xilinx tools at the
appropriate design cycle stages also helps in meeting power spe cifications, and provides
the board designer with informati on on selecting the number, ty pe, and size of the power
supplies.
Clocking and Reset
External and internal clocking r esources are available for use as source clocks to various IP
blocks in the Zynq-7000 AP SoC. Those resources are described b elow. Also described in
this section are the various har dware, software, and debug rese ts, particularly when and
how you should use them.
External Clocks
PS_CLK
On the PS side, a fixed-frequenc y oscillator in the range of 30 –60 MHz is typically used to
provide the processor clock PS_C LK. The clock must be a single- ended LVCMOS signal,
using the same voltage level as the I/O voltage for MIO bank 0.  From this clock, all other PS
internal clocks are generated based on three PLLs: ARM, DRM, an d IO PLL.
Send Feedback

## Page 37

UltraFast Embedded Design Methodology Guide 37
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
The default PS_CLK frequency use d on Xilinx evaluation boards i s 33.3 MHz. Other clock
frequencies can be used, but the following items are dependent on the PS clock frequency
and must be adjusted accordingly:
• The LogiCORE IP Processing System 7 configuration wizard calcu lates the derived clock
dividers and multipliers of each of the PLLs as well as the I/O  peripheral clocks such as
SPI or UART based on the selected PS_CLK frequency. These value s are later used by the
first stage boot loade r (FSBL) during initialization of the PS.
• The U-Boot board configuration include file.
• The Linux design-specific device tree.
Others
On the PL side, single -ended or differentia l fixed-frequency os cillators can be used as
additional clock sources for gre ater flexibility.  They should b e connected to multi-region
clock capable (MRCC) input pins and adhere to the I/O standard and voltage of the
corresponding PL bank. PL input c lock jitter can be much smalle r than that of PS-derived
clocks. For certain applications  (such as to generate a video r esolution dependent, accurate
pixel clock in a video system), external low-jitter programmabl e clock synthesizers are used.
Certain board peripherals require an external crystal to operat e the PHY (for example, a 25
MHz crystal is required for the Ethernet PHY). Also, some perip heral I/O interfaces provide
input and/or output clocks to co mmunicate with the correspondin g PHY (such as Ethernet
RX and TX clocks).
Internal Clocks
PS
All clocks generated by the PS clock subsystem are derived from  one of three
programmable PLLs: CPU, DDR, and I/O. Each of these PLLs is loo sely associated with the
clocks in the CPU, DDR, and peripheral subsystems. During norma l operation, the PLLs are
enabled, driven by the PS_CLK clock pin. In bypass mode, the cl ock signal on the PS_CLK pin
provides the source for the vari ous clock generators instead of  the PLLs. After the boot
process, the bypass mode and output frequency of each PLL can b e individually controlled
by software.
The CPU clock domain is composed of four separate clocks: CPU_6 x4x, CPU_3x2x, CPU_2x,
and CPU_1x. These four clocks are named according to their freq uencies, which are related
by one of two ratios: 6:3:2:1 or  4:2:2:1 (abbreviated 6:2:1 and  4:2:1, respectively). All of the
CPU clocks are synchronous to each other. There are two indepen dent DDR clock domains:
DDR_3x and DDR_2x. These clocks are asynchronous to each other and the CPU clocks. Most
I/O peripherals clocks have dedi cated dividers. Each peripheral  clock is completely
asynchronous to all other clocks.
Send Feedback

## Page 38

UltraFast Embedded Design Methodology Guide 38
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
PS - PL Interface
PL AXI channels (AXI_HP, AXI_ACP, and AXI_GP) have asynchronous  interfaces between the
PS and the PL. The synchronizati on, where the clock domain cros sing occurs, is located
inside the PS. Therefore, the PL  provides the interface clock t o the PS. Each of the
aforementioned interfaces could use unique clocks in the PL.
The PS provides four frequency-p rogrammable fabric clocks (FCLK  [3:0]) to the PL that are
physically spread out along the PS-PL boundary. The clocks can be controlled individually
by setting the clock's source (ARM, DDR, or I/O PLL) and the cl ock's output frequency. There
is no guaranteed phase relations hip between any of the four FCL K clocks, even when
sharing the same clock source. M ake sure to use appropriate des ign constraints when
interfacing between multiple FCLK  regions. The FCLK clocks are disabled until the PS - PL
level shifters are enabled.
RECOMMENDED: It is good practice to route a single FCLK into a clocking wizard IP core instantiated
inside the PL to generate more th an one phase-aligned output clocks.
The following are pros an d cons of using FCLK:
• FCLK is the preferred PL clock u nder the following circumstanc es:
° The processor controls t he PL clock frequency.
° An on-board clock gene rator is not available.
• FCLK is not the preferred PL cl ock under the following circums tances:
° The PL clock frequency is outside the frequency range supported  by FCLK.
° The PL uses a clock provided by the FPGA pins. This is common i n
source-synchronous protocols tha t use the input clock to sample  receive data.
° Low clock jitter is required.
° Some IP blocks that require spec ific clocking cannot use FCLK:
- The memory-interface generator (MIG) requires a differential c lock, Therefore,
FCLK cannot be used for the MIG except at reduced frequencies d ue to jitter.
- GTs should use a differential cl ock from the boa rd as a refere nce clock.
For more information on the PS clock system, refer to the Clock s chapter of the Zynq-7000
All Programmable SoC Technical Reference Manual  (UG585) [Ref 4].
PL
The PL provides clock primitives that are commonly found on FPG A devices, such as global
or regional clock buffers (BUFG, BUFR), phased-locked loops (PL L), or mixed-mode clock
managers (MMCM). For convenience,  the clocking wizard IP core i mplements a wrapper
around the MMCM/PLL primitives w ith up to eight configurable ou tput clocks. The user can
Send Feedback

## Page 39

UltraFast Embedded Design Methodology Guide 39
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
optionally enable dynamic reconf iguration of clock frequencies using the dynamic
reconfiguration port (DRP)  or an AXI-Lite interface.
TIP: In the simplest case, a complete Zynq-7000 system can be built with a single input clock based on
PS_CLK, and all PL clocks are generated from th e provided FCLKs and FPGA clocking resources.
PS Power-On Reset
The PS power-on reset (PS_POR_B) is an active-low signal used t o hold the PS in reset until
all PS power supplies are stable and at their required voltage levels. This signal should be
generated from the power supply power-good signal or from a vol tage supervisor chip. At
the time PS_POR_B is released, t he system clock (PS_CLK) must h ave been stable for 2,000
clock cycles. PS_POR_B should be  pulled high to VCCO_MIO0. When  asserting PS_POR_B,
the pulse length must be longer than 100 μ s.
The power-on reset is the chip master reset. It resets every re gister in the device that can be
reset, resets all PS RAM (including OCM, Fifos, buffers, etc.) and starts BootROM execution,
clearing the PL configuration. W hen PS_POR_B is held low, all P S I/Os are held in 3-state.
PS System Reset
The PS system reset (PS_SRST_B) is an active-low signal that is  used primarily for debugging
proposes. PS_SRST_B must be high  to begin the bo ot process. If PS_SRST_B is not used it
can be pulled high to VCCO_MIO1.  When asserting PS_SRST_B, the pulse length must be
longer than 1 μ s.
A PS system reset (PS_ SRST_B) resets all f unctional logic witho ut affecting the debug
environment. This differs from a power-on reset (PS_POR_B), whi ch erases the debug
configuration. The PS_SRST_B era ses all PS RAM, starts BootROM execution, and clears the
PL configuration. It does not re -sample the boot-mode strapping  pins, unlike the
PS_POR_B. The boot mode remains the same as the previous power- on reset, and the
security level of the previous boot is retained.
The PS_SRST_B signal must be de- asserted before the PS_POR_B si gnal is de-asserted. If the
BootROM execution caused by a PS _POR_B reset is interrupted by the assertion of the
PS_SRST_B reset signal, the syst em will lock down. If both PS_S RST_B and PS_POR_B are
used, PS_POR_B must be  the last signal that is de-asserted. For  more information, refer to
Xilinx Answer Record 52847 [Ref 70].
Contact Xilinx Technical Support if you need a PS reset solutio n that does not clear the PL.
System Software Reset
The System Software Reset, also called SLCR Soft Reset, is asse rted by writing to
PSS_RST_CTRL[SOFT_RST] and has t he same effect as asserting the  PS_SRTS_B pin. All of the
PS RAMs are cleared and the PL is reset as well.
Send Feedback

## Page 40

UltraFast Embedded Design Methodology Guide 40
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Watchdog Timer Resets
There are two sources of watchdog timer resets: the System Watc hdog, SWDT, and the two
ARM Watchdog Timers, AWDT0 and AWDT1. The SWDT always resets th e entire system,
while each of the AWDTs can be used to reset either the associa ted ARM core (same effect
as CPU Reset) or the entire syst em (same effect as System Softw are Reset).
CPU Resets
There are two CPU Resets, one fo r each ARM core asserted by wri ting to
A9_CPU_RST_CTRL[A9_RSTx]. A CPU Reset to a single processor mus t be applied from the
other CPU, through JTAG or the PL.
Debug Resets
There are two debug resets, Debug System Reset and Debug Reset,  that originate from the
ARM DAP and are controlled by JTAG. The Debug System Reset has the same effect as a
System Software Reset, whereas t he Debug Reset only resets the debug logic.
Peripheral Resets
Individual peripheral resets can be asserted under software con trol, using programmable
bits within the SLCR. However, a sserting reset at the periphera l block level is not
recommended. Resetting a peripheral without completing all in-f light or pending
transactions will cause the syst em to hang, because AXI transac tions do not support a
timeout mechanism. When assertin g reset to a peripheral, all pe nding and in-flight
transactions must be completed and no future transactions can b e issued prior to the reset.
PL Resets
The PS provides four programmabl e reset signals to the PL (FCLK _RESET [3:0]). The resets
are individually programmable and independent of the PL clocks.  After a POR or
system-wide reset, the reset sig nals are not de- asserted until the BootROM execution
finishes and the PS to PL level shifters are enabled
The FCLK_RESET is loosely associ ated with the FCLK of the same number. That is, the FCLK
needs to be toggling for the FCLK _RESET to propagate out of the  PS. The reset is an
asynchronous reset to the PL and you must synchronize the reset  inside the PL if required.
RECOMMENDED: To synchronize an FCLK_RESET, connect the signal to the ex ternal reset input port of
a proc_sys_reset IP core. By doing so, the reset outp ut signals connected to other PL IP cores can be
synchronized to the slowest clock.
Send Feedback

## Page 41

UltraFast Embedded Design Methodology Guide 41
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
If the FCLK_RESET signal drives the reset of AXI-based IP in PL  and is reasserted after the
initial de-assertion described ab ove, resetting the IP later wi thout completing all in-flight or
pending transactions to and from  the process block will cause t he system to hang. The
system must idle all AXI masters  and finish all AXI transaction s prior to asserting reset.
Interrupts
Generic Interrupt Controller
Because a Zynq-7000 AP SoC has many interrupt sources, the MPCo re multicore processor
includes an implementation of th e generic interrupt controller (GIC) architecture to help
funnel, prioritize, and arbitrate those interrupt sources. The GIC maps interrupts to specific
processor nIRQ and nFIQ lines. Mu ltiple, concurrent interrupts are presented serially to one
or more processor interrupt lines.
Conceptually, the GIC contains a n interrupt distribution block (distributor) and two
processor-interrupt blocks. Each block contains a set of regist ers. Registers in the
processor-interrupt blocks can only be accessed by the processo r they are attached to using
its private bus and cannot be accessed by the other CPU or othe r AXI masters in the system.
Distributor registers can be acce ssed by either processor, and some registers are also
banked for secure and non-secure access.
Interrupts sent to the GIC can be unmanaged (legacy) or managed . Legacy interrupts are
not controlled by the GIC and the  interrupt handler should not interact with GIC registers.
X-Ref Target - Figure 2-9
Figure 2-9:  System-Level Block Design
Software Generated
Interrupts (SGI)
Generic Interrupt
Controller
Enable, Classify, Distribute
and PrioritizeSoftware Interrupts
CPU 1
CPU 0 CPU 0
Private Peripheral
Interrupts (PPI) CPU 0
CPU 0
Private 5
Private Peripheral
Interrupts (PPI) CPU 1
CPU 1
Private
5
Shared Peripheral
Interrupts (SPI)
Shared Peripherals
CPU 1
CPU 0
PS
I/O Peripherals (IOP)
Programmable
Logic
60
60
1644
Interrupt
Interface
Execution
Unit
Private Interrupt
Registers
IRQ/FIQ
CPU 1
Interrupt
Interface
Execution
Unit
Private Interrupt
Registers
IRQ/FIQ
Interrupt
Control and Status
Registers
CPU Private
Bus
WFI, WFE and
Event Indicators
16 each
X14186-073117
Send Feedback

## Page 42

UltraFast Embedded Design Methodology Guide 42
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Managed interrupts are controlled by the GIC and the interrupt handler must interact with
GIC registers.
The distributor can control mana ged interrupt sources as follow s:
• Define the interrupt as edge-sensitive or level-sensitive, sub ject to hardware
configuration limitations.
• Assign a 5-bit priority to the interrupt, with a programmable binary point.
• Assign a TrustZone technology sec urity state to the interrupt.  Interrupts labeled as
secure are called Group 0 interr upts, and non-secure interrupts  are labeled as Group 1
interrupts.
• Route shared peripheral interru pts to one or both processors.
Note: Private peripheral interrupts ( PPIs) are dedicated to each CPU and cannot be routed
elsewhere other than through the GIC.
• Route a software-generated interrupt to one or both processors .
• Save and restore the pending st ate of each interrupt. This is useful in low-power
applications.
Interrupt Architecture
The PS and PL interrupt sources,  PS interrupt hierarchy, and Co rtex-A9 processor
considerations are descr ibed in this section.
PS Interrupt Sources
Each Cortex-A9 processor can be i nterrupted by the following so urces:
• Sixteen software-generated inte rrupts (SGIs) are available for  software to interrupt
either processor.
• Five private peripheral interru pts (PPIs) are available. There  are two interrupts from PL
(FIQ and IRQ) and one each from the global timer, the private t imer, and AWDT.
• Sixty shared peripheral interru pts are available. There are 44  PS I/O peripheral
interrupts and 16 PL interrupts.
• Four PL interrupts can bypass th e GIC and directly interrupt t he processors, reducing
interrupt latency.
• Although it is not an interrupt , a CPU may use the WFE instruc tion to deliberately stall
and wait for an event on a dedic ated input line from the other CPU or the PL.
Send Feedback

## Page 43

UltraFast Embedded Design Methodology Guide 43
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
PL Interrupt Sources
Each device in the PL that respo nds to interrupts must arrange for its own interrupt
controller, if needed. The follo wing interrupts can be sent fro m the PS to the PL:
• Twenty-nine shared peripheral i nterrupts from the PS. These co rrespond to many (but
not all) of the PS peripherals.
• A processor can also use softwar e-generated interrupts to inte rrupt the PL by using
EMIO GPIOs, an AXI_GPIO output c hannel in the PL, or by asserti ng a per-processor
hardware event line usin g the SEV instruction.
Interrupt IDs
A Zynq-7000 AP SoC supports IRQ IDs #0 through #95, as follows:
• IRQ ID #0–#15.  These are assigned to software generated interrupts, allowing software
to interrupt a processor, includi ng the processor hosting the s oftware.
• IRQ ID #16–#31.  These are assigned to private pe ripheral interrupts. IRQ ID #1 6–#26
are unused. Zynq-7000 AP SoCs impl ement IRQ ID #27–#31, as foll ows:
a. IRQ ID #27 is used by the processor global timer.
b. IRQ ID #28 is used by the managed FIQ and is also an unmanage d input.
c. IRQ ID #29 is used by the processor private timer.
d. IRQ ID #30 is used by the processor AWDT.
e. IRQ ID #31 is used by the manag ed IRQ and is also an unmanage d input.
• IRQ ID #32–#95.  These are assigned to shared per ipheral interrupts. IRQ ID #36  is
unused. Zynq-7000 AP SoCs impleme nt IRQ ID #32–#35 and #37–#95.  Thirty-one
interrupts (IRQ ID #32–#62) can a ll be unlocked or all be locke d against user change.
Unique Capabilities
Interrupts can originate from the PS or the PL, and a PS proces sor or dedicated hardware in
the PL fabric (such as MicroBlaz e™) can respond to interrupts. This enables the unique
capabilities of Zynq-7000 AP SoC s, described in the following s ections.
Interrupt Processing in Fabric
Custom hardware can be created t o offload interrupt processing to the PL. When this is
done, interrupt latency can be v ery low and deterministic (cloc k cycle accuracy). Also, the
custom hardware can perform comp utations that would take longer  on the processor, in
parallel with the processor. If th is is done, data stitching mi ght be required, and the ACP
might be useful in providing c ache coherency for PL masters.
Send Feedback

## Page 44

UltraFast Embedded Design Methodology Guide 44
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Custom hardware can also be used to filter interrupts, reducing  PS interrupt frequency and
processor loading. This can be d one by converting multiple, low -level interrupts into fewer,
high-level interrupts.
Processor as an Extension of Fabric
Alternatively, processors in a Zynq-7000 AP SoC can act as an e xtension of fabric hardware,
performing tasks in software tha t would be difficult to impleme nt in hardware. The PL can
send an interrupt to the PS to in itiate a task, and interrupts can be sent from the PS to PL
indicating task completion. This method can also be used with t he PS DMA330 controller to
provide additional execution threads.
Using OCM for Handlers
Fetching an interrupt handler fr om DDR memory might take more t ime than desired. The
Zynq-7000 AP SoC has a large L2 cache, but an interrupt handler  may not be cached when
an interrupt occurs. In this case, it may be beneficial to plac e interrupt handlers in on-chip
memory (OCM). When this is done,  the variability in time spent fetching an interrupt
handler is limited to L1 caches misses, leading to reduced jitt er
Processor Affinity
Because there are two processors , polling responsibilities and interrupt handlers can be
divided between the processors, reducing latency and improving response time. This can be
done in either symmetric or asymmetric multi-processing systems .
Using FIQ and IRQ
Each Cortex-A9 in a Zynq-7000 AP SoC has two interrupt lines, n FIQ and nIRQ, driven by the
ARM e Generic Interrupt Controll er (GIC). The 'n' prefix indica tes that they are active low
interrupts. FIQ has lower latency than IRQ and is typically use d for high-priority interrupts.
IRQ is used for interrupts that d o not require low-latency resp onse. An FIQ always preempts
an IRQ, and a preempted IRQ hand ler resumes execution after the  FIQ handler finishes.
TrustZone
Zynq-7000 AP SoCs use ARM TrustZon e technology, allowing system  components to be
identified as secure or non-secu re. For example, at different t imes each processor can
operate in secure and non-secure modes. Similarly, interrupts c an be identified as secure
and non-secure. This allows isolation of secure components from  those that are not secure.
In this case, higher-priority FI Qs can be used for secure inter rupts and lower-priority IRQs
for non-secure interrupts. Many secure settings can also be loc ked to prevent changes.
Send Feedback

## Page 45

UltraFast Embedded Design Methodology Guide 45
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
System Design Considerations
System designs should consider t he performance impacts of vario us interrupt
implementation options:
• Latency and associated jitter should be characterized and mana ged by hardware or the
operating system. Jitter occurs if the OS masks interrupts for an unpredictable time
period, or because higher priori ty interrupts are being service d.
• Policies for peripherals and a ssociated software should be def ined for cases when
interrupt handling is delayed. Choices include dropping data, t hrottling or pausing the
remote data source, and allowing  hardware to run with degraded performance.
• Processor utilization is suffici ent for peripheral services an d other tasks, assuming
average and worst case scenarios.
• The interrupt handler's memory location can affect instruction -fetch performance.
Memory closer to the processor wi ll have lower latency. Alignin g the interrupt service
routine so that it starts on a c ache line boundary can improve latency.
• When an interrupted peripheral operates on data that could be cached by the
processor, the processor must mai ntain cache coherency by inval idating or flushing its
caches, or by using hardware coherency mechanisms such as the A CP. On Zynq-7000 AP
SoCs, PL peripherals that use th e ACP port avoid this restricti on.
• In systems implementing asymmetric multi-processing (AMP), an ownership policy for
interrupts (and other system re sources) must be established.
Embedded Device Security
The definition of security in mo dern embedded devices depends o n the application. For
mobile phones, security could re fer to preventing unauthorized access to personal data,
such as bank account numbers and passwords. For data center swi tches, security could refer
to preventing a hacker from mali ciously logging in and disrupti ng network services.
Stealing and decompiling binary s oftware logic stored in flash memory or physically
breaking open devices for reverse engineering are also possible  embedded device security
challenges.
Potential threats to embedded devices include:
• Data privacy in the embedded device
• Cloning the embedded device
• Denial of service
• Malware insertion to change the embedded device behavior
• An insider providing keys to an adversary
Send Feedback

## Page 46

UltraFast Embedded Design Methodology Guide 46
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
The above examples describe threats from hackers and competitor s. Other system security
threats can come from poorly-written programs. Such programs ca n accidentally corrupt
other programs and user data sto red in the embedded-device flas h, or disrupt normal
embedded-device operations by monopolizing the processor or per ipheral bandwidth.
Zynq-7000 AP SoCs are designed to improve the security of the e mbedded systems they
power. This section highlights se curity features of Zynq-7000 A P SoCs that can be used to
provide different levels of security, such as:
• Boot image and bitstream encypt ion and authentication (secure boot).
• Partitioning the system into se parate secure zones (TrustZone) .
• Deploying asynchronous multipro cessing (AMP) on Zynq-7000 AP S oCs.
• Linux deployment on Zynq-7000 AP SoCs.
Secure Boot
An embedded system using a Zynq-7000 AP SoC typically wants to prevent the device from
being used differently than what  was originally intended. An em bedded system with a
Zynq-7000 AP SoC will typically hav e at least one of two progra mmable components:
software (PS images) and PL bitstreams. The system must be desi gned to ensure that once
it is deployed into the field, untrusted and corrupted programm able components are not
used for system boot. Also, secu rity against programmable compo nent theft must be
included to prevent a malicious competitor from stealing PS ima ges and PL bitstreams.
Authentication is used to prevent booting with unauthorized pro grammable components,
and encryption is used to prevent programmable components theft .
Zynq-7000 AP SoCs provide multiple features in hardware and sof tware (BootROM) that can
be configured to ensure that tru sted programmable components (s oftware and PL
bitstreams) are used to boot a Zynq-7000 AP SoC. Secure boot mo de is restricted to NOR,
NAND, SDIO, or Quad-SPI flash as the external boot device. A se cure boot from JTAG or any
other external interfa ce is not allowed.
Send Feedback

## Page 47

UltraFast Embedded Design Methodology Guide 47
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
PS Software Boot Flow
The boot flow for PS is shown in Figure  2-10.
X-Ref Target - Figure 2-10
Figure 2-10:  PS Boot Flow
Power On Reset
(Debug access with JTAG disabled)
Internal memory hardware clean process
(Optional OCM ROM CRC)
RSA authentication performed on FSBL
Load boot image header
AES decryption of FSBL
(Decrypted FSBL loaded to OCM)
HMAC authentication of FSBL
Disable OCM ROM memory
Pass control to FSBL
Disable and LOCK all security features
(AES and HMAC)
Load FSBL into OCM
Disable OCM ROM memory
Enable JTAG
Pass control to FSBL
Secure boot Non-Secure boot
RSA enabled
X14193-080117
Send Feedback

## Page 48

UltraFast Embedded Design Methodology Guide 48
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Power-On BootROM CRC Check
After power-on, the BootROM is t he first software component tha t executes. An optional
128KB CRC check can be done on the BootROM prior to loading the  FSBL. The CRC check is
controlled by eFuse settings. Refer to the Secure Key Driver se ction in Secure Boot of
Zynq-7000 All Programmable SoC  (XAPP1175) [Ref 42] for more information on
programming eFuses in Zynq-7000 AP SoCs.
During BootROM execution, the boot header is read from the exte rnal storage boot device
(SDIO, QSPI flash, NAND flash, or  NOR flash) as configured by t he mode pins. The header
contains information indicating whether the device will boot se curely or non-securely. Refer
to the “Boot and Configuration” chapter in the Zynq-7000 All Programmable SoC Technical
Reference Manual  (UG585) [Ref 4] for more information on the mode pins.
RSA Authentication of FSBL
During execution, the BootROM can authenticate a secure FSBL pr ior to decryption or a
non-secure FSBL prior to execution using RSA public-key authent ication. This feature is
enabled by blowing the RSA Authe ntication Enable fuse in the PS  eFuse array.
Authenticating the FSBL can ensu re that a malicious or corrupte d FSBL does not
compromise a Zynq-7000 AP SoC by booting from an unauthorized b oot source using
unauthorized programmable components. Refer to Secure Boot of  Zynq-7000 All
Programmable SoC  (XAPP1175) [Ref 42] for more information on RSA authentication.
Secure BOOT Image
The programmable components of a monolithic boot image (BOOT.bi n) include:
• PS image components
° An initialization header that can optionally write values to re gisters. For example the
initialization header can be used  to increase the CPU clock spe ed or boot device
speed before the BootROM copies and executes the FSBL.
° FSBL.
° Optional secondary-boot loader, s uch as U-Boot or bare-metal so ftware.
° Optional data images and multiple ELF.
° Optional Linux uImage.
•P L  b i t s t r e a m
The boot image can be made secure, if desired. The PS images an d PL bitstreams in a secure
boot image are authenticated usi ng a hash-based message authent ication code (HMAC)
and encrypted using the advanced  encryption standard (AES). Ref er to Secure Boot of
Zynq-7000 All Programmable SoC  (XAPP1175) [Ref 42] and Zynq-7000 All Programmable
SoC Secure Boot Getting Started Guide  (UG1025) [Ref 21] for more information on creating
secure boot images.
Send Feedback

## Page 49

UltraFast Embedded Design Methodology Guide 49
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
AES & HMAC Authentication Engines
A Zynq-7000 AP SoC PL contains AES decryptio n and HMAC authenti cation engines.
Therefore, the PL must be powered on during the secure boot pro cess, even if the secure
boot image does not have a PL bitstream. The BootROM checks whe ther the PL is powered
on prior to reading encrypted im ages from boot devices, so the embedded system must
ensure the PL is powered on befo re decryption. Because the PL i s powered by a different
power rail, the embedded system m ust be designed to ensure the rail has appropriate
connectivity to the power regulator.
Bootgen
The programmable components of BO OT.bin are assembled using a X ilinx software tool
called Bootgen. Bootgen also encr ypts the programmable componen ts when the secure
boot option is selected. Refer to “Creating a Secure Boot image ” in Secure Boot of
Zynq-7000 All Programmable SoC  (XAPP1175) [Ref 42] and to “Using Bootgen” in
Zynq-7000 All Programmable SoC Software Developers Guide  (UG821) [Ref 7].
Generating Keys
The secure boot authentication and decryption process requires the use of cryptographic
keys. The keys used by Zynq-7000 AP SoCs are:
• AES 256-bit key
•H M A C  k e y
• RSA Primary Secret Key (PSK)
• RSA Primary Public Key (PPK)
• RSA Secondary Secret Key (SSK)
• RSA Secondary Public Key (SPK)
You can provide a a developer's key for the AES and HMAC engine  or generate them using
Bootgen. Bootgen creates one key for both key0 and HMAC. If uni que values for key0 and
HMAC are needed, they can be created by running Bootgen twice, taking the key from each
run, and providing it as a user- supplied set of keys in a third  run. The AES key is
programmed into either eFuse or BBRAM in th e PL using Vivado or  the Secure Key Driver.
In the Zynq AP SoC, the primary RSA key is used to authenticate  the secondary keys.
Secondary keys are used to authenticate partitions (such as sof tware, data, and bitstream).
OpenSSL is used to create RSA primary and secondary keys. OpenS SL is used because it is
readily available, but you can also use other methods to genera te keys. The RSA key
generated by OpenSSL is a private/public key pair. The public k ey is a subset of the private
key. For security, it is important to protect the private key. In RSA, the private key is used to
sign the partitions at the manuf acturing site, and a hash of th e public key is programmed
into the Zynq AP SoC embedded de vice to verify the signature.
Send Feedback

## Page 50

UltraFast Embedded Design Methodology Guide 50
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
eFuse / BBRAM for Security
For RSA authentication, the hash of the PPK is stored in the PS  eFuse array. The PS eFuse is
programmed using the secure key driver. For AES decryption, the  key is stored in either the
eFuse or BBRAM in the PL. The PL  eFuse control bits for eFuse S ecure Boot, BBRAM Key
Disable, and JTAG Chain Disable are programmed using Vivado or the Secure Key Driver.
The eFuses are one-time programma ble (OTP). A power-on reset (P OR) is required after
programming the eFuses.
For more information on the Secu re Key Driver, as well as many other security features
discussed in this section, refer to Secure Boot of Zynq-7 000 All Programmable SoC
(XAPP1175) [Ref 42].
Partitioning a System in Separate Secure Zones (Trust Zone)
Secure boot uses encryption and authentication to prevent a boo t from using unauthorized
software, and it prevents theft of programmable PS images and P L bitstreams. However,
system designers may want to provide additional protection leve ls, such as allowing access
to certain system components only when trusted software execute s on the system. This
would help prevent dynamically-l oaded third-party applications from accessing private
data or monopolizing s ystems resources, degrading system perfor mance. For example, a
system designer might not want third-party software to access s ystem flash that is used to
store private data, such as bank  account details and passwords.
ARM TrustZone technology ensures  runtime security by enabling t he system designer to
divide the system into logical p artitions that allow only trust ed software to access secure
components at the hardware level . For more information, refer t o:
• ARM Security Technology: Building a Secure  System using Trus tZone® Technology
[Ref 76]
• Programming ARM TrustZone Architecture on the Xilin x Zynq-7000 All Programmable
SoC User Guide  (UG1019) [Ref 20]
Security using Asynchronous Multiprocessing (AMP)
Asynchronous multiprocessing (AMP) can be used in a Zynq-7000 A P SoC for system
security by restricting where so ftware can execute. For example , one ARM Cortex-A9
processor can be used to execute untrusted third-party applicat ions and the other ARM
Cortex-A9 processor can be used to execute trusted software. Th e operating system on the
ARM Cortex-A9 processor running t rusted software is given syste m resources, such as
peripherals, that are mission critical. The operating system on  the ARM core running
untrusted software is not made aw are of the secure peripherals.  This approach provides a
logical separation where untrust ed software cannot intentionall y or unintentionally
degrade system performance. This approach ensures runtime secur ity. Preventing a
malicious boot of a Zynq-7000 AP SoC by an unauthorized program mable component is
covered by secure boot.
Send Feedback

## Page 51

UltraFast Embedded Design Methodology Guide 51
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Linux Deployment
Because Linux is ported to Zynq- 7000 AP SoCs, Li nux security fe atures are available. Linux
security includes file access controls, use of the memory manag ement unit to prevent illegal
memory access, such as by programs.
Linux-based platforms such as And roid also provide device secur ity by using virtual
machines that prevent third-part y applications from directly ac cessing hardware resources.
Many other third-party proprieta ry security extensions exist fo r Linux.
Profiling and Partitioning
Profiling tools help you determine  how to partition an applicat ion’s functions between
hardware and software fo r optimal performance.
Software Profiling
Profiling is a form of program an alysis that is used to aid the  optimization of a software
application. It is used to measu re a number of application code  properties, including:
•M e m o r y  u s a g e
• Function call execution time
• Function call frequency
• Instruction usage
Profiling can be done statically ( without executing the softwar e program) or dynamically
(done while the software applic ation is running on a physical o r virtual processor).
Static profiling is generally don e by analyzing the source code , or sometimes the object
code.
Dynamic profiling is usually an intrusive process whereby progr am execution on a
processor is interrupted to gath er information. Trace mechanism s within some processors
can be used to non-intrusi vely gather pr ofiling data.
Profiling allows a designer to ide ntify code-execution bottlene cks that may be caused by:
• Inefficient code
• Poor communication between func tions and a module in the PL
• Poor communication between functions in software
• An algorithm or routine impleme nted in software  that may be mo re suitably
implemented in hardware
Send Feedback

## Page 52

UltraFast Embedded Design Methodology Guide 52
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Once identified, the bottlenecks can be optimized by rewriting the original software
function or by moving it to the PL for acceleration. Alternativ ely, part of the function could
remain in software, while the pro blematic section could be move d to hardware.
Profiling is also useful when analyzing large programs that are  too big to be analyzed by
reading the source code. Profiling can help designers identify bugs that may otherwise not
have been noticed.
The execution flow of various functions is shown in Figure  2-11 above, with the number of
clock cycles required to execute  a given function highlighted. By profiling a program, and
thus determining the number of c lock cycles required to execute  each individual function, it
can be determined whether or not  a function needs to be optimiz ed. During development,
a software engineer may have estimated the average time a funct ion should take to execute
on a given PS. This estimate can  be compared to the profiling r esults and large
discrepancies can be investigate d. An example profiling output for the execution flow in
Figure  2-11 is provided in Figure  2-12.
X-Ref Target - Figure 2-11
Figure 2-11:  Program Execution Example
X-Ref Target - Figure 2-12
Figure 2-12:  Example Profiling Output
Function
A
Function
B
Function
A
Function
C
Fcn
D
Fcn
E
Fcn
F
Function
C
Fcn
G
Timer
Program Execution
Profiler Interrupt
Signals X14187-073117
Function A
Function C
Function B
Function D
Function E
Function F
Function G
2
2
1
1
1
1
1
Calls
1 246
Execution Time
(Clock Cycles)
X14188-073117
Send Feedback

## Page 53

UltraFast Embedded Design Methodology Guide 53
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Xilinx SDK System Debugger
The Xilinx SDK includes profiling tools that help identify bott lenecks in the code that might
occur due to the interaction of functions executed within the P L, and functions executed on
the processor. Once identified, these bottlenecks can be optimi zed by migrating the entire
function to PL, by optimizing th e function code on the processo r, or by splitting the
function between processor and PL.
SDK supports hierarchical profiling, providing a view into whic h calling functions and called
sub-functions have the largest effect on process performance.
TCF Profiling
Profiling in the Xilinx SDK can be done with the TCF profiler. It works using a statistical
sampling method that examines the system at regular intervals, determines what code is
running, and updates appropriate counters. The execution profil e's accuracy improves the
longer a profile is collected, a ssuming the sample rate is suff icient. Unlike other profilers
that make use of inter rupts, this method does not cause inaccur acies if the profiled code
disables interrupts. The profiled program does not need to be r ecompiled, as it does with
gprof.
Performance Monitoring
The performance monitoring featu re in the SDK collects AXI Perf ormance Monitor (APM)
event count module data from the PL, ARM Performance Monitor Un it (PMU) data, and L2
cache data from a Zynq-7000 AP SoC PS. The data is collected by  the SDK in real-time, over
JTAG. The values from these counters are sampled every 10 msec.  These values are used to
calculate metrics shown in the dedicated view.
Send Feedback

## Page 54

UltraFast Embedded Design Methodology Guide 54
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
The Performance Tab in SDK is shown in Figure  2-13.
For each Cortex-A9 CPU, the follo wing PMU events are monitored:
• Data cache refill
• Data cache access
• Data stall
•W r i t e  s t a l l
• Instruction rename
• Branch miss
The following two L2C-PL310 (L2 cache controller) counters are monitored:
• Number of cache hits
• Number of cache accesses
X-Ref Target - Figure 2-13
Figure 2-13:  Performance Tab
Send Feedback

## Page 55

UltraFast Embedded Design Methodology Guide 55
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
The following APM counters for each of the HP and ACP ports can  be monitored when the
APM is used in a design:
• Write byte count
• Read byte count
• Write transaction count
• Total write latency
• Read transaction count
•T o t a l  r e a d  l a t e n c y
ARM Development Studio 5 (DS-5)
The ARM Development Studio 5 (DS -5) tool chain is a complete su ite of software
development tools for ARM processor-based systems. DS-5 covers all development stages
of ARM processor-based products,  from platform bring-up to appl ication profiling, while
including a number of A RM Linux and Android specific features.
The Streamline performance analyz er is a component of the ARM D evelopment Studio 5
(DS-5) tool chain. It is a syste m-level performance analysis to ol for Linux and Android
systems. It uses sample-based pr ofiling, Linux kernel trace, an d software annotation
techniques. A Streamline report p rovides a variety of performan ce-related information on
seven panes: Timeline, Call Path s, Functions, Code, Call Graph,  Stack Analysis, and Logs.
By default, the Streamline profiling reports are generated by s ampling the program counter
every 1ms or 10ms. When event-based sampling is enabled, Stream line takes samples when
an event counter reaches the selected threshold value. These sa mples fall on the instruction
that caused the last  event, and are used to fill the profiling reports with event-based data
instead of time-based data. For example, event-based sampling c an be used to determine
which parts of the code are caus ing cache misses or branch mis- predictions.
Practical Applications
Boot Time
The amount of time it takes the application to boot can be a si gnificant concern for some
systems. Total boot time include s the execution time for the Bo otROM, FSBL, 2nd stage
boot loader (such as U-Boot), and the operating system. For inf ormation about boot time,
refer to Xilinx Answer Record 55572  [Ref 71].
Send Feedback

## Page 56

UltraFast Embedded Design Methodology Guide 56
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Processor Loading
Processor load is a measure, over time, of the computation actu ally done as a percent of the
total computation that could be done. When the processor load n ears 100 percent the
system can start to fail or be unresponsive.
Top is a Linux tool that provides an ongoing look at processor load in real time. It displays
a list of the most CPU-intensive  tasks on the system, and can p rovide an interactive
interface for manipulating proce sses. It can sort the tasks by CPU, CPU usage, memory
usage and runtime.
System Latency
System latency is the length of time after a request is made fo r a system operation to start
until the operation actually start s. Identifying the cause of s ystem latency can be
challenging because it includes the application and all softwar e layers below it, including
the operating system.
Interrupt Latency
Interrupt latency is the length of time for an interrupt to be acted on after it has been
generated. Interrupt latency is often measured by the amount of  time it takes the CPU to
recognize the interrupt and respo nd by suspending execution of the current processing
context. Another measure is the amount of time it takes to begi n interrupt processing.
In SMP Linux, interrupt processing can be done by either CPU wi th the default being to run
on CPU0. If processing is left to the default it can result in a large load on one CPU. The CPU
affinity of each interrupt can b e altered from user space to ba lance the processing load.
There are also applications that help balance interrupt loads, such as irqbalance.
Cyclictest is a Linux tool that m easures the amount of time bet ween an interrupt and the
start of the interrupt response.  The measured time is compared with the expected time, and
the difference is the latency. A number of events can delay the  actual interrupt response,
and cyclictest can be used to id entify and characterize those d elays.
Hardware Profiling
When profiling, a system can be viewed as a hierarchy of subsys tems, each having its own
performance monitoring abilities.  To completely analyze system performance, all data must
be integrated and synchronized i nto a view that allows the desi gner to see where time is
being consumed in the system.
The PL has flexibility not found i n a traditional fixed SOC, gi ving the designer a range of
implementation alternatives. Pro filing a design is one method t hat can be used to fully
understand the impacts of a specific implementation.
Send Feedback

## Page 57

UltraFast Embedded Design Methodology Guide 57
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Program Trace Module (PTM)
The PTM is a module that performs real-time instruction flow tr acing based on the Program
Flow Trace (PFT) architecture. T he PTM generates information th at trace tools use to
reconstruct the execution of  all or part of a program.
The PFT architecture assumes that  the trace tools (such as DS-5 ) can access a copy of the
code being traced. For this reas on, the PTM generates traces on ly at certain points in
program execution, called waypoi nts. This reduces the amount of  trace data generated by
the PTM. Waypoints are changes i n the program flow or events, s uch as an exception. The
trace tools use waypoints to fo llow the flow of program executi on.
For full program-flow recons truction, the PTM traces:
• Indirect branches, with targe t address and condition code
• Direct branches with only the condition code
• Instruction barrier instructions
• Exceptions, with an indication of where the exception occurred
• Changes in processor instruction set state
• Changes in processor security state
•C o n t e x t - I D  c h a n g e s
• Entry to and return from debug state when halting debug-mode i s enabled.
The PTM can also be configured to trace:
• Cycle count between  traced waypoints
• Global system timestamps
• Target addresses for taken direct branches.
Performance Monitor Unit (PMU)
The Cortex-A9 processor PMU prov ides six counters to gather sta tistics on the operation of
the processor and memory system.  Each counter can track any of the 58 events that are
significant system performance measurements. Software applicati ons, like the Xilinx System
Debugger, can make use of the eve nt counts along with software execution times to help
optimize the software. Xilinx dr ivers provide access to this in formation so that software
applications can retrieve this information from the driver and display it.
Send Feedback

## Page 58

UltraFast Embedded Design Methodology Guide 58
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Level 2 (L2) Cache Event Counters
The PL310 L2-cache controller incorporates two counters that al low monitoring of cache
events. These events can assist in understanding how applicatio ns are affecting the L2
cache and how they might be opti mized. Xilinx drivers provide a ccess to this information so
that software applications can retrieve this information from t he driver and display it.
AXI Performance Monitor (APM)
The LogiCORE IP AXI Performance Monitor is a soft IP core that can be built into the PL to
measure AMBA AXI system performa nce metrics in the PL. The perf ormance monitor
measures bus latency of masters/ slaves (AXI4/AXI3/AXI4-Stream) in a system, the amount
of memory traffic over specific durations, and other performanc e metrics. This core can also
be used for real-time profilin g of software applications.
The APM monitors the AXI system non-intrusively so that no CPU processing is required.
However, software on the ARM CPU can initialize monitoring of s pecific data and then
gather the results from the APM,  which is minimally intrusive i n system profiling. Xilinx
drivers provide access to this in formation so that software app lications can retrieve the
information from the driver and d isplay it. The APM can also be  configured by the System
Debugger in the profile mode.
The APM includes the following capabilities that can be helpful  during profiling:
• Studying the latencies of any AXI-based slave, such as a memor y controller, and tuning
the core.
• Obtaining system-level metrics,  such as write-throughput, read -throughput, average
interconnect read-latency, and others.
• Analyzing the transaction laten cies and identifying the agent causing more idle cycles
in the transactions.
• Comparing two sim ilar AXI agents.
• Counting external events (other  than AXI), such as FIFO overfl ow/underflow, interrupts,
and others.
• Logging specific events on the monitor slots, a nd then reconst ructing and analyzing
the behavior/performance.
Ethernet Statistics Registers
The Gigabit Ethernet Controllers contain statistics registers t hat are accessible to software
through low-level inte rfaces. The statistics registers record c ounts of various  event types
associated with transmit and rec eive operations. The counts are  helpful for profiling and
analyzing network performance.  Xilinx drivers pr ovide access to  this information so that
software applications can r etrieve it and display it.
Send Feedback

## Page 59

UltraFast Embedded Design Methodology Guide 59
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Software/Hardware Partitioning
With the help of software profilin g, compute-intensive function s within an application can
be identified. These functions ca n then be compiled into hardwa re and migrated into the PL
for higher performance.
At the interface between hardware and software is a communicati on mechanism that allows
data exchange between the two. T he parameters of the accelerate d function are passed to
or made available to the hardwar e accelerator in PL, and the re sult of the hardware
computation is returned or m ade available to software.
This communication can be done over one of the PS AXI ports (AX I_ACP, AXI_HP, or slave
AXI_GP) using any of the follo wing data movement schemes:
• Memory-mapped registers
• AXI-Stream FIFO
•A X I - D M A
The choice of the port and the data mover employed by the hardw are is influenced by the
data transfer size, the resources required to implement the com munication mechanism, and
any latency requirement. Some of the most commonly used solutio ns are discussed below.
Implementing memory-mapped registers in the accelerator provide s the simplest form of
data communication. In one metho d, the accelerator is an AXI-sl ave. Software writes the
required computation parameters into the registers and starts t he hardware. When the
hardware is done, the accelerator either interrupts the PS or w rites to a status register-bit
polled by software. In low power applications, using the event inputs may be preferred over
interrupts. The software can then  obtain the result with a seri es of register reads. A block
diagram of this method is shown in Figure  2-14.
X-Ref Target - Figure 2-14
Figure 2-14:  Memory Mapped Register
X14189-073117
Zynq Processor System
M_AXI_GP
Zynq Programmable Logic
Register
Accelerator
AXI-Lite IC
Main
Send Feedback

## Page 60

UltraFast Embedded Design Methodology Guide 60
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Alternatively, the accelerator can act as an AXI-master and pul l data from system memory or
a PS peripheral as directed by s oftware. A block diagram of thi s method is shown in
Figure  2-15.
While the register-based solutio n is simple to implement, it wo rks best with accelerators
that have a small data set to tr ansfer across the software/hard ware boundary. There is a
software overhead for accessing i ndividual registers, which mak es the data transfer
expensive. With larger data sets , an AXI FIFO can be employed f or streaming type
interfaces. A block diagram of this method is shown in Figure  2-16.
X-Ref Target - Figure 2-15
Figure 2-15:  Memory Mapped Register With AXI Master
X-Ref Target - Figure 2-16
Figure 2-16:  Memory Mapped FIFO
Zynq Processor System Zynq Programmable Logic
Register
Accelerator
AXI-Lite IC
Main
X14190-073117
M_AXI_GP
M_AXI_HP/ACP
Zynq
Processor
System
M_AXI_GP
Zynq Programmable Logic
AXI FIFO Accelerator
AXI IC
Main
X14191-073117
Send Feedback

## Page 61

UltraFast Embedded Design Methodology Guide 61
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 2: System Level Considerations
Very often, the hardware accelerator is used to process a large  amount of data, such as in a
video based application. The dat a is stored in memory that is a ccessible by both software
and hardware in the PL, such as OCM or DDR. A DMA is used to pu ll data out of the memory
and push the data back into memory after accelerator processing . A block diagram of this
method is shown in Figure  2-17.
The Zynq-7000 All Programmable SoC ZC702 Base Ta rgeted Reference Desi gn (Vivado Design
Suite 2014.2) User Guide  (UG925) [Ref 13] is a video-processing application that implements
an edge-detection filter on a 108 0p60 video stream in both soft ware and hardware. In the
hardware implementation, a video  DMA pulls video data out of th e DDR, pipes it through
the edge-detection engine, then writes the video stream back in to DDR. Software updates
the DMA registers to contr ol the flow of video data.
X-Ref Target - Figure 2-17
Figure 2-17:  Memory Mapped DMA
Zynq Processor
System Zynq Programmable Logic
Reg        DMA
AXI-Lite  IC
Main
X14192-073117
AXI IC
Accelerator
M_AXI_GP
S_AXI_HP/ACP
Send Feedback

## Page 62

UltraFast Embedded Design Methodology Guide 62
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3
Hardware Design Considerations
This chapter covers the following hardware design issues to be considered when designing
with a Zynq ®-7000 AP SoC:
• Configuration and Boot Devices : You can boot from a variety of primary and secondary
boot devices. This section descr ibes the boot flow and boot dev ice options.
• Memory Interfaces : You can connect the DDR memory controller to a variety of DDR
memory devices, using either a 16-bit or 32-bit wide data bus. An ECC option is supported.
• Peripherals : A variety of peripherals are available in the Zynq-7000 AP So C. This section
describes the peripherals and their interaction with the Applic ation Processing Unit
(APU).
• Designing IP Blocks : IP blocks are pre-designed, pre-verified, and reusable functi onal
blocks that can help you reduce design time. This section descr ibes the process of
designing solutions containing IP blocks.
• Hardware Performance Considerations : This section describes hardware performance
metrics and methods you can use to tune the performance of AXI masters, AXI slaves,
and AXI datapaths.
• Dataflow : Dataflow within the processing  system (PS) and between the PS  and
programmable logic (PL) is described in this section.
• PL Clocking Methodology : The PL clocking methodology is covered in this section. The
different PL clock sources and th eir recommended use are descri bed.
• ACP and Cache Coherency : The ACP’s ability to provi de low-latency access to PL
masters, including optional cohe rency with the L1 cache, is des cribed in this section.
• PL High-Performance Port Access : You can use the HP ports to give the PL direct access
to the DDR controller and the on -chip memory (OCM). Design-driv en optimizations
that use the HP ports are described in this section.
• System Management Hardware Assistance : System management, including the control
of system-level parame ters based on user-specific inputs, is di scussed in this section.
• Managing Hardware Reconfiguration : You can apply partial reconfiguration to the
portion of the FPGA that is not static logic. This section desc ribes the process of
partially reconfiguring your design.
• GPs and Direct PL Access from APU : This section describes how you use the GP
interfaces for accessing registers and memory in the PL from th e APU.
Send Feedback

## Page 63

UltraFast Embedded Design Methodology Guide 63
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Configuration and Boot Devices
This section describes Zynq-7000 AP SoC boot devices and how th ey are configured. It
covers the boot flow and the role  of BootROM as an agent for pe rforming the boot
initialization sequence. Primary boot options like Quad-SPI, SD , NAND, NOR flash, and JTAG
boot mode, and secondary boot options like eMMC and PCIe in the  Zynq-7000 AP SoC are
described. The section focuses o n the boot flow and boot device  usability in system-level
scenarios. The JTAG boot mode is considered a slave boot mode a nd is always a non-secure
boot mode.
Typical Boot Flow
The boot sequence in a Zynq-7000 AP SoC involves reading the fi rst-stage boot loader
(FSBL) from external static stor age, typically NAND or NOR flas h memory. The BootROM
contains the code that is executed after power on reset, and th at code reads the FSBL from
the external static storage.
After the PS_POR_B pin is de-asse rted, hardware samples the boo t-strap pins and
configures the PS and the PLLs. Software in the PS internal Boo tROM executes, beginning
with code that configures the ARM core and peripherals necessar y to copy the FSBL image
from the chosen boot device to OCM, and then the code switches execution from the OCM.
You can copy the FSBL from the p rimary boot device mentioned ab ove or you can load it
through JTAG. Optionally, in non -secure boot mode, you can exec ute the FSBL from
Quad-SPI/NOR flash that su pports execute-in-place.
Figure  3-1 depicts the typical boot flow.
You can boot a Zynq-7000 AP SoC in both secure and non-secure m odes. Secure mode boot
is only possible with static memories whereas non-secure mode b oot is possible with both
JTAG and static memories. JTAG boot is primarily used during th e system development
phase.
X-Ref Target - Figure 3-1
Figure 3-1:  Typical Boot Flow
BootROM FSBL SSBL OS APPLICATION
X14131-073117
Send Feedback

## Page 64

UltraFast Embedded Design Methodology Guide 64
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Selecting a Boot Device
The following primary boot opti ons are available for Zynq-7000 AP SoCs:
• Quad-SPI with optional execute-in-place mode
•N A N D  f l a s h
• NOR flash with optional execute-in-place mode
• SD memory card
•J T A G
The following secondary boot options are available for Zynq-700 0 AP SoCs:
• eMMC
• PCIe, Ethernet, USB, UART, or a custom FPGA interface
You can select a BootROM device using any of the following crit eria:
• The device works with the Zynq- 7000 AP SoC BootROM and is supp orted by Xilinx ®
tools (iMPACT, SDK) and higher-level software such as U-Boot an d Linux. You can find a
list of Xilinx-recommend ed devices for different boot options i n Xilinx Answer Record
50991  [Ref 69] .
• The device meets the applicatio n's configuration pin requireme nts. For example, the
QSPI boot option requires fewer pins than the NAND or NOR boot options.
• The device meets the application's size requirements. NAND and  SD boot options
provide higher memory density th an the QSPI and NOR boot option s.
• The device meets the applicatio n's configuration speed require ments. QSPI is the
fastest available boot option.
• Device management can be adequa tely handled by the application . NAND devices can
be more difficult to manage than other boot options. Bad blocks  require design
decisions on how they will be  managed when they occur.
Your choice of boot device affects the number of pins required,  the maximum memory size,
the boot time, and the device management software complexity. Table 3-1 summarizes the
design trade-offs.
Send Feedback

## Page 65

UltraFast Embedded Design Methodology Guide 65
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
More information on each boot opt ion is provided in the followi ng sections.
Quad-SPI with Optional Execute-in-Place Mode
The BootROM can detect the Quad- SPI interface's intended I/O wi dth using the
width-detection parameter value ( 0xAA995566 ) and image-identification parameter value
(0x584C4E58 ). Quad-SPI is the fastest configuration solution available. On ly the SD
memory card boot option has a lower pin count. You can access Q uad-SPI as linear memory
in Zynq-7000 AP SoCs. Device mana gement is simpler because bad blocks are of less
concern than they are in other d evices, such as NAND flash. In linear mode, Quad-SPI
supports up to 16 MB in single m ode and 32 MB in  dual mode. Mor e than 16 MB is also
supported when the QSPI is opera ted in IO mode. For the execute -in-place option, the
BootROM uses the linear addressing feature of the Quad-SPI cont roller for non-secure boot
modes. Multiboot is possible with QSPI.
For information on which vendor flash devices are currently sup ported by the Zynq-7000 AP
SoC tools, refer to Xilinx Answer Record 50991  [Ref 69].
Table 3-1:  Flash Memory Comparison
Peripheral Pins Boot Device XIP Limitations Read/Write Max Size Boot
Time
QSPI 7 single,
8 dual
stacked,
13 dual
parallel
Yes.
Boot image
in 16MB
single and
stacked,
32MB for
parallel.
Yes Capacity limited to 16MB
per device as a boot
device.
Very slow erase/write –
usually used as read only.
Often used in with eMMC
or SD card.
Byte/Block 16MB in
Liner mode,
128MB in
IO mode,
per QSPI.
Each
controller
can support
up to two
QSPIs.
Fast
NAND X8–14
X16–22
Yes
Boot image
in the first
128MB
No Requires software
management of ECC, wear
leveling, bad block.
Requires file systems for
raw flash such as JFFS2 or
UBIFS.
Requires ECC.
Hardware support for
1-bit ECC only.
Block/Block 1GB Medium
SD 6 Yes No Requires Mechanical
connector
Block/Block Any size Slow
Parallel
NOR
37 Yes Yes Support capacity
comparable to large QSPI,
but with high pin count.
Byte/Block 64MB Fast
eMMC 6 No No Cannot boot from eMMC Block/Block Any size N/A
Send Feedback

## Page 66

UltraFast Embedded Design Methodology Guide 66
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
NAND Flash
The NAND flash boot option is an inexpensive solution supportin g large density devices.
The only restriction is the boot image must be located within t he first 1 GB of address space
in the NAND flash device. Perfo rmance of this boot option is lo wer than that of the
Quad-SPI boot option. Typical NAND flash solutions require more  pins and have lower
memory bandwidth than Quad-SPI s olutions. The application desig n needs to have a
mechanism for managing bad clock s, including during boot. Multi boot is possible with
NAND.
Micron (on-die ECC) and Spansion (S34) are the recommended NAND  boot device families.
Micron NAND devices typically require multi-bit ECC, which nece ssitates using only devices
with on-die ECC support.
NOR Flash with Optional  Execute-in-Place Mode
You can access NOR flas h as linear memory with Zynq-7000 AP SoC s. Also, bad blocks are
of less concern than they are in  NAND flash devices. NOR flash density is comparable to
Quad-SPI. It uses more MIO pins compared to other boot options.  A typical NOR flash (byte
peripheral interface) uses 40 MI O pins and can support up to 64  MB.
For information on which vendor flash devices are currently sup ported by the Zynq-7000 AP
SoC tools, refer to Xilinx Answer Record 50991  [Ref 69].
SD Memory Card
SD memory cards have higher dens ities than that of the NAND fla sh boot option. Devices
are generally managed as a file s ystem. Bad blocks do not need to be managed by the
application design. SD memory is slower than the Quad-SPI boot option, and the SD cards
require an on-board connector. eM MC devices are not primary boo t devices but you can
use them as a secondary boot source. In SD boot mode, BootROM d oes not perform header
search and a multi-boot option is not supported. You can improv e boot time in the SD boot
mode by setting the CPU clock di visor to 2 in the ARM_CLK_CTRL register ( 0x1F000200 ).
JTAG
In JTAG boot mode, you can select the independent JTAG mode to support a debugger
connected to the ARM DA P controller and anot her tool connected to the Xilinx PL TAP
controller. The Xilinx PL TAP co ntroller is accessible using th e PL JTAG interface connected
to dedicated PL pins. Access to the ARM DAP controller (for ano ther tool) is done using the
EMIO JTAG interface. This requires downloading a bitstream into  the PL. You can download
the bitstream using the Xilinx PL TAP controller.
Send Feedback

## Page 67

UltraFast Embedded Design Methodology Guide 67
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
eMMC
You can use the eMMC secondary boot option when QSPI is the pri mary boot option and a
small QSPI memory is used. Typic ally, the FSBL will be loaded i n to the QSPI and other
partitions will be loaded into  eMMC. Xilinx recommends using eM MC with the SDIO
controller only in standard speed mode (max frequency of 25 MHz ).
PCIe, Ethernet, USB, UART, and Custom FPGA Interface
You can also implement secondary  boot using PCIe, Ethernet, USB , UART, or a custom FPGA
interface. You can select an opt ion appropriate to your applica tion. The PCIe-based
secondary boot optio n is discussed below.
PCIe secondary boot uses the PC Ie protocol to fetch the second- stage boot loader from a
host system that implements a PCIe root complex. The PCIe block  in the Zynq-7000 AP SoC
PL implements the end point function and forms the communicatio n link with the PCIe root
complex. You can fetch the FSBL image from external memory (QSP I, NAND, or NOR flash)
and after FSBL execution is done, the FSBL can fetch the second ary U-Boot image from the
host-system memory over PCIe.
To implement this option, you n eed to generate a bitstream inst antiating the PCIe block in
the design. For example, you can implement the programmed IO (P IO) design using a Xilinx
7 Series PCIe IP block. You also need to implement a set of PL registers for handshake status
between the APU and the host CPU, and connect the register inte rface to the PS master GP
port. The boot flow is:
• The FSBL will be loaded fro m the primary boot device.
• The APU waits until the FSBL per forms the peripheral initializ ation process.
• The FSBL programs the bit file w ith the PIO design and handsha ke status register set.
• The APU programs the bitDone register after the bit file progr amming is done.
• The host PIO driver reads the b itDone register and writes the U-Boot.elf  file to PL
block RAM.
•A f t e r  U-Boot.elf  is written, the status is writt en to the U-BootDone register.
• The APU polls the U-BootDone bit, and after it is done copies the file to PS DDR
memory.
Send Feedback

## Page 68

UltraFast Embedded Design Methodology Guide 68
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
File System
The flash choice influences the file system that can be impleme nted. The file system choices
described below are specific to Linux, but provide a good outli ne of the issues to be
considered.
eMMC and SD cards have a built-i n controller that runs the Flas h Translation Layer (FTL)
firmware, allowing the device to appear to the OS as a block de vice. Conventional file
systems, such FAT or ext3, work with block devices and can be i mplemented using these
devices.
A raw flash device (such as NAND, QSPI, or parallel NOR) requir es software management so
that reads-from and writes-to me mory cells function properly. L inux uses the memory
technology device (MTD) subsyste m to provide an abstraction lay er between the
hardware-specific devi ce drivers and higher-level applications.  Linux supports file systems
that are layered on top of MTD devices, such as JFFS2 and UBIFS . These file systems are
designed to include software man agement algorithms to handle is sues like wear leveling
and bad block management, and mu st be used for the device to fu nction properly.
Optimizing Boot Time
The BootROM settings used to read from each flash device type a re selected for maximum
compatibility, often at the expe nse of performance. Boot interf ace performance can be
improved by setting the corresponding controller registers in t he register initialization
portion of the BootROM header. T he settings depend on the devic es being used and the
board layout parameters. Optimiz ed register values should be ob tained from vendor data
sheets for the devices  used. Examples of optimized values for e ach boot device can be
found in the Register Initializat ion to Optimize Boot Times sec tion of the Zynq-7000 All
Programmable SoC Technical Reference Manual  (UG585) [Ref 4] and the Xilinx Answer Record
55572  [Ref 71]. The optimized values can be added to the boot image header us ing
Bootgen. Refer to the “Using  Bootgen” appendix in the Zynq-7000 All Programmable SoC
Software Developers Guide  (UG821) [Ref 7] for more information. The BootROM
Performance section of the Boot and Configuration chapter in th e Zynq-7000 All
Programmable SoC Technical Reference Manual  (UG585) [Ref 4] provides methods to
improve timing and bandwidth res ults during different boot stag es.
Send Feedback

## Page 69

UltraFast Embedded Design Methodology Guide 69
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Case Study: Variations in QSPI Boot Time
This case study describes boot-t ime measurements done on a Xili nx ZC702 board using
different QSPI devices running a t 100MHz, and varying the PS fr equency.
The boot time (measured from U-B oot start to the Linux prompt) for a 32 MB Spansion
single device with the PS running  at 667 MHz is approximately 3 036 milliseconds. The boot
time for a 64 MB Spansion dual-p arallel device with the PS runn ing at the same frequency
is approximately 2994 millisecond s. Therefore, using a dual-par allel QSPI device that is
twice the size of a single QSPI device improves boot time by ap proximately 42 milliseconds,
without changing the PS frequency.
Changing the PS frequency also affects boot time. As mentioned above, the boot time for a
32 MB Spansion single QSPI device with the PS running at 667 MH z is approximately 3036
milliseconds. Using the same QSPI device but increasing the PS speed to 867 MHz results in
a boot time of approximately 2523 milliseconds. Therefore, with out changing the QSPI
device, increasing the PS operat ing frequency from 667 MHz to 8 67 MHz improves boot
time by approximately 513 milliseconds.
Memory Interfaces
DDR
The DDR multi-protocol memory c ontroller in the Zynq-7000 AP So C supports 1.8V DDR2,
1.2V LPDDR2, 1.5V DDR3, and 1.35V DDR3L. It can be configured t o provide a 16-bit or
32-bit wide data bus. All device s support the 16-bit and 32-bit  data bus width options,
except the 7z010 CLG225 device th at supports only the 16-bit da ta bus width. The
controller optionally supports EC C in 32-bit configurations, wi th 16 data bits and 10 check
bits. When ECC is enabled the data width is limited to 16 bits.  A 1 GB address map is
allocated to the DDR. However, if ECC is used, only 512 MB of a ddress space is available.
The DDR memory contro ller contains three maj or blocks: an AXI m emory port interface
(DDRI), a core controller with a transaction scheduler (DDRC), and a controller with digital
PHY (DDRP). The details of each block and other controller aspe cts are described at this link
in the Zynq-7000 All Programmable So C Technical Reference Manual  (UG585) [Ref 4].
The controller includes  a digital PHY with a dedicated set of I /Os. On the fastest speed
grade for some Zynq-7000  AP SoC devices, the maximum supported bus clock is 666 2/3
MHz in DDR3 mode. The maximum su pported bus clock is 533 MHz in  DDR3 mode for all
other speed grades. The theore tical maximum bus bit-rate is:
Data transfer rate = 666 2/3 MHz * 2 bits (for double data rate) = 1333 Mb/s per data IO
Send Feedback

## Page 70

UltraFast Embedded Design Methodology Guide 70
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Using the maximum bus width of 3 2 bits, the maximum bus bandwid th is 42.6 Gb/s, or
5.3 GB/s. This bandwidth is shared by multiple masters connected us ing the four DDRI slave
ports as shown in Figure  3-2. The DDRI block connects to  four 64-bit synchronous AXI
interfaces to serve multiple AXI  masters simultaneously. Each A XI interface has its own
dedicated transaction FIFO. Port  S0 is connected to the L2-cach e and services only the PL
CPU and ACP interfaces to ensure  low latency and fast access. P ort P1 is shared by all
central-interconnect masters, such as PS peripherals and AXI GP  ports. The four PL AXI_HP
interfaces are multiplexed down in pairs and are connected to p orts 2 and 3, as shown in
Figure  3-2.
The maximum bus bandwidth is 5.3 GB/s, but it is not sustainabl e. The DDR efficiency must
consider the overhead associated  with DDR and is influence by t he data access pattern.
Address patterns that minimize p age and row changes reduce page  and row change
overhead, resulting in  higher utilization an d higher system thr oughput. Refer to the
“Row/Bank/Column Address Mapping” subsection of the “DDR Memory  Controller” chapter
(available at this link ) in the Zynq-7000 All Programmable So C Technical Reference Manual
(UG585) [Ref 4].
How PL AXI masters are connected to the HP ports also determine s system throughput.
Multiple AXI masters are more likely to produce random address accesses that cause more
page misses, resulting in lower DDR efficiency. In Figure  3-2, the AXI_HP to DDR
interconnect multiplexes four PL  AXI_HP down to two pairs conne cted to ports S2 and S3,
both arbitrated by the interconn ect. When there are only two PL  AXI masters, higher
performance can be achieved by c onnecting the masters to port A XI_HP0 and AXI_HP2, or
AXI_HP1 and AXI_HP3, thus using both port 2 and 3 of the DDR co ntroller. In a typical
Linux-based video design, achievable system bandwidth from the AXI_HP ports is about
50%. This is described in Designing High-Performance Vide o Systems with the Zynq-7000 All
Programmable SoC  (XAPP792) [Ref 36].
The controller DDRC block includes a three-stage arbiter for im proved DDR control latency.
Latency can be controlled using register settings. For details on managing DDR latency,
refer to the “DDRC Arbitration” s ubsection of the “DDR Memory C ontroller” chapter
(available at this link ) in the Zynq-7000 All Programmable So C Technical Reference Manual
(UG585) [Ref 4].
Send Feedback

## Page 71

UltraFast Embedded Design Methodology Guide 71
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
To facilitate high-bandwidth ope ration, the DDR interface timin g must be properly
initialized and calibrated. DDRP includes a DRAM training featu re to help automatically
determine the timing delays requi red to align data to the optim al window for reliable data
capture. This feature is described in the “Initialization and C alibration” subsection of the
“DDR Memory Controller” chapter (available at this link ) in the Zynq-7000 All
Programmable SoC Technical Reference Manual  (UG585) [Ref 4].
The Zynq-7000 AP SoC tool flow helps automate the DDR bring-up.  To do this, the PS DDRC
board parameters need to be co nfigured in accordance with Xilinx Answer Record 46778
[Ref 67]. This will import the delay cha racteristics of DDR signals on the board during the
hardware design process. Those characteristics are used to dete rmine the initial values used
by the automatic training algori thm, or for calculating static interface timing when the
automatic algorithm is not supported by the particular DDR stan dard. The timing values are
part of the design's hardware platform specification and are ex ported to the SDK and used
in PS initialization code that is  called by the FSBL. DDR is no t used by the BootROM.
X-Ref Target - Figure 3-2
Figure 3-2:  DDR Memory Controller Block Diagra m and Interconnect to AXI_HP Ports
S0 S1 S2 S3
M0 M1 M2
AXI_HP
to DDR
Interconnect
AXI HP0 AXI HP1 AXI HP2 AXI HP3
S0 S1 S2 S3
CPUs and
ACP
Other Bus
Masters
DDR
Memory
Controller
DDR Interface
DDR Core
DDR PHY
to OCM
DDR DRAM Memory
Devices
16 or 32 bits
Zynq Device Boundary
X14178-073117
Send Feedback

## Page 72

UltraFast Embedded Design Methodology Guide 72
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
QSPI
The PS QSPI flash controller commu nicates to an external serial  flash memory using the
QSPI interface. The memory flash  cells are arranged in parallel  and are sometimes referred
to as NOR flash. While this configuration is less dense and has  smaller capacity than NAND
flash memory, it allows single-b yte reads anywhere in the array . For reads, it can behave like
a standard address-mapped memory  and is well-suited for code st orage. Also, it supports
the execute-in-place (XIP) featu re where a CPU can execute code  directly out of QSPI
without reading the code into DDR or OCM first. The Zynq-7000 AP SoC Bo ot - Booting and
Running Without External Memory Tech Tip  wiki page [Ref 61] provides a “hello world”
example design on a ZC702 board using XIP.
Of all the flash memories support ed by a Zynq-7000 AP SoC, QSPI  has the highest read
performance and provides the fastest boot solution with a very low pin count requirement.
It supports page-based write and  sector-based erase, but at a s ubstantially s lower rate
compared with other types of devices. For a cost-effective solu tion with fast boot time and
large memory capacity, you can use a small QSPI as the primary boot device for storing the
FSBL. All other partit ions can be placed in a larger flash, suc h as eMMC or SD. For
information on how to implement such a system, refer to the “eM MC Flash Devices” section
(available at this link ) in the Zynq-7000 All Programmable SoC Software Developers Guide
(UG821) [Ref 7].
The QSPI flash controller supports three different modes of ope ration: I/O mode,
linear-addressing mode, and legacy SPI mode. In linear-addressi ng mode, the AXI
transactions received by the QSP I controller are  automatically translated into the
corresponding command a nd data transactions on the QSPI bus con nected to the flash
device. The controller supports only 24-bits of flash address, therefore the maximum size of
QSPI is limited to 16M B in linear mode. BootROM accesses the QS PI in linear mode. When
QSPI is used in XIP mode, the le ngth of the FSBL is limited to the capacity of the QSPI in
linear mode, minus the length of t he boot header. When XIP mode  is enabled (through the
boot header), instead of copying the FSBL to OCM, BootROM hands  control to the FSBL
executing directly from QSPI flash. When QSPI is not used in XI P mode, BootROM copies the
FSBL into OCM for execution. In this case, the size of FSBL is limited by the 192  KB OCM
capacity. The first three quarters of OCM is located at low mem ory, and the top one quarter
is mapped to high memory. The FSBL could use most of the top on e quarter for items such
as stack and heap.
In I/O mode, software composes t he command and data in the TXD registers, and the
controller drives the content of  the register to the flash memo ry in the proper format. The
data driven by the flash memory is shifted into the correspondi ng RXD registers and the
data is extracted by software. U sing I/O mode, the software can  issue flash commands to
specifically modify specific reg ister bits inside the flash mem ory, thus expanding the QSPI
flash address space by effectively switching between pages. Usi ng this method, the
controller can support up to 128 MB per QSPI. For more informati on on QSPI I/O mode,
refer to the I/O mode section in  the Quad-SPI Flash Controller chapter (available at this link )
of the Zynq-7000 All Programmable SoC Technical Reference Manual  (UG585) [Ref 4].
Send Feedback

## Page 73

UltraFast Embedded Design Methodology Guide 73
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
When a QSPI larger than 16MB is used on the board, any Zynq-700 0 AP SoC platform reset
must also trigger a reset to the  QSPI so that the page register  is reset. This ensures that
when BootROM reads from address 0x0 in linear mode it can acces s the boot image. Refer
to Xilinx Answer Record 57744  [Ref 72] for more information on the reset requirement when
using flash devices larger than 16 MB.
If either RSA encryption or XIP mode is used to store boot imag es in flash devices larger
than 16 MB, the boot image cannot be placed at offset 0x0. Inst ead, the boot image can be
located at offset 0x0+32K. If the  image is located at 0x0, a du plicate header image can be
located at offset 0x0+16MB, or a single x1 QSPI can be used.
Different QSPI flash devices req uire different dummy clock cycl es depending on the QSPI
clock frequency and the type of command used to perform the rea d. Depending on the way
the QSPI is configured on the bo ard (x1, x2, x4, single, stacke d, or parallel) and the
particular flash device used, th e controller's LQSPI_CFG regist er must be set appropriately
for proper communication with th e flash device. When using Xili nx-supported QSPI flash
devices, the Xilinx PS QSPI devi ce driver automatically writes the appropriate values into the
LQSPI_CFG register. For informati on on which vendor flash devic es are currently supported
by the Zynq-7000 AP SoC tools, refer to Xilinx Answer Record 50991  [Ref 69].
BootROM automatically issues read commands using either fast re ad (x1), quad output read
(x4), dual-output fast read (x2) , single mode, or parallel mode  by examining the
width-detection value and the im age-identification value in the  BootROM header. Based on
the values, BootROM uses the wid est supported I/O bus width to read data from the
Quad-SPI device, but sends commands in x1. BootROM writes a set  of initial values into the
LQSPI_CFG register. Further details on those values can be foun d in the Quad-SPI Boot
subsection of the Boot and Confi guration chapter (available at this link ) of the Zynq-7000
All Programmable SoC Technical Reference Manual  (UG585) [Ref 4].
In a high-speed QSPI application where the memory-interface clo ck is greater than 40 MHz,
QSPI feedback mode must be used. For more information on the QS PI Feedback clock, see
the Quad-SPI Feedback Clock subsection in the Quad-SPI Flash Co ntroller chapter (available
at this link ) of the Zynq-7000 All Programmable So C Technical Reference Manual  (UG585)
[Ref 4].
The QSPI can be programmed by U -Boot, Linux, iMPACT, and the SD K.
The QSPI flash controller details can be found in the Quad-SPI Flash Controller chapter
(available at this link ) of the Zynq-7000 All Programmable SoC Technical Reference Manual
(UG585) [Ref 4].
Send Feedback

## Page 74

UltraFast Embedded Design Methodology Guide 74
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Static Memory Controller
The static memory controller has two interface modes: a NAND fl ash interface mode and a
parallel port memory in terface mode. The NAND flash interface m ode supports NAND
flash, while the parallel-port i nterface mode supports NOR flas h and asynchronous SRAM.
Because both QSPI and NOR flash use NOR-based memory cells, and  because QSPI is
limited to 16MB in linear mode, capacity is the differentiating  factor in selecting NOR flash
over QSPI. However, because the static memory controller limits  the number of address
lines to 26 bits, it supports NOR flash sizes only up to 64MB. The 16MB QSPI limit applies
only during boot (the amount of data read by BootROM must not e xceed 16MB). After
BootROM loads FSBL into either OCM or DDR memory, the QSPI cont roller can switch into
I/O mode and access up to 128MB of  memory with the support of t he flash-device's page
register. Consequently, the NOR- flash controller's ability to s upport 64MB devices (at the
expense of 40 pins) as compared to 128MB devices supported by Q SPI (using just 8 pins)
makes QSPI a preferred so lution over NOR flash.
The following section describes t he NAND-flash interface mode. For more information
about using the para llel-port memor y interface, refer to the Zynq-7000 All Programmable
SoC Technical Reference Manual  (UG585) [Ref 4].
NAND Memory Controller
In NAND flash the memory cells a re laid out in series, resultin g in more densely-packed
memory cells, higher capacity per silicon area, and cheaper per -bit cost than NOR flash. The
NAND flash controller can support up to 1GB of external NAND fl ash with either an 8-bit or
16-bit I/O bus for add ress/data/command. It supports the Open N AND flash Interface 1.0
specification.
The dense memory-cell packing ca uses the cells to be stressed d uring programming and
erase cycles, making t hem more prone to bit errors. ECC is used  to mitigate those errors.
The NAND flash controller includ es hardware support for 1-bit E CC correction. Software is
used to run flash management alg orithms that make use of the EC C data to manage the
various error modes, deal with bad blocks, homogenize wear acro ss the memory cells, and
improve cell endurance  and data retention.
Because the controller only suppo rts 1-bit ECC, only NAND devic es with on-chip ECC or
one-bit ECC can be used with Zynq-7000 AP SoCs. Currently, only  single-level-cell (SLC)
devices meet the ECC criteria an d multi-level-cell (MLC) device s are not supported. Also, the
controller only supports a singl e chip select. Xilinx supported  NAND devices range in size
from 128MB to 1GB, in both x8 a nd x16 configurations. Xilinx of ficially supports NAND
devices from Micron and Spansion . For information on which vend or flash devices are
supported by the Zynq-7000 AP SoC tools, refer to Xilinx Answer Record 50991  [Ref 69].
Even in a high-capacity NAND device, the Zynq-7000 AP SoC BootR OM will look for a boot
image to start in the first 128MB.  Therefore, the start of both  standard and fallback boot
images (if used) must be gin in the first 128MB.
Send Feedback

## Page 75

UltraFast Embedded Design Methodology Guide 75
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Communication with the NAND flash is based on a set of AC timin g parameters that vary
from device to device. For a Zynq-7000 AP SoC to communicate wi th a NAND device using
the correct timing, a designer sh ould input the relevant timing  parameters into the CS0
column on the SMC Timing Calculation page based on the device's  AC timing values. This is
shown in Figure  3-3.
The CS0 cycle is automatically c alculated based on the NAND clo ck frequency. The values
are exported to the SDK's PS ini tialization code as part of the  design's Hard ware Platform
Specification. The initializatio n code writes those values to t he smc.SET_CYCLE register.
BootROM reads from NAND flash pr ior to executing PS initializat ion code, using a set of
initial values stored in the smc.SET_CYCLE register. Further de tails on those values can be
found in the NAND Boot subsection  of the “Boot and Configuratio n” chapter in the
Zynq-7000 All Programmable So C Technical Reference Manual  (UG585) [Ref 4].
In NAND flash, reads and writes occur in pages, while erasures occur in blocks. Because
NAND flash does not behave like random access memory, Linux sys tems use it as a memory
technology device (MTD) that provides an abstraction layer, all owing software to access the
device using the MTD subsystem API. That API is common among di fferent flash types and
technologies. MTD is not a block device and it lacks the softwa re management algorithms
to handle issues like wear leve ling and bad block management. I nstead of traditional file
systems like ext2, ext3, and FAT (which work on top of block de vices), the file system must
be designed to work on top of raw flash, such as JFFS2 or UBIFS . JFFS2 works on top of MTD
subsystems. UBIFS works on top o f UBI subsystems, and those wor k on top of MTD
subsystems to provide software management algorithms required f or NAND devices.
X-Ref Target - Figure 3-3
Figure 3-3:  SMC Timing Page Example
Send Feedback

## Page 76

UltraFast Embedded Design Methodology Guide 76
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Peripherals
The memory-mapped peripherals present in the Zynq-7000 AP SoC P S, and the interaction
of those peripherals with the APU and the memory controller, ar e described in this section.
It is assumed that the reader is familiar with the AMBA bus top ology (AHB and APB) and has
an understanding of the USB, CAN , UART, Ethernet, and SPI proto cols.
The Zynq-7000 AP SoC peripherals can be broadly categorized as:
• PS peripherals
• PL peripherals
The PS peripherals are hard-wired peripherals and are implement ed as part of the standard
ASSP implementation. The PL peri pherals are programmable and re configurable on the fly.
This section covers the PS peripherals and the PL peripherals a re covered in the following
section.
The PS peripherals are memory mapped and the peripheral memory map is predefined.
Peripherals implement the Advanc ed Microcontroller Bus Architec ture (AMBA)
protocol-compliant bus architecture and are connected to either  the central interconnect or
part of the application processo r unit. They communicate with t he ARM Cortex-A9
processor using AMBA-specified transactions. The peripherals ar e ARM TrustZone security
aware and can optionally deny no n-secure accesses coming from a  non-secure master.
Peripherals connected to the cent ral interconnect can optionall y be routed to the PL that
enables PL access.
Send Feedback

## Page 77

UltraFast Embedded Design Methodology Guide 77
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Figure  3-4 shows the top-level block diagr am of the peripherals present i n PS.
Peripheral Descriptions
The following are key periphera ls present in the PS block.
USB Peripheral
The PS USB controller is USB 2.0 compliant and can operate in a ny of the following modes:
•D e v i c e  m o d e
•H o s t  m o d e
• On-The-Go (OTG) mode
X-Ref Target - Figure 3-4
Figure 3-4:  PS Peripheral Block Diagram
2X UART
Memory Peripherals
QSPI, NAND, NOR
Central
Interconnect
DDR Controller
SWDT
TTC
SLCR
2X USB
2X GEM
2X SDIO
2X CAN
2X SPI
2X I2C
GPIO
APU
L1/L2 CacheOCM
EMIO
MI
O
Processing System 7
PL Master/Slave PL Master
PL Interconnect
X14138-073117
Send Feedback

## Page 78

UltraFast Embedded Design Methodology Guide 78
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
The USB controller attaches to an  external PHY using the ULPI i nterface, which is
implemented as an 8-line SDR data bus using the MIO. The ULPI P HY is not part of the USB
controller, and you can implement any ULPI-compliant PHY to con nect to the USB controller
in the Zynq-7000 AP SoC. The port -controller indication, power select, and power failure
signals can be routed to the PL via EMIO. The sideband signals can also be routed to the
SelectIO™ pins. The USB controlle r has a built-in DMA engine wi th a transmit and receive
FIFO that transfers the data to and from memory using the AHB b us.
Refer to the USB Host, Device, a nd OTG Controllers chapter (ava ilable at this link ) of the
Zynq-7000 All Programmable So C Technical Reference Manual  (UG585) [Ref 4] for more
information.
Data Flow
The data transferred by the DMA from memory is encapsulated usi ng the USB 2.0 protocol
format and is transmitted over t he ULPI interface to the PHY.
System Level Considerations
The USB controller is clock ed from two clock domains:
• The AHB interface is clocked by the CPU_1x clock domain.
• The USB protocol engine and the  port controller interface use the 60 MHz clock
generated by the ULPI PHY.
You can use three different methods to reset the USB controller :
• You can trigger a cont roller reset with a PS reset by writing to the USB command
register using the APB interface.
• You can trigger a ULPI PHY reset  under the control of a GPIO s ignal.
• You can trigger a USB bus reset with the auto reset feature in  OTG mode.
You can configure the controller as a USB host, USB device, or as an OTG. The configuration
is determined by your applicatio n. The controller host mode req uires the USB host
controller interface be built in  the Linux image. You can set d ifferent device mode options,
either USB mass storage, isochro nous, or interrupt-based. For a  high-speed endpoint, the
maximum packet size is 512 bytes for bulk transfers and 1024 by tes for isochronous devices.
You can use isochronous mode for  streaming applications, such a s video.
Send Feedback

## Page 79

UltraFast Embedded Design Methodology Guide 79
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Ethernet Peripheral
The gigabit Ethernet MAC (GEM) implements a 10/100/1000 Mb/s Et hernet MAC
compatible with the IEEE 802.3-200 8 standard. It is capable of operating in either half mode
or full-duplex mode at all three speeds. You can configure each  of the two GEM controllers
independently. To save pins, eac h controller uses an RGMII inte rface through the MIO.
Access to the PL is through the EMIO which provides the GMII in terface.
You can create other Ethernet communication interfaces in the P L using the GMII available
on the EMIO interface.
Because the GEM controller in the Zynq-7000 AP SoC provides onl y the MAC function, you
must implement a separate PHY.
Data Flow
The DMA block present in the con troller fetches data from syste m memory using the AHB
bus and stores data in the trans mit FIFO. The FIFO data is conv erted to Ethernet protocol
format by the controller and is s ent to the Ethernet PHY using an RGMII or GMII interface,
depending on whether the user se lects the MIO or  EMIO interface .
Registers are used to configure the features of the MAC, select  different modes of
operation, and enable and monito r network management statistics
The controllers provide MDIO interfaces for PHY management. You  can control the PHYs
from either of the MDIO interfaces.
System Level Considerations
The GEM controller offers a numbe r of system-level features tha t can be implemented
based on system requirements. For example, you can enable check sum off-loading in a
system that requires better network efficiency and less CPU uti lization. Another
system-level consideration is implementation of precision time protocol (PTP) as defined in
IEEE 1588. The controller detects and responds to PTP events an d requires a PTP compliant
network peer.
You can optionally route Etherne t packets from the controller t o the PL using the DMA
interface. This option may requi re implementation of packet acc eleration or packet
inspection IP in the PL.
The GEM controller does not suppo rt jumbo frames. If you requir e jumbo frame support,
you can implement the Xilinx AXI Ethernet MAC IP in the PL. You  can use the AXI DMA IP to
read and write Ethernet frames to and from PS DDR memory. The G EM controller does not
support 3.3V IO voltage. Refer to the Gigabit Ethernet Controll er chapter (available at this
link) in Zynq-7000 All Programmable So C Technical Reference Manual  (UG585) [Ref 4] for
more information.
Send Feedback

## Page 80

UltraFast Embedded Design Methodology Guide 80
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
SDIO Peripheral
The SD/SDIO controller communicate s with the SDIO devices and S D memory cards. You
can route the SDIO interface through the MIO multiplexer to the  MIO pins, or through the
EMIO to SelectIO pins in the PL.  The controller can support SD and SDIO applications in a
wide range of portable low-pow er applications such as 802.11 de vices, GPS, WiMAX, and
others.
The SD/SDIO controller is compatible with the standard SD Host Controller Specification
Version 2.0 Part A2 with SDMA (s ingle operation DMA), ADMA1 (4 KB boundary limited
DMA), and ADMA2 support. ADMA2 allows data at any location and any size to be
transferred in a 32-bit system memory using scatter-gather DMA.  The core also supports up
to seven functions in SD1 and SD4, but does not support SPI mod e. The core does support
the SD high-speed (SDHS) and SD H igh Capacity (SDHC) card stand ards. You should be
familiar with the SD2.0/SDIO 2.0 specifications [Ref 91].
The SD/SDIO controller is accessed  by the ARM processor via the  AHB bus. The controller
also includes a DMA unit with an internal FIFO to meet throughp ut requirements. The
SD/SDIO controller complies with  the MMC 3.31 specification.
Data Flow
The SD/SDIO controller has a DMA built into the controller that  can fetch data from system
memory using the AHB bus. The co ntroller implements a pair of F IFOs to read and write
data to the attached card to maximize throughput. The data is w ritten to the attached card
or read back based on an SD-spec ific command initiated by the A PU.
System Level Considerations
SD cards are essentially NAND fla sh devices with built-in contr ollers that implement the
flash translation layer (FTL). The FTL handles ECC, block manag ement, and wear leveling so
that the memory behaves like a bl ock device. Because of this, c onventional file systems
(such as FAT, ext2, and ext3) ca n be implemented. Because of mu lti-chip packaging
technologies and modern advances  in multi-level cell technology , SD memory devices
provide the highest density and capacity of all flash memory ch oices available in a
Zynq-7000 AP SoC. The drawback of SD memory is the requirement for a mechanical SD
card connector. When a physical connector is undes irable, eMMC is an alternative. eMMC
consists of flash memory and a controller packaged in a small b all grid array (BGA) that can
be directly mounted ont o a circuit board without a mechanical c onnector. The SD and
eMMC solutions differ in their ability to function as boot devi ces. A Zynq-7000 AP SoC can
boot directly from an SD card, but it cannot do so from an eMMC . eMMC solutions require
an additional boot d evice, such as QSPI.
Send Feedback

## Page 81

UltraFast Embedded Design Methodology Guide 81
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
In addition to the CLK, CMD and Data signals, card detect (CDn)  signals indicate the
insertion or presence of the SD card, and write protect (WPn) s ignals indicate the position
of the write protect switch on t he memory card. Some software d rivers rely on the use of
these signals. Thus, if the signals are not available, a simple  solution is to tie CDn active and
WPn inactive.
You can also use the SD/SDIO peripheral as a boot mode device. Refer to Configuration and
Boot Devices  and to the SD/SDIO Controller chapter (available at this link ) in Zynq-7000 All
Programmable SoC Technical Reference Manual  (UG585) [Ref 4] for more information.
UART Peripheral
The UART controller is a full-duplex asynchronous receiver and transmitter that supports a
wide range of programmable baud rates and I/O signal formats. T he controller can
accommodate automatic parity gene ration and multi-master detect ion mode.
The UART operations are controlled by the configuration and mod e registers. The state of
the FIFOs, modem signals, and other controller functions are re ad using the status, interrupt
status, and modem status registers.
Data Flow
The communication between the con troller and the APU occurs ove r the APB bus. The
controller is structured with separate Rx and Tx data paths. Ea ch path includes a 64-byte
FIFO. The data that arrives from  system memory over the APB bus  are stored into the
transmit FIFO. The received data from the MIO/EMIO interface is  stored in the receive FIFO
and transmitted to system memory using the APB bus.
The controller serializes and de- serializes data in the Rx and Tx FIFOs and includes a mode
switch to support loop back configurations for the RxD and TxD s ignals. The FIFO interrupt
status bits support polling or a n interrupt-driven handler. Sof tware reads and writes data
bytes using the Rx and Tx data port registers.
System Level Considerations
Zynq-7000 AP SoCs include two UART  controllers that are commonl y used as debug ports
for embedded systems. They are also often used in providing a t erminal connection with a
host PC. Because of their utility, they are supported by all la yers of software: FSBL, U-Boot,
stand-alone, and various operating systems.
The UART is used by the FSBL early in the boot process to send information to the terminal.
The simplest connection to the U ART controller requires two sig nals, TX and RX. It is
recommended that the user have access to UART1 for debug, even when using a PMOD with
two test points, TX and RX.
Send Feedback

## Page 82

UltraFast Embedded Design Methodology Guide 82
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Because of its low bandwidth, high voltage swings, and large co nnector, most modern
computers no longer have a UART port and instead use USB as the  standard peripheral bus.
Therefore, it may be necessary to add a USB-to-UART bridge cont roller on the board to
enable connection between the h ost USB port and the Zynq-7000 A P SoC UART port. This
is shown in Figure  3-5. The host PC terminal software r ecognizes the bridge as a virt ual
COM port and any of the widely-available terminal programs can be used to communicate
with a Zynq-7000 AP SoC.
Figure  3-6 is an example of the Cypress USB-to-UART bridge device being u sed to enable a
connection between a host computer and a Zynq-7000 AP SoC. In t he simplest
implementation, only the UART controller's TXD and RXD signals are required to support a
terminal. If flow control is required, this can be added using the extended MIO. Cypress
provides a royalty-free Virtual COM Port (VCP) driver that allo ws the CY7C64225
USB-to-UART bridge to appear as a COM port to the communication  software on the host
computer, such as TeraTerm or HyperTerm.
An alternative imple mentation uses the Silicon Labs CP2103GM US B-to-UART bridge
device. See the ZC702 Evaluation Board for the Zy nq-7000 XC7Z020 All Programmable SoC
User Guide  (UG850) [Ref 8] for details.
X-Ref Target - Figure 3-5
Figure 3-5:  Connecting a Zynq-7000 AP SoC UART to PC via USB-to-UART Bridge
Table 3-2:  CY7C6 Connections
EPP Pin UART Function
in EPP
Schematic Net
Name CY7C6 Pin UART Function in
CY7C64225
D11 (MIO Bank 1/501) TX, data out USB_1_RXD 23 RXD, data in
C15 (MIO Bank 1/501) RX, data in USB_1_TXD 4 TXD, data out
X-Ref Target - Figure 3-6
Figure 3-6:  Connection using a Cypre ss USB-to-UART Bridge
PC
Virtual
Com
Port
USB-to-UART
Bridge Zynq DeviceUSB UART
X14181-073117
Zynq Device
D11
C14
1.8V to 3.3V
CY7C6
D+
D-
RXD
TXD
RXD
TXD
USB
Connector
D-
D+
UART_D-
UART_D+
U_RXD
U_TXD
UART_RXD
UART_TXD
X14165-073117
Send Feedback

## Page 83

UltraFast Embedded Design Methodology Guide 83
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Only a two-pin UART can be route d through the MI O. A full 8-pin  UART requires routing
through EMIO. It supports a prog rammable baud rate plus protoco l and parity. Details of
the UART controller can be found in the UART Controller chapter  (available at this link ) in
the Zynq-7000 All Programmable So C Technical Reference Manual  (UG585) [Ref 4].
CAN Peripheral
The CAN controller in PS is a mem ory-mapped peripheral that sup ports bit rates up to 1
Mb/s. The controller implements a transmit and receive FIFO wit h a capability of storing 64
messages. The controller implemen ts 16-bit time stamping for re ceive messages and
provides receive and t ransmit error counters.
Data Flow
The CAN controller has an APB interface connecting the peripher al to the central
interconnect and you can use it to configure the control regist ers. You can route the CAN
transmit and receive signals to either MIO or the PL through EM IO. The CAN controller
supports five modes of operation:
• Configuration mode
• Normal mode
• Sleep mode
• Loopback mode
• Snoop mode
You can initiate each of these modes with a register write oper ation using the APB bus
attached to the controller. Refe r to the CAN Controller chapter  (available at this link ) in the
Zynq-7000 All Programmable So C Technical Reference Manual  (UG585) [Ref 4] for more
information.
I2C Peripheral
I2C (Inter-Integrated Circuit) i s a multi-master serial single- ended bus that uses two
bidirectional open-drain lines, Serial Data (SDA) and Serial Cl ock (SCL), both pulled up with
resistors. The protocol includes  a slave address, an optional r egister address within the
slave device, and per-byte ACK/N ACK bits. I2C is used for attac hing low-speed peripherals
such as sensors, EEPROMs, I/O ex panders, programmable clock dev ices, or A/D and D/A
converters to an embedded system. Several bus implementations a re derived from the I2C
bus, including the System Manage ment Bus (SMBus), Power Managem ent Bus (PMBus), and
Intelligent Platform Manage ment Interface (IPMI).
Zynq-7000 AP SoCs include two I2 C controllers that can operate at the common I2C bus
speeds of 100 Kb/s (standard mod e) and 400 Kb/s (fast mode). Ea ch controller can function
as a master or a slave in a multi-master design. The master can  be programmed to use both
normal (7-bit) addressi ng and extended (10-bit) addressing mode s. The master is
Send Feedback

## Page 84

UltraFast Embedded Design Methodology Guide 84
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
responsible for generating the c lock and controlling the data t ransfer. Data can be
transmitted or received in both master and slave mode configura tions.
Data Flow
In slave monitor mode the I2C interface can be set to monitor s lave-busy status. In this
mode the I2C continuously attemp ts a transfer to a particular s lave device until that slave
device responds with an ACK.
In slave mode, extended address support is determined automatic ally by detecting a
specific code in bits [7:3] of the first address byte. You can set the HOLD bit to prevent the
master from continuing with the transfer, preventing an overflo w condition in  the slave.
However, you must clear the HOLD bit before a timeout occurs in  the I2C controller. You can
program different timeout values.
You can program the I2C controller registers using the APB slav e interface. The I2C interface
specific SCL and SDA signals can be routed either to the PL via  EMIO, or they can be routed
to MIO. If routed through EMIO, the SCL and SDA signals are oft en implemented using
tri-stated I/O buffers  to communicate with I2C devices connecte d to one of the PL I/O
banks. The controller raises the completion interrupt to indica te to the host that a transfer
is complete. In master mode, any NACK received by the controlle r is communicated to the
host using NACK interrupt. Refer to the I2C Controller chapter (available at this link ) in the
Zynq-7000 All Programmable So C Technical Reference Manual  (UG585) [Ref 4] for more
information.
System Level Considerations
A pull-up resistor shall be placed at the far end of the SCL an d SDA lines, furthest from the
Zynq-7000 AP SoC. See Design Calculations for Robust I2C Communications  [Ref 78] for
pull-up resistor example calculat ion. Typical voltages are +5 V  or +3.3 V. A
level-shifter/repeater might be required depending on the volta ges of I2C devices and the
Zynq-7000 AP SoC I/O bank used. PC B and package delay skew for SDA to SCL should be
less than ±500 ps.
Not all I2C slave devices have p rogrammable addresses, thus add ress conflicts can occur
when connecting multiple devices  with identical addresses to a single bus. For this reason,
an I2C adapter port is typically routed through an I2C bus swit ch to connect I2C slaves with
identical addresses to different  bus segments. Applications mus t first address and then
configure the bus switch to select the desired I2C channel befo re communicating with slave
devices on one of the I2C bus se gments. There can be more than one device per I2C bus
segment if the I2C addresses are different and the capacitance of a bus segment is below
the allowable value. An example I2C bus topology including a 1: 8 bus switch is shown in
Figure  3-7. For more informa tion, refer to PCA9548A Low Voltage 8-Channel I2C Switch
With Reset  [Ref 90].
Send Feedback

## Page 85

UltraFast Embedded Design Methodology Guide 85
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Stand-alone, U-Boot, and Linux drivers are available to operate  the I2C controller. The
stand-alone driver can be used i nside the FSBL for early initia lization of peripherals. All
common transfer modes are supported for both master and slave m ode. Refer to the Xilinx
Linux I2C driver wiki page [Ref 54] for more information on the Linux driver as well as a
simple application example.
SPI Peripheral
SPI (Serial Peripheral Interface ) is a synchronous serial bus t hat operates in full-duplex
mode. It uses four wires: SCLK (Serial Clock), MISO (Master Inp ut, Slave Output), MOSI
(Master Output, Slave Input), an d SS (Slave Select). Devices co mmunicate in master/slave
mode where the master device ini tiates the data transfer. The m aster does not use an
addressing mechanism when communi cating with a slave. Multiple slave devices are
allowed, using individual slave- select lines that are typically  active-low. SPI is commonly
used to talk to A/D and D/A converters, flash and EEPROM memori es, LCDs, and many other
peripherals. The JTAG standard i s essentially an application st ack for a three-wire SPI
protocol.
Zynq-7000 AP SoCs include 2 SPI controllers that can operate in  master, slave, or
multi-master mode. The controlle r always operates in full-duple x mode, receiving and
transmitting data simultaneously.
Data Flow
In master mode, up to three slav e devices can be targeted using  individual slave-select
signals. It is possible to add a n external peripheral-select 3- to-8 decoder on the board to
target up to eight slave devices . When using the 3-to-8 decoder  option you can use
software to control the three output pins to the decoder. Softw are can use this feature to
control an external tr i-state when a device has a single bidire ctional SPI data pin.
X-Ref Target - Figure 3-7
Figure 3-7:  Example I2C Bus Topology
XC7Z020
AP SoC
I2C0 Adapter
PS Bank 501
(VCCMIO_PS 1.8V)
PCA9517
I2C
Level Shifter
AB
VCCMIO_PS 1.8V 3.3V
PCA9548
I2C 1-to-8
Bus Switch
0X74
CH7 – PMBUS_DATA/CLK
X14174-073117
UCD9248 Power Controller 0x34
UCD9248 Power Controller 0x35
UCD9248 Power Controller 0x36
sI570 Programmable Oscillator 0x5D
CH6 – FMC2_LPC_IIC_SDA/SCL
CH5 – FMC1_LPC_IIC_SDA/SCL
CH4 – IIC_RTC_SDA/SCL
CH3 – PORT_EXPANDER_SDA/SCL
CH2 – EEPROM_IIC_SDA/SCL
CH1 – IIC_SDA/SCL_HDMI
CH0 – USER_CLK_SDA/SCL
ADV7511 HDMI Transmitter 0x39
M24C08 EEPROM 0x53
TCA6416APWR I/O Expander 0x21
RTC-8564JE Real Time Clock 0x51
Send Feedback

## Page 86

UltraFast Embedded Design Methodology Guide 86
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
In slave mode, the controller re ceives messages from an externa l master and transmits a
simultaneous reply. The controlle r reads and writes to slave de vices via the 128-byte TX/RX
FIFOs using the 32-bit register-mapped data-port registers. The  read and write FIFOs
provide buffering between the SPI  I/O interface and software se rvicing the controller via
APB slave interface. The FIFO is used for both slave and master  I/O modes. Refer to the SPI
Controller chapter (available at this link ) in the Zynq-7000 All Programm able SoC Technical
Reference Manual  (UG585) [Ref 4] for more information.
CAUTION! All SPI transactions must be byte-aligned (mul tiple of 8 bits). Slave devices that implement
non-byte aligned SPI transactions, such as 10-bit address and 16-bit data, are not supported.
System Level Considerations
Both SPI interfaces, SPI[0,1] ca n be routed to MIO pins or to t he PL via EMIO. If routed
through EMIO, the most common me thod is to implement the interf ace signals using
tri-stated I/O buffers to communi cate with SPI devices connecte d to one of the PL I/O banks
(if this is done, the SPI interface cannot be used until the PL  has been programmed). The
slave select signals SS[1,2] can  be optionally enabled when usi ng the core in master mode.
These signals are true outputs because they are only available when the core is configured
as a master. The SS0 signal is tri-stated because it is also us ed in slave mode. The SCLK clock
frequency can operate up to 50 MHz when the I/O signals are rou ted to MIO pins. When the
I/O signals are routed through E MIO, the SCLK frequency can ope rate up to 25 MHz.
Figure  3-8 shows the SPI controller config ured for master mode and routed  through MIO.
SS0 must be routed through an EMI O pin. In this configuration, when SS0 is used it needs
to be pulled high using a pull-up resistor and must not be driv en low by an external device.
Up to three slave devices can be  connected simultaneously and s elected using the
corresponding slave-select line (SSn). If less than three slave s are connected, any of the SS
signals can be used. If SS0 is not used, it must be pulled to V cc and not used for any other
purposes.
X-Ref Target - Figure 3-8
Figure 3-8:  SPI Slave Connection to SPI Controller in Master Mode
SPI Master
Controller
MIO
SCLK
MOSI
MISO
SS0
SS1
SS2
MISO Slave 0
SS0
MOSI
SCLK
Slave 1
SS1
Slave 2
SS2
Zynq Device
Boundary
External DevicesZynq Device
X14171-073117
VCC
Send Feedback

## Page 87

UltraFast Embedded Design Methodology Guide 87
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
When routed via EMIO, connect the  EMIOSPIxSSON0 output signal t o the PL slave and tie
the EMIOSPIxSSIN input signal to Vcc. It is important that SS0 is high because the controller
snoops this signal in master mode to detect a multi-master mode  situation. If SS0 is low, the
controller will assume multi-mas ter mode and issue a Mode_Fail interrupt. Multi-master
mode is not recommended. For deta ils on driving SPI control sig nals, refer to Xilinx Answer
Record 47511  [Ref 68].
Figure  3-9 shows the SPI controller configured for slave mode and routed through MIO. The
slave-select line SS0 is used to  connect the external master de vice to the slave controller.
Other external slave devices can  be connected off-chip dependin g on the capabilities of the
master device.
It is recommended that the SCLK, MISO, MOSI, and SS lines have matched lengths to help
meet setup and hold times. PCB and package delay skew for the M ISO, MOSI, and SS lines
relative to SCLK should be less than ±50 ps.
Stand-alone, U-Boot, and Linux drivers are available to operate  the SPI controller. The
stand-alone driver can be used inside the FSBL for early periph eral initialization if the
controller is routed via MIO. If the controller is routed via E MIO, the initialization can take
place only after the bitfile is downloaded. All common transfer  modes are supported for
both master and slave mode. Refer to the Xilinx Linux SPI drive r wiki page [Ref 55] for more
information on the Linux driver as  well as a simple application  example.
GPIO Peripheral
GPIO (General Purpose Input/Output) are generic pins that can b e programmed by the user
at run-time, including whether i t is an input or output. GPIO p ins are typically used for
connecting LEDs, DIP switches and  push buttons, or to connect t he interrupt and reset
signals of board peripherals. Us ing GPIO via EMIO provides a so lution for controlling PL
X-Ref Target - Figure 3-9
Figure 3-9:  SPI Master Connection to SPI Controller in Slave Mode
SPI Slave
Controller
MIO
SCLK
MOSI
MISO
SS0
SS1
SS2
MISO
SS0
MOSI
SCLK
Other External
Slave Devices
Zynq Device
Boundary
External
Master
Device
Zynq Device
X14172-073117
nc
nc
MISO
SSa
MOSI
SCLK
SSb
SSc
SSd
Send Feedback

## Page 88

UltraFast Embedded Design Methodology Guide 88
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
reset without worrying about th e side affects of controlling FC LK_RST. It also provides
access to 64 inputs from the PL, 64 true outputs, and 64 output  enables to the PL through
the EMIO interface. Yo u can use output enabl es as an additional  64 outputs by controlling
the direction registers, if the output enables are not required . Each GPIO is independently
and dynamically programmed as inp ut, output, or interrupt-sensi ng. When configured to
sense interrupts, it can be set t o level-sensitiv e (high or low ) or edge-sensitive (positive,
negative, or both).
System Level Considerations
The GPIO controller has four ban ks. Bank 0 has 32 pins and bank  1 has 24 pins. The total of
54 GPIO pins in the two banks ar e dedicated to MIO. These pins are tri-stated and can be
configured as inputs or outputs. Banks 2 and 3 have 32 pins eac h, and the total of 64 GPIO
pins are connected to the PL usi ng EMIO. These GPIO contain thr ee signals: in put, output,
and output enable. Tri-state bu ffers can be instantiated at the  device boundary, however,
the PS to PL connections are simple wires.
Each GPIO is independently and d ynamically programmed as input,  output, or
interrupt-sensing. When configured to sense interrupts, it can be set to level-sensitive (high
or low) or edge-sensitive (posit ive, negative, or both). Softwa re can read all GPIO values
within a bank using a single loa d instruction, or write data to  one or more GPIOs (within a
range of GPIOs) using a si ngle store instruction.
CAUTION! MIO pins [8:7] are available as output only. GP IO channels 7 and 8 can only be configured
as outputs.
I/O standards and voltages for o n-board peripherals need to mat ch the MIO or PL I/O pin
configuration.
Both stand-alone and Linux drive rs are available to operate the  GPIO controller. The
stand-alone driver can be used inside the FSBL for early initia lization of peripherals. Refer to
the Xilinx Linux GPIO driver wiki page [Ref 53] for more information on the Linux driver as
well as a simple application example.
Cortex-A9 Multiprocessing Peripherals
The Cortex-A9 multiprocessing per ipherals include the SWDT and TTC with auto decrement
feature and they can be used as general purpose timers. These t imers serve as a mechanism
to startup the processor from standby mode.
The System Level Control Registe r (SLCR) acts as a peripheral t o the APU and external PL
master. You can access the SLCR only in the secure mode of the master requesting a register
access. The SLCR consists of reg isters that configure various c locking, reset, and security
settings of the peripherals.
Send Feedback

## Page 89

UltraFast Embedded Design Methodology Guide 89
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
PS DMA Controller
You can use the PS DMA controlle r to transfer data from any PS or PL peripheral to DDR,
OCM, linear QSPI, SMC, a PL peri pheral, or linear addressable m emory connected to the
M_AXI_GP port in the PS-PL boundary.
You can use the DMA controller i n an application requiring hard ware co-processor
acceleration, where a PL algorit hm is used to process data writ ten by the Cortex-A9 into
DDR memory. In such an application where data is processed by b oth a PS and PL
peripheral, the DMA controlle r plays an important role.
You can use the DMA controller t o save system power. The CPU ca n go into low-power
mode and bulk data transfers can  occur over the PS DMA interfac e. Because the CPU clock
is much faster than the DMA clock, this approach saves consider able dynamic power. Refer
to the DMA Controller chapter in Zynq-7000 All Programmable SoC Technical Reference
Manual  (UG585) [Ref 4] for more information.
XADC
The XADC contains two 12-bit 1-MS PS ADCs with separate track an d hold amplifiers, an
on-chip analog multiplexer, and on-chip thermal and supply sens ors. The two ADCs can be
configured to simultaneously sam ple two external analog-input c hannels. The track and
hold amplifiers support a range o f analog input s ignal types in cluding, unipolar, bipolar,
and differential. The external inputs include one pair of dedic ated differential analog-input,
(Vp/Vn) and sixteen multi-functi on pins that can support analog  input or can be used as
digital I/O (Vauxn/p). The dedicated analog inputs can support signal bandwidths of at least
500 KHz at sample rates of 1MSPS , or 250KHz on the auxiliary ch annels.
The XADC also includes a number of  on-chip sensors that support  measurement of the
on-chip power supply voltages and  die temperature. The results of the ADC conversion
from any source (temperature, supply voltage, or analog input c hannels) are stored in a set
of status registers inside the X ADC block. Because the temperat ure is available and the
clocks are programmable, you cou ld adjust the Zynq-7000 AP SoC clocks as temperature
changes.
The XADC block also includes a set of control registers used to  configure and control XADC
operations. This includes alarm registers that are used to spec ify automatic alarm
thresholds for the internally-measured sensors (temperature and  voltage). The alarm
automatically triggers a PS inter rupt when temperature or volta ges falls outside the
acceptable ranges defi ned by the registers.
The XADC analog inputs can be use d to support motor control, a touch sensor, or many
other applications that require an analog front-end. The voltag e and temperature sensing
capability can be used to monitor system health and to react ap propriately when the system
experiences abnormal temperature or voltage conditions.
Send Feedback

## Page 90

UltraFast Embedded Design Methodology Guide 90
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Two application notes describing  the XADC used as a system moni tor and to perform ADC
operations on external  analog signals are:
• Using the Zynq-7000 Processing System (PS) to  Xilinx Analog to Digital Converter (XADC)
Dedicated Interface to Implement Syst em Monitoring and External Channel
Measurements  (XAPP1172) [Ref 41]
• System Monitoring Using the Zynq-7000 AP SoC Processing System with the XADC AXI
Interface  (XAPP1182) [Ref 43]
The XADC status and control registers are accessible using eith er the parallel DRP interface
or the serial JTAG-DRP interface, as shown in Figure  3-10. The LogiCORE™ IP can be used to
encapsulate the entire XADC hard  block with the necessary logic  to turn the XADC into a
32-bit AXI slave peripheral that can be connected to the master  AXI_GP port of the PS. This
solution is required for the PS to access the data at a 1Mbps r ate. The AXI XADC LogiCORE
IP has the disadvantage that it consumes PL resources to implem ent, however, it provides a
fast and clean interface to the XADC. It takes full advantage o f the parallel data path and is
the only method that can realize  the full 1MSPS, as demonstrate d in System Monitoring
Using the Zynq-7000 AP SoC Processing System with the XADC AXI Interface  (XAPP1182)
[Ref 43].
An alternative solution is to us e the built-in PS_XADC interfac e block. The advantage is that
it requires no additional PL logic (the FPGA does not have to b e configured when using
built-in features). Reading and w riting the XADC DRP registers requires a write of the proper
command to XADCIF_CMDFIFO and a read from XADCIF_RDFIFO. Howeve r, because the
block serializes the FIFO contents and shifts data in and out o f the XADC hard block one bit
a time via the DRP JTAG interface, this solution is slower and cannot keep up with the higher
data rate. As demonstrated in Using the Zynq-7000 Processing Sy stem (PS) to Xilinx Analog
to Digital Converter (XADC) Dedicated Inte rface to Implement System Monitoring and
External Channel Measurements  (XAPP1172) [Ref 41], this interface was able to achieve only
100KHz. Also, the PL-JTAG interf ace and the internal PS-XADC in terface cannot be used at
the same time.
Send Feedback

## Page 91

UltraFast Embedded Design Methodology Guide 91
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
X-Ref Target - Figure 3-10
Figure 3-10:  XADC Block Diagram
FLASH
Memory
Interface
Zynq Processing System
IO Perpherals
MIO
APU
Arbiter
PS XADC
Interconnect
DDR Controller
DAP
Clk Gen Reset
Zynq Programmable Logic
PL JTAG
Interface MUX
Control
Register
MUX
Status
Register
MUX
DevC
VP_0
VN_0
Vref_n
Vref_p
VAUXP
[0:15]
VAUXN
[0:15]
12-bit
  ADC B
12-bit
  ADC A
LogiCore IP
AXI_XADC
Core Logic
On-chip Ref 1.25V
JTAG
(Serial)
DRP
(Parallel)
Internal
Temp
Internal
Voltage
Fast XADC access path
Slow XADC access path
X14168-073117
XADC hard macro
Central
Interconnect
M AXI GP
Send Feedback

## Page 92

UltraFast Embedded Design Methodology Guide 92
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Communication with Peripherals
The peripherals discu ssed above implement an  AMBA-specific bus structure to
communicate with the APU and the memory system. USB, GEM, SDIO,  and SPI peripherals
have two types of communication interface:
• The APB interface connects the peripheral slave to the APU mas ter. The interface
communicates using the central interconnect.
• The AHB interface enables high speed bus transactions between the DMA controller
embedded in the peripheral and t he system memory. The interface  connects to the
system memory using the central interconnect.
Figure  3-11 shows the peripheral bus connection to main memory and the APU . Figure  3-11
is a generic block diagram of a peripheral with DMA and control  register sets implemented.
X-Ref Target - Figure 3-11
Figure 3-11:  Peripheral Communication Bus
X14139-073117
DMA
Register Interface
Interface
DriverProtocol Engine
AHB
Bus
APB
Bus
Send Feedback

## Page 93

UltraFast Embedded Design Methodology Guide 93
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Peripheral Design Example
This example shows things to consider when designing with perip herals. The example uses
the Zynq-7000 AP SoC GEM controllers and two different physical  interfaces. One controller
has an RGMII PHY using the MIO interface and the other controll er has a 1000BASE-X PHY
using the EMIO interface. You ca n select any supported interfac e to meet your
requirements.
1. The PS has two instances of a GEM controller. One uses the RG MII interface and the
other uses the 1000 BASE-X interface.
2. TrustZone security aware access of the peripheral from the Co rtex-A9 multiprocessing
core.
3. You can enable and disable the  TCP checksum off-load to GEM h ardware, noting the
CPU utilization and performance differences between the two opt ions.
Figure  3-12 shows the hardware block diagram.
Although this example is built a round a gigabit Ethernet periph eral, you can extend the
concepts to other PS peripherals.
X-Ref Target - Figure 3-12
Figure 3-12:  Example GEM Instantiation
Programmable Logic
••••••• ••••••••••
Processing System 7
UART
Central Interconnect
GEM0
GEM1
APU
GIC
DDR Controller
1000BASE-X
GTX
EMIO
PS-PL Interconnect
MIO
SFP Connector
Send Feedback

## Page 94

UltraFast Embedded Design Methodology Guide 94
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Hardware Design C onsiderations
You can create the hardware design using the Vivado ® IP integrator flow. You must enable
MIO connectivity for GEM0 and EM IO connectivity for GEM1. Enabl ing EMIO for GEM1
brings the transmit and receive GMII signals to the PS IP top-l evel instance. The user must
instantiate the 1000BASE-X IP core from Xilinx in the IP integr ator design and connect it to
the GEM1 EMIO ports. You can imp lement the design using the Viv ado Design Suite
implementation flow to generate the bitstream. See PS and PL Ethernet Performance and
Jumbo Frame Support with PL Et hernet in the Zynq-7000 AP SoC  (XAPP1082) [Ref 40] for
more information.
Software Design Considerations
The GEM peripheral supports off-loading the TCP checksum to har dware to boost Ethernet
performance and improv e CPU utilization by p erforming compute-i ntensive checksum
calculations in hardware. The us er can enable checksum off-load  by writing into the GEM
configuration register u sing the APB interface.
The GEM driver configures the GEM DMA for a specific transfer s ize. The driver also sets up
the descriptor ring, DMA allocati on, and recycling, and program s the source and
destination MAC addresses.
The DMA transfer begins after en abling the transmitter and rece iver by writing to the
network control register.
Designing IP Blocks
Pre-verified intellectual proper ty (IP) blocks are used to redu ce time-to-market, and to
enable feature-rich digital and analog circuitry on the SoC. Th ese IP blocks include
embedded processors, memory block s, interface blocks, analog bl ocks, and components
that handle application-specific  processing functions. Use of s tandard interface
specifications, such as the AMBA high-speed specification and A XI specification, improve IP
block reusability. You can refer  to the Vivado IP catalog for m ore information on the IP
blocks supported by the selected Zynq-7000 AP SoC device.
There are two main categories of IP blocks:
• Soft IP Blocks : You can implement these blocks  in an FPGA fabric and are spec ified
using RTL or higher-level descri ptions. They are more suitable for digital cores, because
a hardware description language (HDL) is process-independent an d can be synthesized
to the gate level. The HDL form has the advantage of flexibilit y, portability, and
reusability, with the drawback o f not having guaranteed timing or power
characteristics.
Send Feedback

## Page 95

UltraFast Embedded Design Methodology Guide 95
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
• PS IP Blocks : These blocks have fixed layouts and are optimized for a speci fic
application and process. Their p rimary advantage is predictable  performance, which
comes with additional effort and  cost, plus lack of portability , that may greatly limit the
areas of application. PS IP block s are usually prequalified, me aning the provider has
tested it in silicon. This adds greater assurance to its correc tness.
The inherent complexity of SoC d esigns leads to the implementat ion of more complex
interfaces around a processing blo ck. The high-speed serial tra nsceiver present on a
Zynq-7000 AP SoC is a typical example. The transceiver's high-s peed serial IOs are capable
of transferring data in multiples of gigahertz. The transceiver  block is capable of performing
byte-boundary alignment, clock d ata recovery, and skew eliminat ion across multiple
transceiver lanes. It is also ca pable of clock compensation in systems that use independent
transmit and receive clocks with  ppm variation. User logic conn ects to the transceiver
through a complex interface, and  the functionality of that logi c is complex because it must
control the various functional b locks within the transceiver.
An IP block plays a significant role in handling the transceive r configuration by masking the
underlying complexity from the us er interface. An Aurora IP blo ck from Xilinx with an AXI4
Stream-compliant user interface performs the transceiver initia lization, clock
compensation, channel bonding, a nd byte-boundary alignment. A u ser can build a
transceiver application based on  the AXI4 Stream interface with out knowledge of the
underlying transceiver complexity.
Figure  3-13 shows how the Aurora IP plugs into the transceiver interface i n a Zynq-7000 AP
SoC.
X-Ref Target - Figure 3-13
Figure 3-13:  Aurora IP Example
Aurora IP User Interface
X14135-073117
Aurora IP Protocol Engine
High Speed Serial IO
Clock/Reset Interface
User Application
AXI4 Stream Interface
Complex Interface
Send Feedback

## Page 96

UltraFast Embedded Design Methodology Guide 96
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
IP Core Design Methodology
Xilinx enables different methodol ogies for creating IP blocks a nd offers an easy
maintenance approach. You can re use the IP blocks in the embedd ed system designs
created for Zynq-7000 AP SoCs and other processing systems, suc h as MicroBlaze™
processors. The following sections describe the IP creation met hodologies using the Xilinx
tool chain.
System Generator
System Generator is a tool that can create DSP IP blocks based on a user configuration,
using MathWorks Simulink for FPGA  system design. It offers a hi gh-level model-based
environment for system designs. A large number of building bloc ks are available in System
Generator, from simple mathemati cal operators to complex DSP op erations.
In the Vivado Design Suite, the IP Packager compilation target allows a user to package the
IP generated from the System Generator and include it in the Vi vado IP Catalog. You can use
the System Generator design like other IP blocks from the IP Ca talog and instantiate it in
your design.
HDL Coder
HDL Coder is a tool from MathWor ks that generates synthesizable  HDL code from MATLAB
functions and Simulink models. I t provides a workflow that anal yzes the MATLAB/Simulink
model and converts the model fro m floating-point  to fixed-point , providing a high-level
abstraction. The workflow also p rovides verification code, allo wing the HDL code to be
tested with the original  MATLAB/Simulink model.
Not all the functions present in MATLAB and Simulink support HD L generation. Because of
this, some of a model' s functionality may ha ve to be modified t o use functions or blocks
that support HDL generation.
Send Feedback

## Page 97

UltraFast Embedded Design Methodology Guide 97
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Vivado High Level Synthesis
Vivado High Level Synthesis (HLS) is a tool from Xilinx that is  capable of converting C-based
designs to RTL design files for implementation on Xilinx FPGA d evices. The Vivado HLS tool
flow is shown in Figure  3-14.
The Vivado HLS flow packages the RTL output into the following formats, allowing you to
easily integrate the output in to other Xilinx design tools:
• IP Catalog: Contains a ZIP file  that you can add to the Vivado  IP Catalog.
• Synthesized Checkpoint (.dcp): A Vivado checkpoint file that y ou can add directly into a
design in the Vivado Design Suite.
• System Generator for DSP: You c an add this output to the Vivad o edition of System
Generator for DSP.
• System Generator for DSP (ISE ®): You can add this output t o the ISE edition of System
Generator for DSP.
• Pcore for EDK: You can add th is output to the Xilinx Platform Studio.
In addition to the packaged outp ut formats, the RTL files are a vailable as stand-alone files
(not part of the recommended packaged formats).
X-Ref Target - Figure 3-14
Figure 3-14:  Vivado HLS Flow
RTL Export RTL Simulation
Constraints/
Directives
C, C++,
OpenCL Kernel,
System C Testbench
Verilog/VHDL RTL Wrapper
X14136-080117
Vivado HLS
d
Send Feedback

## Page 98

UltraFast Embedded Design Methodology Guide 98
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
IP Core Design Considerations
When designing an IP block, reus ability of that IP block across  multiple embedded system
designs and across different user  configuration options should be considered.
Parameterization and implementat ion of standard bus topologies allows an IP block to be
reusable in most system-level scenarios.
You should consider the followi ng when designing an IP block:
• Parameterization : Parameterization includes inte rface-level configuration and I P
feature-specific configuration. Interface-level configuration i s important when the IP
block interfaces with other IP b locks and the user must control  different bus
parameters, including the data a nd address bus width, clocking,  reset interface
configuration, etc. IP feature-specific configuration enables o r disables a feature in the
IP block depending on the user selection.
You can handle parameterization in IP blocks in multiple ways. The basic level of
parameterization can be implemen ted in the HDL code. The HDL pa rameters can be
configured from the IP configura tion wizard available after pac kaging the IP block using
Vivado IP integrator tool. You c an implement a customized envir onment to
parameterize the IP block.
• Bus Topology : The reusability of IP blocks is an important consideration wh en
designing an IP block. You can e nhance reusability by implement ing a bus topology
that complies with industry-stan dard bus interfaces. One of the  most widely used
standards is AMBA, and a broad class of IP blocks exist that co mply with that bus
specification. A bus topology im plemented with industry-standar d interfaces enables
easy plug and play of master and slave IP blocks at the system level. Such IP blocks can
also offer flexibility in selecti ng a particular version of the  standard protocol and
interface-level configurations.
The choice of bus interface depe nds on system-level requirement s. The AXI4-Lite bus is
primarily used as a control bus f rom the PS, and the AXI4 Memor y-Mapped bus is for
memory transfers betwe en the IP core. The AXI4-Stream bus is us ed to connect to
streaming blocks in the design t hat do not have addressing cont ext. The following
figure shows the AXI4-Lite, AXI4 Memory-Mapped, and AXI4-Stream  buses in an AXI
DMA-based design. In this figure, the AXI DMA is responsible fo r moving data between
the PS system memory and the AXI 4-Stream compliant Sobel IP usi ng the high
performance port. The PS sets up  the AXI DMA's buffer descripto r using the AXI4-Lite
interface.
Send Feedback

## Page 99

UltraFast Embedded Design Methodology Guide 99
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
• IP Security and Documentation : Protecting a design against copyright infringement is
an important consideration in de signing IP blocks. You can empl oy various security
algorithms to encrypt the HDL f ile. The Xilinx tools allow you to encrypt and decrypt
the HDL using the AES algorithm.
Connecting IP Blocks to the PS
When the interface bet ween the PS and PL uses AMBA-compliant in terfaces, you can
implement a design using soft IP  blocks. The PS-PL interface ha s a GP port (master and
slave) that can implement an AXI3 or AXI4 interface, and can co nnect the PS to a soft IP core
register interface. You can use the high-performance (HP) ports  as AXI3 slave ports that are
driven by an AXI3 or AXI4 master IP block in the PL. You can us e the ACP interface in a
similar way. The ACP interface i mplements the AWCACHE and ARCAC HE signals, and the
user IP block implementing the A CP master controller needs to i mplement these signals.
For more information, refer to ACP and Cache Coherency .
The ACP interface enables connectivity to the L2 cache, and the  interface can be used where
the IP block in the PL is co-pro cessing a compute-intensive ope ration requiring
considerable CPU utilization.
You can implement the AXI3/4 mem ory mapped or AXI4 stream proto col. The AXI3/4
memory mapped interface has read /write addressing signals and d ata interface signals. The
AXI4 stream interface does  not have address signals.
X-Ref Target - Figure 3-15
Figure 3-15:  AXI4-Lite, AXI4 Memory-Mapped, and AXI4-Stream Buses
Programmable LogicProcessing
System
AXI
DMA
AXI4 Stream Sobel IP
Master
GP
Slave HP
AXI4 Memory Mapped Interface
AXI4 Stream Interface
AXI4 Lite Interface
X14214-080117
Send Feedback

## Page 100

UltraFast Embedded Design Methodology Guide 100
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
When designing a Zynq AP SoC wit h an IP block, the PL must acco unt for the following:
1. The IP block complies with the  AXI3/4 protocol specification.  The AXI interfaces in the
PS-PL boundary are AXI3-protocol compliant. You can use a Xilin x-provided AXI
interconnect IP block to connect  the AXI4-compliant IP to the P S-PL interface ports.
2. The IP block is part of an IP integrator repository, simplify ing integration of the IP block
into a system level design.
3. The PS-PL interface supports me mory-mapped access of implemen ted peripherals.
4. You can select the AXI4 stream  interface to co nnect IP blocks  that do not require
addressing context. The AXI4 stream interface is widely used fo r video-based IP blocks.
You can store the stream video i nput from the video IP block in  the PS DDR memory
using the video DMA IP block co nnected to the HP port interface .
Case Study: Designing with Xilinx IP Blocks
This section describes how to design a system using IP blocks f rom the Xilinx IP integrator
catalog. You can apply the methods to any IP block.
The case study is of a notch filt er, which is a DSP IP that can  process analog samples to
remove non-linearity i ntroduced by an extern al sensor. When an analog signal passes
through a non-linear sensor, for example an RTD sensor, the sen sor can introduce nonlinear
behavior at the analog signal output. This is due to variations  in the sensor transfer function
based on temperature. The non-lin ear output requires compensati on, and you can
implement the compensation algor ithm in either the analog or di gital domains. Digital
algorithms offer more cost effect ive and accurate reconstructio n of the non-linear signal.
A Zynq-7000 AP SoC has a Xilinx ADC in the PL, and the IP block  that instantiates the XADC
provides a user wrapper with an option to convert the XADC samp les to an AXI4-Stream
compliant interface. The user can  design an IP block that compe nsates for the non-linear
sensor by preemptively correcting the XADC's samples with looku p polynomial coefficients.
You can design the sensor-compensating IP block using DSP48 blo cks available in the
Zynq-7000 AP SoC. The IP can implement two user interfaces: an AXI4-Stream interface for
data and an AXI4-Lite interface for control. The AXI4-Stream in terface can connect to the
XADC Wizard IP, and the AXI4-Lite interface can connect to the PS's GP0 master-interface
for controlling the IP-s pecific parameters.
Figure  3-16 shows a block diagram of the IP block.
Send Feedback

## Page 101

UltraFast Embedded Design Methodology Guide 101
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
The process of creating the IP block is:
1. Write HDL code that implements  an AXI4-Stream interface for d ata and an AXI4-Lite
interface for control. Implement the function that multiplies t he AXI4-Stream data with
the interpolated coefficients.
2. Package the HDL code using Viv ado IP Packager. Auto-infer int erfaces and associate
clocks with each of the interfaces.
3. Set up a local repository and copy the packed IP XACT files t o the local repository.
4. Create a Vivado project an d add the local repository.
5. Create the block design by ins tantiating the local IP block w ith other IP blocks and
connect them together.
6. Implement the design using Vivado Design Suite.
X-Ref Target - Figure 3-16
Figure 3-16: IP Use-Case Illustration
Zynq Processing System
 DDR3
Memory
GP0 IRQ_F2P32 bit @ 100 MHz
UART
Programmable
Logic
Processing System
DDR Controller
Non Linear
Analog
AXI4 Stream
X14137-073117
XADC Wizard IP
Sensor Compensator
BRAM Block IP
Send Feedback

## Page 102

UltraFast Embedded Design Methodology Guide 102
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Hardware Performance Considerations
The PL on a Zynq-7000 AP SoC has  multiple communication paths f or software and
hardware to shar e data and resources. Ea ch of these paths has c onfiguration settings for
altering hardware-specific performance. In this section, hardwa re performance metrics will
be defined, and methods for tuni ng performance of AXI masters, AXI slaves, and AXI
datapaths will be described.
Hardware Performance Metrics
An important metric of PL perfor mance is the AXI throughput and  latency when accessing
performance-critical IP in a Zyn q-7000 AP SoC. Xilinx uses ARM AMBA AXI interconnects in
PL to connect and map user IP into a global address space. Some  application datapaths will
be throughput constrained (such as video and networking) or lat ency constrained (such as
real-time applications or protoc ol-specific constraints). Often  when a Zynq-7000 AP SoC
design is started, the system architect can only specify perfor mance using the two simple
metrics of throughput and latenc y, something observed by many Z ynq-7000 AP SoC
customers.
To highlight the trade-off between latency and throughput, an A CP master that issues eight
outstanding 32-byte transactions will have an aver age read late ncy 130% higher than a
single outstanding tra nsaction master. However, the master with  eight outstanding
transactions also has a 262% high er average throughput. This is  because multiple
outstanding transactions are pip elined, leading to a higher thr oughput and latency
performance profile. The designer can decide if latency or thro ughput is more important to
system performance.
These two metrics form the found ation of visualizing and tuning  application performance.
The AXI interfaces that IP might access within a Zynq-7000 AP S oC are described below. AXI
IP design best-practic es are not considered.
High-Performance AXI Masters
An AXI master's design and confi guration affects its ability to  drive high-performance
traffic. Following are two examp les of AXI maste rs that have di fferent performance
characteristics as seen from an AXI interface.
AXI Master #1 . Supports a 32-bit AXI-Lite int erface and issues one outstandi ng AXI
transaction at a time. This mast er generates single-beat transa ctions and runs at 100 MHz
on a ZC702 board.
AXI Master #2 . This master uses a 64-bit AXI4 interface and can issue 16 out standing
transactions at a time, with a maximum burst length of 16 beats  per transaction. This master
can run at 200 MHz on the sam e Zynq-7000 AP SoC board.
Send Feedback

## Page 103

UltraFast Embedded Design Methodology Guide 103
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Independent of the datapath and the AXI destination slave, the performance of AXI master
#1 will not match AXI Master #2. T o minimize throughput constra ints, the AXI master should
fully use the AXI address and data channels. To minimize latenc y constraints, limit the
number of outstanding transacti ons because transactions will pi peline sequentially in the
AXI data channel.
This simple example might be int uitive, but building high-perfo rmance AXI masters adds
design complexity and may consume more resources. Often, perfor mance is only
considered after performance goals are not met. The following s ection outlines
performance considerations w hen designing an AXI master.
Building High-Performance AXI Masters
Many designs are generated using prebuilt IP, and performance c hoices are limited.
However, the following general g uidelines can help build high-p erformance AXI masters, or
tune existing IP when para meterization is possible.
• For throughput-constrained masters, support multiple outstandin g transactions .
This requirement adds complexity to AXI masters, but Zynq-7000 AP SoC interfaces can
internally support varying numbe rs of multiple transactions. Th is data pipelining
enables higher utilization of AXI  data channels, often the only  channel that matters in
throughput-based designs.
• For low latency masters, throttl e the number of outstanding tra nsactions to
maximize latency-t hroughput behavior . This item can be difficult to quantify, but
through experimentation, the lat ency curve can be shaped to min imize latency the
master sees while allowing multip le outstanding transactions. Figure 3-17  is an
example latency-throughput curve  showing how an increase in the  number of
requested transactions affects latency.
X-Ref Target - Figure 3-17
Figure 3-17:  Example Latency Throughput Curve for HP Port Reads
Send Feedback

## Page 104

UltraFast Embedded Design Methodology Guide 104
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
• Ignore the AXI response channel . If possible, use poste d writes to reduce the
transaction latency. For example , consider a transaction comple te on an AXI rdlast or
wrlast signal, ignoring the writ e response channel response. In  a well-formed design,
there will be no channel or slave  errors that an A XI master mus t manage. If writes
cannot be posted, then this cha nnel cannot be ignored. However,  the AXI write
response channel typically adds tens of cycles to a transaction  in many Zynq-7000 AP
SoC datapaths.
• Consider AXI master addressing b ehavior and the destination AXI  slave response .
The address sequence that an AXI  master generates affects the d estination slave's
ability to service that traffic. For example, if an AXI master generates random addresses
to a DDR-based memory, it can ca use lower memory performance. A lso, multiple
masters accessing DDR address ra nges can cause suboptimal DDR s cheduling. This is
not always an issue because some  memory slaves, such as the OCM , are better at
handling random accesses. Also, if random access is kept within  a small address range,
the L2 cache can service this tr affic. These AXI slaves will be  discussed later.
• Maximize clock rate, data widt h, and transaction burst size . These parameters
should be matched to what is s upported natively by a Zynq-7000 AP SoC (such as
internal 64-bit datapaths and a maximum AXI3 burst length of 16  beats). Typically,
increasing the AXI master clock rate affects just a portion of the total datapath, because
a transaction likely also travels  through the PS and its clock domains. PL data widths
will be internally translated to  the PS data widths, when neede d. Using burst size as an
example, if a PL AXI master driv es AXI4 traffic into the PS, th e transactions might be
translated into AXI3 transactions.
Using Performance-Critical AXI Slaves
Performance-critical slaves resp ond to data-movement requests f rom PL. Zynq-7000 AP
SoCs have three AXI slaves that are especially performance crit ical: the OCM, L2 cache, and
DDRC. The addition of a configura ble memory-interface generator  (MIG) to the PL is also
possible. The benefits of the different slaves are:
• On-Chip Memory.  The OCM is a 256KB memory block  accessible to both ARM cores
and the PL from the GP, HP, and ACP ports. The OCM is an ideal component for use in
synchronization or scr atchpad applications.
• L2 Cache.  The 512KB L2 cache is only accessible by the ACP from the PL. It is a shared
resource with the two ARM Cortex -A9 cores. This slave has excel lent performance
characteristics when data traffi c fits within 5 12KB. However, p erformance degrades if
there is heavy processor contention. The ACP and coherent memor y access is described
in ACP and Cache Coherency .
Send Feedback

## Page 105

UltraFast Embedded Design Methodology Guide 105
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
• DDR Controller.  You can connect the DDRC to a v ariety of off-chip memory devic es,
such as DDR3 and LPDDR2. The DDR C is accessible from the PL usi ng the AXI master
interfaces (GP, HP, and ACP). Ea ch PL interface has a unique da tapath to the DDRC. The
DDRC has higher memory capacity and throughput performance than  the OCM and L2
cache.
• PL Attached MIG (Optional).  Zynq-7000 AP SoCs can su pport an MIG-generated
memory controller in the PL. Thi s soft IP option provides anoth er high-performance
memory interface that can isolat e PL memory from the processor system's software
access to the DDRC. The MIG exports an AXI interface that allow s designs to attach
standard AXI-master IP. The greatest benefit of this core is th e ability to customize the
PHY into banking and addressing schemes for a specific applicat ion.
Selecting Performance-Critical AXI Slaves
The AXI slave selected for a datapath is often done so to meet functional requirements, such
as CPU coherency or memory size.  The selection of an AXI slave can also be driven by
performance requirements. The fo llowing selection consideration s have been used by
several Zynq-7000 AP SoC customers:
• Avoid or isolate perform ance-critical datapaths.  Often during the design process,
certain datapaths are marked as critical to system performance and other paths are
marked as secondary. For example , a network-processing applicat ion may need
dedicated access to off-chip memor y, whereas packet inspection can occur at a slower
rate on less critical datapaths.  You can isolate ACP access to the L2 cache from HP to
DDRC traffic by limiting the memo ry footprint of the ACP access . Similarly, OCM
accesses from GP can be isolat ed from ACP and HP traffic.
• Low latency.  The amount of latency that toler ated depends on the system-lev el
application and behavior of data  traffic. The OCM has excellent  low-latency
characteristics. Accessing small memory regions through the ACP  enables an
application to take ad vantage of low-latency L2 cache access.
• High throughput.  The high-performance ports prov ide high throughput to the PS
DDRC from the PL. A common problem with the HP performance is L 2 cache contention
at the DDRC. A memory-intensive software application can cause a reduction in HP
throughput. However, you can red uce contention by using the DDR C priority settings
and the QoS 301 settings on the L2 cache to DDRC datapath.
• Configurability and confidence.  Some designs might use a PL MIG to avoid memory
access contention with the proce ssor subsystem. Other designs m ight use a custom
memory interface based on previo us designs or developer experie nce. Prototyping
boards for Zynq-7000 AP SoC support MIG (such as the ZC706 boar d) and enable
designers to evaluate a custom M IG core and compare the results  with standard
Zynq-7000 AP SoC datapaths to the DDRC.
Send Feedback

## Page 106

UltraFast Embedded Design Methodology Guide 106
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
High-Performance Datapaths
There are two symmetric datapaths for the PS to communicate wit h the PL (master GP0,
master GP1), and there are seven  datapaths for PL AXI Masters t o drive traffic into the PS.
The AXI interfaces are describ ed in the following sections:
• ACP and Cache Coherency
• PL High-Performance Port Access
• GPs and Direct PL Access from APU
The process of using the system- performance goals to select bet ween those interfaces is
described below.
Selecting a High-Performance Datapath
The selection of a datapath is o ften based on design function. However, performance
considerations can also dr ive datapath selection.
• Choosing between the ACP and HP ports.  When the cache and user AXI4 signals are
set for a cache access, the ACP p ort provides access to the L2 cache and maintains
cache coherency with the ARM Cor tex-A9 cores. Using the ACP wit hout the cache
enabled can be useful to a PL master because the memory map mat ches that seen by
the Cortex-A9 cores.The L2 cache is a shared resource, and usin g the ACP port can
impact processor memory bandwidth . Also, if the traffic generat ed by AXI masters
spans a large address range (such as video f rames) or is random  in nature (such as
scatter-gather DMA), L2 cache misses will increase, causing a c orresponding increase in
latency and potentia lly lower throughput.
The HP ports support 32-bit and 64-bit data paths, providing hi gh-throughput access to
the DDRC. The HP ports contain FI FOs for increased burst throug hput and you can
control their prioritization. Th e HP ports also provide low lat ency and high bandwidth to
the OCM. You might find this use ful if the accelerators are in the PL and the OCM is large
enough for the buffer.
• Selecting the GP ports.  The slave GP ports provide PL  masters direct access to many
resources isolated from performa nce-critical datapaths on the A CP and HP ports.
• Memory-access footprint.  If a design uses the ACP for non-coherent access with poor
cache locality, then the DDRC se rves the majority of ACP traffi c. In an example
Zynq-7000 AP SoC deployment, ACP  latency is reduced up to 53% b y increasing cache
locality of transactions. HP and GP transactions do not access the L2 cache and are not
directly affected by cache behav ior. For more information on us ing the ACP for
coherent access, see ACP and Cache Coherency .
Send Feedback

## Page 107

UltraFast Embedded Design Methodology Guide 107
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
• PS datapath performance controls.  System clock rates, QoS-301 signals, and DDRC
priority settings can all impact  datapath performance. You can set most of the
memory-mapped registers and func tions that use IP integrator wh en building the
design. You can set QoS-301 bits a t runtime. Although higher sy stem clock rates help
move data faster, the QoS-301 signals and DDRC priority setting s can shift performance
between contending AXI masters. For example, QoS-301 settings o n the L2 to DDRC
datapath can limit L2 cache transactions to the DDRC, allowing HP traffic to be serviced
by the DDRC more frequently. DDRC priority settings can also be  used to prioritize read
and write transactions within the DDRC.
Monitoring Hardware Performance
Xilinx provides an AXI performance monitor (APM) core shown in Figure  3-18 that you can
use to observe and measure laten cy and throughput on PL AXI int erfaces. This core is
available in IP integrator and is the basis for all AXI perform ance measurements referenced
in this document.
Zynq-7000 AP SoC developers can in sert this APM into their PL d esign like other IP, and
verify performance metrics th roughout the design cycle.
X-Ref Target - Figure 3-18
Figure 3-18:  Adding an AXI Performance Monitor into a Vivado 2013.4 IP integ rator Design
Send Feedback

## Page 108

UltraFast Embedded Design Methodology Guide 108
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Dataflow
This section provides an overview of the dataflow in a Zynq-700 0 AP SoC. The first part
describes the dataflow within th e PS, focusing on APU access of  PS DDR, and of PS
peripherals to PS DDR. The second part describes dataflow from the PL to the PS, focusing
on the following PS-PL AXI interfaces: general purpose interfac es, ACP interface, and high
performance interfaces. Througho ut, major system design charact eristics and
considerations are described. For more information, refer to th e Zynq-7000 All
Programmable SoC Technical Reference Manual  (UG585) [Ref 4].
The various interconnect blocks used within the Zynq-7000 AP So C devices are designed to
meet the needs of various functio nal blocks. The PS interconnec t is based on
high-performance data path switch es that enable data transfers between various
peripherals and DDR memory, or between the APU and DDR or OCM m emories. The PS-PL
interface provides an AXI interf ace in the PL, enabling PL peri pherals to connect to the PS
and subsequent dataflow.
The block diagram in Figure  3-19 shows the major data paths that are covered in this
section.
X-Ref Target - Figure 3-19
Figure 3-19:  Block Level Data Path Overview
DDR Memory Controller
Memory Interconnect
On Chip RAM
High Performance PortsFIFO
FIFO
FIFO
FIFO
OCM Interconnect
APU
APU
Snoop Control Unit
Accelerator
Coherency
Port
L2 Cache
Controller Central Interconnect
Master Interconnect (for slave
peripherals)
General
Purpose AXI
(M_AXI_GP)
General
Purpose AXI
(S_AXI_GP)
Slave Interconnect
(for master
peripherals)
IOP (DMA/
Masters)
X14133-073117
Send Feedback

## Page 109

UltraFast Embedded Design Methodology Guide 109
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Interconnect within PS
There are two primary data paths within the PS: the APU interco nnect to PS DDR, and the PS
peripheral interconnect to PS DDR.
The central interconnect is 64 bits and is the core of the ARM NIC-301 switches. The master
and slave interconnect route low-to-medium level traffic betwee n the central interconnect
and the general purpose interconnects and IO peripherals in the  PS. Memory interconnect
provides a direct, high-speed dat a path from the PL HP interfac e to the DDR memory
controller. It also provides acce ss to on-chip RAM through the OCM interconnect.
The interconnect does not offer a full cross-bar structure; not  all masters can access all
slaves. The details on which mas ters can access which slaves ar e available in the
Interconnect Datapaths table at this link  in the Zynq-7000 All Programma ble SoC Technical
Reference Manual  (UG585) [Ref 4].
APU Access to PS-DDR
Each processor provides two 64-bi t pseudo-AXI interfaces. All A XI transactions are routed
through the SCU to the OCM or L2 -cache controller based on thei r addresses. The APU
accesses DDR memory through the SCU and L2-cache controller. Bo th the SCU and
L2-cache controller behave like switches because of their addre ss-filtering feature. The SCU
also provides the lowest latency  path from the APU or ACP perip herals in the PL to the
OCM, and also contains the inte lligence to manage data coherenc y between the two
processors and L1cache.
When the L2-cache controller is d isabled, the transactions are directed either to the DDR
controller or master interconne ct based on their addresses.
PS Peripheral Access to PS-DDR
The IO peripherals (USB, GEM, an d SDIO, for example) implement two interfaces for
communication:
• An APB interface for connecting peripheral slaves to the APU m aster
• An AHB interface that facilitat es high-speed bus transactions for connecting an
embedded DMA controller in the h igh speed peripherals to system  memory
The APB interface is used primar ily to control peripherals. The  AHB interface (from a DMA
master in a peripheral) is conne cted to central interconnect, p roviding access to the DDR
controller.
Send Feedback

## Page 110

UltraFast Embedded Design Methodology Guide 110
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
PS-PL AXI Interfaces
This section describes the PS-PL  AXI interfaces that are used t o connect PL-based
peripherals and functions to the PS. Usage models for each inte rface are described in their
respective sections.
General Purpose AXI Interface (AXI_GP)
The AXI_GP interface has four 32-bit general-purpose ports with  two master and two slave
ports; the PL is the master for two ports and the PS is the mas ter for the other two ports.
The ports are connected to the ma ster and slave interconnect po rts in the PS.
The AXI_GP ports are provided fo r general purpos e use and are n ot designed for high
performance.
A typical use model for the M_AXI_GP port is to connect it to t he control-plane interface of
a peripheral implemented in the PL. You can use the S_AXI_GP po rt to communicate with
addressable PS peripherals from the PL. When PL peripheral perf ormance requirements are
not high, you can also use  S_AXI_GP to access PS-DDR.
Accelerator Coherency Port (ACP)
The ACP provides an interface to masters in the PL for direct c onnection to the SCU. The PL
masters maintain memory coherency with L1 caches and have direc t access to the L2 cache
and OCM. The ACP has the same le vel of connectivity to peripher als and memory as the
CPU. For more information, refer to the address map in the Syst em Addresses chapter
(available at this link ) of the Zynq-7000 All Programmable SoC Technical Reference Manual
(UG585) [Ref 4].
Addresses on the ACP port are snooped by the SCU to provide ful l I/O coherency. Reads on
the ACP will hit in any CPU's L1 data cache, and writes will in validate any stale data in L1 and
write through to L2. This result s in significant  performance be nefits and simplifies driver
software.
The ACP allows a device, such as an external PL-DMA, direct acc ess to CPU-coherent data
regardless of where the data is in the CPU cache or memory hier archy. The resulting system
coherence relieves the software driver of performing costly ope rations such as cache
flushing and helps improve system performance.
The ACP is optimized for cache- line length transfers and also h as certain limitations that
should be taken into account when designing a system with an AC P. Further details are
available in ACP and Cache Coherency .
Use of ACP for high performance applications should be consider ed with care because the
peripherals connected to the ACP will compete with the CPUs for  access to caches and the
memory subsystem in the PS, im pacting overall performance.
Send Feedback

## Page 111

UltraFast Embedded Design Methodology Guide 111
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
High Performance Ports (AXI_HP)
Four high-performance AXI interfaces are provided to enable a h igh-throughput data path
between the PL masters, and DDR and OCM memory in the PS. Each datapath is selectable
between 32-bit and 64-bit. A dedicated memory interconnect prov ides direct connectivity
of these AXI-HP ports to the DDR  memory controller in the PS. A lso, FIFO buffers for read
and write traffic are present, p roviding high-performance capab ilities. These ports are also
referred to as the AXI FIFO Interface (AFI).
The four AXI-HP ports are multip lexed down in pairs and are con nected to two ports on the
memory controller. The memory interconnect switch arbitrates be tween the two ports.
When using two HP ports, use of port-0 and port-2 is recommende d because these are on
separate DDR interfaces.
The HP AXI interface provides ad ditional capabilities, such as QoS, FIFO occupancy, and
issuance throttling on interconne ct. This enables bandwidth man agement when there are
multiple masters with different types of traffic flow. You can control the QoS signals using
PL signals or by statically co nfiguring the APB registers.
In addition to the PS-PL AXI Int erfaces discussed above, there are additional PS-PL
interfaces:
a. Extended MIO allows routing of  IO peripheral signals to the P L. This provides an
interface between the PS IOP controller and user logic in PL, a nd it also enables use
of PL device pins. For more information, refer to this link  in the Zynq-7000 All
Programmable SoC Technical Reference Manual  (UG585) [Ref 4] .
b. PS-PL clock, reset, and interr upt interfaces that provide clo ck, reset, and interrupt
signals in the PL. For more information, refer to this link  in the Zynq-7000 All
Programmable SoC Technical Reference Manual  (UG585) [Ref 4] .
c. Device configuration interface, used to configure the PL unde r PS software control.
For more information, refer to this link  in the Zynq-7000 All Programmable SoC
Technical Reference Manual  (UG585) [Ref 4] .
d. The DMA interface between PS a nd PL can be used for high-spee d data transfer
between the PL IP block and other peripherals or memory blocks in the PS. The
interface between the PS and the fabric can be used to propagat e CPU interrupt
events.
Send Feedback

## Page 112

UltraFast Embedded Design Methodology Guide 112
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
System Level Design Considerations
When managing the bandwidth of PS-PL AXI interfaces, the follow ing should be considered:
• The general-purpose ports shoul d be used for low-to-medium typ es of traffic, such as
controlling PL peripherals from the PS, or as a data path for l ow-speed PL peripherals.
For example, you can move Ethern et packets into the PL through the S_AXI_GP port
because the bandwidth and latency requirements are satisfied by  the port. However, in
applications requiring guaranteed  latency and high performance,  such as video
implemented in PL, use of HP ports is preferable.
• The accelerator coherency port is useful when applications in the PL need to maintain
coherency with the processor L1 caches, and need reduced softwa re overhead.
• The high-performance port is recommended when applications in the PL need
high-bandwidth access to the DDR controller or the OCM. Multipl e ports are provided
so that you can distribute the P L masters across four HP ports for improved load
balancing, rather than restricti ng PL masters to a single HP po rt. You can obtain even
higher bandwidth for one PL mast er by using multiple HP port se ts (HP0 and HP2, or
HP1 and HP3).
For more information about using multiple port sets, refer to this link  in the Zynq-7000
All Programmable SoC Technical Reference Manual  (UG585) [Ref 4] .
PL Clocking Methodology
This section covers the clock methodology in Zynq-7000 AP SoC P L, describing the different
clock sources available in the P L and their recommended usage. Those clock sources are:
• Clock from PS (FCLK)
• Clock Recovered from a GT
• Clock from External Source
• Clock Generated by MMCM
At the end of this section a vid eo system design is discussed a s a typical model
demonstrating use of the  various clock sources.
Clock from PS (FCLK)
Refer to the Clocking and Reset  for information on using FCLK.
Send Feedback

## Page 113

UltraFast Embedded Design Methodology Guide 113
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Clock Recovered from a GT
The receiver clock data recovery (CDR) circuit in the GT transc eiver extracts clock and data
from an incoming data stream. Th e recovered cloc k has a direct relationship to the
transceiver line rate and the data-path width. You can use the recovered clock in a PL design
requiring a high-speed serial tr ansceiver for communication wit h the link partner. The
recovered clock typically has in herent jitter, and that jitter must be corrected before using
the clock in a design that is sensitive to input jitter. In gen eral, the recovered clock is used
to sample data received by the PL logic. The architecture of th e CDR is shown in Figure  3-20.
For more information, refer to the Receiver chapter of 7 Series FPGAs GTX/GTH Transceivers
User Guide  (UG476) [Ref 2] and 7 Series FPGAs GTP Transceivers  (UG482) [Ref 3].
Clock from External Source
An FPGA clock-capable IO pin that supports differential clocks can supply a PL clock. If a
single-ended c lock is used, it should be  connected to the P (ma ster) side of the
clock-capable input pin pair.
The choice of single-ended versu s differential-input clocking d epends on the design's
clocking requirements. Different ial clocking is recommended bec ause it eliminates
power-supply noise and line-coup ling noise. If the design is pi n limited, you can use
single-ended  clocking.
When a single-ended clock is connected to the P side of an inpu t pin pair, the N side cannot
be used for another single-ended clock. However, you can use it  as a user IO.
The clock-capable pins provide d edicated, high-speed access to the internal global and
regional clock sources, as shown in Figure  3-21.
For more information, refer to 7 Series FPGAs Clocking  Resources User Guide  (UG472) [Ref 1].
X-Ref Target - Figure 3-20
Figure 3-20:  CDR Architecture
0MRIEV
)56<42 (*) )HKI
7EQTPIV
(EXE
7EQTPIV
4-<
4-(
()19<
()19<
'(6
*71
400
6<(%8%
6IGSZIVIH'PSGO
<
Send Feedback

## Page 114

UltraFast Embedded Design Methodology Guide 114
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Clock Generated by MMCM
The MMCM is used to generate mult iple clocks with different fre quency and phase
relationships. The MMCM also de- skews the clock output. A use m odel is shown in
Figure  3-22.
The MMCM primitive, MMCME2_ADV, p rovides the functions listed a bove and the input
clock selection using the Dynami c Reconfiguration Port (DRP).
X-Ref Target - Figure 3-21
Figure 3-21:  Clock Capable Inputs
X-Ref Target - Figure 3-22
Figure 3-22:  MMCM Use Model
Global Clocking
Backbone
X14150-073117
Clock
Capable
Input
Dedicated Routing
BUFG
CLKOUT0
CLKOUT0B
CLKOUT1
CLKOUT1B
CLKOUT2
CLKOUT2B
CLKOUT3
CLKOUT3B
CLKOUT4
CLKOUT5
CLKOUT6
CLKFBOUT
CLKFBOUTB
LOCKED
CLKIN1
CLKFBIN
RST
MMCM
45 To Logic
BUFG
6
BUFG
IBUFG
1 2
3
X14151-073117
Send Feedback

## Page 115

UltraFast Embedded Design Methodology Guide 115
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
FCLK Use Model
An example FCLK use model is a v ideo application that displays a test pattern on a display
monitor. Figure  3-23 illustrates this model.
The use model has the following IP blocks:
• Test pattern generator (TPG) : Generates video frames o f different tes t patterns.
• Video timing controller (VTC) : Generates the timing for TPG.
• Video direct memory access module (VDMA) : Writes the video frames generated by
TPG in to the DDR memory.
• Display controller : Fetches the frames from the DDR  through HP2 port and displays
on monitor.
• On-board clock synthesizer : Used as a video clock driving all input video modules and
the display controller. It is programmable by the PS.
• Clock derived from FCLK using the MMCM : This clock has a hig her frequency than
Sys_clk. It is used by the VDMA and display controller AXI mast er interfaces because of
display controller lat ency requirements.
In this example, the design could use an external clock routed to PL and to an MMCM that
generates the desired Sys_clk ou tput. The PS AXI interconnect p rovides the clock domain
between the HP/GP port and the PL.
X-Ref Target - Figure 3-23
Figure 3-23:  FCLK Use Model
DDR Interconnect DDR Memory
Controller
VTC TPG VDMA
Video
Clock
Display
Controller Monitor
MMCM
DDR
Memory
HP0 HP2FCLK
PS
PL Sys_clk
X14152-073117
Send Feedback

## Page 116

UltraFast Embedded Design Methodology Guide 116
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
ACP and Cache Coherency
The accelerator coherency port p rovides low-latency access for PL masters, including
optional cache coherency with the dual core ARM Cortex-A9 CPUs.  From a system
perspective, the ACP interface has similar connectivity as the APU CPUs. Because of this, the
ACP competes with the APU CPUs f or resource access outside the APU block. Figure  3-24
shows an overview of the ACP connectivity.
The ACP's main benefit, compared to other PL masters, is access  to CPU cache-coherent
memory and use of the low-latenc y 512KB L2 cache. In a common Z ynq-7000 AP SoC
implementation, a PL accelerator is connected to the ACP port. It is configured by the CPU
over one of the GP ports, and th en the accelerator does its dat a movement over the ACP.
Coherent data movement  is managed in hardware, allowing the PL ACP-master to issue
standard AXI reads and writes. T he only requirement on ACP cach e-coherent accesses is
that those transactions have the  A*CACHE and A*USER bits set to  all 1s.
X-Ref Target - Figure 3-24
Figure 3-24:  ACP Connectivity Diagram
Accelerator Coherency
Port (ACP)
CPUs
Snoopable Data Buffers
and Caches
CPUs
Snoopable Data Buffers
and Caches
SCU
L1 Cache
Line UpdatesRead/Write
RequestsM
S S
OCM
M0 M1
Maintain L1 Cache
Coherency
Cache Tag
RAM Update
Flush Cache
Line to Memory Tag
RAM
L2 Cache
S
M0 M1
Tag RAM
Data RAM
System
Interconnect
Cacheable and
Non-cacheable
Accesses
Cacheable and Non-cacheable
Accesses to DDR, PL,
Peripherals, and PS Registers
DDR System
Interconnect
X14132-073117
PL Logic
Cache Coherent
Transactions
APU
Send Feedback

## Page 117

UltraFast Embedded Design Methodology Guide 117
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
This hardware-managed coherency model is an alternative to havi ng PL accelerators use the
HP or GP ports to access non-cohe rent memory directly from the DDR Controller. Here,
software-managed coherency would be necessary, whereby the proc essor would have to
flush shared memory back to the DDR to guarantee coherency. Whi le there are many ways
to implement software-managed coherency, the ACP does so in har dware, easing software
design.
Because the ACP supports cache coherency, ACP-attached AXI mast ers compete with the
CPUs for L2-cache reso urces (the L1 cache is  only available to the CPU). Any AXI read or
write transaction coming from th e ACP will use L2-cache resourc es to service the data
movement (arbitration, tag match ing, and cache-line fetches to DDR Controller). If this data
movement is coordinated with CPU  activity (such as the accelera tor example above), then
sharing the memory resources benefits the larger system applica tion. If this data movement
operates in parallel with unrelated CPU tasks, there are additi onal opportunities to mitigate
contention on the CPUs and ACP m asters, as described in the nex t section.
ACP Design Methodology
The following design methodology best-practices for effectively  using the ACP are based on
several customer use-cases plus performance analysis of the Zyn q-7000 AP SoC ACP.
ACP-Master Design Methodology
• Avoid Thrashing the Cache . The 512KB L2 cache is a shared resource between the two
ARM processors and the ACP. The ability of the ACP to access la rge quantities of data
has the potential to lower software performance. Locking and pa rtitioning the cache
can help ensure the shared data has a high cache hit rate. For example, video-style
accesses to the ACP port would h ave little cache locality and, without cache
management, hurt memory system performance.
In one example performance test case, ACP accesses that have go od cache locality will
show 54% lower latency when compared to an ACP access pattern w ith no cache locality.
Results will vary by application.
• Match AXI Transaction Parameters to ACP . The ACP is an AXI3 compliant 64-bit
interface. Transactions for AXI3  or AXI4 compliant masters atta ched to the ACP will be
converted to 64-bit-wide transac tions with a maximum burst leng th of 16 beats. All
conversion is done using soft IP such as the protocol converter  or the AXI interconnect.
Converted non-64-bit transactions and high beat-count transacti ons have the potential
to cause extra data-transfer cycles. Additional ACP access opti mizations and constraints
are described in the ARM Infocen ter Accelerator Coherency Port web page [Ref 75] .
Send Feedback

## Page 118

UltraFast Embedded Design Methodology Guide 118
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
• Choose Blocking versus No n-blocking Transactions . Care must be taken with
transactions completing out of o rder on the ACP port. Under cer tain conditions, writes
and/or reads can complete out of  order unless the axresp channe l is used as a barrier
between subsequent transactions.  Ideally, the response channel should be ignored,
allowing transactions to complet e as soon as data is transferre d. However, care is
required when issuing multiple r eads and writes to the same add ress range. For DMA
bulk transfers, this is typically not a problem. However, you c an see the problem when
multiple outstanding read and wr ite transactions are issued to a small address range.
In an example use-case, if the A CP's response channel is ignore d during multiple
read-modify-write oper ations to the same address, out-of-order read-after-write
collisions can occur.
• ACP use for non-coherent access . It is recommended that non-cache-coherent traffic
from PL be routed through the HP or GP ports. If required, howe ver, you can set the AXI
4-bit cache fields to modify the  behavior of ACP accesses. For more information, refer
to Section 2.4 Accelerator Coherency Port in the Cortex-A9 Technical Reference Manual
[Ref 77] .
PS Configuration for the ACP Design Methodology
• L2-Cache Clocking and Prefetching . The L2 cache is clocked at the CPU clock rate
and, with good cache locality, will service the majority of ACP  accesses. While you can
raise the PL clocks to decrease the access latency, you should also clock the L2 cache as
fast as possible. You can use L2 prefetch settings to turn pref etch on and off, and use
other settings to control the number of cache lines fetched per  miss. For example, ACP
accesses with little ca che locality may not benefit from prefet ching because they can
cause mis-speculated fetches fro m the L2 to the DDR controller.
Refer to the Zynq-7000 All Programmable So C Technical Reference Manual  (UG585)
[Ref 4]  for more information on optimizing the PS settings for ACP acc esses and
modifying the L2 cache settings.
Send Feedback

## Page 119

UltraFast Embedded Design Methodology Guide 119
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Contention with Software  on CPU Methodologies
• Consider CPU Memory Access Patterns . The effect of cache contention with the
processor is also dictated by th e processor's memory-access pat terns. Software that
runs entirely out of a processor's L1 cache will not be affecte d by ACP accesses.
However, ACP accesses can affect  software with low cache locali ty, such as a
memory-striding application.
For example, a memory-intensive software application running on  the ARM Cortex-A9 is
unaffected by heavy ACP traffic accessing a single 4 KB memory page from the L2 cache.
As a further example, running L1 -cache-bound benchmarks, such a s Dhrystone or
Coremark, on the CPU is unaffecte d by heavy ACP traffic accessi ng a 512 KB buffer held
within the L2 cache.
• Advanced Cache Management. You can use techniques suc h as cache locking and
cache partitioning to assist in cache sharing and cache isolati on between multiple CPU
and ACP masters. These techniques  may require you modify linker  scripts and tailor
ARM memory descriptors to the a pplications memory layout. For a  tutorial on how to
lock caches and the possible performance effects, refer to Zynq -7000 AP SoC Boot -
Locking and Executing out of L 2 Cache Tech Tip wiki page [Ref 62] .
• Monitoring Contention . It is important to monitor and measure contention when
design goals are not being met. You can monitor the L2 cache, t he CPUs, and the ACP
itself for ACP performance. You c an monitor the L2 cache using event counters,
processor cache accesses using the ARM Performance Monitoring U nits (PMU), and the
ACP using Xilinx's AXI performanc e monitor implemented in the P L. These monitoring
methodologies are further described in Performance .
Send Feedback

## Page 120

UltraFast Embedded Design Methodology Guide 120
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
PL High-Performance Port Access
The high performance (HP) ports give the PL direct access to th e DDR controller and to the
On-Chip Memory (OCM). The Zynq-7000 AP SoC Technical Reference Manual provides an
excellent functional description of the HP ports and possible p erformance opt imizations.
This section describes common design-driven optimizations imple mented in customer
designs that use the HP ports.
The HP ports are typically used in a design needing PL high-thr oughput access to either the
OCM or, more commonly, DRAM attached to the DDR controller. Figure  3-25 shows that the
HP ports contend with each other  and other PS masters at differ ent points in the PS
architecture. Methods for achiev ing a high-throughput design on  multiple HP interfaces
with system contention are described below.
X-Ref Target - Figure 3-25
Figure 3-25:  High Performance (HP ) Port Connectivity
High Performance
AXI Controllers
(AXI_HP)
Memory
Interconnect
M0
FIFO
S0
M1
FIFO
S1
M2
FIFO
S2
M3
FIFO
S3
M0 M1 M2
Central
Interconnect
OCM Interconnect
S0 S1
M
On-chip RAM
S1 S0
SCU
DDR Memory Controller
S3 S2 S1 S0
L2 Cache
X14134-073117
Send Feedback

## Page 121

UltraFast Embedded Design Methodology Guide 121
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
HP Master Design Methodology
• Order of adding HP ports . Because of the HP data paths, HP ports should be added to
minimize data path contention. I n general, HP po rts should be a dded in the following
order: HP0, HP2, HP1, and HP3. Using this order, HP masters can  take full advantage of
the two dedicated DDR controller ports.
For example, in a design requiri ng two HP ports, a 15% improvem ent in combined
throughput can be realized if he avy read traffic is routed thro ugh HP0 and HP2 instead
of HP0 and HP1. As higher throug hput traffic is driven, the per formance difference
increases.
If more than four HP masters are required, you can use an AXI i nterconnect in the PL to
multiplex the masters onto the four HP ports. When assigning th e masters to HP ports,
the goal is to maximize HP port throughput. For example, you ca n assign high-traffic
masters to separate HP ports and pair them with low-traffic mas ters. An important
consideration is that a single H P port could saturate at a lowe r throughput than the
DDRC's saturation point.
• AXI Addressing Optimizations . Standard DRAM access op timizations should be
considered, including address op timizations and minimizing read /write mix, if possible.
Designing High-Performance Video Systems with the Zynq-7000 All Programmable SoC
(XAPP792) [Ref 36]  provides guidance on using nonl inear addressing to match the
row-bank-column layout of DRAM for a video application. Also, w henever possible, the
read/write mix should be minimized, although this is not always  possible due to design
behavior.
For example, in a system with read-only HP0 and HP2 ports, the read throughput on HP0
drops 0 12% when HP2 is changed to write-only. The performance degradation range
depends on traffic addressing a nd generated transaction rate.
• Increasing the PL clock rate . Increasing the programmable clock speeds is a common
method used to maximize applicat ion performance. However, there  are diminishing
returns on increasing the PL clo ck rate when performance bottle necks exist in moving
data between the PL and the DDR controller. Referring to the da ta path in Figure 3-25 ,
although the PL master initiates traffic in the PL clock domain , the majority of the data
path is in PS clock domains. Also, the maximum DDRC bandwidth s hould be considered
because the DDRC will eventually saturate due to increased PL m aster traffic.
For example, in a design where two HP ports are driving heavy r ead and write traffic to
the 533MHz DDR controller, increas ing the PL clock speed from 5 0 MHz to 100 MHz
increases total HP throughput 92% , whereas an increase from 100 MHz to 200 MHz
increases throughput 13%. In the  latter case, traffic is driven  more often from the PL,
resulting in a saturated DDR controller.
Send Feedback

## Page 122

UltraFast Embedded Design Methodology Guide 122
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
PS Configuration for the HP Design Methodology
When designing with HP ports, the contention of high-throughput  traffic at the DDR
controller and attached DRAM des tination cannot be ignored. The  HP ports have two
dedicated ports to the DDR contr oller, but those are arbitrated  with the L2 Cache and the
central interconnect in the DDR controller. You can minimize co ntention from the 512KB L2
cache port because the L2 cache services CPU and ACP requests i f the L2 cache holds the
requested data. However, if the CPUs or ACP access memory with little cache locality, those
cache accesses are serviced by t he DDRC, potentially hurting HP  performance. Also, the
central interconnect c ontention at the DDR C is application depe ndent, with the potential
for heavy traffic coming from US B or gigabit Ethernet masters.
You can use two advanced techniqu es to limit L2 and central int erconnect access to the
DDRC, with a goal of improving HP  throughput in high-contention  implementations. You
should use these techniques after default settings are tried an d an HP performance goal is
not met. You can modify either of the following:
• The DDRC priority settings
• The QoS-301 settings within the PS
The techniques can prioritize HP traffic to the DDR, but do not  necessarily increase overall
performance. Instead, they slow down other PS masters to the be nefit of the HP ports.
• DDR Controller Priority Settings . These settings control the order that transactions
are serviced at the DDR controll er ports and at the DDR PHY. Th e high priority read
feature and go2critical counter v alues are the most important f eatures controlled by
the DDR controller priority settings. You can use the high prio rity read options on each
DDR controller port to increase a  port's read priority over tha t of other DDR controller
ports. This increase in priority  can have an effect on the HP t hroughput of highly
loaded systems (such as where a ll HP ports are driving high thr oughput traffic). These
advanced features are useful whe n a Zynq-7000 AP SoC is pushed to its performance
limits, such as when the DDR contr oller is saturated at theoret ical maximum
throughput. Refer to this link  in the Zynq-7000 All Programmable SoC Technical
Reference Manual  (UG585) [Ref 4]  for more information.
• QoS-301 Settings . The AXI data path from the L2 cache to the DDR controller has
QoS-301 settings that are currently accessible only through dir ect register writes from
your application. You cannot modi fy them using the Vivado GUI. This feature allows
transaction throttling on that p ath, benefitting HP port perfor mance under heavy DDR
traffic. This feature is best us ed when memory-intensive softwa re with poor L2-cache
locality is running. Refer to this link  in the Zynq-7000 All Programmable SoC Technical
Reference Manual  (UG585) [Ref 4]  for more information.
Send Feedback

## Page 123

UltraFast Embedded Design Methodology Guide 123
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Contention Mitigation for DDR Controller Methodologies
Similarly to the ACP contention sources, HP performance is affe cted by system loading,
specifically at the DDR controller. The biggest potential sourc e of contention will be the L2
cache making cache line requests to service CPU or ACP accesses . CPU and ACP contention
will depend on memory access patterns exceeding the capacity of  the 512KB L2 cache.
Ethernet and USB traffic from th e central switch  can also drive  large amounts of traffic to
the DDR controller.
• Monitoring Contention . It is important to monitor and measure contention when
design goals are not being met. For HP performance, you can mon itor the L2 cache,
Ethernet controller, and the HP ports. You can monitor the L2 c ache and Ethernet
controller using event counters within the core, and monitor th e HP ports using Xilinx's
AXI performance monito r implemented in PL.
• How much contention is an issue?  Most contention-mitigation techniques noticeably
improve performance when the tot al system traffic to the DDR ap proaches the DDR
controller's theoretical maximum . For example, a 32-bit DDR con troller running on the
ZC702 board at 533MHz can theore tically sustain 4.3GB/s of memo ry throughput. The
DDR controller is designed to arb itrate fairly and sustain seve ral high-throughput
sources, and contention effects will not be visible at low DDR controller utilization.
• Using an attached PL Memory Interface Generator (MIG) . Xilinx also provides PL
memory interfaces to off-chip DDR  that can supplement or replac e the HP to DDR
controller data path. Functiona lly, you can isol ate this added memory from the PS
memory map, or you can access it u sing the GP ports. For more i nformation, refer to
Xilinx Answer Record 58387 [Ref 73] .
The MIG is typically a better-pe rforming memory option for larg e bulk data transfers to
contiguous addresses from a single master, such as Ethernet and  video frames. Also, this
memory option is best for buffering data isolated from PS acces ses, because direct CPU
accesses to this PL DDR would go  through the 32-bit GP ports, l imiting MIG
performance. Otherwise, the PS DDR controller provides excellen t memory performance
for HP workloads.
Send Feedback

## Page 124

UltraFast Embedded Design Methodology Guide 124
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
System Management Hardware Assistance
This section describes the hardware components that enable syst em management in a
Zynq-7000 AP SoC PS. System management includes control of syst em-level parameters
based on user-specific inputs. C hip-level management includes c ontrol of die temperature,
management of errors, implementa tion of low-power mode during s ystem inactivity,
management of secure and non-s ecure access to peripherals.
Software components play an impo rtant role while performing sys tem management. The
focus of this section is on hard ware assistance for system mana gement on Zynq-7000 AP
SoCs.
Xilinx Analog-to-Digital Converter
The Xilinx analog-to-digital con verter (XADC) is a flexible ana log interface that resides in PL
and assists in monitoring temper ature and power-supply sensors.  The XADC has three
interfaces, JTAG, DRP and PS-XA DC, with which system applicatio ns can monitor the
temperature and voltage status a nd take appropriate action. The  JTAG and DAP interfaces
are present in all 7-series FPGAs. However, the PS-XADC interfa ce is only present in
Zynq-7000 AP SoC devices.
Figure  3-26 shows how the XADC arbitrates between the AXI XADC DRP interfa ce and the
PL-JTAG or PS-XADC interface.
X-Ref Target - Figure 3-26
Figure 3-26:  XADC Arbitration
X14146-080117
JTAG
PS
AXI XADC
P
S

X
A
D
C
XADC
A
r
b
i
t
e
r
DRP
Send Feedback

## Page 125

UltraFast Embedded Design Methodology Guide 125
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
TrustZone Security
The ARM TrustZone technology supports system-wide security at m ultiple levels, including
hardware, software, and memory. The Zynq-7000 AP SoC PS archite cture supports multiple
operating modes, including supervisor, system, and user modes, to provide different levels
of protection at the  application level.
A processor switches between two  separate worlds, secure world and normal world,
through a processor mode calle d monitor mode, as shown in Figure  3-27. The TrustZone
technology is implemented in man y PS components, including: APU , L1-cache controller,
memory management unit, SCU, SLCR, triple timer counter, watch- dog timer, I2C, GPIO, SPI,
CAN, UART, QSPI, NOR, DDR memory controller, L2-ca che controlle r, AXI interconnects,
on-chip memory, DMAC, Gigabit Et hernet controller, SDIO control ler, and USB controller.
DDR Memory Controller
You can configure DDR memory in 64MB segments, and configure ea ch segment to be
secure or non-secure using a con trol register, TZ_DDR_RAM (0xF8 000430).
• A bit value of 0 indicates a secure memory region for the asso ciated memory segment.
• A bit value of 1 indicates a non-secure memory region for the associated memory
segment.
When there is non-secure access to a secure segment of DDR memo ry, a DECERR response
is returned to the initiator of the transaction. Write transact ions are masked and result in no
write to the DDR memory, whereas  read transactions return all z eroes.
X-Ref Target - Figure 3-27
Figure 3-27:  Switching Between Secure and Non-Secure World
Non-Secure World Secure World
User Mode
Privileged Mode
User Mode
Privileged Mode
Monitor
Mode
X14147-073117
Send Feedback

## Page 126

UltraFast Embedded Design Methodology Guide 126
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
L2 Cache Controller
The L2 cache controller supports TrustZone technology by adding  an NS bit to cached data.
In this way, the cache controlle r treats secure and non-secure as being in two different
memory spaces. For a read transf er, the cache controller sends a line-fill command to
external memory, propagates any security errors from external m emory to the processor,
and does not allocate the line in  L2 cache if there is an error .
DDR Error Recovery
An error correction code (ECC) mechanism is supported for 16-bi t DDR content. This allows
recovery of corrupted DDR data. T en ECC bits for each 16 data b its support correction of
single-bit errors and detection of two-bit errors. When ECC is enabled for writes, ECC code
is computed and written to DDR along with the data. When ECC is  read, the DDR controller
checks the data against the stor ed ECC code. Writing DDR memory  without enabling ECC,
and then reading with ECC enabled, may return ECC errors.
When an error is corre ctable, the controlle r corrects the data and sends it without
generating an interrupt or AXI re sponse. When an error is uncor rectable, the controller
sends an AXI SLVERR response along with the corrupted data to t he AXI master. AXI masters
in the PS might also generate L2  or DMA interrupts, or CPU pref etch or data exceptions.
When they do, the same AXI SLVE RR response is sent to the PS AX I master.
Low Power
You can power-optimize Zynq-7000 AP SoCs in various ways: PL po wer off, processor
standby mode, clock gating of PS  subsystems, PLL configuration,  or I/O voltage control.
When the PL is not in use, you can power-off the entire PL. How ever, the PL loses state when
it is powered off, and it must b e reconfigured when it is power ed on again. The system
software should determine when t o power-off the PL and it shoul d reconfigure the PL when
it is needed again.
Clock Gating
The PS has multiple clock domain s, and each cloc k has gating co ntrol to stop the clock.
System software can enable gating of a particular clock when th at clock domain is not in
use. This reduces dynamic power dissipation.
You can disable clocks using sys tem-level control registers (SL CR), which starts at address
0xF8000000.
For example, when the SPI controller is not in use, you can dis able the controller reference
clock by writing an appropriate value to register SPI_CLK_CTRL (0xF8000158).
Send Feedback

## Page 127

UltraFast Embedded Design Methodology Guide 127
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Figure  3-28 shows how clock gating of the SPI reference clock works.
Managing Hardware Reconfiguration
Partial reconfiguration is the a bility to reconfigure a portion  of an FPGA chip to implement
different logic functions without disturbing the remaining logi c on the chip. The technology
enables an FPGA to implement di fferent functional blocks in a t ime-sliced manner.
TIP: The Partial Reconfiguration Design Hub in th e Documentation Navigator provides links to
additional information about Partial Reco nfiguration. For more information, see Related Design Hubs .
FPGA partial reconfiguration is supported using the following c onstructs:
• A configuration-select line that enables partial reconfigurati on of an SRAM FPGA
without powering down the supply voltage.
• A configuration latch that can store the configuration data us ed for partial
reconfiguration.
In the Zynq-7000 AP SoC PL architecture, the basic programmable  unit is a configuration
frame composed of a LUT, DSP48, and BRAM. In partial reconfigur ation, the configuration
frames are reprogrammed using a Processor Configuration Access Port (PCAP) that acts as
a reconfiguration agent. Each co nfiguration frame has a unique address identified with a
top/bottom address bit , a major address, and a minor address. T he partial bitstreams are
generated using a Xilinx Vivado Tool flow, and the partial bits treams are parsed by the PCAP
to reconfigure the frames.
X-Ref Target - Figure 3-28
Figure 3-28:  Clock Gating
IO PLL
ARM PLL
DDR PLL
6-bit Programmable
Divider Clock Gate
SPI_CLK_CTRL [5:4]
SPI_CLK_CTRL [13:8] SPI_CLK_CTRL [0:1]
SPI Ref Clock
X14148-073117
Send Feedback

## Page 128

UltraFast Embedded Design Methodology Guide 128
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Partial reconfiguration offers t he following advantages over a traditional full configuration:
• Reduced hardware resource utilization : A designer can fit more logic into an existing
device by dynamically time-slicing design functions.
• Increased productivity and scalability : Only the modified function needs to be
implemented in context with the already-verified design
• Enhanced maintainability and  reduced system down-time : You can deploy new
functions and insert them dynami cally while the system is up an d running
Figure  3-29 shows a conceptual view of the partial reconfiguration methodo logy. The static
design does not change over time  and establishes communication between the partial
reconfiguration modules and the static design. The communicatio n between the static logic
and the partial reconfiguration modules occurs over a set of co mmunication macros
consisting of a bidirectional co mmunication entity and tri-stat e gates.
The Zynq-7000 AP SoC has a PL po rtion that you can reconfigure using partial
reconfiguration. The PL is progr ammed using the Processor Confi guration Access Port
(PCAP) that is part of the PS Device Configuration Interface. T he PCAP block communicates
with the CPU and system memory u sing a PCAP to APB bridge that converts APB
transactions to PCAP read/write transactions. You can store the  partial bitstreams
generated using the Xilinx Vivado design tool into the PS DDR m emory, and retrieve them
to configure the PL over the PCAP interface using the partial r econfiguration methodology.
X-Ref Target - Figure 3-29
Figure 3-29:  Conceptual View of Partial Reconfiguration
Static
Logic
Input
Communication
Macro
Output
PR1PR1
PR2
PR3
••••••• •••••••••••
•• ••• •• • ••• •• ••••••••••••••
Processing System
Send Feedback

## Page 129

UltraFast Embedded Design Methodology Guide 129
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Partial Reconfiguration Terminology
The reconfigurable partition refers to the physical location on  the FPGA selected for partial
reconfiguration. The remainder o f the design is referred to as static logic. You can refer to
a specific design implementation  as a reconfigurable module. A configuration defines a
complete FPGA design and produces a full bitstream for a reconf igurable module and static
logic, plus a partial bitstream for the reconfigurable module.
System Level Considerations
When using partial reconfigurati on in your design flow, you sho uld take the following
system-level considerations into account.
RECOMMENDED: To learn how to design with Partial Reconfiguration in Vivado, refer to the Partial
Reconfiguration Design Hub in the Documentation Navigator. For more information, see Related
Design Hubs .
Hardware Design Flow
The first step in creating a par tially reconfigurable design is  to create a design using a
reconfigurable module and static design flow. Implementation of  a partial reconfiguration
design flow requires the Xilinx Vi vado design tool, as describe d in the following steps:
• Create a partial reconfiguratio n project using the Xilinx Viva do design tool targeting
the evaluation platform, and import the netlists and constraint  files.
• Define the reconfigurable parti tion. This partition ensures th at the logic and routing
common to each of the multi ple designs is identical.
• Create reconfigurable modules f or the reconfigurable partition  by adding the
corresponding netlist and constraint files.  Constraints that ap ply only to specific
reconfigurable modules must be s coped to the mod ule level and s hould be provided
with the corresponding netlist. C onstraints applied to the stat ic logic and any
constraints that are shared acro ss all reconfigurable modules s hould be included in the
top-level constraint file.
• Floorplan the reconfigurable pa rtition by setting the physical  size of the partition and
the types of resources desired. Xilinx FPGAs support reconfigur ation of CLBs
(Flip-Flops, LUTs, distributed R AM, Multiplexers, etc.), BRAM, and DSP blocks, plus all
associated routing resources. The designer must floorplan the r econfigurable partition
such that it can accommodate the  resources required by the reco nfigurable modules.
As a guide, 20% overhead should b e assumed for routing resource s. The location of a
reconfigurable partition inside the PL with respect to the stat ic logic depends on the
data flow and how the reconfigur able modules communicate with t he rest of the
design. A simple strategy is to implement the configuration wit h the highest resource
utilization without floorplanning , identify the region where mo st of the resources are
Send Feedback

## Page 130

UltraFast Embedded Design Methodology Guide 130
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
placed, and create a partition around this region that is big e nough to hold all the
resources.
• When building reconfigurable des ign configurations, the first configuration
implemented should be th e most challenging one.
• Run the partial reconfiguration verify-configuration utility t o validate consistency
between the reconfigurable-module implementations.
• Generate full and partial bitstr eams for the reconfigurable mo dules.
Figure  3-30 shows the hardware design flow implementing partial reconfigur ation.
X-Ref Target - Figure 3-30
Figure 3-30:  HW Design Flow for Partial Reconfiguration
RTL Module 1 System RTL Module 2
Implementation Implementation
Bitgen Program Bitgen Program
Static BitstreamPartial Bitstream Partial Bitstream
Synthesis
RM 1 RM 2Static Design
X14142-080117
.
Send Feedback

## Page 131

UltraFast Embedded Design Methodology Guide 131
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
System Design Flow
The Device Configuration (DevC) interface containing the AXI-PC AP bridge is used to
implement the partial reconfigur ation flow on a Zynq-7000 AP So C.
The following example summarizes the boot sequence for partial reconfiguration:
1. After power-on reset, the BootROM determines the external mem ory interface or boot
mode (SD flash memory) and the encryption status (non-secure). The BootROM uses the
DevC's DMA to load the First Sta ge Boot Loader (FSBL) into on-c hip RAM (OCM).
2. The BootROM shuts down and releases CPU control to the FSBL w hich in turn configures
the PL with the full bitstream via the PCAP.
3. The FSBL loads and releases co ntrol to the user application i n bare-metal OS.
4. The user application loads the partial bitstreams into DDR me mory during start-up. This
is to maximize the configuration  throughput over the PCAP inter face, speed up the
configuration time, and take advantage of cache.
5. The application can use the pa rtial bitstreams at any time to  modify the pre-defined PL
regions while the rest of the FP GA remains fully active and uni nterrupted. This is done
by transferring the reconfigurabl e module bitstream from DDR to  the PL via PCAP.
6. A single configuration engine handles both full configuration  and partial
reconfiguration. The task of loa ding a partial bitstream into t he PL does not require
knowledge of the reconfigurable m odule's physical location beca use
configuration-frame addressing i nformation is included in the p artial bitstream
Figure  3-31 shows the system level flow for  partial reconfiguration. The X ilinx device
configuration driver i mplements low-level AP Is to interact with  the PCAP block, and the
user application can call the AP Is to initiate the partial reco nfiguration flow. The user
application must be aware of the source addresses in the DDR wh ere the partial bitstreams
are stored.
Send Feedback

## Page 132

UltraFast Embedded Design Methodology Guide 132
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations

The example above shows how to l oad partial bitstreams from the  PS-DDR memory. In
general, the bitstreams can exis t in any external memory that t he device configuration
interface can access.
Managing Reconfiguration using U-Boot and Linux
You can use Linux and U-Boot to dynamically load the reconfigur able bitstream to the PL. If
an application is running on Linux and a portion of the hardwar e must be reconfigured, the
application can send a request to the Linux kernel to load the appropriate PL bitstream and
the corresponding kernel module s upporting the hardware device.
If the FSBL execution time is cr itical, you can use partial rec onfiguration to partition the
design so that the smaller bitstreams are loaded faster during FSBL execution. This reduces
overall boot time. U-Boot can co nfigure and initialize the rema ining design. Partitioning is
useful when a specific PL functions must be started within a sp ecific time limit.
You can encrypt the partially reconfigured bitstream using an e ncryption key. You can
decrypt using either U-Boot or Linux, depending on the applicat ion requirements. Once
decrypted, you can use the bitst ream to configure the PL using the PCAP interface.
X-Ref Target - Figure 3-31
Figure 3-31:  System Level Flow for PR
Programmable Logic
Processing System 7
Configuration
Flash
Top Switch DDR
Controller
AXI Master Interface
PCAP Interface
CPUBoot
ROM
FIFO FIFO
X14143-080117
.
.
Send Feedback

## Page 133

UltraFast Embedded Design Methodology Guide 133
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
GPs and Direct PL Access from APU
This section describes APU acce ss to registers and memory in th e PL through its AXI
general-purpose interfaces, the address requirements for AXI sl aves in PL, and issues
relating to security and performance. A system design is descri bed that deals with direct PL
access by ARM Cores and represents a typical use case.
The APU in PS can access registers and memory in PL using GP ma ster AXI interfaces, which
are part of the PS-PL interface. There are two GP master AXI in terfaces that the APU can use
to initiate an AXI transaction to a slave implemented in PL.
M_AXI_GP ports have the following features:
•A X I - 3  p r o t o c o l .
• Data bus width of 32-bits.
• Master port ID width of 12-bits.
• Master-port issuing capability of  eight reads and eight writes .
The AXI interfaces, M_AXI_GP0 an d M_AXI_GP1, each occupy 1GB of  system address space,
as shown in Table 3-3.
All APU accesses within the  address ranges shown in Table 3-3 pass through the
Interconnect in the PS to either M_AXI_GP0 or M_AXI_GP1, depend ing on the address. If the
transactions initiated by the APU are outside these address ran ges, the transactions will not
be routed to master GP ports.
Table 3-3:  Address Range of GP Ports
Interface Low Address High Address
M_AXI_GP0 0x40000000 0x7FFFFFFF
M_AXI_GP1 0x80000000 0xBFFFFFFF
Send Feedback

## Page 134

UltraFast Embedded Design Methodology Guide 134
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Figure  3-32 shows the path used by an APU  accessing an AXI slave in PL.
Performance
The GP ports are directly connected to the PS master interconne ct ports without FIFO
buffering, unlike HP ports that have FIFO buffering to increase  performance and
throughput. Therefore, GP ports are for general purpose and not  for high performance. The
GP port has a latency of 38 M_ AXI_GP interface clock cycles.
Design Considerations for AXI Master GP Port
• When AXI interconnect in the PL  is connected to the PS GP mast er AXI interface and the
HP AXI slave interface, you need to disable HP slave port acces s from the master port
GP. In the IP integrator address editor under processing_system 7 addressing, un-assign
the HP port address to avoid the address conflict.
• Accesses to the GP interface are  not cached by default. You ca n cache accesses by
changing the Translation  Lookaside Buffers (TLBs).
• When using the GP interface wit h an AXI interconnect in PL, sy stem software should
never access an address that does  not exist in the AXI intercon nect. This will avoid
permanent AXI interconnect lock-u p (there is no t imeout set by the AXI interconnect).
• The voltage translators at the PS-PL boundary must be configur ed before the APU uses
the master GP interface to access the AXI slave in PL. This is normally done by the FSBL.
X-Ref Target - Figure 3-32
Figure 3-32:  APU Accessing PL Slave through GP Port
Cortex A9
Snoop Control Unit
L2 Cache Controller
Master Interconnect
PL Slave
M_AXI_GP
X14144-080117
.
Send Feedback

## Page 135

UltraFast Embedded Design Methodology Guide 135
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 3: Hardware Design Considerations
Use Case
Figure  3-33 shows how the GP master AXI interface on the PS access AXI sla ve registers in
the PL to configure peripherals,  read status, and access DDR me mory.
The GP0 port is connected to a DDR controller to increase the D DR memory available to the
PS through the DDR controller in the PL. The GP1 port is used t o configure the AXI IIC and
AXI GPIO IP blocks. The TLB has to be changed to allow caching of PL DDR memory.
X-Ref Target - Figure 3-33
Figure 3-33:  APU Accessing AXI Slaves in PL
PL
PS
M_AXI_GP0 M_AXI_GP1
AXI Interconnect
AXI IIC AXI GPIO
DDR
Controller
DDR Memory
X14145-080117
.
Send Feedback

## Page 136

UltraFast Embedded Design Methodology Guide 136
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4
Software Design Considerations
This chapter covers the following software design issues to be considered when designing
with a Zynq ®-7000 AP SoC:
• Processor Configuration : Configuring the processor to meet system requirements is an
important consideration in imple menting an embedded system. Thi s section will help
you optimize the ARM cores to best fit your application needs.
• OS and RTOS Choices : This section will help you understand the pros and cons when
selecting the appropriate software platform for your embedded s ystem — OS, RTOS, or
bare metal.
• Libraries and Middleware : Libraries help you combine common and useful functions in
a single place so that they can be re-used by your applications . Middleware sits on top
of the operating system and reduces complexity by centralizing software stacks that
otherwise would be redundant in a n application layer. This sect ion describes how you
use libraries and middleware to  improve application-programming  productivity and
reliability.
• Boot Loaders : There are a variety of ways you can use to boot and bring up applications
in your embedded system. This section describes the Zynq-7000 A P SoC boot flow
options from power-up to  application execution.
• Software Development Tools : The Xilinx software develop ment tools you can use to
build software components for you r Zynq-7000 AP SoC are describ ed in this section.
Send Feedback

## Page 137

UltraFast Embedded Design Methodology Guide 137
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
Processor Configuration
To fully use an SoC in an embedd ed system, it is important to c onfigure the processor to
meet system requirements. This section describes the aspects to  consider. The content here
is specific to Zynq-7000 AP SoC s ystems, but it can be applied to any system.
Clock Speed and Multiple Cores
A good balance between power and performance can make an embedd ed system highly
effective and efficient. Processors can be configured to run at  lower clock frequencies than
the maximum limit, potentially sav ing power. If an operating sy stem supports multiple
processor cores, power could be saved by running the cores at a  lower frequency instead of
a single core at a high frequency. Power savings can be determi ned by analyzing the power
requirements and consumption of the multiple processor cores ru nning at the lower clock
frequency and comparing the resu lt with a single  core running a t a high clock frequency.
The processor clock frequency can be dynamically changed by sys tem software. When
running both processor cores, the y always run at the same frequ ency. Multi-threaded
software that scales across core s helps take full advantage of a multicore system. Such
software can increase performanc e by executing threads in paral lel, without pushing the
system to the maximum clock frequency.
SMP and AMP Configuration
Deciding to use a multicore proc essor affects the software syst em design, including
operating system selection. Most  multicore SoCs have an option to run the system as an
asymmetric multiprocessor (AMP) or symmetric multiprocessor (SM P).
An AMP configuration uses each processor core for different (us ually unrelated) tasks. Each
core works independently, and at  various times signals or synch ronizes with other cores to
exchange messages. Typically, each core has its own memory addr ess space, except for the
memory used to pass messages. In practice, the AMP configuratio n is typically used to run
different operating systems or di fferent, independent instances  of the same operating
system.
An SMP configuration uses multip le processor cores to perform t asks within the same
operating environment, such as w hen multi-core Linux runs multi ple tasks simultaneously. A
common scheduler is res ponsible for dispatching different tasks  on different processor
cores. The operation is symmetri cal because the system view fro m each core is identical.
Different AMP and SMP configurations use different cache cohere ncy and memory-sharing
implementations. The system's AMP or SMP behavior can be contro lled using the processor
core's system-control private re gisters (for example, CP15 in t he ARM v7 core).
Send Feedback

## Page 138

UltraFast Embedded Design Methodology Guide 138
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
Figure  4-1 and Figure  4-2 show typical examples of AMP and SMP systems, respectively
(processor refers to processor core).
Figure  4-1 shows two AMP examples:
• In example 1, each processor is allocated private memory, and that memory is not
shared between the processors. Both processors have access to c ommon memory and
a set of peripherals.
• In example 2, one processor doe s all memory operations but can not access the
peripherals. The second processor accesses the peripherals but does not perform
memory operations.
In Figure  4-2, both processors have equal a ccess to all peripherals and memo ry.
.
Using Coprocessors
Hardware coprocessors can improve  system performance. For examp le, using
NEON-specific instructions can i mprove performance if the syste m will perform lots of
floating-point or SIMD operation s. Those instructions use the N EON media coprocessor
capability in the ARM Co rtex-A9 MPCore processor.
X-Ref Target - Figure 4-1
Figure 4-1:  Typical AMP Configurations
X-Ref Target - Figure 4-2
Figure 4-2:  Typical SMP Configuration
Private
Memory Processor Processor Private
Memory
Common Memory I/O
Processor Processor
Memory
I/O
Asymmetric Multiprocessing Example 1 Asymmetric Multiprocessing Example 2
X14153-080117
.
Processor Processor
Memory I/O
Processor Processor
A Typical SMP Configuration
LAN
X14154-073117
Send Feedback

## Page 139

UltraFast Embedded Design Methodology Guide 139
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
Although the NEON technology is power-optimized, most coprocess ors are power-hungry.
However, because coprocessors are  designed for specific tasks, they are faster and more
power efficient than using the m ain processor fo r performing th ose tasks. Coprocessors
reduce CPU bandwidth and allow CP U power reduction when workloa d is reduced.
Co-processors execute specific in structions desig ned for their use. For example, the
Zynq-7000 AP SoC Spectrum Analyzer part 2-Building ARM NEON Library Tech Tip  [Ref 64]
shows how to use NEON libraries t o target the NEON capabilities  of a Zynq-7000 AP SoC.
Cache Considerations
Caches can greatly improve syste m performance and should be use d when possible. Most
SoCs have integrated L1 and L2 c aches. Each CPU core typically has a dedicated L1 cache
that can be individually configured for use by that core. The L 2 cache is usually shared by all
CPU cores. Coherency between the caches is maintained by a snoo p control unit (SCU), and
coherency decisions are determine d by the AMP or SMP multi-proc essor configuration.
The caches should be invalidated before they are enabled. The L 1 instruction cache must be
enabled at the beginning of the boot process (typically, by the  first-stage boot loader), and
it should not be disabled therea fter. The L1 and L2 data caches  can be configured and
enabled at a later time.
All cache operations are done on cache lines. The cache control ler can write back (flush) and
invalidate cache lines by cach e way or by physical address.
Usually, an SoC contains different ly ordered memory (such as st rongly ordered or device
memory), and the system can use or not use cache operations on that memory. Also, there
can be cache policies, such as w rite-through or write-back, tha t are program specific.
If any system peripheral uses memory that is shared with the CP U, coherency between that
memory and the CPU cache should be maintained by software using  cache operations
(which are costly). Similarly, i n some complex systems, a perip heral might have access to
cached memory for improved performance. In that case, coherency  between the peripheral
cache, memory, and the CPU cache  should be maintained by softwa re. The software
overhead of maintaining coherency introduces latency. The laten cy can be avoided by using
the hardware coherency provided by cache-coherent ports, such a s the accelerator
coherence port (ACP).
Zynq-7000 AP SoC systems provide a n ACP that gives external por ts access to processor
caches. An ACP allows other non-c ached master peripherals and a ccelerators, such as a
DMA engine or cryptographic acce lerator core, to be cache-coher ent with the processor
core L1 caches.
Send Feedback

## Page 140

UltraFast Embedded Design Methodology Guide 140
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
Processor State after Power on Reset
In the Zynq-7000 AP SoC, both processor cores start after power -on reset (POR). CPU0
starts at address 0x0, where BootROM loads the first-stage boot  loader. CPU1 is sent into a
wait-for-event (WFE) loop. Any interrupt will cause CPU1 to wak e up and exit the WFE state.
The boot loader, kernel, or equivalent software is typically re sponsible for starting CPU1 at
a later time, when it is going to be used.
In most cases, DDR memory is not initialized at POR, so the fir st-stage boot loader is loaded
into simpler memory, such as on- chip memory, and is mapped to a ddress 0x0 in the SoC.
ARM processors start in supervis or (SVC) mode after POR. Then, the kernel or equivalent
software changes the ARM p rocessor mode as required.
Interrupt Handling
ARM cores provide a generic inte rrupt controller (GIC) and priv ate peripheral interrupt (PPI)
controller for handling interrupt s. The GIC has a flexible appr oach to inter-processor
communication, and the routing an d prioritization of system int errupts. Software can
control up to 224 independent interrupts. Each interrupt can be  distributed to one or both
processor cores, hardware-priori tized, and routed between the o perating system and the
ARM TrustZone technology software management layer (see Secure Configurations ). There
are also priority mask registers that allow interrupts below a specified priority to be
ignored.
Apart from the GIC, a processor core can mask all incoming inte rrupts by setting an
interrupt mask in a processor syst em control register. In ARM p rocessors, the IRQ and FIQ
lines can be masked independent ly for each processor core.
Interrupt handlers should be configured at the beginning of the  kernel boot-up. There are
three possible interrupt sources:
• Private Peripheral Interrupts (PPIs):
These per-processor-core interru pts have limited  function. They  include FIQs, CPU
watchdogs, CPU timers, and some IRQs which might include interr upt signals from FPGA
logic.
• Shared Peripheral Interrupts (SPIs):
These interrupts are shared between the processor cores. The GI C decides how to
distribute the SPIs to particula r processor cores. These are ge nerally hardware
interrupts, and there can b e large numbers of them.
• Software Generated Interrupts (SGIs):
These are synchronous interrupts  generated by writing an interr upt number on a
particular SGI register on the system.
Send Feedback

## Page 141

UltraFast Embedded Design Methodology Guide 141
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
You can configure the GIC registers to handle the interrupts li sted above. Figure  4-3 shows
the interrupt routing mechanism of GIC v1.0 (PL310).
Timers
Each processor core ha s private timers that can be used in the context of that processor
core. The timers can be useful f or tracking the core run time, instead of the entire system.
The SoC also has global timers t hat give system-wide timing inf ormation. Interrupts
generated by these timers are pr ivate peripheral interrupts (PP Is) and are assigned on a
per-processor-core basis. Timer interrupts are often essential to system operation, because
they are used for scheduling and time-slicing tasks.
MMU Configurations
Most operating systems, like Linux , require a virtual memory sy stem. The memory
management unit (MMU) is a hardw are block that facilitates virt ual-memory access. The
MMU uses data structures, such as  page tables, for address tran slation. The
operating-system kernel must configure the MMU and set up page tables to implement the
virtual-memory system. Different  page tables are required for d ifferent operating-system
modes, such as the secure mo de of TrustZone technology.
X-Ref Target - Figure 4-3
Figure 4-3:  Interrupt Handling
Software
Generated
Interrupts
(SGI)
CPU 0
Distributor
Private
Peripheral
Interrupts  (PPI)
Interrupt Control Distributor (ICD)
CPU 1
Distributor
Shared Peripheral
Interrupts (SPI)
Input/Output
Peripherals (IOPs)
Programmable
Logic (PL)
SGI Distributor
CPU  0  Timer
and  AWDT
PL FIQ0, IRQ0
Private
Peripheral
Interrupts  (PPI)
CPU  1  Timer
and  AWDT
PL FIQ1, IRQ1
Software
Generated
Interrupts
(SGI)
nIRQ
nFIQ
nIRQ
nFIQ nIRQ
nFIQ
nIRQ
nFIQnIRQ
nFIQ
System
Watchdog
Timer
nIRQ
nFIQ
CPU 1
CPU 0
X14155-073117
CPU 0
CPU 1
CPU 1
Send Feedback

## Page 142

UltraFast Embedded Design Methodology Guide 142
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
Secure Configurations
The Zynq-7000 AP SoC provides an option of dividing a system in to two worlds, secure and
non-secure, by using the TrustZo ne technology mechanism. The pr ocessor mode must be
switched to monitor mode (secure  mode) to enter the secure worl d for performing secure
operations. Also, there must be a separate MMU configuration fo r the different worlds.
For more information on TrustZone technology, see TrustZone Security .
OS and RTOS Choices
Operating system software manages the operations and protects t he hardware resources of
a computing system. An OS or RTOS can support multitasking and manage resource usage.
Bare-metal software can serve as  a minimal implementation of ne cessary
system-management functions. This section covers comparisons of  system-management
types, hardware requirements, available OS and RTOS ports, runn ing multiple OSs, and
development and debug tools.
There are also security consider ations between a monolithic OS and a microkernel. A
full-featured monolit hic OS like Linux uses the MMU for secure and non-secure memory
regions, whereas a microkernel R TOS does not use the MMU and th us will not offer the
same memory protection as a mono lithic kernel. For details, ref er to the Xilinx Security
Solutions webpage [Ref 48].
Types of Embedded-System Software
Table 4-1 compares features of bare-metal, RTOS, and OS system-managemen t software.
Table 4-1:  Bare-Metal Software, RTOS, and OS Comparison
Bare Metal Software RTOS General-Purpose OS
Capabilities Simple Simple to Advanced Advanced
Hardware
abstraction
None Minimal High-level
Multi-tasking No Yes Yes
Real-time Guaranteed response time Guaranteed response time As quickly as possible
Memory
management
None Basic memory protection Advanced virtual-
memory management
Code footprint Small (KBs) Small to Medium (KBs to MBs) Medium to Large (MBs)
Example Bare-metal software with
SDK
VxWorks, FreeRTOS Windows Embedded,
Linux
Open-source
considerations
Available with Vivado ®
and SDK tools. These tools
require specific licenses.
Some are available with
open-source licenses, some
are paid versions
Some are available with
open-source licenses,
some are paid versions
Send Feedback

## Page 143

UltraFast Embedded Design Methodology Guide 143
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
The selection of system-manageme nt software can depend on the f ollowing factors:
• Prior-Experience and/or Existing Solutions:  This approach to selecting
system-management software saves  time and validat ion effort. It  also simplifies
designing systems with variations of an existing OS or RTOS wit h added features. This is
because of the learning curve in volved in using a new OS or RTO S with a different set of
supported features.
• Capabilities:  OSs and RTOSs differ in their features and middleware support.  It is
important to select one based on  the needs of the overall syste m design, such as
middleware stacks for USB, TCP /IP, and file-system support.
• Configurability:  Some RTOSs have GUI-based confi guration options used to enable
caches, prioritize interrupts, select the RTOS tick periods, et c. Full-featured OSs like
Linux can be feature-conf igured using tools like menuconfig . These configuration
interfaces and tools save time and highlight available feature options.
• Performance:  Interrupts and task-switching l atencies may vary between diffe rent OSs
and RTOSs. Thoroughly investigat e the hard real-time, soft real -time, and overall
latencies when choosing an OS or RTOS.
• Memory Size:  Memory-size requirements for an  OS, RTOS, and application task s need
to be estimated when choosing an OS or RTOS.
• Cost:  There are free GNU license-based OSs or RTOSs. Some vendors ch arge, based on
their support and services model:
° Bare-metal BSP and drivers are p rovided free with Xilinx develo pment environments
like the SDK.
° RTOS selection can be based on free or paid commercial licenses , depending on the
features and support model.
° Linux selection can be based on free or paid commercial license s, depending on the
features and support model.
° Commercial variants come with sup port and additional features, like USB
middleware stacks or R TOS file-system stack.
• Application Requirements:
° If an application needs advanced software with ready-made libra ries, then consider
a full-featured OS , such as Linux.
° If an application needs hard rea l-time response for many tasks,  then consider an
RTOS like freeRTOS.
° If an application needs both a f ull-featured OS and real-time r esponse, then
consider a multi-OS environment like Linux Symmetric Multi-Proc essing (SMP) with
real-time patches, or asymmetric  multiprocessing (AMP) with Lin ux and RTOS
running on the dual ARM cores or hypervisor.
Send Feedback

## Page 144

UltraFast Embedded Design Methodology Guide 144
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
Hardware Requirements for Running an OS or RTOS
An OS or RTOS requires the following:
• System Timer:  This is a hardware timer for th e kernel heartbeat, like jiffie s in the Linux
OS. The timer is used by the OS or RTOS for all time-related ke rnel activities, such as
scheduling and delays.
• Memory Footprint:  As low as 5 to 30 KB of RAM and ROM for an RTOS. A few KBs to
100 MBs for Linux OS, based on th e kernel and services configur ation selections.
• Memory Management Unit (MMU):  Required for a full-featured, general-purpose OS
like Linux. May be used for memory protection by some RTOS impl ementations.
The Zynq-7000 AP SoC has all the hardware resources to run an R TOS and/or a full-featured
OS like Linux. Achieving the time  determinism of a real-time so lution depends on many
other factors, like resource-all ocation and access times, overa ll solution architecture, etc.,
along with an RTOS.
OS and RTOS Ports
There following describes several example OS and RTOS ports to the Zynq-7000 AP SoC, but
the full list is not limited to this information.
Linux OS and PetaLinux Tools
The Xilinx ® Linux distribution includes the  Linux OS and a complete config uration, build,
and deploy environment for the Zynq-7000 AP SoC. Because PetaLi nux is full-featured,
integrated, tested, and document ed, it is the recommended and s upported Linux
deployment mechanism for Xilinx customers. As a Xilinx product,  PetaLinux has the same
level of product management, support, bug-tracking, and emphasi s that other Xilinx tools
receive.
Although the Linux OS built using  the PetaLinux Tools is based on a stable and thoroughly
tested Linux kernel, also from  the Xilinx Git server, PetaLinux  offers much more than what
can be downloaded from the Xilinx Git server. PetaLinux include s an installer, development
tools, board support packages (B SPs), platform-management utili ties, application and
library frameworks, and documenta tion. PetaLinux is available u nder no-charge and
commercial licenses, as described in the PetaLinux licensing pa ge. All PetaLinux users are
entitled to community (forum-base d) support; commercial license es may also access
support directly from Xilinx. For details, see the Xilinx Linux  wiki page [Ref 56] and the Xilinx
PetaLinux wiki page [Ref 58].
Xilinx's PetaLinux Tools supports configuring, customizing, bui lding, and packaging a Linux
BSP for full-featured OS functi onality on the Zynq-7000 AP SoC.  For details on how to
configure and use these BSPs, re fer to the Xilinx PetaLinux Too ls web site [Ref 50].
Send Feedback

## Page 145

UltraFast Embedded Design Methodology Guide 145
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
OS and RTOS Ecosystem
In addition to the Xilinx OS and RTOS ports, described above, t he Zynq-7000 AP SoC has
strong ecosystem support product s from 3rd-party and alliance m embers. These products
may have differences in supported  features, context-switch perf ormance, interrupt
latencies, technical support, and  in their middleware support f or file systems, USB, PCIe,
Ethernet, etc.
Table 4-2 and the following sections desc ribe the 3rd-party and alliance  member ecosystem
solutions. For additional infor mation, refer to the Xilinx Zynq -7000 AP SoC Ecosystem
webpage [Ref 49].
Quadros Systems Features
RTXC RTOS, from Quadros Sy stems, has these features:
Table 4-2:  OS, RTOS, and Middleware Products
Alliance Member OS, RTOS, and Middleware Products More
Information
Adeneo Embedded Windows Embedded Compact 7,  Linux, Android, and QNX [Ref 86]
Discretix Security-centric software and IP solutions [Ref 79]
ENEA Software AB OSE RTOS and ENEA Linux [Ref 80]
eSOL uITRON 4.0 RTOS, T-Kernel RTOS and IDE [Ref 81]
Green Hills Software INTEGRITY RTOS [Ref 83]
Express Logic ThreadX RTOS [Ref 82]
iVeia Android On Zynq-7000 AP SoC [Ref 86]
Mentor Graphics Nucleus RTOS [Ref 87]
Micrium µC/OS RTOS [Ref 88]
MontaVista Software MontaVista Carrier Grade Linux [Ref 89]
Open Kernel Labs OKL4 Microvisor [Ref 92]
QNX QNX Neutrino RTOS [Ref 93]
Quadros RTXC RTOS
For information about features, see Quadros Systems
Features, page  145
[Ref 94]
Real Time Engineers Ltd. FreeRTOS [Ref 95]
Sciopta Sciopta RTOS [Ref 96]
Sierraware Open source SierraVisor Hypervisor and SierraTEE Trusted
Execution Environment
[Ref 97]
SYSGO PikeOS [Ref 98]
[Ref 99]
Timesys LinuxLink [Ref 101]
Wind River VxWorks, Linux, and Workbench IDE [Ref 102]
Send Feedback

## Page 146

UltraFast Embedded Design Methodology Guide 146
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
• Small, scalable footprint to fit  any ROM or RAM budget (typica lly 25 KB or less)
• Delivered in source code, with sample code for a working proje ct using ARM DS-5
development tools
• Graphical configuration program, RTXCgen, for ease of building  the application's RTOS
• Graphical trace tool, RTXCview,  for visibility into system per formance and behavior
• RTXC/mp available for asymme tric multiprocessing (AMP)
• License fees apply
The following middleware stacks a re supported along with RTXC R TOS:
• Ethernet TCP/IP v4 and v6
• Ethernet packet prioritization
• Ethernet security suite
• Application server:
° AJAX, JSON, and XML-RPC
° Remote device management, with p ersistent sockets (WebSockets)
° Remote GUI
• USB host and device
• High performance, fail-safe file systems:
° NAND and NOR
° SD, MMC, and flash drive
Support for Zynq-7000 AP SoC and  ZC702 development boards:
• Timer initialization
• UART initialization
• MMU initialization
• Interrupt controller setup and initialization
Send Feedback

## Page 147

UltraFast Embedded Design Methodology Guide 147
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
• Instruction- and data-cache initialization.
• Advanced support for ARM Vector Floating Point (VFP) and NEON:
° Explicit or automatic enabling of  VFP-register context extensio ns for tasks that use
VFP or NEON.
° Optional support for a VFP and NEON register set that reduces c ontext-switch
overhead.
° Uses “lazy swapping” to minimize interrupt latency and context- switch overhead for
VFP and NEON register sets.
° Control of VFP context, such as manual suspend and automatic or  manual resume.
Fine-level control allows application to minimize VFP-register context overhead in
non-VFP and non-NEON execution p aths. Useful in mostly integer environments in
which tasks rarely need VFP or NEON, except in isolated functio ns. When used with
lazy swapping, explicit suspend c ontrol can be used to improve overall system
throughput.
Real Time Engineers Ltd.
FreeRTOS is free to use without any need to expose custom code.  FreeRTOS supports
real-time tasks, queues, binary semaphores, counting semaphores , mutexes, etc., for
communication and synchronization between tasks and interrupt-s ervice routines. The
FreeRTOS memory footprint is about 4 to 9KB. The middleware sta cks supported with
freeRTOS include:
• FAT file system
• UDP/IP and TCP/IP stacks
•C L I
•S a f e t y
• CyaSSL SSL/TSL
Multi-OS
There are multiple ways to enabl e multiple operating systems ru nning on both CPU cores of
the dual-core ARM Cortex-A9 MPCo re processor in the Zynq-7000 A P SoC. See the
following links for information a bout the symmetric and asymmet ric multi-processing
options:
• Zynq-7000 All Programmable SoC Software Developers Guide  (UG821) [Ref 7]
• Xilinx Multi-OS Support wiki page [Ref 57]
Send Feedback

## Page 148

UltraFast Embedded Design Methodology Guide 148
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
Simple AMP
A simple multi-OS AMP implementation can consist of running, fo r example, Linux OS and
a bare-metal application or of r unning two bare-metal applicati ons.
The two CPU cores of the ARM pro cessor share memory and periphe rals. Asymmetric
multi-processing (AMP) is a mech anism that allows both cores to  run their own operating
systems or bare-metal applicatio ns with the possibility of loos ely coupling those
applications via shared resources. Figure  4-4 shows an example of AMP with Linux OS and
a bare-metal application. Figure  4-5 shows an example of AMP with Linux OS and an RTOS.
Referring to Figure  4-4, AMP with Linux OS and a bare-metal application operates as
follows:
• Linux runs on CPU0.
° Linux then starts the CPU1 execut able loaded into memory by the  FSBL.
• The bare-metal application runs  in dedicated memory space on C PU1.
° MMU0 is used by Linux as normal. MMU1 is used to define the bar e-metal
application’s memory context, bu t no special coding is required .
° The bare-metal application does n ot run within the Linux memory  context.
° Linux is not aware of the  memory used by CPU1.
X-Ref Target - Figure 4-4
Figure 4-4:  AMP with Linux OS and Bare-Metal Application
Zynq
CPU 0 CPU 1
Linux Executable Code
Linux User
Apps
X14160-073117
Send Feedback

## Page 149

UltraFast Embedded Design Methodology Guide 149
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
The MMU can be used to contain the application.
° The MMU defines what addresses (memory and AXI devices) the app lication can
access normally.
° CPU1 is not restricted  from accessing the Linux memory spaces o r shared devices
(ICD or SCU), but Linux can detect if and when that occurs and take the appropriate
action.
• Implementation approach.
° Communication between Linux and t he bare-metal application use the OCM.
° OCM caching is disabled for improved determinism.
• The use case is supported by X ilinx Worldwide Technical Suppor t department.
For more information, refer to:
• Simple AMP: Bare-Metal System Running on Both Cortex-A9 Processors  (XAPP1079)
[Ref 39]
• Simple AMP Running Linux and Bare-Metal Sy stem on Both Zynq-7000 AP SoC Processors
(XAPP1078) [Ref 38]
Referring to Figure  4-5, AMP with Linux OS and RTOS operates as follows:
• The firmware runs in dedicated memory space at address 0x0000_ 0000.
° The FreeRTOS kernel does not run within the Linux memory contex t.
° Linux can read and write this add ress space just like it can re ad any other device
memory.
X-Ref Target - Figure 4-5
Figure 4-5:  AMP with Linux OS and RTOS
Zynq
CPU 0 CPU 1
Linux FreeRTOS Kernel
Non Critical
Apps
X14161-073117
Critical Tasks
Send Feedback

## Page 150

UltraFast Embedded Design Methodology Guide 150
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
• The MMU limits how firmware affects Linux.
° The MMU defines what addresses (memory and AXI devices) the app lication can
access normally.
° The granularity is 1 MB. If two devices lie in a 1 MB region yo u cannot isolate one
without the other.
° The GIC is shared betw een firmware and Linux.
- Interrupts are routed to firmware or Linux by the GIC.
- Firmware is not prevented from reconfiguring the GIC.
• The Linux kernel is not preve nted from corrup ting firmware.
° However, violations should only occur from explicit calls or th rough specific types of
crashes.
° System design and comprehensive testing may mitigate customer r eal-world
concerns.
• Implementation approach.
° Should be applicable to other flat RTOS.
° Might be applicable to RTOS using  virtual memory (such as kerne l and user space).
For an overview of the Linux OS and FreeRTOS AMP design shown i n Figure  4-5, refer to
PetaLinux Tools User Guide: Zynq All Programmable SoC Linux-FreeRTOS AMP Guide  (UG978)
[Ref 17].
ARM Cortex-A9 TrustZone
The Zynq-7000 AP SoC supports the ARM Cortex-A9 TrustZone techn ology, according to
the recommendations of the Trust ed Base System Architecture spe cification. This
technology enables the developme nt of platforms that support a Trusted Execution
Environment (TEE)  and security-aware app lications and secure se rvices, or Trusted
Applications (TA). A TEE is a sma ll, secure kernel that is typi cally developed with standard
APIs according to the TEE specifi cation evolved by the Global P latform industry forum.
The TrustZone technology support s development of separate Rich Operating System and
TEE environments by creating operating modes, in addition to th e Normal domain, that are
known as the Monitor mode and th e Secure domain. The Secure dom ain has the same
capability as the Normal domain but it operates in a separate m emory space. A Secure
Monitor acts as a virtual gatek eeper to control migration betwe en the domains.
Send Feedback

## Page 151

UltraFast Embedded Design Methodology Guide 151
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
Development and Debugging Tools
The development and debugging tools available to support your a pplication are described
below.
Xilinx Software Development Kit
The Xilinx Software Development K it (SDK) provide s a variety of  Xilinx software packages,
including drivers, libraries, bo ard-support packages, and compl ete operating systems, for
developing a software platform.
TIP: The Software Development Kit Design Hub in th e Documentation Navigator provides links to
additional information about Usin g the Software Development Kit and embedded design. For more
information, see Related Design Hubs .
The Xilinx SDK is a complete deve lopment environment, including :
• Platform-aware BSP generation
• Sample application-code generat ion, ranging from memory tests to TCP/IP echo
servers
• Cross-compilation tools
• Application profiling
• Linker-script generation
• Debug interfaces through JTAG
• Target communication framework
• Remote debugging
• Heterogeneous multicore debugging
•F l a s h  l o a d e r s
• Boot-file creation for secure  and non-secure environments
• First-stage boot loader (FSBL) generation
SDK supports Linux-kernel debugg ing through JTAG and applicatio n thread-level
debugging using the target commu nications framework (TCF) agent  and GNU GDB
infrastructure.
Send Feedback

## Page 152

UltraFast Embedded Design Methodology Guide 152
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
ARM DS-5 Development Studio
ARM DS-5 Development Studio is a complete development environme nt that supports
Linux, Android, and RTOS debuggin g. For details on using the DS -5 with a Zynq-7000 AP
SoC, refer to the Xilinx XC702 DS-5 Getti ng Connected Guide  [Ref 103] and the Zynq-7000
Platform Software Development Using the ARM DS-5 Toolchain  (XAPP1185) [Ref 44].
IAR
The IAR Systems' debugger suppor ts OS and RTOS kernel-level deb ugging. For more
information, see the IAR Integrat ed Solutions Partner Program w eb site [Ref 85].
Libraries and Middleware
This section summarizes how stat ic and dynamic libraries and mi ddleware can be used to
improve application-programming  productivity and reliability.
Libraries
Libraries are a convenient method of combining common and usefu l functions into a single
unit that can be re-used by progr ams. A library abstracts imple mentation details and
provides a tested and optimized behavior that can be easily inc orporated into programs.
Libraries support static  and dynamic linking.
Libraries can be categorized int o commonly used libraries and d omain-specific libraries:
• Examples of commonly used libra ries include GNU C, GNU C++ lib rary, POSIX Pthread
libraries.
• Examples of domain-specific lib raries include Intel Threading Building Bloc ks (parallel
processing), FFmpeg audio, OpenC V, direct rendering manager (DR M), kernel mode
setting (KMS), ARM OpenMAX DL sample software library (audio/vi deo processing),
and MATLAB engine library ( mathematical processing).
Benefits of Libraries
• Provide behavior and code reusa bility (the write-once, use-man y approach).
• Speed up application developmen t by abstracting underlying har dware and software.
• Provide easily maintainable cod e that reduces testing resource s.
For example, the GNU C library is well-tested, and bugs are fix ed regularly. Because of this,
using the library saves substanti al testing and development res ources.
Send Feedback

## Page 153

UltraFast Embedded Design Methodology Guide 153
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
Xilinx Libraries for Stand-Alone Systems
The Xilinx Software Development K it (SDK) provides a set of reu sable libraries and drivers
for Zynq-7000 AP SoC processing system (PS) and programmable lo gic (PL) components.
These libraries and drivers include:
• libxil.a — Device drivers for peripherals.
• LibXil MFS — A me mory file system.
• LibXil FFS — A generic FAT file  system based on an open source  implementation. It is
primarily used with the SD/eMMC d river and a glue layer is impl emented to link it to
that driver.
• LibXil Flash — A library that p rovides read, write, erase, loc k, unlock, and
device-specific functions for parallel flash devices.
• LibXil Isf — An in-system flash  library that supports the Xili nx in-system flash hardware
and serial flash on SPI/QSPI.
• LibXil SKey — The LibXil SKey library provides a programming m echanism for
user-defined eFUSE bits. The PS eFUSE holds the RSA primary key  hash bits and user
feature bits, which can enable  or disable some Zynq-7000 AP SoC  processor features.
• lwIP — A third-party, light-wei ght TCP/IP networking library.
Libraries are classified into two types, static and dynamic, ac cording to the type of linkage
object.
Static Libraries
Static libraries are a collectio n of object files that become, after linking, part of an
application image. In Linux, the se libraries are called archive s. The file names of static
libraries conventionally end with a. a suffix.
Advantages
• Simple to use; external depende ncies are resolved at compile t ime.
• Shorter compilation time.
• Runs slightly faster. In theory, code in static E LF libraries that is linked into an
executable should run 1% to 5% f aster than a shared library or a dynamically loaded
library.
• Simplifies makefile link steps,  because the linker takes care of searching and extracting
object files required  by the application.
Send Feedback

## Page 154

UltraFast Embedded Design Methodology Guide 154
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
Disadvantages
• Changes to static libraries req uire rebuilding all dependent a pplications.
• Executable memory footprint becomes larger.
• If processes that share an object library run simultaneously, the code and data sections
of the object library are copied  into the address space of each  process.
When to Use
Static linking is often the easi est way to distribute an applic ation because it relieves the user
from the task of distributing an y dependent library with the ta rget application.
Dynamic Libraries
Dynamic libraries are loaded whe n an application that uses them  is executed. A single copy
of the object library is shared among multiple applications, so  that the library's code and
data sections do not become part  of application's address space . Shared objects are not
copied into each application prog ram area. Instead, a single co py of the object library is
loaded into memory at run time when the first application requi ring that library is executed.
In Linux, the naming convention for dynamic-library files has a  lib prefix, the name of the
library, and the string .so followed by a version number that is incremented whenever the
interface or implementation changes.
Advantages
• Smaller executable memory footpr int than for static libraries.
• If an object library is changed , dependent applications simply  need to be re-executed.
Disadvantages
• Libraries are dependent on the run time loader. In Linux, the dynamic loader (ld.so) is
part of the GNU C library and is responsible for loading all de pendent shared libraries.
• Symbol relocation is performed at run time. Because of this, a pplications using a shared
dynamic library may tak e slightly more time to execute than a s tatic-library
counterpart.
Running an executable on a target platform requires that the cu stom shared library path be
added to the search path of the dynamic linker. The LD_LIBRARY_ PATH environment variable
specifies to the run time linker  that the custom shared library  resides at some particular
location.
Send Feedback

## Page 155

UltraFast Embedded Design Methodology Guide 155
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
When to Use
Use a dynamic library when the lib rary is shared between multip le applications. For
example, use embedded run time l ibraries like the GNU C library  in this manner.
One such use case can be found i n a Xilinx Zynq-7000 AP SoC Tec h Tip demonstrating use
of the ARM NEON Library on a ZC702 platform. Refer to Xilinx Zynq-7000 AP  SoC Spectrum
Analyzer part 2-Building AR M NEON Library Tech Tip  [Ref 64].
The Tech Tip describes the proce ss of obtaining and building a set of filtering functions
targeting the Zynq-7000 AP SoC Z C702 platform. Many application s that can take
advantage of the processing ca pabilities of the  Zynq-7000 AP So C involve complex
calculations used in filtering, video manipulation, and signal processing.
An open source project within th e ARM community p rovides a libr ary of common, useful
functions accelerated by NEON that you can use when developing applications. This has
evolved into the Ne10 project and the Ne10 library.
Middleware
Middleware is a set of libraries t hat runs between the operatin g-system and application
layers. In embedded systems, mi ddleware is system software that  sits on top of the
operating system or is sometimes  included as part of the operat ing system. For example,
common middleware such as a TCP/IP communica tion stack is typic ally part of modern
operating systems.
Middleware reduces complexity by centralizing software stacks t hat otherwise would be
redundant in an application laye r. There are many type of middl eware, including
message-oriented middleware (MOM) , remote procedure call (RPC),  and networking
protocols above the device-drive r layer and below the applicati on layer.
Examples
• TCP/IP stacks
•U S B  h o s t  s t a c k
• Controller area n etwork (CAN) stack
• Multimedia middleware stack
Advantages
•F a s t  d e v e l o p m e n t  o f  r o b u st and powerful applications
• Does only what is unique to the application
• Supports scalability and abstraction
• Reliability
Send Feedback

## Page 156

UltraFast Embedded Design Methodology Guide 156
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
Use Case
lwIP is an open source TCP/IP pr otocol suite available under th e BSD license. Although it
can be used with an operating system, lwIP is a stand-alone sta ck without operating system
dependencies. The use-case demon strates how you can integrate m iddleware, such as a
lightweight IP (lwIP) network sta ck, into a stand-alone applica tion.
The Xilinx software development k it (SDK) provides lwIP softwar e customization. The lwIP
stack supports IP, ICMP, IGMP, UDP, TCP, and other networking p rotocols. By using the lwIP
stack, you can focus on developi ng your application core and le ave the TCP/IP
implementation to the lwIP stack.
For more information about how to integrate an open-source netw ork stack into an
application development, refer to LightWeight IP (lwIP) Application Examples (XAPP1026)
[Ref 37].
Boot Loaders
A boot loader is the software that initializes the system in pr eparation for execution of the
next level of software, such as an operating system. Usually, e ach operating system has a set
of boot loaders specific for it.  Boot loaders usually contain s everal ways to boot the OS
kernel and also contain commands for debugging and/or modifying  the kernel
environment.
Details of the boot process depend on the complete system desig n and choice of OS, such
as embedded Linux, RTOS, or bare-metal OS. The number of stages  in booting also may vary
based on the system design. This section describes the boot flo w of the Zynq-7000 AP SoC,
from power-up to application execution.
Boot Process
The Zynq-7000 AP SoC boot process can be a multist age boot, dep ending on the system
requirements. This section descr ibes three broadly divided stag es of booting and their role
in the booting process. Figure  4-6 shows the steps while boo ting embedded Linux and
application code on a Zynq-7000 AP SoC.
When power is applied to the SoC, the boot process starts from the BootROM. This process
loads and then starts executing the first-stage boot loader (FS BL) from on-chip memory
(OCM). The FSBL configures the s pecific initialization. Then, b ased on the software
architecture, the second-stage  boot loader (SSBL), such as U-Bo ot in the case of embedded
Linux, is initialized and execute d. The FSBL and/or SSBL start the RTOS or embedded Linux
and the application code.
Send Feedback

## Page 157

UltraFast Embedded Design Methodology Guide 157
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
Stage 0
At power-on or reset, the ARM co re runs initialization code fro m the BootROM. The
BootROM code cannot be changed; it is a factory pre-programmed code that comes with
each Zynq-7000 AP SoC. The BootROM code determines the device o n which the next-level
loader is located by reading the boot-mode pins. Depending on t he boot-mode setting, the
FSBL is copied from either NAND,  parallel NOR, s erial NOR (Quad -SPI), or Secure Digital
(SD) flash memories to the OCM.
X-Ref Target - Figure 4-6
Figure 4-6:  Boot Flow
Start
BootROM
First Stage Boot Loader
(FSBL)
BitStream (Optional)
Next Executable Image: Either U-
Boot or Standalone application
Linux OS & ApplicationIs U-Boot?
Yes
X14156-073117
Standalone Application
No – Execute
standalone app
Send Feedback

## Page 158

UltraFast Embedded Design Methodology Guide 158
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
Figure  4-7 shows the standard (non-secure) boot flow. The secure boot flo w is described in
Embedded Device Security
Stage 1
The FSBL gets execution control from the BootROM and either run s from the OCM or
execute-in-place flash based on the boot mode settings. The FSB L initializes the PS and
looks for a bit file in the boot device. If found, the FSBL wri tes the bit file to the PL. Whether
or not a bit file is found, the FSBL loads application binaries  and data files into memory until
the complete image has been read from the boot device. Then the  FSBL starts executing the
first application bina ry that was loaded.
Typically, the FSBL initializes t he external RAM and loads the second-stage boot loader
(SSBL) or a stand-alone application. Based on the software arch itecture, if it is a full featured
OS like embedded Linux the SSBL (such as U-Boot in the case of embedded Linux) is
initialized and executed. The FSB L and/or SSBL start the RTOS o r embedded Linux and the
application. Then, the FSBL hands over control by jumping to th e start address of the SSBL,
in the case of a full-featured O S like embedded Linux, or to an  RTOS or application.
Stage 1 can include the user app lication if it is small enough to fit in OCM memory.
The Zynq-7000 AP SoC supports both secure and non-secure boot m ethods. The boot-ROM
code flow for both methods is described below.
X-Ref Target - Figure 4-7
Figure 4-7:  Non-Secure Boot Flow
Found
Valid
Image?
Yes
X14157-073117
Execute
In-Place?
BootROM
Increment to the next
32K offset
Load FSBL
To OCM
Jump to FSBL
StartJump to
Flash Offset
Yes
No
No
Start
Send Feedback

## Page 159

UltraFast Embedded Design Methodology Guide 159
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
For secure boot, the principal security objective of the SoC is  to lay a foundation of trust. It
does this using integrity, confidentiality, and authentication from the time power is applied
to the time control is asserted. The SoC also provides a method  for maintaining this trust.
The SoC does this by using the P L's built-in Advanced Encryptio n Standard (AES-256) and
hashed message authentication co de (HMAC) engines, and the RSA authentication
capability of the PS.
The SoC boots securely unless it is changed from a secure to a non-secure mode. The first
decision point is the initial load of the FSBL. If the FSBL is encrypted, the BootROM code
boots securely and hands control off to the FSBL securely, whil e disabling JTAG. If the FSBL
is not encrypted, the AES 256 and  HMAC engines are disabled and  the JTAG ports can be
accessed. To enable RSA authentication, the RSA Enable eFUSE mu st be programmed.
The Xilinx design tools allow spec ifying whether the software a nd bit-stream partitions are
authenticated using the public-k ey RSA algorithm and whether su bsequent images are
encrypted and authenticated usin g the AES and HMAC engines. An unencrypted partition
can also be specified. This allo ws use of both public- and priv ate-key algorithms on a
partition basis.
Alternatively, when configuratio n time is critical, a trade off  can be made between security
and boot time, because configuration speed is faster for unencr ypted partitions than for
encrypted partitions. A relative ly large, open-source U-Boot or  Linux image, for example,
loads faster if the image is unencrypted. If any of the secure features are selected, the initial
FSBL, at a minimum, must be encr ypted with AES-256 and authenti cated with the HMAC
algorithm.
Figure  4-8 shows the FSBL flow for secure boot mode. Figure  4-9 shows the FSBL flow for
non-secure boot mode.
For more information about secur e boot of the Zynq-7000 AP SoC,  refer to the following
documents:
• Secure Boot in the Zynq-7000 All Programmable SoC  (WP426) [Ref 35]
• Secure Boot of Zynq-7000 All Programmable SoC  (XAPP1175) [Ref 42]
Send Feedback

## Page 160

UltraFast Embedded Design Methodology Guide 160
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
X-Ref Target - Figure 4-8
Figure 4-8:  FSBL Flow for Secure Boot
Authentication Certificate?
Initialization
Read Partition Header
RSA Verify Partition
Partition Encrypted?
Route Partition to
AES-HMAC Engine
Route Partition to
Destination
Last Partition?
Handoff Executable
Partition
X14158-073117
Yes
No
No
Yes
No
Send Feedback

## Page 161

UltraFast Embedded Design Methodology Guide 161
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
Stage 2
This stage could be a second-stage boot loader (SSBL) like U-Bo ot, or it could be an RTOS
or application. In the case of a full-featured OS like embedded  Linux, the SSBL U-Boot runs
in CPU0 to initialize and set up the environment in which the O S will boot. The initialization
includes configuring the MMU to use flat memory (that is, virtu al and physical locations are
the same). The boot loader then fetches the kernel image (per t he boot-mode setting) and
other information, such as boot arguments, into RAM. Then the l oader passes control to the
OS, such as embedded Linux.
In the case of Linux, the OS detects and enables the second pro cessor core, configures and
activates the MMU and data caches, and performs other actions t o make a complete system
available to applications.
There is no limit to what each st age can actually  do, although some things can be done
more easily in one stage than in others. For example, reading a  file from an NTFS USB drive
is possible from Linux, but it r equires some development effort  to do it from the boot
loader. U-Boot can be adap ted to such requirements.
Zynq-7000 All Programmable SoC Software Developers Guide  (UG821) [Ref 7] covers the
architecture details, programming  model, OS considerations, and  complete development
steps for running Li nux and applications o n Zynq-7000 AP SoC.
X-Ref Target - Figure 4-9
Figure 4-9:  FSBL Flow for Non-Secure Boot
Start FSBL
(from OCM)
MIO, Clock, DDR Initialization
and device initialization
Increment Multiboot
Register to the next 32K
Offset in Flash and do a
Soft Reset (Fallback)
Get the
partition and
validate the
header?
No
Load the partitions from the
selected boot flash.
If bitstream, program the PL.
If application, copy it to DDR.
Application
handoff to DDR
location
Yes
X14159-073117
Send Feedback

## Page 162

UltraFast Embedded Design Methodology Guide 162
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
Software Development Tools
Xilinx provides a variety of soft ware development tools that ca n be used to build various
software components used by th e Zynq-7000 AP SoC, including:
• Board Support Package (BSP).  This is a set of APIs used to access low-level hardware.
These APIs are grouped based on the peripheral they access and functions they
perform. The BSP also includes s tartup, CPU initialization, and  EABI code.
• Stand-alone (bare-metal) applications.  These are simple app lications that do not
support complex kernel features such as multi-tasking. Such app lications use the BSP
APIs to access low- level hardware.
• FSBL (first stage boot loader).  This is a small application that performs PS hardware
initialization, loads the fabric with a bit stream, optionally loads additional data, and
loads the second-stage boot loader. The FSBL is an example of a  stand-alone
(bare-metal) application.
• U-Boot (second stage boot loader).  This boot loader perf orms the necessary
hardware initialization for the kernel to begin execution. When  done, the Linux kernel is
loaded and starts executing.
• Linux kernel.  Linux is an open source operati ng system. The hardware-depende nt
parts of the Linux kernel (devic e drivers, etc.) are provided f or the Zynq-7000 AP SoC.
The hardware independent parts of the kernel (file systems, net working, etc.) are similar
to other Linux machines. The ker nel is configured as needed and  targeted to the ARM
processor.
• User applications.  Typical user applications run in the Linux environment and are
hardware independent. Hardware access is done through the drive r APIs.
• Device tree blob.  The device tree is a structure of nodes and properties describ ing
components and features supported by the hardware (PS periphera ls, ARM processors,
and PL peripherals). The nodes p rovide information such as the hardware-component
map address, interrupt number, d efault settings,  etc. The devic e tree is compiled and
provided to the Linux kernel at boot time. While booting, the k ernel uses this
information to load the co rresponding device drivers.
Also, the software development tools are used to selectively de bug and profile the software
on the hardware platform.
Send Feedback

## Page 163

UltraFast Embedded Design Methodology Guide 163
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
The software development tools for Zynq-7000 AP SoCs include:
• GUI-based tool chain.  These tools provide you with a graphical user interface. The t ool
and build features are selected t hrough a set of menu options. After this is done, the
compiler/linker is started in the background and the compilatio n progress is shown
visually. The GNU tools are inte grated into the GUI-based tool chain applications. The
Xilinx software development kit (SDK) is an example of a GUI-ba sed tool chain.
With the IDE (integrated development environment), programmers can build a variety of
software compone nts, such as:
° BSP
° User applications on a stand-alone platform
° User applications on a Linux platform
• Command-line based tool chain.  These tools are standard GNU tools (such as gcc)
that are configured for the ARM processor. CodeSourcery (a gcc toolchain from Mentor
Graphics supporting the ARM arch itecture) is used in the develo pment tools for the
Zynq-7000 AP SoC. The compiler an d linker options are supplied using the command
line or with makefiles. The arm -linux-xilinx-gnueabi-gcc is an example of a
command-line based tool chain.
With the GNU-based tool chain, pr ogrammers can build a variety of software
components, such as:
° The Linux kernel and device drivers
° Device tree blob
° User applications
° Reusable libraries
• Hybrid tool chain.  These tools are a combination of GUI and command-line based
tools. The configuration of all project components is done thro ugh GUI-based tools.
However, each component build is done using command-line tools.  PetaLinux is an
example of a hybrid tool chain.
The GNU tools that are configure d for ARM processors are integr ated into a hybrid tool
chain. With a hybrid tool chain, programmers can build a variet y of software
components, such as:
° The Linux kernel and device drivers
° Device tree blob
° User applications
° Reusable libraries
° Completely packaged image
Send Feedback

## Page 164

UltraFast Embedded Design Methodology Guide 164
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
GUI-Based Tool Chain
The Xilinx SDK is an integrated development environment (IDE) b ased on Eclipse. The Xilinx
SDK provides an environment for creating, compiling, and debugg ing software applications.
The SDK runs the GNU-based comp iler tool chain in the backgroun d. The supported utilities
include the GCC compiler, a linke r, the GDB debugger, and other  utilities such as a JTAG
debugger, flash programmer, and libraries. Also, the tool integ rates drivers fo r all Xilinx IP
cores, example applications, software service packages (such as  lwIP), and bare-metal BSPs.
Programmers can integrate any of these components to build the application. The SDK
supports applications developed using assembly, C, and C++.
Features of the Xilinx SDK include:
• Support for Zynq-7000 AP SoCs and MicroBlaze™ processors.
• Based on the Eclipse C/C++ Development Tooling (CDT).
• Complete IDE that directly interfaces to Vivado tools.
• Complete software design and de bug processes are supported inc luding multicore,
hardware, and softwa re debug capabilities.
• The editor, compilers, build tools, flash memory management, J TAG, and GDB
debuggers are integrated.
• Supported by the Xilinx edition of Mentor Sourcery CodeBench L ite.
• Custom libraries and device drivers.
• The SDK includes user-customizable drivers for all supported X ilinx hardware IP cores, a
POSIX-compliant kernel library, a nd networking and file-handlin g libraries. The libraries
and drivers can be customized based on feature needs, memory re quirements, and
hardware capabilities.
• Managed makefiles, management o f hardware platforms, remote de bug, cross probing
support between hardware and software debug, flash programming,  boot image
(boot.bin) creation, linker scrip t generation, repository manag ement, and FPGA
programming.
• Profiling support.
Features of the Xilinx SDK debugger include:
• Based on the Eclipse Target Co mmunication Framework (TCF).
• Homogenous and heterogeneou s multi-processor support.
• Linux application debug on the target platform.
• Hierarchical profiling.
• Bare-metal and Linux application development.
Send Feedback

## Page 165

UltraFast Embedded Design Methodology Guide 165
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
• Support for symmetric multi-pro cessing and asymmetric multi-pr ocessing designs.
• Associate hardware and softw are breakpoints per core.
• NEON library support.
Applications are developed based  on either a stand-alone or a L inux platform model.
Stand-Alone Platform
In a stand-alone platform, an a pplication is built as monolithi c, executable code.
Multi-tasking is not s upported, so device drivers are loaded wi th the application and the
application invokes the driver APIs directly.
The stand-alone software platfo rm is a single-threaded environm ent used when an
application accesses processor functions directly. The stand-al one software platform
supports program profiling and pr ovides functions such as proce ssor interrupt handling,
exception handling, and cache handling.
Stand-alone platforms are used by  small, dedicated systems that  do not require an
operating system. The advantages include:
• Application development is t ypically simple and quick.
• The overall complexity is minim ized because context switching and multi-tasking is not
used.
• Developers can have a more deta iled and comprehensive understa nding of the
top-to-bottom system implementation.
• Ideal for the initial development stages of new hardware.
• A console (text) based applicat ion can be built using this pla tform.
The disadvantages include:
• A complex application system req uiring multi-tasking cannot be  built.
• Not ideal for GUI-based applications.
The steps for developing a sta nd-alone application include:
• Creating a new workspace and im porting the hardware platform i nto the workspace
(the hardware platform is exporte d from the Vivado design tools ).
• Creating a new board support package (BSP) and application.
• Alternatively, importing an exi sting BSP and software applicat ion into the workspace. A
board support package (BSP) in t he SDK contains libraries and d rivers that software
applications can use when th e provided APIs are used.
• Modifying the BSP settings.
Send Feedback

## Page 166

UltraFast Embedded Design Methodology Guide 166
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
• Building the BSP and application.
• Debugging software applications.
• Profiling software applications.
Figure  4-10 shows the development cycle using the SDK tool.
More details on SDK usage can be  found in the following documen ts:
• K7 Embedded TRD 2013.2  [Ref 51]
• OS and Libraries Do cument Collection  (UG643) [Ref 5]
X-Ref Target - Figure 4-10
Figure 4-10:  SDK Software Development Flow
Hardware Platform Exported
from Vivado to SDK
Create an SDK workspace
Import the hardware platform
into the workspace
Create or import a BSP
Create or import a software
project
Develop the software
application
Generate a Linker script
Download the hardware
bitstream to the FPGA device
Profile software applicationDebug software application Run software application
X14163-073117
Send Feedback

## Page 167

UltraFast Embedded Design Methodology Guide 167
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
Linux Platform
Linux is a multi-process operating system, and applications wri tten for a Linux platform are
code compatible with any system that runs Linux. The applicatio ns use the Linux library APIs
and therefore access the hardwar e resources in an abstract mann er.
Application development for a Li nux platform is similar to othe r Linux application
development processes that are h ardware-platform independent. T he procedure for
creating applications in the SDK workspace is similar to the st and-alone platform except the
Linux-platform BSP is selected.
GNU-Based Compiler Tool Chain
The Zynq-7000 AP SoC supports la unch of the GNU tool chain in t wo ways:
• GNU open-source tool chain
• PetaLinux framework
These variants are described in the following sections.
GNU Open-Source Tool Chain
The open-source tool chain is ba sed on Mentor Graphics' CodeSou rcery tool chain.
Sourcery CodeBench is a complete  development environment for em bedded C/C++
development on ARM, Power, ColdF ire, and other architectures. S ourcery CodeBench Lite
Edition includes:
• GNU C and C++ compilers
• GNU assembler and linker
• C and C++ runtime libraries
• GNU debugger
For ARM processors, the tool cha in supports the ARM, Thumb, and  Thumb-2 instructions
for the active architectures, in cluding version 7 of the ARM ar chitecture.
The GNU open source tool chain is described in more detail on t he Xilinx Zynq-7000 AP SoC
Linux wiki page [Ref 65].
PetaLinux Framework
The PetaLinux Tools is a developme nt environment t hat works wit h the Xilinx
hardware-design flow for Zynq-70 00 AP SoCs. Tailored to acceler ate design productivity,
the solution contains everything necessary to build, develop, t est and deploy embedded
Linux systems.
Send Feedback

## Page 168

UltraFast Embedded Design Methodology Guide 168
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
PetaLinux consists of three key elements:
• Pre-configured binary bootable images.
• Fully customizable Linux opera ting system for Xilinx devices.
• PetaLinux Tools, including tool s and utilities to automate com plex tasks across
configuration, build , and deployment.
Because PetaLinux is fully featu red, integrated, tested, and do cumented, it is the Xilinx
recommended and supported Linux d eployment mechanism for Xilinx  customers. PetaLinux
BSPs provide a complete, integra ted and tested, Linux operating  system for Xilinx devices
including:
•B S P
•B o o t  l o a d e r
• Linux kernel
• Linux applications & libraries
• C & C++ application development
•D e b u g
• Thread and FPU support
• Integrated web server for easy remote management of network an d firmware
configurations
Although PetaLinux is based on a stable and thoroughly tested v ersion of Linux, the
PetaLinux Tools includes more tha n what is available from the X ilinx Git server. The
PetaLinux Tools includes an insta ller, development tools, BSPs,  platform management
utilities, application and library  frameworks, and documentatio n that are not found in the
Xilinx open source Li nux (OSL) offering.
All PetaLinux users are entitled to community (forum-based) sup port. Commercial licensees
can get support directly from Xilinx.
The PetaLinux tool chain is descr ibed in more detail on the Xil inx PetaLinux Tools web site
[Ref 50].
Send Feedback

## Page 169

UltraFast Embedded Design Methodology Guide 169
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 4: Software Design Considerations
JTAG Debugger
The GUI-based SDK includes debugging capabilities, enabling pro grammers to debug code
in the following ways:
• Single step
•B r e a k  p o i n t s
•M e m o r y  w a t c h
• Disassembly
• Call-stack
• Processor register dump
The SDK provides various ways to use the debug capabilities. Th e system debugger is based
on the Vivado hardware  server (which is base d on TCF). The syst em debugger performs
debug operations over JTAG or a TCP/IP link. The JTAG link is u sed for local debug and the
TCP/IP link is used for communica ting with the TCF agent in Lin ux. The debugger is also
available as a command line debugger called XSDB. XSDB can be u sed without invoking the
SDK.
The GUI-based SDK debugger is described in more detail in K7 Embedded TRD 2013.2
[Ref 51]
The command-line XMD debugger is described in more detail in th e Embedded System Tools
Reference Manual  (UG1043) [Ref 22].
JTAG Profiler
The GUI-based SDK also includes a software prof iler. The profil er enables programmers to
monitor function calls, time spe nt by the processor on each fun ction, a graphical display of
processor usage, etc. As with the debug capabilities, the profi ler is based on the TCF-based
XMD tool, which performs the pro filing operations over the JTAG  link.
Refer to the AXI Interface Based KC705 Embedded Ki t MicroBlaze Processor Subsystem
Software Tutorial  (UG915) [Ref 12] for more information.
Send Feedback

## Page 170

UltraFast Embedded Design Methodology Guide 170
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 5
Hardware Design Flow
This chapter covers the following hardware design flows to be c onsidered when designing
with a Zynq ®-7000 AP SoC:
• Using the Vivado IDE to Build IP Subsystems : You can use the Vivado ® Design Suite to
build IP subsystems using a varie ty of tools, which are describ ed in this section.
• Rule-Based Connection : You can catch errors by running the design validation process ,
which runs design-rule  checks on the block design and reports w arnings and errors.
This section describes the  design validation process.
• Creating Hierarchical IP Subsystems : You can use the Vivado IP integrator tool to create
hierarchical IP subsystems.
• Board Window : The Board window in IP integra tor shows all the interfaces th at are
present on a particular board.
• Generating Block Designs : When a block design or IP su bsystem has been created, the
source files, IP constraints, and  structural netlist can be gen erated. After this is done,
the design can be integrated into a higher-level HDL design, or  taken through synthesis
and implementation.
• Creating and Packaging IP for Reuse : The Vivado IP packager enables Vivado IDE users
and third-party IP developers to  easily prepare an IP design fo r use in the Vivado IP
catalog. The custom IP can then be instantiated into a design u sing the Vivado Design
Suite.
• Creating Custom Interfaces : The Vivado Design Suite requ ires that all memory-mapped
interfaces use an AXI interface. The suite has a wizard that as sists converting a custom
IP interface to one that adheres  to the AXI interface standard.
• Managing Custom IP : The Vivado IP Catalog contains  built-in repository management
features for adding IP cores from another source.
• Vivado High-Level Synthesis (HLS) : The high-level synthesis (HLS) tool transforms a C,
C++, OpenCL Kernel, or SystemC design specification into a regi ster transfer level (RTL)
implementation that in turn can be synthesized into a Xilinx Al l Programmable device.
Send Feedback

## Page 171

UltraFast Embedded Design Methodology Guide 171
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 5: Hardware Design Flow
Overview
As programmable device s become larger and more complex, and as design schedules
become shorter, use of third-par ty IP and design reuse are beco ming mandatory. Xilinx
recognizes the challenges design ers face and has created a powe rful feature within the
Vivado Design Suite to help solve these challenges. This featur e is called the Vivado IP
integrator.
The IP integrator enables the creation of block designs. These block designs are essentially
IP subsystems containing any number of user-configured IP and i nterconnect. IP integrator
is the feature for doing embedded-processor design in Vivado de sign tools with Zynq-7000
AP SoCs, MicroBlaze™ processor de signs, and non-processor-based  designs. It is used to
instantiate high-level synthesis (HLS) modules from Vivado HLS,  DSP modules from System
Generator, and custom IP made av ailable using the create-and-pa ckage IP flow. Designs can
be created interactively on the IP integrator GUI canvas or pro grammatically through a Tcl
programming interface. Xilinx rec ommends using the IP integrato r tool for processor based
designs. For details, see the Vivado Design Suite User Guid e: Embedded Processor Hardware
Design  (UG898) [Ref 18]and Vivado Design Suite User Guide: Designing IP Subsystems Using
IP Integrator  (UG994) [Ref 19].
Using the Vivado IDE to Build IP Subsystems
The Vivado IDE can be used to build IP subsystems with the IP i ntegrator GUI, scripted tcl
flow, or the designer assistance  that is part of IP integrator.
Using the GUI to Create an IP Subsystem
The IP integrator has a powerful  GUI environment for creating I P subsystems. IP cores can
be instantiated and interconnect ed using various automation fea tures. Custom IP can also
be packaged for use in IP integr ator. Designs should be reassem bled in the GUI
environment and taken through the flow. After the design is sta ble, a script can be written
that creates and implements the design. For more information ab out features of the GUI,
refer to the Vivado Design Suite User Guide: Design ing IP Subsystems Using IP Integrator
(UG994) [Ref 19].
Using a Scripted Flow to Create an IP Subsystem
Every action in the IP integrator GUI canvas results in an equi valent tcl command. These Tcl
commands are also logged in the V ivado Design Suite journal fil e. A script can be written
based on the journal file, and that script can be re-used to cr eate and implement the design
later.
Send Feedback

## Page 172

UltraFast Embedded Design Methodology Guide 172
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 5: Hardware Design Flow
Designer Assistance
To expedite the creation of a processor-based design, use the B lock Automation and
Connection Automation features of IP integrator. The Block Auto mation feature should be
used to configure the processor and related IP cores, whereas t he Connection Automation
feature should be used to make r epetitive connections to differ ent pins or ports in the
design. IP integrator is also board-aware and supports Xilinx ® evaluation boards. This
means that when an evaluation board is used as the target hardw are, IP integrator knows all
the interfaces present on that p articular board. A design's I/O  ports can be connected to
existing interfaces on the target board using the Connection Au tomation feature. Designer
assistance also helps with clock s and reset connectivity. Sever al kinds of tabs, such as the
Signals tab and the Board Part Interface tab, help make connect ions in the block design.
Designer assistance helps expedit e interconnectivity and elimin ates unintended design
errors.
Block Automation
For some complex IP and processor-based designs, IP integrator has a feature called Block
Automation. This feature support s quick assembly of processor- or IP-based subsystems
with commonly used components. After the basic building blocks for an embedded design
are assembled, this basic system  can be extended by adding IP c ores from the catalog.
Connection Automation
When the Block Automat ion is done and a basic system has been b uilt, external I/O pins
need to be connected. The Connect ion Automation serves this pur pose. Connection
Automation helps make connections to the I/O pins and it helps make connections to
different sources on the design i tself. Combined with board awa reness, the Connection
Automation feature helps connect  the block design ports to exte rnal interfaces on the
target board and to create physi cal constraints for these ports . Use of this feature,
therefore, is highly recommended.
Send Feedback

## Page 173

UltraFast Embedded Design Methodology Guide 173
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 5: Hardware Design Flow
Rule-Based Connection
IP integrator runs basic design- rule checks in real time as the  design is being assembled.
However, there is a potential fo r something to go wrong during design creation. As an
example, the frequency of a clock pin may not be set correctly.  Such errors can be caught by
running design validatio n. Design validation  runs design-rule c hecks on the block design
and reports any warnings or erro rs regarding the design. The wa rnings and/or errors can
then be cross-probed from the messages view into the block diag ram. Design validation is
recommended to catch design err ors that may go unnoticed until later in the design flow.
Running design validation also r uns parameter propagation on th e block design, one of the
most powerful features of IP int egrator. The feature lets an IP  core auto-update its
parameterization based on how it is connected in the design. IP  cores can be packaged with
specific propagation rules, and IP integrator runs these rules as the diagram is generated.
Creating Hierarchical IP Subsystems
The IP integrator can be used to  create hierarchical IP subsyst ems. This feature can be
useful for designs having a larg e number of blocks that could o therwise become hard to
manage on the GUI canvas. Multip le hierarchical levels are supp orted, so blocks can be
grouped based on design function . The use of hierarchy within I P integrator can keep
designs modular and neat on the IP integrator canvas.
The visual aspects of design objects can be changed. For exampl e, clocks and resets can be
colored differently, and various layers can be enabled and disa bled.
Board Window
As mentioned above, IP integrato r is board-aware. When a block design is targeted to a
particular Xilinx eval uation board, the Boar d window shows all the interfaces that are
present on that particular board. The interfaces present in the  Board Part Interfaces Tab can
be connected to create a target design with or without a proces sor. This is a powerful
mechanism for creating a block design. When an interface is sel ected for connection, all IP
cores that can connect to that particular interface are display ed. For example, on a Kintex ®
KC705 board, if the 8-bit LEDs are selected, three IP choices a re presented (the GPIO, the IO
Module, and the MicroBlaze MCS IP ) that can connect to this int erface. Based on the IP
selection, a connection can be made to LEDs on the board or, us ing the Designer Assistance,
to the rest of the block design.
Send Feedback

## Page 174

UltraFast Embedded Design Methodology Guide 174
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 5: Hardware Design Flow
Generating Block Designs
When a block design or IP subsystem has been created, the sourc e files, IP constraints, and
structural netlist can be generat ed. After this is done, the de sign can be integrated into a
higher-level HDL design, or take n through synthesis and impleme ntation.
Using Out-of-Context Synthesis for Block Designs
Hierarchical design flows enable the partitioning of designs in to smaller, more manageable
modules that can be processed independently. In the Vivado Desi gn Suite, these flows are
based on the ability to synthesiz e a partitioned module out-of- context (OOC) from the rest
of the design. The most common use with IP integrator is for sy nthesizing an OOC module
and creating a design checkpoint (DCP) file. This block design,  if used as a part of the larger
Vivado design, does not need to be re-synthesized each time oth er parts of the design
(outside of IP integrator) are modified. This results in consid erable run-time improvements
and should be considered if run-times are a matter of concern, specifically during the early
stages of design exploration.
Creating Remote Block Designs
IP integrator can create stand-a lone block designs that can be re-used by multiple Vivado
Design Suite projects. After the  design is created and put unde r revision control, multiple
design teams can re-use the same  block design for creating mult iple projects. This is an
important re-use feature of IP integrator that should be consid ered in a team-based
environment.
Creating and Packaging IP for Reuse
The Vivado IP packager enables V ivado IDE users and third-party  IP developers to easily
prepare an IP design for use in the Vivado IP catalog. The cust om IP can then be
instantiated into a design using  the Vivado Design Suite. Use o f the following packaging
flow results in a consistent use r experience, whether using Xil inx IP, third-party IP, or
customer-developed IP within the Vivado Design Suite.
Packaging Custom IP and IP Subsystems
The Vivado Create and Package IP function supports the creation  of custom IP for delivery
in the Vivado IP Catalog. The industry standard IP-XACT format is used for packaging the IP
core. The location of the packag ed IP can be added to the Repos itory Manager section of
the Vivado Design Suite Settings . When a repository of one or m ore IP cores is added, the
IP is shown in the IP Catalog. U sers can select and customize I P cores from this catalog.
Send Feedback

## Page 175

UltraFast Embedded Design Methodology Guide 175
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 5: Hardware Design Flow
The flow for using the Vivado IP Packager is:
1. Use the Vivado IP Packager to create and package the IP HDL a nd associated data files.
The IP Packager currently does n ot support SystemVerilog source s as the top level. A
Verilog or VHDL wrapper around the SystemVerilog source is requ ired.
2. Provide the Packaged IP to a team member or customer.
3. Have the end-user add the IP l ocation to the R epository secti on of the Vivado Design
Suite Settings.
4. The IP core is shown in the IP Catalog, and the end-user can select and customize the IP
core in a way similar to Xilinx-delivered IP.
The Create and Package IP function provides two ways of creatin g custom IP. The first way
is to use the Create and Package  IP function to create a new IP  core with one or more AXI
interfaces. When the interfaces have been created, insert the c ustom IP and connect to
these interfaces. The second way is to package the IP core and include it in the IP catalog for
later use in IP integrator. This  second way can be used when al l HDL files for the custom IP,
including the AXI inte rface, are available.
The Create and Package IP function allows IP end-users to have a consistent experience,
whether using Xilinx IP, third-party IP, or custom IP. For more  information on creating and
packaging IP, see the Vivado Design Suite User Guide: Creating and Packaging Custom IP
(UG1118) [Ref 23].
Updating the IP Catalog
The Vivado Design Suite IP catal og is a unified repository that  supports searching,
reviewing detailed information, an d viewing documentation for a n IP core. After an IP core
has been packaged, users can point to the IP repository contain ing the newly packaged IP
core in the Vivado tool and add the IP core to the IP catalog. The newly packaged IP core is
then ready to be used in the IP integrator.
Send Feedback

## Page 176

UltraFast Embedded Design Methodology Guide 176
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 5: Hardware Design Flow
Creating Custom Interfaces
The Vivado Design Suite requires that all memory-mapped interfa ces use an AXI interface.
The suite has a wizard that assi sts converting a custom IP inte rface to one that adheres to
the AXI interface standard. The Create and Package IP flow can generate three AXI interface
types:
• AXI4: For memory-mapped interfac es that allow bursts of up to 256 data-transfer
cycles with a single address phase.
• AXI4-Lite: A lightweight, single -transaction, memory-mapped in terface.
• AXI4-Stream: An interface that removes the requirement for an address phase and
allows unlimited data-burst sizes.
The Create and Package IP flow can create a template AXI4 peripheral that includes HDL,
drivers, a test application, ver ification intellectual property  (VIP), and an example template.
After the peripheral has been created, design files can be adde d to complete the custom IP.
See the Vivado Design Suite User Guide: Designing with IP  (UG896) [Ref 23] and Vivado
Design Suite User Guide: Designing IP Subsystems Using IP Integrator  (UG994) [Ref 19] for
details.
Managing Custom IP
The Vivado IP Catalog contains b uilt-in repository management f eatures for adding IP cores
from another source. To make the  custom IP visible, place the c ustom IP in a location that
is accessible from the host mach ine. Then, launch the Vivado De sign Suite and run the IP
Settings functions from the IP C atalog to register the new user  repository location and
include the new IP core in the IP catalog.
There are two types of repositories:
• Standard Xilinx Repositories: The Vivado Design Suite ships st andard Xilinx repositories.
These repositories are always en abled, and they cannot be chang ed in the Xilinx IP
Catalog.
• Configured User Repositories: User repositories are visible fr om the active machine that
contains one or more IP cores.
The Repository Manager allows a dding or removing user repositor ies and establishing
precedence between repositories. IP is distinguished through a unique ordered list of
elements corresponding to the ve ndor, library, name, and versio n (VLNV).
Send Feedback

## Page 177

UltraFast Embedded Design Methodology Guide 177
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 5: Hardware Design Flow
If multiple repositories are referenced and have the same IP VL NV in multiple locations, the
Vivado IDE displays the IP core in the repository with highest precedence. The Xilinx IP
repositories are always enabled,  and they always have lowest pr ecedence.
When the repository setup for a given project is changed, the R epository Manager stores
the changes within the settings.  Consequently, changes are visi ble when the project is
reopened on any machine (assuming  the repository paths are also  available).
Vivado High-Level Synthesis (HLS)
The high-level synthesis (HLS) tool transforms a C, C++, OpenCL  Kernel, or SystemC design
specification into a register tr ansfer level (RTL) implementati on that in turn can be
synthesized into a Xilinx  All Programmable device.
HLS performs two types of synthesis on the design:
• Algorithm Synthesis: This synth esizes the funct ional statement s into RTL statements
over potentially multiple clock cycles.
• Interface Synthesis: This trans forms the function arguments (o r parameters) into RTL
ports with specific timing proto cols, allowing the design to co mmunicate with other
designs in the system.
Like the many decisions made dur ing manual RTL design, the numb er of available
implementations and optimizations is large, and the combination s of how they impact each
other is very large. HLS abstracts these details and helps crea te an optimal design in the
shortest time.
Typically, HLS is used after a so ftware bottleneck has been ide ntified by profiling the
software application within the S DK or third-party tools. When the bottleneck function(s)
have been identified, the next s tep is to move those function(s ) into hardware using HLS.
Finally, the HLS design can be e xported as an IP core to be use d in IP integrat or. HLS also
generates a simulation model for the IP core that can be used t o verify the IP function. Refer
to the Vivado Design Suite User Guide: High-Level Synthesis  (UG902) [Ref 9] for more
information.
Send Feedback

## Page 178

UltraFast Embedded Design Methodology Guide 178
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 5: Hardware Design Flow
Summary
In general, the following steps s hould be followed to capture a n embedded design in IP
integrator:
1. Add processor IP, such as th e Zynq-7000 AP SoC or the MicroBl aze processor.
2. When the processor IP is instantiated, designer assistance is  available. Use designer
assistance to configure the processor and peripherals.
3. Customize the processor further, if needed. This step is need ed if more function and
control over clocks, resets, I /O ports, etc., is desired.
4. Add peripherals, and connect them using designer assistance, when available.
5. Add connectivity IP for externa l interfaces, such as GPIO, Et hernet, etc.
6. Add custom accelerators for th e Processing Logic, if needed.
7. Connect and review clock and re set domains, usi ng the Signals  tab or the Make
Connection wizard.
8. Run design-rule checks by vali dating design. Resolve any erro rs or warnings flagged
during design validation, and r un design validation until no fu rther errors are flagged.
9. Synthesize, implement, and generate bit-stream for the design .
10. Export the design to the SD K for software development.
Send Feedback

## Page 179

UltraFast Embedded Design Methodology Guide 179
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6
Software Design Flow
This chapter describes software design flow for the Zynq ®-7000 AP SoC and provides
guidance for various software de velopment roles,  referred to as  personas . The design flow
for each persona includes an overview of the tool flow and avai lable solutions—from Xilinx
and its partners—at each stage. References are provided to exte rnal documents and other
sections in this guide if mo re information is needed.
Unlike ASICs and ASSPs,  the Zynq-7000 AP SoC has programmable l ogic (PL, the
hardware-configurable FPGA porti on of the device) and a process ing system (PS, the two
ARM Cortex-A9 cores). The hardwa re design and configuration of PL can be done using the
Xilinx ® Vivado ® tools. Refer to Chapter  5, Hardware Design Flow . The hardware design files
from the Vivado tools are sent t o the Xilinx SDK for software d evelopment. Figure  6-1
shows the hardware and software development flow for the Zynq-7 000 AP SoC.
X-Ref Target - Figure 6-1
Figure 6-1:  Hardware and Software Development Flow
Hardware Design
and Configuration
Software Application
Compile
Download and Debug
Profile
Xilinx SDK
Generate HW
Handoff Files
Hardware
Bitstream
Performance
OK?
No
Yes
X14203-
073117
Send Feedback

## Page 180

UltraFast Embedded Design Methodology Guide 180
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
Referring to Figure  6-1, the files sent from the hardware flow to the software flow (r eferred
to as handoff files ) contain information such as th e hardware specification, PS pe ripheral
information, register memory map,  and a bitstream for the PL. T he handoff files insulate
software developers from the Zynq-7000 AP SoC reconfigurable ha rdware. The handoff files
make the hardware appear to software as an ASSP. Software devel opers can use the handoff
files to design firmware, drivers, and a board-support package (BSP).
Typically, the software design flow of Zynq7000-AP SoCs involve s development of one or
more of the software  layers shown in Figure  6-2.
The remaining sections cover sof tware development flow of three  personas: board bring-up
developer, driver developer, and  application developer. Each pe rsona works on one of the
layers in Figure  6-2. A persona can refer to the corresponding section in this chap ter to
understand software development f low pertaining to their area o f work.
X-Ref Target - Figure 6-2
Figure 6-2:  Software Development Layers
Applications
Middleware Framework (Optional)
Operating System (Optional)
Firmware Board Support Package
Hardware
X14204-
073117
Send Feedback

## Page 181

UltraFast Embedded Design Methodology Guide 181
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
Board Bring-Up Development
Board bring-up a ctivities include develo ping low-level firmware , setting up the boot
sequence, and basic tests for the interfaces and the peripheral s. This section describes the
Xilinx development solu tions available for basic board bring-up  activities, divided into the
following phases:
1. PS initialization
2. PL configuration
3. Memory and peripheral testing
4. Hardware and software debug
PS Initialization
Xilinx tools auto generate the ps7_init.tcl  and ps7_init.c  files when Vivado exports
a design. The ps7_init.c  file is an initialization file a uto generated by Vivado and us ed
by the first stage boot loader (F SBL) to initialize the PS. Whe n bringing up the board, the
first step is to connect to the target Zynq-7000 AP SoC through  the Xilinx debugger and run
the ps7_init.tcl  script (provides the same results as ps7_init.c ) to initialize the PS
peripherals, clocks, DDR, PLL, a nd MIO. To verify the PS initia lized successfully, execute
memory reads and verify commands from the XSDB debugger. System  peripherals can be
read and written to verify basic functionality.
The FSBL can load a second stage  boot loader, such as U-Boot, o r it can load and boot an
operating system. In bare-metal implementations, FSBL directly loads the application code.
Refer to the Zynq-7000 All Programmable SoC Software Developers Guide  (UG821) [Ref 7]
for more information on the FSBL , including normal and secure b oot.
On third-party debuggers, the FS BL can be used t o initialize DD R memory and load the
application code, which can be debugged using the debugger. For  example, the FSBL can be
loaded in OCM, executed for a few seconds, stopped, and then th e debug tool can be used
(via JTAG) to load the applicatio n code in DDR for debug. Most debuggers support script
mechanisms for automating this process.
The Xilinx SDK repository provid es bare-metal drivers that can be used for board bring-up.
Send Feedback

## Page 182

UltraFast Embedded Design Methodology Guide 182
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
U-Boot
U-Boot is an open-source universal boot loader that can act as a primary or secondary boot
loader. U-boot can be used to lo ad a stand-alone application, a  bitstream, or a Linux OS
kernel. On Zynq-7000 AP SoCs, U-Boot is used as a secondary boo t loader, but it can be
configured and rebuilt to act as  a primary boot loader. The FSB L is designed to bring up a
secondary boot loader like U-Boot . U-Boot can be loaded from an  external device, and it
can be used to initialize PS per ipherals not initialized by the  primary boot loader. U-Boot or
any other secondary b oot loader can be remov ed from the final p roduct to reduce boot
time.
The flow charts in Figure  6-3 outline the boot sequence and th e files involved in the boot
process.
The open-source Xilinx U-Boot project is available at the Xilin x Git repository. Xilinx U-Boot
is also released as a part of the PetaLinux offerings. Refer to  the Xilinx U-Boot wiki page
[Ref 59] for more information on confi guring and building U-Boot.
X-Ref Target - Figure 6-3
Figure 6-3:  Boot Sequence and Boot Files
Boot ROM
Load & Run FSBL
Load Bitstream
[optional]
Load & Run Application
Running a Standalone Application
Boot ROM
Load & Run FSBL
Load Bitstream
[optional]
Load & Run U-boot
Running Linux
Load Linux Kernel
Load Device Tree
Load RAM Disk
Run Linux Kernel
X14205-
073117
Send Feedback

## Page 183

UltraFast Embedded Design Methodology Guide 183
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
PL Configuration
The PL is configured e ither by software r unning on the ARM core  or through JTAG. Xilinx
supports PL configuration usin g the FSBL, U-Boot, or Linux.
On production boards, the FSBL can configure the PL using the P CAP interface. During the
development and debug phase, the  PL can be configured through J TAG from either the
Vivado tools or Xilinx SDK. Afte r the PL is configured, the pro cessor can access PL
peripherals in the same manner as  PS peripherals. The debugger can read and write PL
peripheral registers at this stage.
Memory and Peripheral Testing
The Xilinx SDK has a memory test that can verify the DDR memory  and the signal integrity
of the memory controller and DDR i nterface. The bare-metal memo ry test application can
be used to exercise a DDR memory power-on self-test. The DRAM t est application template
is located in your installation directory at
SDK\2014.2\data\embeddedsw\lib\sw_apps\zynq_dram_test .
Example drivers are available for many PS peripherals. They can  be found in the
SDK\< Version >\data\embeddedsw\XilinxProcessorIPLib\drivers\
<Peripheral>  folder of your installation dir ectory. The folder also contain s sample test
applications for Xilinx Soft IP cores. These tests can be used to test peripherals during the
board bring-up phase. Also, the tests can be modified to develo p a comprehensive
power-on self-test or built-in test.
Hardware and Software Debug
There may be cases when DDR initi alization fails. If this occur s, a connection to the
debugger can be made by debugging the FSBL stage. Any applicati on downloaded to DDR
can be debugged after that. The Xilinx SDK supports heterogeneo us multicore debugging,
allowing debug of both MicroBlaze™ processors and the ARM cores . Also, cross triggers can
be used when it is unclear wheth er the problem is in software o r hardware. Refer to the
Vivado Design Suite Tutorial: Embedded Processor Hardware Design  (UG940) [Ref 15] for
more information on sett ing up cross triggers.
Send Feedback

## Page 184

UltraFast Embedded Design Methodology Guide 184
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
Driver Development
Driver developers create softwar e drivers for SoC and on-board peripherals, establishing
interfaces for higher software l ayers such as the OS or bare-me tal applications. Peripheral
drivers must be created for the ARM Cortex-A9 and MicroBlaze co res. This section covers
points to consider when developi ng bare-metal and Linux drivers  for the configured
hardware, and it highlights available Xilinx solutions.
Bare-Metal Drivers
The Xilinx SDK supports various file types used in driver devel opment (both Xilinx IP drivers
and custom drivers) and used dur ing the software development cy cles. The file types and
directory structur e are shown in Figure  6-4.
X-Ref Target - Figure 6-4
Figure 6-4:  Directory Structure of Dri vers, OSs, and Libraries
<Library Name>
drivers sw_services bsp poores
<my_driver> <my_library> <my_os> <my_driver>
src data
MDD Tcl.c files .h files
src data
MDD Tcl.c files .h files
src data
MDD Tcl.c files .h files
src data
MDD Tcl.c files .h files
X14206-
073117
Send Feedback

## Page 185

UltraFast Embedded Design Methodology Guide 185
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
Handoff File Details
The software development cycle —  from handoff to debug — is sho wn in Figure  6-5.

The software development cycle begins with handoff files create d during the hardware
design flow. After preparing the hardware design with the Vivad o tools, a hardware handoff
folder is created for use by the SDK in driver and application development. Beginning with
release 2014.2, Vivado hardware e xport creates a single, compre ssed hardware definition
file ( *.hdf ) and writes it to the SDK_Export  folder. This file conta ins hardware details,
such as base addresses and versio n information. From the SDK wo rkspace, a hardware
platform project is created and t he project within the workspac e is configured by pointing
it to the *.hdf  file. The SDK (beginning with release 2014.2) supports import of traditional
XML files in addition to the *.hdf  files.
When building the BSP project, the SDK generates an xparameters.h  file, populating it
with hardware details (such as ba se addresses and interrupt IDs ) in the form of #define
X-Ref Target - Figure 6-5
Figure 6-5:  Software Development Cycle with the SDK
Hardware Design Tool
(example Vivado)
.bit
.bmm
Board
SDK
Create/Identify a Workspace
(Automatic)
Create a New Project/Board
Support Package
Application Development
Download to FPGA
Debug
.elf
X14207-
073117
Send Feedback

## Page 186

UltraFast Embedded Design Methodology Guide 186
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
constants. Software dr ivers (stand-alone p latform) and applicat ions can reference these
constants in the code.
Driver File Organization
The drivers for Xilinx IPs (PS pe ripheral IPs and soft IPs) are  shipped with the SDK. These
drivers are located in the data/embeddedsw/XilinxProcessorIPLib/drivers
folder in your SDK installation folder. Each driver is located in a separate folder. For
example, the IIC PS driver version 2.0 is located in the
data/embeddedsw/XilinxProcessorIPLib/drivers/iicps_v2_0  folder of your
SDK installation.
Each driver folder con tains four subfolders:
• data: This folder contains the MDD file and Tcl script file.
• doc: This folder contains help file s that provide details of APIs and data structures
implemented in the driver.
• examples : This folder contains C source files demonstrating examples on  how to use
the driver. These examples are r eady to build and launch on the  hardware. The
examples can be used as-is when following the procedure for bui lding stand-alone
applications. The examples can also be modified as needed.
• Src: This folder contains the drive r source code (C and H files).
Send Feedback

## Page 187

UltraFast Embedded Design Methodology Guide 187
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
The source file repository is organized as shown in Figure  6-6.
To load driver source code into the project workspace, the SDK reads the MDD file in each
version folder. The SDK selects the corresponding driver versio n based on parameter values
in the MDD file. When the SDK fin ds a driver with multiple vers ions, it takes the highest
version as default. However, the  programmer can select the requ ired version from a drop
box.
X-Ref Target - Figure 6-6
Figure 6-6:  Source File Repository
Send Feedback

## Page 188

UltraFast Embedded Design Methodology Guide 188
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
The MDD is used to assist w ith the following tasks:
• Integrating custom drivers into the SDK.
• Modify existing drivers and int egrate the variants into the SD K.
• Modify the BSP, such as add ing new software services.
IP Blocks and Drivers
The IP blocks and drivers can be characterized as shown in Table 6-1. As can be seen in the
table, the SDK can identify and load any driver source code for  either type of IP block.
PS IP
PS IP blocks are hardware blocks that are part of the Zynq-7000  AP SoC PS. The PS includes
several peripherals (USB, I2C, Ethernet, etc.) plus the ARM Cor tex-A9 processor.
The application requires driver support to access the periphera ls. Bare metal and Linux
drivers are provided. The SDK provides pre-built bare-metal dri vers and Linux kernel (Xilinx
supported) drivers for all PS IP peripherals.
Soft IP
Soft IP blocks are hardware blocks built as part of the design and loaded into the Zynq-7000
AP SoC PL. Some examples of soft IP blocks in the PL are VDMA, AXI-Ethernet, and third
party IP blocks.
The application requires driver support to access the periphera ls. Bare metal and Linux
drivers are provided. Bare-metal  drivers are provided by the SD K and Linux drivers are
provided by the Linux kerne l source tree from Xilinx.
The following steps must be followed so that a third-party IP d river can be used in the SDK:
• Create a driver for the IP block.
• Create the associated data definition file (MDD) and data gene ration file (Tcl) for use by
the SDK.
• Set the driver path as an external repository of the SDK proje ct. The SDK can now
recognize and load t he driver normally.
The bare-metal driver and applic ation development flow is shown  in Figure  6-7.
Table 6-1:  IP Block and Drive r Combinations Supported by the SDK
Soft IP (PL) PS IP (PS)
Xilinx drivers Supported Supported
Custom drivers Supported Supported
Send Feedback

## Page 189

UltraFast Embedded Design Methodology Guide 189
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
For more information, refer to the Zynq-7000 All Programmable SoC Software Developers
Guide  (UG821) [Ref 7].
Xilinx Driver Flow
Soft IP drivers are shipped with  the tool insta llation. The dri vers can be directly imported
into the BSP from the st andard driver location.
There are two methods for modify ing and using the standard driv ers:
•M e t h o d  1 :
° Modify the driver source code in the default driver path.
° Reload and build the BSP. This a ction will cause the modified d river to be loaded.
•M e t h o d  2 :
° Create a driver folder structure in a local path.
° Copy the standard driver and assi gn a different version number.
° Modify the source code and t he corresponding MDD file.
° In the SDK, point to the local repository path so that the SDK uses the modified
driver.
For more information on MDD para meters, refer to  the “Microproc essor Driver Definition
(MDD)” information in the Generating Basic Software Platforms: Reference Guide  (UG1138)
[Ref 24].
X-Ref Target - Figure 6-7
Figure 6-7:  Bare-Metal Application Development Overview
Hardware
Specification
File (XML)
.PS
Configuration
PL
Configuration
(bitstream)
BRAM
Configuration
(BMM)
Hardware
Handoff
Xilinx SDK
Eclipse
IDE
GNU
Compiler
Tool
Chain
C/C++
Toolkit Debugger
BSP Middleware
Drivers Applications
Xilinx
Embedded
Software
Import Hardware Platform
Create Bare-Metal BSP
Create Bare-Metal Application
Build Application
Configure PS and PL
Run the Application
Debug The Application
Add Custom IP Driver Support
Deploy Application
. . .
Bare-Metal Application Development Overview X14208-
073117
Send Feedback

## Page 190

UltraFast Embedded Design Methodology Guide 190
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
Custom Driver Flow
Custom IP software can be in the form of libraries or drivers. The Xilinx MDD and MLD files
provide the capabilities needed to create drivers for custom IP  blocks, enabling developers
to:
• Develop new drivers and i ntegrate them into the SDK
• Customize existing drivers
• Customize a BSP format and folder structure tailored to the OS  tool chain
• Customize the OS based on the hardware
The MLD format describes the para meters that can be used to cus tomize libraries and
operating systems. For more info rmation on user-written librari es and operating systems
that must be configured by the L ibgen tool, refer to the “Micro processor Software
Specification (MSS)” chapter in the Generating Basic Software Platforms: Reference Guide
(UG1138) [Ref 24].
MDD files contain directives for  customizing or creating softwa re drivers. For more
information on the MDD format and the parameters that can be us ed to customize or create
drivers, refer to the “Microproc essor Driver Definition (MDD)” chapter in the Generating
Basic Software Platforms: Reference Guide  (UG1138) [Ref 24].
The method for modifying and using custom drivers is the same a s method two for Xilinx
drivers, described in Xilinx Driver Flow in .
Linux Driver Development
Linux on Zynq-7000 AP SoCs requir es drivers for both PS IP (per ipherals) and soft IP
(custom logic implemented in the PL). Drivers can be added to L inux as a part of the kernel
or as loadable kernel modules. X ilinx provides a complete Linux  source targeted to the
Zynq-7000 AP SoC. For more informa tion and to download a copy, see The Official Linux
Kernel from Xilinx web page [Ref 100]. The Xilinx Wiki's Linux drivers page lists information
on drivers from Xilinx. The Xili nx Wiki's Linux page also provi des information on
Linux-related offerings from Xilinx.
Xilinx releases pre-built image s for Zynq-7000 AP SoC evaluatio n boards (ZC702, ZC706,
and ZedBoard) with the r elease of Xilinx tools.
Send Feedback

## Page 191

UltraFast Embedded Design Methodology Guide 191
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
Device Tree
Information about hardware added  or removed (such as an IP bloc k in the PL) can be sent
to the kernel using a device tr ee. The device tree can also be used to convey specific
information about the hardware.
The Xilinx Wiki's build device tree page describes how to build  a device tree BSP using the
Xilinx SDK. The SDK requires the following two files when creat ing a device tree BSP:
• Hardware handoff files from the Vivado tools.
• Device tree files ( .tcl and .mld) from the device tree relea se in the SDK repository.
Root File System
Xilinx provides the initial root  file system for Zynq-7000 AP S oCs: ramdisk/initrd. Other
supported file systems can be mounted on the root file system a fter system boot. The Xilinx
Wiki has more information on how to build and modify the root f ile-system.
Linux Kernel Debug
The Xilinx SDK's system debugger can be used for Linux kernel d ebug through JTAG. The
system debugger is a heterogeneous multicore debugger that enab les simultaneous debug
of MicroBlaze and ARM cores. Processor cores can be controlled individually by the system
debugger when the Linux kernel i s running in SMP mode. PL addre ss space can be
debugged, and during debug PL me mory space is shown in the memo ry view.
The SDK help has information on how to use the system debugger to debug a Linux kernel
on a Zynq-7000 AP SoC. The SDK help also describes how Linux ke rnel symbol files can be
added during debug configuration  and the steps for mapping the compilation path from
the Linux host machine to the Li nux source tree in a Windows en vironment.
By default, when debugging using attach to running target  mode, the PL registers will not
be accessible. The environment variable HW_SERVER_ALLOW_PL_ACCE SS must be set using
the SDK shell, and the hw_server  started using the following se quence:
1. Kill all running instances of hw_server.
2. Launch a terminal command pr ompt from the SDK and set
HW_SERVER_ALLOW_PL_ACCESS.
3. Launch hw_server from the same shell.
Alternatively, the GDB debugger can be used for Linux kernel de bug through JTAG. The ARM
DS-5 also supports Linux kernel debug on Zynq-7000 AP SoC devic es.
Send Feedback

## Page 192

UltraFast Embedded Design Methodology Guide 192
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
Application Developer
Applications are devel oped to run on bare me tal or an operating  system such as Linux or
FreeRTOS. This section describes how applications can be develo ped, debugged, and
analyzed for Linux and bare-me tal platforms running on Zynq-700 0 AP SoCs. Use cases are
provided to illustrate how the SDK tools assist in developing, debugging, and analyzing the
software application.
Bare Metal
The SDK supports software application development on the export ed hardware design. The
SDK extracts hardware information from the design exported by t he Vivado tools. Based on
that information the SDK provide s a complete application develo pment environment.
Application development requires  a board-support package, inclu ding hardware
initialization, drivers, and a set of libraries, such as TCP/IP  Stack (lwIP), and FAT File System
(FFS).
The Xilinx SDK provides  two template types:
• Hardware (PS only) templates fo r Zynq-7000 AP SoCs. Using this  template, an
application can be dev eloped without creating a design with the  Vivado tools.
Templates are available for the ZC702, ZC706, ZedBoard, and Mic roZed boards.
• Application templates. Prede fined applications, such as hello world  and an empty
application can be generated for any hardware design using the available peripherals.
Other applications, su ch as lwip, can be created with minimal e ffort in the SDK.
The SDK can also be used in batc h mode, where yo u can create an d build applications
through a command line interface , without invoking the SDK IDE.
For more information, refer to the Xilinx Software Development Kit Help  (UG782) [Ref 6].
The Xilinx SDK comes with a set of libraries you can use to fac ilitate stand-alone application
development. For more information, see Xilinx Libraries for Stand-Alone Systems .
Send Feedback

## Page 193

UltraFast Embedded Design Methodology Guide 193
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
Use Case: Develop, Debug, and Integrate
The dialog box in Figure  6-8 shows the creation of a C /C++ application. For more
information, refer to the SDK Help [Ref 6]: Xilinx C/C++ New Project Wizard.
After an application is created, it must be built. For more inf ormation, refer to the SDK Help
[Ref 6]: Building Proje cts web page.
For more information on running and debugging applications, ref er to the SDK Help [Ref 6]:
Running, Debugging, an d Profiling Projects.
X-Ref Target - Figure 6-8
Figure 6-8:  C/C++ Application Dialog Box
Send Feedback

## Page 194

UltraFast Embedded Design Methodology Guide 194
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
Linux Application Developer
Linux applications use the Linux s oftware stack, which includes  the Linux kernel, libraries,
file system, and the driver APIs.
Some of the architectural choice s that affect the development o f Linux applications are:
1. Symmetric multiprocessing (SMP)  or asymmetric multiprocessing  (AMP) system.
2. Resource sharing in AMP systems. AMP systems require memory m apping for separate
cores. For more informa tion, refer to the sample AMP configurat ions.
3. SMP system interrupt affinity.
4. Third party libraries. Refer to Libraries and Middleware , for more information. Licensing
for open-source libraries and sof tware used on proprietary proj ects should be
considered.
5. Secure execution, such as TrustZone execution.
6. Driver support for custom IP.
7. Inter-processor communication m echanism. For more information , refer to How a
MicroBlaze can peaceably coexis t with the Zynq-7000 AP SoC  [Ref 84] .
For more information on architec tural design considerations, se e Chapter  4, Software
Design Considerations .
Xilinx provides documents, basic software blocks, and reference  designs that can be used
during the architectur e design and evaluation stage. For more i nformation, refer to the
Xilinx Linux wiki page [Ref 56].
Application Development Flow
The Xilinx SDK provides a set of tools and a suggested developm ent flow for developing
Linux applications. This is descri bed in detail in  the “Softwar e Application Development
Flows” chapter of the Zynq-7000 All Programmable SoC Software Developers Guide  (UG821)
[Ref 7].
Alternatively, in-house or third -party solutions can be used to  develop Linux applications.
The following support is required by the tools for developing a pplications for Zynq-7000 AP
SoCs:
• A build system, inclu ding a cross-development tool chain on th e host system.
• A Linux kernel, device tree, software stack, and libraries.
• A Zynq-7000 AP SoC Linux target or emulation platform.
Send Feedback

## Page 195

UltraFast Embedded Design Methodology Guide 195
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
Xilinx Tool Flow for Linux Application Development
Xilinx provides Linux drivers, BSPs, and source code as a part of the PetaLinux tool flow and
Xilinx Linux distribution. The PetaLinux flow is designed for F PGAs and devices similar to the
Zynq-7000 AP SoC. It offers confi guration and Linux deployment capabilities for the
Zynq-7000 AP SoC, including a complete tool chain, BSPs, and Xi linx evaluation boards. For
more information on configuring PetaLinux, refer to the Xilinx Wiki's PetaLinux page.
 PetaLinux is covered in more detail in OS and RTOS Choices .
Figure  6-9 shows the Xilinx tools used in Linux application development.
Application Development Using the Xilinx SDK
The Xilinx SDK supports developme nt and debug of Linux applicat ions for Zynq-7000 AP
SoCs. It supports the ARM Linux G CC tool chain (Sourcery CodeBe nch Lite) and offers
various Xilinx tools fo r Linux application development. The Xil inx SDK also comes bundled
with Linux application templates and supporting libraries to he lp developers evaluate the
Zynq-7000 AP SoC with minimal setup.
For more information on Linux app lication development flow, ref er to the “Software
Application Development Flows” chapter of the Zynq-7000 All Programmable SoC Software
Developers Guide  (UG821) [Ref 7].
Figure  6-10 shows how a Linux app lication development project can be creat ed in SDK,
using an OpenCV Example Applicat ion template. SD K provides the libraries required for
OpenCV applications.
X-Ref Target - Figure 6-9
Figure 6-9:  Linux Application Development using Xilinx Tools
Hardware
Specification
File (XML)
.PS
Configuration
PL
Configuration
(bitstream)
BRAM
Configuration
(BMM)
Hardware
Handoff
Xilinx SDK
Eclipse
IDE
GNU
Compiler
Tool
Chain
C/C++
Toolkit Debugger
BSP Middleware
Drivers Applications
Xilinx
Embedded
Software
Import Hardware Platform
Boot Linux
Create Linux Application
Build Application
Run the Application
Debug The Application
Add Custom IP Driver Support
Profile Application
Add Application to Filesystem
Modify Linux BSP
X14209-080117
Send Feedback

## Page 196

UltraFast Embedded Design Methodology Guide 196
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
Figure  6-11 shows how different build settings and libraries can be select ed when building
Linux applications using SDK.
SDK enables users to connect to a Zynq-7000 AP SoC Linux target  using an IP address. After
the connection is made, the applic ation executable can be copie d to the Linux target and
run.
X-Ref Target - Figure 6-10
Figure 6-10:  Creating a New Linux Appli cation in the Xilinx SDK
X-Ref Target - Figure 6-11
Figure 6-11:  Xilinx SDK Build Set ting and Libraries
Send Feedback

## Page 197

UltraFast Embedded Design Methodology Guide 197
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
Linux Application Debug
Linux applications can be debugged on Zynq-7000 AP SoCs using G DB or the Xilinx system
debugger. The Xilinx SDK also ena bles local-target or remote-ta rget Linux application
debug. Linux application debug is supported by the Xilinx SDK u sing gdbserver for GDB, or
a TCF agent for the system debug ger. A TCF agent process must b e running on the Linux
target to debug Linux applications using the system debugger.
Linux applications can also be dev eloped and debugged using oth er IDEs, such as ARM
DS-5. If a command-line approach is preferred, a build system d eveloped in-house can be
used, or one can be obtained from an OS vendor. The Zynq-7000 A P SoC ecosystem is
supported by a variety of OS partners. A list of OS partners is  can be found in OS and RTOS
Choices .
Xilinx SDK Tools and Packages
Xilinx provides tools an d software packages for developing Zynq -7000 AP SoC software. The
development utilities are released as:
• Xilinx tools releas ed in the SDK IDE.
• Software packages, including a bare-metal BSP and drivers, plu s source code.
• Software released through Xilinx Git.
Tools Released in the Xilinx SDK
Tools and utilities released in th e Xilinx SDK are  described in  the following sections.
X-Ref Target - Figure 6-12
Figure 6-12:  Xilinx SDK Build Set ting and Libraries
Send Feedback

## Page 198

UltraFast Embedded Design Methodology Guide 198
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
Boot Image Creation
The Xilinx SDK provides facilitie s for creating a boot image. B ootgen can stitch the
boot-loader FSBL, the bitstream,  and application executable fil es (including U-Boot) to
generate a boot image file in . bin or . mcs format. The SDK also has a Create Boot Image
wizard option for adding the partition images and creating a bo otable image . For more
information, refer to the following:
• “Creating a Zynq Boot Image for an Application” in Xilinx Software Development Kit
Help (UG782) [Ref 6] .
• “Using Bootgen” app endix (available at this link ) in the Zynq-7000 All Programmable
SoC Software Developers Guide  (UG821) [Ref 7] .
•  Vivado Design Suite QuickTake Vi deo: How to Create Zynq Boot Im age Using Xilinx
SDK
Programming Utilities
Program Flash
The program flash utility allows users to download .bin and .mc s files to on-board flash
devices. Figure  6-13 shows the flash devices supported by this utility.
Program FPGA
The PL bitstream can be programmed in different ways. One metho d is to use the Program
FPGA utility in the SDK GUI.
X-Ref Target - Figure 6-13
Figure 6-13:  Flash Devices Supported by the Program Flash Utility
Send Feedback

## Page 199

UltraFast Embedded Design Methodology Guide 199
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
Debuggers
The Xilinx SDK provides heterogen eous debuggers t hat support AR M and MicroBlaze
debug. The debug capability is s upported by the GUI and command  line interface. The
command line interface supports Tcl scripting, enabling command  execution in JTAG mode.
The following debuggers are s upported by the Xilinx SDK:
•S y s t e m  D e b u g g e r .
• XSDB: Xilinx System Debu gger (command line flow).
• XMD: Xilinx Microprocessor Debugger.
•G D B  d e b u g g e r .
To ensure that the MicroBlaze core is visible to the debugger, MDM must be enabled when
creating the hardware design in Vivado.
The SDK system debugger provides hardware-software debug featur es that assist in
debugging code running on Zynq- 7000 AP SoCs. The debugger also facilitates
hardware-software cross triggers.
For more information, see Chapter  7, Debug .
Performance Analysis
Performance analysis is an impor tant step in identifying code b ottlenecks. The Xilinx SDK
provides code profilers and a per formance analyzer. For more in formation, see Chapter  2,
Profiling and Partitioning .
Send Feedback

## Page 200

UltraFast Embedded Design Methodology Guide 200
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
Application Templates
Figure  6-14 shows the application templates bundled in the SDK for bare-me tal
programming.
Xilinx Git Software Solutions Release
Xilinx releases system software for Zynq-7000 AP SoCs and Micro Blaze targets on the Xilinx
Git page. Some of the packages r eleased on the Git page include :
1. Linux xlnx: The X ilinx Linux kernel
2. U-Boot-xlnx: The Xi linx U-Boot repository
3. Device tree: The Xilinx SDK Linux device tree generator
4. meta-xilinx: Xilinx device and b oard support for Yocto/OE-cor e.
X-Ref Target - Figure 6-14
Figure 6-14:  SDK Application Templates
Send Feedback

## Page 201

UltraFast Embedded Design Methodology Guide 201
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 6: Software Design Flow
Xilinx Software Development Tools
Software development tools provided by Xilinx include the SDK a nd the Xilinx Yocto Project.
Xilinx SDK
The Xilinx SDK is an Eclipse-based  IDE and contains Xilinx tool s and software packages. It
enables embedded soft ware development for  Xilinx FPGAs and Zynq -7000 AP SoC devices.
The SDK contains essential software packages, such as pre-defin ed hardware configurations
for Xilinx evaluation boards, per ipheral and IP device drivers,  a bare-metal BSP repository,
firmware with required supported l ibraries, and application tem plates. The packages are
released with the latest source code so that they can be modifi ed as-needed. The SDK also
contains other tools that are used to create a boot image, prog ram the processor, and test
performance.
The Xilinx SDK is free and can be downloaded from https://www.xilinx.com/tools/sdk.htm .
PetaLinux
PetaLinux offers a solution for t he development and deployment of Linux-based software
on All Programmable devices. The  PetaLinux tool set includes an  installer, development
tools, Linux-based BSPs for Xilin x evaluation boards, and libra ry frameworks. The Xilinx Wiki
contains a detailed description of PetaLinux. The wiki page als o contains documentation on
the overall Xilinx Linux offerin gs and Xilinx open -source softw are.
Xilinx Yocto Project
The Xilinx Yocto Project provides  templates, tools and methods for creating custom
Linux-based systems for embedded products built on MicroBlaze a nd Zynq-7000 AP SoCs.
Included are meta files, development boards, and a QEMU emulato r. The Xilinx Wiki Yocto
page provides links to Xilinx Yoct o releases. This includes met a-xilinx, a Yocto BSP layer
supporting Linux kernel build,  U-Boot and Poky distributions.
The Xilinx Yocto project also ena bles up-streaming of relevant drivers and software
packages from non-Xilinx entitie s. Customers and OS vendors are  encouraged to develop
compliant software and upstream d rivers, which helps enhance th e product an d overall
Xilinx community.
For more information on the Xilin x Yocto Project, refer to the following:
• Xilinx Yocto wiki page [Ref 60]
• Yocto Project web page [Ref 104]
Send Feedback

## Page 202

UltraFast Embedded Design Methodology Guide 202
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 7
Debug
This chapter covers the following  information about the debug m ethodology:
• Overview : This section provides an overview of the debug methodology fo r developing
applications using a Zynq ®-7000 AP SoC.
• Software-Only Debug : Embedded software debug is d one using the Xilinx® Software
Development Kit (SDK). The SDK de bug perspective provides a com prehensive debug
environment.
• Simulation-Based Debug : Simulation emulates the final design's behavior in a software
environment. Simulation helps ve rify design functionality by in jecting stimulus and
observing the output result.
• Board Debug : After a design is implemented,  it must be tested on hardware.  Software
debug of hardware can be done us ing the SDK tool. Debug can be useful in finding
problems in the FPGA or fabric side.
• Hardware and Software Co-Debug : Xilinx provides a sol ution allowing you to
simultaneously debug the processing system (PS) and the periphe rals in the
programmable logic (PL).
• Virtual Platforms : Virtual platforms are software systems that mim ic the behavio r of
hardware. They are fast, function al models of an embedded platf orm.
Because of the programmable logic (PL) density and the processo r system complexity, the
debug methodology described in t his section is critical to the development of applications
using a Zynq-7000 AP SoC.
The test and debug capability of  Zynq-7000 AP SoCs combined wit h the ARM CoreSight
technology enables you to debug the processing s ystem (PS) and PL using intrusive and
non-intrusive debug methods. Users can debug a complete system,  including the PS and PL
together. In addition to debugging software, users can debug ha rdware points in the PS and
user-selected hardwa re points in the PL.
The test and debug capability is based on the ARM CoreSight v1. 0 architecture and defines
four classes of CoreSight techno logy components: access and con trol, trace source, trace
link, and trace sink. Also, the Debug Access Port (DAP), which is not a CoreSight
component, provides a ccess to CoreSight components and other sy stem features.
Send Feedback

## Page 203

UltraFast Embedded Design Methodology Guide 203
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 7: Debug
Overview
The software tools allow both intrusive and non-intrusive debug . There are break and watch
points for intrusive debug. Non- intrusive debug is done using A RMs Program Trace
Macrocell (PTM), which captures instruction flow. Flow is compr essed by capturing only
changes in the program flow. Data can be sent off-chip through 2 to 32 trace output port
pins that are part of the MIO/EM IO. The other option is to load  the trace data into the
Embedded Trace Buffer (ETB) and use third-party tools to upload  the trace data through
JTAG.
Software-only debug can be done, or the Vivado ® Integrated Logic Analyzer (ILA) cores can
be added to the design for combined hardware and software debug . The PL JTAG port is
daisy chained with the ARM Debug Access Port (DAP). The Vivado logic analyzer cores are
accessed through the PL JTAG. ARM and third-party tools attach to the ARM Debug Access
Port (DAP).
For more information on PS and P L debug configurations, refer t o the “JTAG and DAP
Subsystem” (available at this link ) and “System Test and Debug” (available at this link )
chapters of the Zynq-7000 All Programmable SoC Technical Reference Manual  (UG585)
[Ref 4].
PS Debug
The Zynq-7000 AP SoC PS provides the following capabilities for  system-wide trace:
• Debug and trace visibility of who le systems with a single debu gger connection
• Cross triggering support between SoC subsystems
• Multi-source trace in a single stream
• Higher data compression  than previous solutions
•S t a n d a r d  p r o g r a m m e r ' s  models for tools support
• Automatic topology discovery
• Open interfaces for third party soft cores
• Low pin-count options
Send Feedback

## Page 204

UltraFast Embedded Design Methodology Guide 204
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 7: Debug
PL Debug
Xilinx provides the fabric trace monitor (FTM) for PL test and debug. It is based on the ARM
CoreSight architecture, and is a  component of the trace source class in the CoreSight
system within Zynq-7000 AP SoCs.  The FTM receives trace data fr om the PL and formats it
into trace packets to be combine d with the trace packets from o ther trace source
components, such as program trac e macrocell (PTM) and instrumen tation trace macrocell
(ITM). With this capability, PL e vents can be traced simultaneo usly with PS events. The FTM
also supports cross-triggering b etween the PS and PL, except fo r the trace dumping
feature. Also, the FTM provides general-purpose debug signals b etween the PS and PL.
The PL test and debug features are:
• ARM CoreSight compliant
• 32-bit trace data from the PL
• 4-bit trace ID from the PL
• Clock domain crossing between the PL and PS
• FIFO buffering for trace packet s to absorb PL trace data burst s
• FIFO overflow indication by g enerating an overflow packet
• Trace packets are compatible with ARM trace port software and hardware
• Trigger signals to and from the PL
• General-purpose I/Os to and from the PL
Software-Only Debug
Embedded software debug is done using the Xilinx Software Devel opment Kit (SDK). The
SDK debug perspective provides a comprehensive debug environmen t. The debug window
shows the session state, includin g a call stack, source code, d isassembled code, process
memory, register information, an d the XMD console. Breakpoints can be set and execution
controlled using standard debugger commands.
Send Feedback

## Page 205

UltraFast Embedded Design Methodology Guide 205
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 7: Debug
A typical application development and debug process overview in cludes the steps shown in
Figure  7-1.
System Debugger and Target Connections
When debugging applications, the System Debugger connects to th e target board through
JTAG using the Target Communication Framework (TCF). When debug  starts, the System
Debugger runs a hardware server a gent on the local host. Altern atively, it can run on a
remote host when one machine is running the debug application a nd another machine is
connected to the board, such as i n a remote lab environment. Th e System Debugger
target-connections window allows  management of the board under debug.
System Debugger
The Xilinx System Debugger (XSDB) is the preferred software deb ug method for Zynq-7000
AP SoCs. System Debugger provides heterogeneous debug of dual A RM and multiple
MicroBlaze™ processors in the same session, on either bare meta l or Linux-based systems.
It also includes hierarchical pr ofiling, ARM NEON  library suppo rt, and the XSDB command
X-Ref Target - Figure 7-1
Figure 7-1:  Application Development and Debug Overview
Create/Edit Source Code (C/C++)
Compile/Link (C/C++ Perspective)
Debug using System Debugger (Debug
Perspective)
Profile using System Debugger (optional)
Program to Flash Memory (including HW
bitstream)
X14201-080117
Send Feedback

## Page 206

UltraFast Embedded Design Methodology Guide 206
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 7: Debug
interface. After a board is connected, the status of each CPU i n the system can be identified.
The debugger also provides a way to attach target applications (.elf files) to each CPU,
assign symbols for Linux debug, view and set registers, view an d set breakpoints, and
monitor memory locations. Commands can be issued to the system through XSDB, and
disassembled application code can  be viewed using halts and bre akpoints.
For more information, including how to connect to a board, refe r to the Xilinx Software
Development Kit Help  (UG782) [Ref 6].
Xilinx System Debugger (Command Line)
XSDB is the command interface for  loading and controlling CPUs.  It can be invoked either
from the command line or using a n interactive GUI built into th e SDK. It includes a Tool
Command Language (Tcl) interface that supports scripting of rep etitive or complex tasks.
XSDB also provides ways to read registers, memory locations, an d set code breakpoints. The
XSDB supports dynamic he lp for command usage.
Profiling
The System Debugger in the SDK also supports code profiling tha t displays function call
execution time, so that the most time-consuming parts of an app lication can be identified.
Function calls can be isolated a nd the called sub-functions pro filed, and the user can
cross-probe to the source code f or reference. Profiling can be used to determine where
software applications might be co nverted into PL or DSP functio ns for faster system
performance.
GNU Tool Chain Support
In addition to System Debugger, the SDK supports application de bug using the GNU tool
chain, including the GNU Debugge r (GDB) and gprof for applicati on profiling.
Drivers and BSP Debug
Software applications must link to or run on top of a software platform using the provided
APIs. Therefore, before creating  and using software application s in the SDK, a board
support package (BSP) must be created. A board support package is a collection of libraries
and drivers that forms the lowes t layer of an application softw are stack.
The SDK includes a stand-alone board support package for applic ation development. This
package is a simple, semi-hosted , and single-threaded environme nt that provides basic
features, such as standard input /output and acce ss to processor  hardware features.
Board support packages and their libraries can be configured us ing the SDK Board Support
Package settings dialo g box. Multiple board support packages ca n be created in the SDK
workspace. This allows users to work simultaneously with differ ent board support package
configurations, and to re-target  applications from one package to another.
Send Feedback

## Page 207

UltraFast Embedded Design Methodology Guide 207
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 7: Debug
Drivers can be used to create ap plications. The applications an d drivers can be debugged
using Xilinx System Debugger in s tand-alone debug mode or attac hed to a running target.
The debugger can be configured for each core, and user-selectab le options can run
initialization files before downl oading and running the stand-a lone application through
JTAG.
For more information, refer to the Xilinx Software Development Kit Help  (UG782) [Ref 6] and
the Zynq-7000 All Programmable SoC Software Developers Guide  (UG821) [Ref 7].
OS Debug
Xilinx System Debugger can be u sed in the attach-to-running-tar get mode for debugging
the operating system and support ing drivers. The System Debugge r configurations allow
users to add the kernel symbol files and to provide the compila tion path mapping to enable
source-code debugging. The kernel  source must be compiled with following flags set.
CONFIG_DEBUG_KERNEL=y
CONFIG_DEBUG_INFO=y
The debugger can also debug cod e running in PL address space, a nd the memory view
supports PL memory space during debugging.
When debugging using attach-to-r unning-target mode, the default  is that the PL registers
will not be accessible. The envir onment variable HW_SERVER_ALLO W_PL_ACCESS needs to
be set through the SDK shell and then the hw_server as follows:
1. Kill any instance of h w_server that is running.
2. Launch a terminal command pr ompt from the SDK, and set
HW_SERVER_ALLOW_PL_ACCESS .
3. Launch hw_server from the same shell.
Alternatively, the GDB debugger can also be used for Linux kern el debugging. Like system
debugger, GDB is a remote debugger connected to a server that t ranslates between TCP
and JTAG. The ARM DS-5 Developme nt Studio also supports Linux k ernel debugging for
Zynq-7000 AP SoCs.
For more information, refer to t he “Attach and Debug Linux Kern el Using Xilinx System
Debugger” topic in the Xilinx Software Development Kit Help  (UG782) [Ref 6].
Linux Application Debug
Developers can debug Linux appli cations by selecting the System  Debugger's Linux
application debug mode. The Xilin x SDK also enables local targe t or remote target debug
for Linux applications. Linux app lication debug is supported by  the Xilinx SDK using the TCF
agent. A TCF agent process must  be running on the Linux target to debug Linux applications
using System Debugger.
Send Feedback

## Page 208

UltraFast Embedded Design Methodology Guide 208
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 7: Debug
The GDB debugger can also debug L inux applications. The remote ARM Linux application
debugger supports debug by comm unicating with the gdbserver pro cess running on the
Zynq-7000 AP SoC target. An exampl e System Debugger window is s hown in Figure  7-2.
Developers can use IDEs other th an the Xilinx SDK, such as the ARM DS-5 Development
Studio, for Linux application deve lopment and debug. Some devel opers prefer using a
command-line tool when developing  Linux applications. Those dev elopers can use tools
built in-house or obtained from OS vendors. The Zynq-7000 AP So C ecosystem is supported
by a variety of OS partners. A list of OS partners is found in OS and RTOS Choices .
Trace
The Cortex-A9 includes a program  trace module (PTM) that is com patible with the ARM
CoreSight program-flow trace cap abilities. This can be used on either Cortex-A9 processor
and provides full visibility into  the processor instruction flo w. The Cortex-A9 PTM has
visibility over all code branches and program flow changes with  cycle-counting, enabling
profile analysis. The PTM block a nd the CoreSight design kit pr ovides the ability to
non-obtrusively trace the execut ion history of multiple process ors. The instruction
execution results can be stored in an on-chip buffer, or sent o ff-chip using a standard trace
interface for improved visibility during development and debug.
The ARM DS-5 Development Studio with DSTREAM supports ETB and P TM instruction trace
functions for Zynq-7000 AP SoC devices. Lauterbach Trace32 also  supports trace data from
PTM, FTM, ETB, and AXI Monitor.
For more information on SDK soft ware debug, refer to the follow ing:
• Zynq-7000 All Programmable SoC Software Developers Guide  (UG821) [Ref 7]
• Xilinx Software Development Kit Help  (UG782) [Ref 6]
X-Ref Target - Figure 7-2
Figure 7-2:  SDK System Debugger Window
Send Feedback

## Page 209

UltraFast Embedded Design Methodology Guide 209
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 7: Debug
Simulation-Based Debug
Simulation emulates the final de sign's behavior in a software e nvironment. Simulation helps
verify design functionality by i njecting stimulus and observing  the output result.
System Simulation
Zynq-7000 AP SoCs can be simulated  at the RTL level using the Z ynq-7000 AP SoC
verification intellectual proper ty (VIP). The VIP supports func tional simulation of Zynq-7000
AP SoC applications. It enables functional verification of PL b y mimicking the PS-PL
interfaces, and the PS OCM/DDR m emories. The VIP is delivered a s a package of encrypted
Verilog modules. The VIP operati on is controlled using a sequen ce of Verilog tasks
contained in a Verilog syntax file . For more information on the  Zynq-7000 AP SoC VIP, refer
to the product specification for the Zynq-7000 All Programmable SoC Verification IP v1.0
(DS940) [Ref 32].
If the design is created using I P integrator, the Vivado tools automatically use the
Zynq-7000 AP SoC VIP when the design simulation files are gener ated. The PL logic is
simulated using the IP RTL and the Zynq-7000 AP SoC VIP. A typi cal use case generates
transactions from the PS using G P ports. This can be done using  one of the Verilog tasks
defined as part of the Zynq-7000 AP SoC VIP.
When using a PL-side DDR memory,  the MIG slave interface will b e connected to the
Zynq-7000 AP SoC VIP with the AXI- interconnect. If a Micron mem ory module is used, the
associated Micron simulation mod el must be connected to the tes t bench during design
simulation.
Verifying Custom IP
Custom IP packaged using the Viv ado tools can be verified using  simulation and on
hardware. When creating custom I P using the Create and Package IP feature, the Verify the
Peripheral IP using the AXI VIP Simulation Interface  option should be used. Selecting
this option ensures that a templ ate IP integrator design is cre ated with AXI VIP, thus
simulating the core functionality. The test bench used by this template design uses the API's
defined in the AXI VIP. For more  details on the AXI Verificatio n Intellectual Property with
respect to APIs and response codes, refer to the AXI Verification IP v1.1 Product Guide (AXI)
(PG267) [Ref 33].
The default test bench template should be modified when testing  IP cores generated by the
CIP wizard. For more information  about the process of mapping H DLs with custom IP
templates, refer to this link  in the Vivado Design Suite User Gu ide: Creating and Packaging
Custom IP  (UG1118) [Ref 23]. Also, if ports are exposed, th e template IP integrator design
and the template test bench must  be modified accordingly before  design simulation.
Send Feedback

## Page 210

UltraFast Embedded Design Methodology Guide 210
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 7: Debug
Board Debug
After a design is implemented, it must be tested on hardware. S oftware debug of hardware
can be done using the SDK tool. Debug can be useful in finding problems in the FPGA or
fabric side.
FPGA-Only Debug
The PL can be debugged using the  Vivado Integrated Logic Analyz er (ILA). The ILA can be
included in the RTL code or inse rted in the PL after synthesis.  It can be configured to
monitor design interfaces and ne ts. A trigger co ndition can be specified during run-time
that exposes a specific problem.  Nets marked for debug and conn ected to the ILA can be
monitored to locate the problem source.
Processor-Only Debug
The SDK is used to debug softwar e issues. The SDK allows a user  to view the code, view
variable values, follow control flow, and set-up and analyze br eak points.
Before using the SDK, the design must be exported to hardware. The export process creates
a design directory containing fi les from the Vivado tools descr ibing the hardware
configuration. The files contain  information about all design I P blocks and their memory
map. Using this inform ation, the SDK can create the IP drivers.  Different software
applications can be created in t he SDK using the information pr ovided by the export
function.
After a software application has been built in the SDK, the FPG A can be programmed using
the design bitstream and the app lication can be launched on the  hardware. System
Debugger can then be used to debug the software application.
Send Feedback

## Page 211

UltraFast Embedded Design Methodology Guide 211
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 7: Debug
Hardware and Software Co-Debug
Zynq-7000 AP SoCs give you outstanding design potential, allowi ng you to combine
processor function with custom F PGA logic. With this high poten tial comes greater
complexity and the need for a po werful set of tools. Xilinx pro vides a solution allowing you
to simultaneously debug the PS a nd the peripherals in the PL.
Hardware and software co-debug i s done using the Vivado ILA and  the Xilinx SDK. The ILA
enables nets to be marked for debug and analyzed. The SDK allow s setting breakpoints or
watchpoints, stepping through pro gram execution, viewing progra m variables and the
stack, and viewing system memory  contents. Co-debug is used to debug system-level
issues when the software and hardware are combined.
Cross Triggering
Embedded Cross Trigger (ECT) is t he cross-triggering mechanism to debug interactions
between hardware and s oftware. Using ECT, a CoreSight component  can interact with other
components by sending and receiv ing triggers. ECT contains two components:
• CTM: Cross Trigger Matrix
• CTI: Cross Trigger Interface
Cross triggering can be used to co-debug an application running  on the processor and the
PL hardware. Vivado Hardware Man ager and the SDK are used for t his purpose.
Cross-trigger ports in the Zynq- 7000 AP SoC enable this feature  using handshake signals
with ILA. There are specific interfaces, TRIGGER_IN and TRIGGER _OUT, for each ARM core.
Designers can choose either or b oth of the ARM cross trigger in terfaces at the PS-PL
interface. Also, the designer must use the ILA IP in the PL and  set cross triggers in the SDK
GUI. Processor software can be interrupted when a hardware trig ger condition occurs and,
similarly, hardware signals can be probed when a software break point occurs. For more
information on the procedure to s et cross triggers and debug us ing Vivado, refer to the
Vivado Design Suite Tutorial: Embedded Processor Hardware Design  (UG940) [Ref 15].
Custom IP Hardware Validation
The CIP wizard enables custom IP  design template generation in IP integrator that can be
debugged on hardware. The Create and Package IP  feature provides you with the capability
to generate an example design connecting JTAG to the custom IP using an AXI Master core.
The design incorporates Master and Slave AXI VIPs based on the peripheral IP created and
stitches them with the peripheral IP. After the corresponding b itstream is programmed on
the board, you can modify the ge nerated test vector Tcl file to  test the peripheral IP
function tested on the board. The test vector file contains a s eries of writes and reads that
are used to validate the IP.
Send Feedback

## Page 212

UltraFast Embedded Design Methodology Guide 212
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 7: Debug
Virtual Platforms
Virtual platforms are software s ystems that mimic the behavior of hardware. They are fast,
functional models of an embedded platform. They execute the sam e software binaries as
hardware and run on tr aditional desktops, la ptops, or servers. Virtual platforms enable
system design to be done earlier and at a higher level of abstr action. They enable software
development to progress before h ardware (board or HDL) is avail able. They also support
unlimited fault injection and tes t, thereby catching and elimin ating bugs in early
development phases. Virtual plat forms can be easier and faster to modify than hardware
because hardware parameter s can be changed quickly.
Zynq-7000 AP SoC Virtual Platform
The Zynq-7000 AP SoC virtual platform uses models of PS compone nts found in a typical
SoC, including:
• The Cortex-A9 MPCore processor
• Peripherals around the processor,  such as UART, Ethernet, USB,  CAN, and others
• Component models frequently use d in the programmable fabric, s uch as PCIe
technology and video
The virtual platform can connect the models to a variety of int erfaces, including Ethernet,
USB, serial console, and graphical displays.
The virtual platform enables deve lopers to create and integrate  new device models within
the Zynq-7000 AP SoC PL. Models can also be created and integra ted within the board
containing the Zynq-7000 AP SoC. Unlike other solutions that re quire a hardware
implementation of custom IP to be connected to the virtual targ et, the Xilinx virtual
platform can be modified entirely  in software to represent a cu stom hardware design.
Xilinx virtual platforms are ben eficial to all stages of produc t development, from
pre-architecture product definit ion, system design, development , integration, test, to final
delivery.
The benefits include:
•T i m e  t o  M a r k e t
° Early software development:  Software teams can start developing device drivers
and applications prior t o hardware availability.
° Fast software development:  Unlike simulators for  hardware design and
verification, the virtual platfo rm runs fast enough to satisfy software developers.
° Smarter software development:  Virtual platforms enable software developers to
explore new techniques and trick s that can significantly reduce  development time.
Send Feedback

## Page 213

UltraFast Embedded Design Methodology Guide 213
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 7: Debug
° No retargeting:  Register and instruction-accurate models ensure that the virtu al
platform will run the same produc tion binaries used by the hard ware
implementation, simplifying soft ware migration to the physical platform.
° No hardware and software dependencies:  The need for developers to share
scarce development equ ipment is eliminated.
• Product Quality
° Improved system design:  Concurrently experiment wit h alternative software and
hardware configurations to y ield the best system design.
° Complete system visibility and control:  Any register and memory location can be
monitored and debugged, even at points that are inaccessible on  a physical device.
° Improved testing iterations:  Software and hardware can be debugged and tested
in parallel for more compr ehensive test coverage.
° Enhanced software regression testing:  Nightly software builds and tests can be
run on the virtual platform.
° Enhanced Fault injection and Metric driven verification:  A virtual platform
enables hardware fault injection , even at points that are inacc essible on a physical
device.
Cadence Virtual System Platform
Although traditional virtual platforms enable new development a pproaches that result in
changes in product design, they often fall short when product t eams move from a
development platform to their product-specific hardware. Extens ible virtual platforms offer:
• Convenient, well-defined model:  The Zynq-7000 SoC virtual  platform is out-of-box
ready. Software teams can use it  immediately to start developin g Linux, RTOS, and
bare-metal applications.
• Extensibility:  Xilinx and Cadence enable developers to extend the virtual pla tform with
new devices (instantiated within  the Zynq-7000 SoC programmable  fabric or on the
board) or system models. The ext ensible virtual platform has th e flexibility and
configurability of physical hardwa re. Using Cadence tools, it s upports models written in
C or System-C, as well as models written in SystemVerilog or VH DL.
Send Feedback

## Page 214

UltraFast Embedded Design Methodology Guide 214
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 8
SDSoC Environment
This chapter covers the following  information about designing i n the SDSoC environment:
• Overall Usage Flow in : You should understand the over all usage flow for using the
SDSoc design environment, as we ll as supported OSs and hardware  platforms.
• Profiling : SDSoC integrates profiling capabilities on top of the ones av ailable in Xilinx®
SDK, allowing you to profile the application without code instr umentation.
• Performance Estimation : The SDSoC environment provides tools to quickly estimate the
performance improvement that can  be expected when you identify functions for
hardware acce leration.
• Generating and Running a Compl ete Software-Hardware System : After running the
performance estimation flow, you  can rebuild the system and see  the actual
performance of the generated system.
• Optimizing Performance Using C-Callable RTL IP Library : You can use the C-Callable RTL
IP library to optimize performance.
• Optimizing IP Performance Using HLS : You can use Vivado high- level synthesis (HLS) to
compile application code that is sent to hardware in the SDSoC environment, and then
improve code using common strategies used by the SDSoC tool.
• Optimizing System Performance : With SDSoC, you can us e various techniques to
optimize your system performance.
• Debugging the System : SDSoC allows projects to be cr eated and debugged using the
SDSoC environment. SDSoC shares the debugging infrastructure an d methodology
with the Xilinx SDK System Debugger.
• Performance Measurement and Analysis : SDSoC shares many of the advanced
system-level performance measurement and analysis capabilities with Xilinx SDK. It
provides optional functions for measuring performance and for i dentifying
performance bottlenecks.
• Expert Use Models : Expert users can override de sign decisions made by SDSoC.
Send Feedback

## Page 215

UltraFast Embedded Design Methodology Guide 215
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 8: SDSoC Environment
Introduction
SDSoC provides a C/C++ programming experience with an easy-to-u se Eclipse-based
development environment, including design tools for Zynq®-7000A P SoC development by
software engineers and system arc hitects. SDSoC includes a full -system optimizing C/C++
compiler that provides automated software a cceleration in progr ammable logic combined
with automated system connectivity generation between the softw are and the hardware.
The SDSoC programming model is designed to be intuitive to soft ware engineers. An
application is written as C/C++ co de, with the pro grammer ident ifying a target platform
and a subset of the functions within the application to compile  into hardware. The SDSoC
C/C++ compiler and linker then co mpile the application into har dware and software to
realize the complete embedded sy stem implemented on a Zynq devi ce, including a
complete boot image with firmwar e, operating system, and applic ation executable.
Figure  8-1 shows the complete system flow.
SDSoC unifies the hardware and s oftware design flows presented in this guide into a single
C/C++ based flow and automates many of the time-consuming tasks , especially the system
connectivity generation and the h ardware-software integration. Figure  8-2 illustrates the
X-Ref Target - Figure 8-1
Figure 8-1:  Complete C/C++ Application to Zynq System Flow with SDSoC
Send Feedback

## Page 216

UltraFast Embedded Design Methodology Guide 216
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 8: SDSoC Environment
difference between the traditional hardware-software design flo w and the design flow
using SDSoC. By automating many of the design tasks, SDSoC enab les a software engineer
and system architect to quickly implement an application and pe rform rapid design
iteration.
The hardware/software interface is defined by the interactions and data flow among
functions mapped to hardware and  the rest of the program. Each function mapped to
hardware runs as an independent t hread, but the compiler ensure s that the program
semantics are preserved. Rather than recoding an application to  invoke device drivers for
each hardware function, SDSoC co mpiler automatically maps the o riginal application onto
the generated hardware system us ing its own library of efficien t data movers to
communicate data between the proce ssing system and the programm able logic.
The easiest way to understand the mapping is to realize that th e SDSoC compiler analyzes
the program structure and its da ta flow and generates a hardwar e and software system that
efficiently implements the program's data flow, including optim izations to communicate
data directly from one hardware block to another, rather than a lways going through the
processing system main memory.
Applications can link with C-callable IP libraries to support I P reuse. When application code
links with C-callable libraries p rovided as part of the platfor m, the interface to these
libraries essentially encapsulate s the platform-specific portio ns of the application. In this
way, applications can achieve co nsiderable portability across p latforms.
Overall Usage Flow
Figure  8-3 shows the overall usage flow usi ng the SDSoC design environmen t. For a given
user application, the first step is to identify the compute-int ensive parts of the application
using profiling or by ot her means. These par ts should either be  already present or
refactored into functions. In th e SDSoC design environment, the se functions can then be
assigned to hardware. SDSoC suppo rts a fast performance estimat ion without generating
X-Ref Target - Figure 8-2
Figure 8-2:  The Traditional Design Flow(a)  and the Design Flow with SDSoC ( b)
Send Feedback

## Page 217

UltraFast Embedded Design Methodology Guide 217
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 8: SDSoC Environment
full bit-stream to enable rapid d esign optimization. Based on t he performance estimation,
optimizations can be done with the following goals:
• To migrate more computation to hardware
• To optimize the performance of f unctions moved to hardware; fo r example, using
high-level synthesis (HLS) pragmas
• To optimize the data transfer p erformance between the processi ng system and
programmable logic; for example, using different data movers or  different memory
allocation
Send Feedback

## Page 218

UltraFast Embedded Design Methodology Guide 218
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 8: SDSoC Environment
After achieving the desired performance, SDSoC can generate the  SD card image for the full
system to run the application on  the target platform. Based on running the generated
system, further optimizations can be done.
X-Ref Target - Figure 8-3
Figure 8-3:  SDSoC User Flow
''%TTPMGEXMSRVYRRMRK
SR%61
4VSJMPIETTPMGEXMSR
1EVOJYRGXMSRWJSV,;
EGGIPIVEXMSR
)WXMQEXITIVJSVQERGI
&YMPHETTPMGEXMSRXSKIRIVEXI7;
ERH,;
7('EVH-QEKI
6YRSRXLIFSEVH
3TXMQM^IHEXEXVERWJIVERH
TEVEPPIPMWQYWMRK%4*''
KYMHIPMRIW
3TXMQM^IEGGIPIVEXSVGSHI
%REP]^ITIVJSVQERGI
Send Feedback

## Page 219

UltraFast Embedded Design Methodology Guide 219
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 8: SDSoC Environment
By default, SDSoC targets the Linux operating system. The SD ca rd image that is generated
includes the Linux kernel, file s ystem, and user application. S DSoC also supports FreeRTOS
and a standalone (bare metal) mo de as choices of OS. For FreeRT OS and standalone, the
user application is compiled with  support from Xilinx Standalon e system (LibXil). For more
details on options to control t he OS choice, refer to the SDSoC Environment User Guide
(UG1027) [Ref 26] and the SDSoC Environment Tutorial: Introduction  (UG1028) [Ref 27].
SDSoC comes with support for a few hardware platforms out of th e box. This list of
supported platforms includes popu lar boards such as ZC702, ZC70 6, Zed board, and
MicroZed. You can select the targ et platform for an application  either in SDK while setting
up the project, or by specifying the -sds-pf  command line option within a Makefile. You
can view the list of all available platforms by running the com mand line tool sdscc with the
option -sds-pf-list .
SDSoC also allows users and thir d-parties to generate platforms  starting with their own
Vivado designs. Such platforms c an be selected by pointing to t he top-level platform
directory either in SDK or the command line. For more details o n creating SDSoC platforms,
refer to the SDSoC Environment Platform Development Guide  (UG1146) [Ref 28].
Profiling
The importance of performance an alysis and profiling has been w ell documented in
previous chapters. SDSoC integrates those principles through ho oks and features inside the
tool. Profiling capabilities build on top of the ones in Xilinx  SDK, and therefore, application
developers can use the non-intru sive TCF profiler to profile th e application without any
code instrumentation. Based on the profile information, a first  pass at moving functions to
hardware can be started. F or more details, refer to Chapter  6, Software Design Flow .
SDSoC also supports the standard Eclipse based tools, such as g prof, for profiling the user
application; refer to Chapter  7, Debug  for references. An SDSoC user can modify the build
properties of the applic ation and select the –pg and –g1 options to obtain the profiling
information. Once these options are selected, the user can buil d the project and execute it
on the board to obtain the profile information file ( gmon.out ). The SDSoC environment
includes the standard Eclipse-b ased graphical view of the gmon.out  file, which shows a
hierarchical view of functions with the percentage of time spen t in each of them.
Send Feedback

## Page 220

UltraFast Embedded Design Methodology Guide 220
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 8: SDSoC Environment
Performance Estimation
After functions have been identif ied for hardware acceleration,  the SDSoC environment
provides tools to quickly estimat e the performance improvement that can be expected by
these choices. For example, a full build cycle for a typical ap plication might take 40 minutes,
whereas the performance estimation flow can give an estimate of  the application speedup
in the order of minutes. The perf ormance estimation flow can be  run by changing the build
configuration to “SDEstimate” an d building the project. More de tails on this flow can be
found in SDSoC Environment User Guide  (UG1027) [Ref 26] and the SDSoC Environment
Tutorial: Introduction  (UG1028) [Ref 27].
Generating and Running a Complete
Software-Hardware System
Once you are satisfied with the estimated performance obtained by performing iterations
using the performance estimation  flow, you can change the build  configuration to
“SDRelease” and rebuild the project. You can also copy the gene rated SD card image to an
SD card and run on the board to see the actual performance of t he generated system.
Optimizing Performance Using C-Callable RTL IP
Library
As described in Introduction , the data flow defined by a s oftware application can be
automatically mapped onto hardwar e and software in an applicati on-specific SoC. The
SDSoC compiler maps and schedules  operations onto hardware func tions based on
program data flow. An applicatio n can also link to a library th at provides a function call
mapping onto an IP block defined in a hardware description lang uage like Verilog. From the
point of view of the application code and the SDSoC compiler, t he scheduling and mapping
are identical whether the function is synthesized at compile ti me using HLS or mapped onto
an HDL IP block. Any call to a h ardware function will be mapped  into hardware by the
SDSoC compiler.
A traditional “software driver” approach to targeting an IP blo ck peripheral typically
exposes only the control interfa ce; the hardware system capture s the data flow. Using a
full-system compiler like SDSoC, application code can instead d irectly invo ke the data
processing functions as it would any other functional library. The data transport, such as
using DMA, is abstracted and aut omatically invok ed to implement  the function call
efficiently.
Send Feedback

## Page 221

UltraFast Embedded Design Methodology Guide 221
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 8: SDSoC Environment
For more information, refer to the SDSoC Environment Platform Development Guide
(UG1146) [Ref 28].
Optimizing IP Performance Using HLS
The application code that is sent to hardware in the SDSoC envi ronment is compiled
through the Vivado high-level sy nthesis (HLS) compiler. This is  described in Chapter  5,
Hardware Design Flow . Several optimization strategies are presented in the Vivado Design
Suite User Guide: High-Level Synthesis  (UG902) [Ref 9]. Some common strategies to improve
code are used by the SDSoC tool,  such as adding a pragma for en abling pipelining before
a compute intensive l oop and increasing the memory bandwidth fo r the inner loop by
specifying the array_pa rtition pragma for t he variables accesse d inside the inner loop. For
more high-level details for optim ization strategies, refer to SDSoC Environment User Guide
(UG1027) [Ref 26].
Optimizing System Performance
System performance improvements through acceleration is one of the key principles
integrated in the SDSoC. Chapter  2, System Level Considerations  and Chapter  3, Hardware
Design Considerations  touched upon the different ways to improve performance from bo th
Software and Hardware perspectiv e. This section describes some additional techniques
used by SDSoC and how the it imp lements some of the previously described techniques
such as storing data in system  memory and data pipelining.
Using Physically Contiguous Memory
The SDSoC system-optimizing comp iler incorporates memory alloca tion trade-offs in
software and hardware functions.  On Linux based systems, memory  allocated by malloc()
is paged. The kernel keeps track of the pages for the user and presents a unified view to the
user application. However, when memory allocated by malloc()  is transferred to the
accelerator, there is a performa nce penalty to collect individu al pages and transfer them
using the scatter-gather mode in the AXI-DMA. SDSoC provides a user-accessible function
sds_alloc() , which behaves like malloc()  but allocates physically contiguous memory.
This results in faster performanc e when using data movers like scatter-gather DMA, but it
also allows SDSoC to choose data movers like simple-mode of the  AXI-DMA with
significantly better perform ance due to lo wer overhead.
Send Feedback

## Page 222

UltraFast Embedded Design Methodology Guide 222
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 8: SDSoC Environment
Using Local Caches and Streaming Data
The data transferred to the code compiled through Vivado HLS ca n be sent once to reside
in BRAMs in the programmable logic for the duration of the comp utation, if the amount of
data is small. If the data is too large to fit in BRAMs in the programmable logic, or if it is not
used multiple times during the c omputation, then it can be sent  as a datastream to the
generated accelerator. You can c ontrol these choices for cachin g or streaming data being
transferred between the process or and accelerator, as detailed in the SDSoC Environment
User Guide  (UG1027) [Ref 26].
Using Shared Memory
Instead of transferring data from the processor's memory to the  accelerator's local memory
or streaming it through the accelerator, it is also possible fo r the processor and accelerator
to access a common region of shared memory. You can achieve thi s by adding code
pragmas to the function that is mapped to hardware. Using this technique requires the user
application to alloca te the memory using sds_alloc()  instead of malloc() . More
details about this can be found in the SDSoC Environment User Guide  (UG1027) [Ref 26].
Using Direct Accelerator-Accelerator Data Transfers
If multiple functions are select ed for hardware acceleration, t he SDSoC environment can
automatically pipeline them. This  means that it passes the data  transferred between them
directly in hardware, without co pying it to the processor first , so long as there is no use on
the processor side.
Using Multiple Instances of the Same Hardware Function
Multiple calls from a single source location to a function mapp ed to hardware are mapped
to a single accelerator. However, SDSoC provides an async  code pragma, which directs the
compiler to generate multiple acce lerator instances to improve the performance of the
application by processing  more data in parallel.
Pipelining Data Communication with Computation
Multiple successive calls to an a ccelerator can be pipelined by  the SDSoC compiler under
user pragma control. T his allows the overlap of accelerator com putation with the data
transfer of the subsequent call to the accelerator. Consider Figure  8-4, which shows
sequential calls to an accelerator with two inputs and one outp ut.
Send Feedback

## Page 223

UltraFast Embedded Design Methodology Guide 223
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 8: SDSoC Environment
Figure  8-5 shows two calls to the same acce lerator executin g in a pipelin ed fashion.
Multiple buffers, automatically inserted by the compiler, are u sed so that the data transfer
for the second call can start as  soon as the data transfer for the first call is done. This is
achieved in the SDSoC environment by using the async  pragma as described in Chapter 7
of the SDSoC Environment User Guide  (UG1027) [Ref 26].
Debugging the System
SDSoC shares the debugging infra structure and methodology with the Xilinx SDK System
Debugger, including enhancements to support debugging applicati ons for the standalone
platform and having the ability to look into IP registers in th e physical address space. Refer
to Chapter  6, Software Design Flow .
SDSoC allows projects to be created and debugged using the SDSo C IDE. Projects can also
be created outside the SDSoC IDE using user-created Makefiles a nd debugged either on the
command line or using the SDSoC I DE. For details about debuggin g, refer to the SDSoC
Environment User Guide  (UG1027) [Ref 26] and the SDSoC Environment Tutorial: Introduction
(UG1028) [Ref 27].
X-Ref Target - Figure 8-4
Figure 8-4:  Sequential Execution of Calls to the Accelerator
X-Ref Target - Figure 8-5
Figure 8-5:  Pipelined Execution of Calls to the Accelerator
Send Feedback

## Page 224

UltraFast Embedded Design Methodology Guide 224
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 8: SDSoC Environment
Performance Measurement and Analysis
For simple performance measuremen t and to identify performance bottlenecks, SDSoC
provides the function sds_clock_counter() , which returns a cycle-accurate timestamp
from a free-running counter in ha rdware. You can use this count er to instrument your code
and collect performance data. You also have access to Vivado_HL S reports under the _sds
folder in the build directory, f rom which you can gain more ins ight about the generated
hardware and cha nges you could make to improve performance.
SDSoC shares many of the advanced system-level performance meas urement and analysis
capabilities with Xilinx SDK; refer to Chapter  6, Software Design Flow . The SDSoC compiler
optionally inserts an AXI Performance Monitor (APM) into the ge nerated system to monitor
traffic between the Zynq device P rogramming Logic (PL) and Proc essing System (PS). By
observing activity at the PS/PL boundary using the APM, a desig ner can determine whether
a system is saturating the capacity of a particular resource, s uch as the cache-coherent ACP
port.
A hardware function observing an  idle data transport interface for long periods between
computations might indicate a co mpute-bound system that would b enefit from accelerator
micro-architecture optimization to increase throughput and decr ease latency. Conversely, a
data transport interface that is  saturated might indicate a sit uation where traffic can be
redirected to other available tr ansport interfaces on the PS. F or more information, refer to
the Xilinx Software Development Kit (SDK) Us er Guide: System Performance Analysis
(UG1145) [Ref 25].
Expert Use Models
You can override every design decision made by SDSoC as needed,  either by inserting
pragmas into application code or by using IDE/command-line para meters.
Specific controls for more advan ced users provide the following  capabilities.
• Data mover selection: To contro l the mapping of data transfers  on to different IP
blocks, such as simple mode DMA, scatter-gather DMA, and 2-D DM A.
• Zynq-7000AP SoC processing system interfaces to CPU and DDR se lection: To control
the mapping onto cache-coherent o r high-throughput AXI interfac es.
• Hardware function "port" interf ace selections: To control the hardware interfaces on
hardware accele rator; for example, as  "shared memory" between hardware function
and controlling software thread,  or as "copy-in, copy-out" for caching data in local
BRAMs.
• Run-time variable size data transfers: For transfers that obey  "copy-in, copy-out"
semantics, limiting transfer siz es when possible can improve sy stem performance.
Send Feedback

## Page 225

UltraFast Embedded Design Methodology Guide 225
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Chapter 8: SDSoC Environment
• Hardware function microarchitecture using Vivado HLS: For comp ute-bound systems,
you can employ Vivado HLS pragmas and directives to improve thr oughput and latency.
• Blocking vs. non-blocking functi on invocation: By default, fun ctions preserve the
original function call semantics, but you can instruct the comp iler, using pragmas in the
code, to return contro l "immediately", such as, to implement so ftware task pipelining.
• Mapping subsets of hardware func tions into different bitstream s that the application
will time-multiplex during run-time: To time multiplex the prog rammable logic fabric to
realize more hardware functions than can fit in the target devi ce concurrently.
For more details regarding each of these controls, refer to the  “SDSoC Pragma
Specification” section in the SDSoC Environment User Guide  (UG1027) [Ref 26].
Advanced users, hardware designe rs, and system software teams m ight want to build their
own SDSoC platform, including pa rtial hardware design and softw are components like OS,
drivers, file system, and librari es. They can also package thei r own HDL IP as C-callable IP
libraries. There is a well-define d, low-overhead methodology fo r exporting a Vivado
hardware system to su pport SDSoC, as well as to create C-callab le libraries for HDL IPs. For
more information , refer to the SDSoC Environment Platform Development Gu ide (UG1146)
[Ref 28].
SDSoC is a tool that brings a lot  of techniques described in ea rlier chapters under one
umbrella to aid you in effectivel y architecting, designing, and  debugging a system. It
provides a means to implement me thodology principles described earlier and also
highlights new principles that b ecome visible when seen under o ne umbrella. The biggest
benefits of the tool are reaped by the Software designer. This is a must have in a Software
designer's toolbox to accelerate  development of systems with ha rdware components.
Send Feedback

## Page 226

UltraFast Embedded Design Methodology Guide 226
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Appendix A
Additional Resources and Legal Notices
Xilinx Resources
For support resources such as Answers, Documentation, Downloads , and Forums, see Xilinx
Support .
Solution Centers
See the Xilinx Solution Centers  for support on devices, softw are tools, and intellectual
property at all stages of the design cycle. Topics include desi gn assistance, advisories, and
troubleshooting tips.
Documentation Navigator and Design Hubs
Xilinx Documentation Navigator provides access to Xilinx docume nts, videos, and support
resources, which you can filter and search to find information.  To open the Xilinx
Documentation Navigator (DocNav):
• From the Vivado IDE, select Help > Documentation and Tutorials .
• On Windows, select Start > All Programs > Xilinx Design Tools > DocNav .
• At the Linux command prompt, enter docnav .
Xilinx Design Hubs provide links t o documentation organized by design tasks and other
topics, which you can use to learn key concepts and address fre quently asked questions. To
access the Design Hubs:
• In the Xilinx Documentatio n Navigator, click the Design Hubs View  tab.
• On the Xilinx website, see the Design Hubs  page.
Note: For more information  on Documentation Navigator, see the Documentation Navigator  page
on the Xilinx website.
Send Feedback

## Page 227

UltraFast Embedded Design Methodology Guide 227
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Appendix A: Additional Resources and Legal Notices
Xilinx Documentation Navigator
The Xilinx Documentation Navigato r is a free tool that you can use to access documentation
while using Xilinx products. The Documentation Navigator is ava ilable as part of the Vivado
Installer. When it is installed on your system, you can access it by going to Start > Programs
> Xilinx Design Tools > DocNav  and clicking the DocNav  icon.
For detailed information about using the Xilinx Documentation N avigator, refer to this link
in Vivado Design Suite User Guide: Getting Started (UG910) [Ref 11].
Related Design Hubs
Design hubs provide quick access to documentation, training, an d information for specific
design tasks. The following design hubs are applicable to embed ded development and the
methods described in this guide:
• Partial Reconfiguration Design Hub
• Software Development Kit (SDK) Design Hub
References
The references below provide additional information.
Xilinx User and Reference Guides
1. 7 Series FPGAs Clocking Resources  (UG472 )
2. 7 Series FPGAs GTX/GTH Transceivers  (UG476 )
3. 7 Series FPGAs GTP Transceivers  (UG482 )
4. Zynq-7000 All Programmable So C Technical Reference Manual  (UG585 )
5. OS and Libraries Document Collection  (UG643 )
6. Xilinx Software Development Kit Help  (UG782 )
7. Zynq-7000 All Programmable SoC Software Developers Guide  (UG821 )
8. ZC702 Evaluation Board for the Zynq-7000 XC7X020 All Programmab le SoC User Guide
(UG850 )
9. Vivado Design Suite User Gu ide: High-Level Synthesis  (UG902 )
10. Vivado Design Suite User Guide:  Power Analysis and Optimization  (UG907 )
11. Vivado Design Suite User Guide: Getting Started  (UG910 )
Send Feedback

## Page 228

UltraFast Embedded Design Methodology Guide 228
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Appendix A: Additional Resources and Legal Notices
12. AXI Interface Based KC705 Embedded Kit Mi croBlaze Processor Subsystem Software
Tutorial  (UG915 )
13. Zynq-7000 All Programmable SoC ZC702 Base Ta rgeted Reference Design (Vivado Design
Suite 2014.2) User Guide  (UG925 )
14. Zynq-7000 All Programmabl e SoC PCB Design Guide  (UG933 )
15. Vivado Design Suite Tutorial: Em bedded Processor Hardware Design  (UG940 )
16. UltraFast Design Methodology Guide for the Vivado Design Suite  (UG949 )
17. PetaLinux Tools User Guide: Zynq All Pr ogrammable SoC Linux-FreeRTOS AMP Guide
(UG978 )
18. Vivado Design Suite User Guide: Embedded Processor Hardware Design  (UG898 )
19. Vivado Design Suite User Guide: Designing IP Subsystems Using IP Integrator  (UG994 )
20. Programming ARM TrustZone Ar chitecture on the Xilinx Zy nq-7000 All Programmable SoC
User Guide  (UG1019 )
21. Zynq-7000 All Programmable SoC Secu re Boot Getting Started Guide  (UG1025 )
22. Embedded System Tools Reference Manual  (UG1043 )
23. Vivado Design Suite User Guide: Creating and Packaging Custom IP  (UG1118 )
24. Generating Basic Software Platforms Reference Guide  (UG1138 )
25. Xilinx Software Development Kit (SDK) Us er Guide: System Performance Analysis
(UG1145 )
SDSoC Documentation
26. SDSoC Environment User Guide  (UG1027 )
27. SDSoC Environment Tutorial: Introduction  (UG1028 )
28. SDSoC Environment Platform Development Guide  (UG1146 )
29. SDSoC Environment Optimization Guide  (UG1235 )
Other Xilinx References
Data Sheets
30. Zynq-7000 All Programmable SoC (Z-7007S , Z-7012S, Z-7014S, Z-7010, Z-7015, and
Z-7020): DC and AC Swit ching Characteristics  (DS187 )
31. Zynq-7000 All Programmable SoC Overview  (DS190 )
32. Zynq-7000 All Programmable SoC Verification IP v1.0  (DS940 )
Send Feedback

## Page 229

UltraFast Embedded Design Methodology Guide 229
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Appendix A: Additional Resources and Legal Notices
Product Guides
33. AXI Verification IP v1.1 Product Guide (AXI)  (PG267 )
White Papers
34. Get Smart about Reset: Think Local, Not Global Whitepaper  (WP272 )
35. Secure Boot in the Zynq-7000 All Programmable SoC  (WP426 )
Application Notes
36. Designing High-Performance Video System s with the Zynq-7000 All Programmable SoC
(XAPP792 )
37. LightWeight IP (lwIP) Application Examples  (XAPP1026 )
38. Simple AMP Running Linux and Bare-Metal Sy stem on Both Zynq- 7000 AP SoC Processors
(XAPP1078 )
39. Simple AMP: Bare-Metal System Ru nning on Both Cortex-A9 Processors  (XAPP1079 )
40. PS and PL Ethernet Performa nce and Jumbo Frame Support with PL Ethernet in the
Zynq-7000 AP SoC  (XAPP1082 )
41. Using the Zynq-7000 Processing System (PS) to Xilinx Analog to Digital Converter (XADC)
Dedicated Interface to Im plement System Monitoring  and External Channel
Measurements  (XAPP1172 )
42. Secure Boot of Zynq-7000 All Programmable SoC  (XAPP1175 )
43. System Monitoring Using the Zynq-7000 AP SoC Processing System with the XADC AXI
Interface  (XAPP1182 )
44. Zynq-7000 Platform Software Develo pment Using the ARM DS-5 Toolchain  (XAPP1185 )
Web Pages
45.  AXI Performance Monitor web page
46.  AXI Timer/Counter web page
47.  LogiCORE™ AXI Traffic Generator web page
48.  Xilinx Security Solutions web page
49.  Xilinx Zynq-7000 AP SoC Ecosystem web page
50.  Xilinx PetaLinux  Tools web page
Send Feedback

## Page 230

UltraFast Embedded Design Methodology Guide 230
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Appendix A: Additional Resources and Legal Notices
Wiki Pages
51.  K7 Embedded TRD 2013.2 wiki page
52.  Xilinx Linux Drivers wiki page
53.  Xilinx Linux GPIO driver wiki page
54.  Xilinx Linux I2C driver wiki page
55.  Xilinx Linux SPI driver wiki page
56.  Xilinx Linux wiki page
57.  Xilinx Multi-OS Support wiki page
58.  Xilinx PetaLin ux wiki page
59.  Xilinx U-Boot wiki page
60.  Xilinx Yocto wiki page
61.  Zynq-7000 AP SoC Boot - Booting and Running Without External Me mory Tech Tip wiki
page
62.  Zynq-7000 AP SoC Boot - Locking and Executing out of L2 Cache T ech Tip wiki page
63.  Zynq-7000 AP SoC Low Power Techni ques part 1 - Installing and R unning the Power
Demo Tech Tip wiki page
64.  Xilinx Zynq-7000 AP SoC Spectrum Analyzer part 2-Building ARM N EON Library Tech Tip
65.  Xilinx Zynq Linux wiki page
66.  Xilinx Zynq Power Management wiki page
Answer Records
67.  Xilinx Answer Record 46778
68.  Xilinx Answer Record 47511
69.  Xilinx Answer Record 50991
70.  Xilinx Answer Record 52847
71.  Xilinx Answer Record 55572
72.  Xilinx Answer Record 57744
73.  Xilinx Answer Record 58387
Send Feedback

## Page 231

UltraFast Embedded Design Methodology Guide 231
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Appendix A: Additional Resources and Legal Notices
Information from Other Companies
74. ARM DS-5 Development Studio St reamline Performa nce Analyzer documentation:
http://ds.arm.com/ds-5/optimize
75. ARM Infocenter Accelerator Coherency Port web page:
http://infocenter.arm.com/help/i ndex.jsp?topic=/com.arm.doc.ddi 0407e/CACGGBCF.ht
ml
76. ARM Security Technology: Building a Secu re System using TrustZone® Technology :
http://infocenter.arm.com/help/t opic/com.arm.doc.prd29-genc-009 492c/PRD29-GENC
-009492C_trustzone_security_whitepaper.pdf
77. Cortex-A9 Technical Reference Manual :
http://infocenter.arm.com/help /topic/com.arm.doc.ddi0388e/DDI03 88E_cortex_a9_r2p
0_trm.pdf
78. Design Calculations for Ro bust I2C Communications:
http://www.edn.com/design/analog/4371297/Design-calculations-for-robust-I2C-communic
ations
79. Discretix: http://www.discretix.com/
80. ENEA Software AB Solutions: http://www.enea.com/solutions/
81. eSOL Embedded Engineering  and Enabling Solution: http://www.esol.com/
82. Express Logic ThreadX RTOS: http://rtos.com/produc ts/threadx/xilinx_arm
83. GreenHills INTEGRITY RTOS: http://www.ghs.com/prod ucts/xilinx_zynq.html
84. How a MicroBlaze can peaceably co exist with the Zynq-7000 AP SoC :
http://www.eetimes.com/do cument.asp?doc_id=1280680
85. IAR Integrated Solutions Partner Program:
http://www.iar.com/Products/RTOS/Integrated-RTOSes/
86. iVeia Adeneo Embedded Board Support Packages:
http://www.adeneo-embedded.com/Pr oducts/Board-Support-Packages
87. Mentor Graphics Nucleus RTOS:
http://www.mentor.com/embedded-so ftware/nucleus/?sfm=auto_sugge st
88. Micrium µC/OS RTOS: http://micrium.com/products/
89. MontaVista Carrier Grade Edition 7:
http://www.mvista.com/product-carrier-grade-edition7.html
90. PCA9548A Low Voltage 8-Channe l I2C Switch With Reset :
http://www.ti.com/lit/ds/symlink/pca9548a.pdf
91. SD Association, Latest Si mplified Specifications:
https://www.sdcard.org/downl oads/pls/simplified_specs/
92. Open Kernel Labs OKL4 Microvisor: http://www.ok-labs.com/products/okl4-microvisor
Send Feedback

## Page 232

UltraFast Embedded Design Methodology Guide 232
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Appendix A: Additional Resources and Legal Notices
93. QNX Neutrino RTOS:
http://www.qnx.com/products/neutr ino-rtos/neutrino-rtos.html#ov erview|
94. Quadros RTOS: http://www.quadros.com/pr oducts/operating-systems
95. Real Time Engineers FreeRTOS Interactive webpage:
http://www.freertos.org/Interacti ve_Frames/Open_Frames.html?htt p://interactive.freert
os.org/entries/23277857-Updated-Xi linx-FreeRTOS-port-for-Zynq-t o-SDK-14-4-release
96. Sciopta RTOS: http://www.sciopta.com/news/ZYNQ-7000.html
97. Sierraware Hypervisor and Sier raTEE Trusted Ex ecution Enviro nment:
http://www.sierraware.com/arm_hypervisor.html
98. SYSGO PikeOS BSPs for ZC702,  Zed, and Zynq-7000 All Programm able SoC BSP:
http://www.sysgo.com/products/boa rd-support-packages/pikeos-bsp -list/
99. SYSGO PikeOS Product Information:
http://www.sysgo.com/news-events/ press/press/details/article/sy sgos-certified-pikeos
-supports-xilinxs-zynq- 7000-all-programmable-soc/
100.The Official Linux Ker nel from Xilinx webpage: https://github.com/Xilinx/linux-xlnx
101.Timesys LinuxLink: http://www.timesys.com/em bedded-linux/linuxlink
102.Wind River VxWorks, Linux, and Workbench IDE: http://www.windriver.com/
103. Xilinx XC702 DS-5 Gett ing Connected Guide:
http://www.arm.com/files/pdf/zc702_ds5_2.pdf
104.Yocto Project webpage: http://git.yoctoproject.org/cg it/cgit.cgi/meta-xilinx/about/
Training Resources
Xilinx provides a variety of trai ning courses and QuickTake vid eos to help you learn more
about the concepts presented in this document. Use these links to explore related videos:
1.  Vivado Design Suite QuickTake Video: How to Create a Zynq Boot Image Using Xilinx
SDK
2. Vivado Design Suite Quic kTake Video Tutorials
Send Feedback

## Page 233

UltraFast Embedded Design Methodology Guide 233
UG1046 (v2.3) April 20, 2018 www.xilinx.com
Appendix A: Additional Resources and Legal Notices
Please Read: Important Legal Notices
The information disclosed to you hereunder (the “Materials”) is  provided solely for the selection and use of Xilinx products. To the
maximum extent permitted by applicable law: (1) Materials are m ade available "AS IS" and with a ll faults, Xilinx hereby DISCLA IMS
ALL WARRANTIES AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULA R PURPOSE; and (2) Xilinx shall not be liable (whether
in contract or tort, including negligence, or under any other t heory of liability) for any loss or damage of any kind or natur e related
to, arising under, or in connection with, the Materials (includ ing your use of the Materials), including for any direct, indir ect, special,
incidental, or consequential los s or damage (inc luding loss of data, profits, goodwill, or any type of loss or damage suffered  as a
result of any action brought by a third party) even if such dam age or loss was reasonably foreseeable or Xilinx had been advis ed
of the possibility of the same. Xilinx assumes no obligation to  correct any errors contained in the Materials or to notify you  of
updates to the Materials or to p roduct specifications. You may not reproduce, modify, distribute, or publicly display the Mate rials
without prior written consent. Certain products are subject to the terms and conditions of Xilinx’s limited warranty, please r efer to
Xilinx’s Terms of Sale wh ich can be viewed at https://www.xilinx.c om/legal.htm#tos ; IP cores may be subject to warranty and
support terms contained in a license issued to you by Xilinx. X ilinx products are not designed or intended to be fail-safe or for use
in any application requiring fail-safe performance; you assume sole risk and liability for use of Xilinx products in such crit ical
applications, please refer to Xilinx’s Terms of Sale which can be viewed at https://www.xilinx.com/legal.htm#tos .
AUTOMOTIVE APPLICATIONS DISCLAIMER
AUTOMOTIVE PRODUCTS (IDENTIFIED AS “XA” IN THE PART NUMBER) ARE  NOT WARRANTED FOR USE IN THE DEPLOYMENT OF
AIRBAGS OR FOR USE IN APPLICATIONS THAT AFFECT CONTROL OF A VEH ICLE (“SAFETY APPLICATION”) UNLESS THERE IS A
SAFETY CONCEPT OR REDUNDANCY FEATURE CONSISTENT WITH THE ISO 26 262 AUTOMOTIVE SAFETY STANDARD (“SAFETY
DESIGN”). CUSTOMER SHALL, PRIOR TO USING OR DISTRIBUTING ANY SY STEMS THAT INCORPORATE PRODUCTS, THOROUGHLY
TEST SUCH SYSTEMS FOR SAFETY PURPOSES. USE OF PRODUCTS IN A SAF ETY APPLICATION WITHOUT A SAFETY DESIGN IS FULLY
AT THE RISK OF CUSTOMER, SUBJECT ONLY TO APPLICABLE LAWS AND RE GULATIONS GOVERNING LIMITATIONS ON PRODUCT
LIABILITY.
© Copyright 2014-2018 X ilinx, Inc. Xilinx, th e Xilinx logo, Art ix, ISE, Kintex, Spartan, Virtex , Vivado, Zynq, and other desig nated
brands included herein are trad emarks of Xilinx in the United S tates and other countries. All ot her trademarks are the propert y of
their respective owners.
Send Feedback
