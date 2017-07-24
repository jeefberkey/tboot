# Trusted Boot

## External Sources

The majority of policy generation was sourced from:
https://github.com/yocum137/txt-oat/blob/master/scripts

Other sources include (in order of perceived helpfulness):
* https://software.intel.com/sites/default/files/managed/2f/7f/Config_Guide_for_Trusted_Compute_Pools_in_RHEL_OpenStack_Platform.pdf
* `tboot` docs, found at `/usr/share/doc/tboot-1.9.5/`
* https://wiki.gentoo.org/wiki/Trusted_Boot
* https://fedoraproject.org/wiki/Tboot

## General procedure

1. Enable and take ownership of the TPM
2. Download and install SINIT
3. Determine kernel parameters for linux and tboot
    1. `intel_iommu=on` must be set for linux
    2. There may only ever be one space between kernel parameters
4. Create policy
    1. Policy must be regenerated every time there is a new kernel or the kernel parameters are changed
5. Create the `tboot` boot entry
6. Verify that the SINIT is the last module in the `tboot` boot entry
7. Reboot

## Preparation

1. Activate the TPM in the BIOS and set a BIOS password
2. Ensure VTd is enabled in the BIOS
3. Boot into the kernel you intend to trust
4. Install trousers, tpm-tools, tboot and start the tcsd daemon:
    `yum install -y trousers tpm-tools tboot; systemctl start tcsd`
5. Own the TPM using the well-known SRK password:
    `tpm_takeownership -z`
6. Download the appropriate SINIT for your platform:
    `https://software.intel.com/en-us/articles/intel-trusted-execution-technology`
    1. Extract
    2. Copy the `.BIN` file to `/boot`

## EL7

1. Populate `/etc/default/grub-tboot` like this, or with your preferred tboot kernel parameters:

```
GRUB_CMDLINE_TBOOT=logging=serial,memory,vga
GRUB_CMDLINE_LINUX_TBOOT=intel_iommu=on
GRUB_TBOOT_POLICY_DATA=list.data
```

2. Copy `20_linux_tboot` to `/etc/grub.d/20_linux_tboot`
3. Run `grub2-mkconfig -o /etc/grub2.cfg`
4. ~~Manually edit `/etc/grub2.cfg`:~~
    1. ~~Add `--unrestricted` to the tboot entries~~
    2. ~~Add `module /list.data` in the middle~~
4. Make sure the SINIT is the last module loaded in the GRUB configuration
5. Run `./create-lcp-tboot-policy_el7.sh $tpm_owner_password` to create and install policy
6. Reboot
7. Select tboot kernel module

### Excerpt from working env:

```
### BEGIN /etc/grub.d/20_linux_tboot ###
submenu "tboot 1.9.4" --unrestricted {
menuentry 'CentOS Linux GNU/Linux, with tboot 1.9.4 and Linux 3.10.0-514.el7.x86_64' --class centos --class gnu-linux --class gnu --class os --class tboot --unrestricted {
        insmod part_msdos
        insmod ext2
        set root='hd0,msdos1'
        if [ x$feature_platform_search_hint = xy ]; then
          search --no-floppy --fs-uuid --set=root --hint-bios=hd0,msdos1 --hint-efi=hd0,msdos1 --hint-baremetal=ahci0,msdos1 --hint='hd0,msdos1'  baeff891-11a5-403b-8592-463f73f5d8b3
        else
          search --no-floppy --fs-uuid --set=root baeff891-11a5-403b-8592-463f73f5d8b3
        fi
        echo    'Loading tboot 1.9.4 ...'
        multiboot       /tboot.gz logging=vga,serial,memory vga_delay=10 min_ram=0x2000000
        echo    'Loading Linux 3.10.0-514.el7.x86_64 ...'
        module /vmlinuz-3.10.0-514.el7.x86_64 root=/dev/mapper/VolGroup00-RootVol ro console=ttyS1,57600 console=tty1 crashkernel=auto rd.lvm.lv=VolGroup00/RootVol rd.lvm.lv=VolGroup00/SwapVol fips=1 rhgb quiet rd.shell=0 audit=1 boot=UUID=baeff891-11a5-403b-8592-463f73f5d8b3 intel_iommu=on
        echo    'Loading initial ramdisk ...'
        module /initramfs-3.10.0-514.el7.x86_64.img
        echo    'Loading list.data ...'
        module /list.data
        echo    'Loading sinit 2nd_gen_i5_i7_SINIT_51.BIN ...'
        module /2nd_gen_i5_i7_SINIT_51.BIN
}
}
### END /etc/grub.d/20_linux_tboot ###
```

## EL6

1. Create a tboot grub entry.
    1. The following entry is based off of vanilla centos 6.9
    2. Your kernel parameters may vary, and you can add/subtract as needed
    3. You MUST include intel_iommu=on
    4. There MUST NOT be more than one space between kernel parameter options
    5. The SINIT .BIN MUST be specified last in the list

```
title CentOS-tboot
        root (hd0,0)
        kernel /tboot.gz logging=vga,serial,memory vga_delay=10
        module /vmlinuz-2.6.32-696.el6.x86_64 ro root=/dev/mapper/vg_tpm04-lv_root rd_LVM_LV=vg_tpm04/lv_swap rd_NO_LUKS LANG=en_US.UTF-8 rd_NO_MD rd_LVM_LV=vg_tpm04/lv_root SYSFONT=latarcyrheb-sun16 crashkernel=auto KEYBOARDTYPE=pc KEYTABLE=us rd_NO_DM rhgb quiet intel_iommu=on
        module /initramfs-2.6.32-696.el6.x86_64.img
        module /list.data
        module /2nd_gen_i5_i7_SINIT_51.BIN
```

2. Run `./create-lcp-tboot-policy_el6.sh $tpm_owner_password` to create and install policy
3. Reboot
4. Select tboot kernel module

## Resetting The TPM

1. While the TPM is activated, run `./clear.sh $tpm_owner_password` to release the control registers
2. Clear the TPM with the `tpm clear` command, or clear in the BIOS
3. Re-activate the TPM in the BIOS
4. Reboot
5. Ensure `tcsd` is running
6. `tpm_takeownership -z`

## Status

Strategy | Status | Notes
-------- | ------ | -----
combined | working? | this script
oat      | incomplete | |
tboot docs | fail | |
fedora wiki | fail | this one used a custom policy, which I don't understand |
gentoo wiki | fail | this one ignores the kernel in the measurement, which defeats the purpose |

In EL6 and EL7, the tboot console log is throwing an error (can be checked with `parse_err` from the `tboot` package):
    `AC module error : acm_type=0x1, progress=0x10, error=0x2`

That error is translated to `MLE measurement is not in policy`, with the following doc:
    `https://gist.github.com/jeefberkey/f62fa202cebfee99083886ad3d338fc4#file-docs-txt-L228`

Also, the policy it generates is supposed to be failsafe, meaning if tboot were to fail, the boot would continue anyway. However, the host always reboots after tboot fails.

## Items to do

- [ ] Lock kernel and tboot version in yum
- [ ] Remove untrusted items from grub
- [ ] Make tboot only entry and default entry in grub
