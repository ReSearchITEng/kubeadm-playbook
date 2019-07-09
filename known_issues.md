## Bugs/Limitations of this project
Solved & low importance:
- helm reset: helm command not found even when it's there
- drain -> does not work only against desired nodes, but it should!!!
- dashboard via helmchart is ideal for versions 1.7+. So for 1.6 some items like CronJobs (and Overview) will not work.


## Virtualbox bugs (for those using vagrant solution):
- Issue: After some times it shows on console:
  		 "kernel:NMI watchdog: BUG: soft lockup - CPU#0 stuck for 22s! kworker"
  		 and the vm is no longer responding. It happens on master.
  Solution: 
    a) The project already implemented the code to change hdd controller from IDE to SATA.
  Status: SOLVED


- Issue: at boot time, it says:
  "kernel: piix4_smbus 0000:00:07.0: SMBus base address uninitialized - upgrade BIOS or use force_addr=0xaddr"
  
  Tried: 
  -	vi /etc/default/grub #in the GRUB_CMDLINE_LINUX line, at the end, add:    pci=noacpi acpi=off noapic  
	#and run: 
	grub2-mkconfig -o /boot/grub2/grub.cfg

	But did not work.

  - change motherboard chipset frp, piix3 to some other version
    But did not work.

  - echo -e "\nblacklist i2c_piix4\n" >> /etc/modprobe.d/blacklist.conf  
	#echo -e "\nintel_powerclamp\n" >> /etc/modprobe.d/blacklist.conf  # did not try
	and reboot
	But did not help either (actually block machine login via ssh). Maybe try to put blacklist i2c_piix4 also in /etc/dracut.conf.d/nofloppy.conf's omit_drivers list.

