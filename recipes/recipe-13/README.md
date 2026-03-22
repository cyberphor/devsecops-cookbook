## Recipe 13: OpenStack

**Hardware**  
* Dell PowerEdge R610
  * Boot Mode: BIOS
  * BIOS Version 6.6.0
  * iDRAC6 2.85.04
  * Proxmox Virtual Environment (VE) 8.2
* Compute: 2 x Intel Xeon CPUs (E5645 @2.40 GHZ)
* Memory: 112 GBs
* Virtual Disk 0 (Hypervisor OS): 1 x SSD (RAID 0)
* Virtual Disk 1 (Images): 1 x SSD (RAID 0)
* Virtual Disk 2 (Virtual Machines): 4 x HDD (RAID 0)
* Management NIC: 
* Service NICs: 

**Networking**  
* Server Management Console: 192.168.2.2./24
* Server: 192.168.2.3/24

## Task 01
**Step 1.** Update the server's Basic Input/Output System (BIOS). 

**Step 2.** Boot to BIOS Configuration Utility. 

**Step 3.** Create and initialize Virtual Disk 0. This will be the virtual disk the server boots from.

**Step 4.** Create and initialize Virtual Disk 1.

**Step 4.** Create and initialize Virtual Disk 2.