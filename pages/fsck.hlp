 FSCK - File System Check
Usage: fsck           - scan current disk and report errors
       fsck -f        - scan current disk and fix any errors

Fsck is a filesystem check tool for Elf/OS V5.  Note, this is for V5 disks only, this tool expects the directory structure of V5, V4 and before directories are not compatible with this tool.

   Important note, this tool is still developmental, I have tried it now on three different LAT-32 disk images, one with errors, one without, and one where I purposely introduced errors, the tool worked as expected and did not destroy anything.  But since this is still a developmental tool, I would recommend backing up your disk image before trying this.  This should work on V5 LAT-16 disks, but I have not yet tried it on a LAT-16 disk.

  Running fsck without a command line switch scans the disk only and does not apply any fixes, adding -f as a switch will allow fsck to correct any errors that it can.  This tool should be able to scan any disk size, but be aware on larger disks the LAT scan can take quite a bit of time.

  Here is what this tool scans for:

    New style boot sector check value.  Corrective action for this is to write the correct value if it is wrong
    Check V5MdPtr in sector 0.  Chances are if this is wrong your disk will not boot right anyways.  Corrective action is to set this field if it is wrong
    Every file in the filesystem will have its lump chain checked, if any lump in the chain is invalid it will be flagged.  Corrective action is to write the EOF code of 0000FEFE into the invalid lump.
    Every file in the filesystem is checked for invalid characters in its name.  Corrective action is to replace invalid characters with an underscore.
    A scan of all LAT entries is performed.  Any LAT entries that are cross-linked will be flagged.  There is no corrective action for cross-linked lumps, as it is not possible for the tool to decide on which file really owns the lump.
    A scan of all LAT entries is performed looking for orphaned lumps, which will be flagged.  Corrective action on orphaned lumps is to set their value to 0000 0000 which makes them again available for allocation.

  I plan on writing a second tool that can be used for cross-linked lumps to find out which files are sharing a cross-linked lump, this at the least will make it easier to fix the cross-linked lump using sedit, but I may try to build into the tool the ability to separate the chains that are sharing a lump.

  Final warning, again this is early developmental software, so backup your disks before allowing fsck to write changes back to your disk.