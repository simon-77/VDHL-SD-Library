# VDHL-SD-Library
A VHDL-Library for reading a SD-Card with a FPGA in a small test project

I had to write a VHDL unit which could access a SD-Card for a school project.
Even though I found some existing Verilog and VHDL projects which did this, I had some special requirements:
The SD-Card must be accessed in 4-bit SD-Mode to achieve a write speed of up to 25 MB/s and it must be written in VHDL.
I couldn't find something which met my requirements so I decided to write a library from scratch.

I found an official and freely available specifiaction of SD-Cards from the "SD Card Association" which I used for designing my VHDL Library. This specification is included in this github repository: "SD Specification_Part 1_Physical Layer_Simplified_v4.10_2013.pdf"

The folder "sd_v3" holds a project which includes the source code of my SD-Library and shows furthermore how it can be used.
Some details of the project:
* Design Suite: Quartus Prime Lite Edition V17.0
* Target FPGA:  "DE0-Nano" (Cyclone IV)

Features of the SD-Library:
* written in VHDL
* support 4-bit SD-mode
* support high-speed clock of 50MHz
* read speed of up to 25MByte/s
* Read single block
* Read multiple blocks
* Stop a transmission and resume it later
* Supported Cards:
  - SDSC (Standard Capacity SD) (up to 1GB)
  - HCSD (High Capacity SD) (up to 32GB)
  - XCSD (Extended Capacity SD) (up to 2TB)

What the SD-Library does not support:
* write data to SD-Card
* It neither supports partitions nor filesystems
* It does not support UHS-I or UHS-II mode

This library can read blocks from the SD-Card very efficiently,
but it neather can write data to the SD-Card nor can it interpret partitions or filesystems.
Our usecase was that we had a single large file (a few GB) which had to be read in by the FPGA block by block very fast.
We did a diskdump of the file to the SD-Card as a block-device in Linux:
$ sudo dd if=file.img of=/dev/sdb
Note that we do not use the partition (/dev/sdb1), but the blockdevice (/dev/sdv).
Now the file is laying on the SD-Card byte after byte and can be read with this Library.
A normal computer tryes to detect partitions and a filesystem and can not use the SD-card.
To use the SD-card with your computer again you have to format your SD-Card.
(Create new partition table with a partition and create a filesystem on top of this partition)

Reading a filesystem should be a fairly easy task. My Librarys doesn't need to be changed,
but a unit must be built around it that reads the metadata of the the partitions and the filesystem
and utilize this metadata to access the right block which holds the information of the file.

If you wan't to have write access, you need to modify my unit and add write support.
(Tipp: You need to modify the unit 'sd_controller').


I put it here so that you can use it in your own projects, if you happen to need to read from an SD-card.
More information can be found in the source file.
Feel free to contact me for questions and let me know if you use it in your own project.

Kind regards
Simon
