# Getting Trusted Boot working on EL7

I sourced the original versions of these scripts from https://github.com/yocum137/txt-oat/blob/master/scripts

Other sources include (in order of perceived helpfulness):
* https://software.intel.com/sites/default/files/managed/2f/7f/Config_Guide_for_Trusted_Compute_Pools_in_RHEL_OpenStack_Platform.pdf
* `tboot` docs, found at `/usr/share/doc/tboot-1.9.5/`
* https://wiki.gentoo.org/wiki/Trusted_Boot
* https://fedoraproject.org/wiki/Tboot

## Steps for the OAT process

1. Enable the TPM and set up a bios password
2. Install trousers and start the tcsd daemon: `yum install -y trousers; systemctl start tcsd`
3. Own the TPM using the well-known SRK password (`tpm_takeownership -z`)
4. Make sure you're running the version of the kernel you will be trusting
5. Install `tboot`: `yum install -y tboot`
6. Download the appropriate SINIT for your platform https://software.intel.com/en-us/articles/intel-trusted-execution-technology
    1. Extract
    2. Copy the `.BIN` file to `/boot`
7. Download these scripts
7. Copy our `20_linux_tboot` to `/etc/grub.d/20_linux_tboot`
8. Run `./create-lcp-tboot-policy.sh $tpm_owner_password` to create and install policy
9. Populate `/etc/default/grub-tboot` like this:

```
GRUB_CMDLINE_TBOOT=logging=serial,memory,vga
GRUB_CMDLINE_LINUX_TBOOT=intel_iommu=on
GRUB_TBOOT_POLICY_DATA=list.data
```

10. Run `grub2-mkconfig -o /etc/grub2.cfg`
11. ~~Manually edit `/etc/grub2.cfg`:~~
    1. ~~Add `--unrestricted` to the tboot entries~~
    2. ~~Add `module /list.data` in the middle~~
    3. ~~Make sure the SINIT is the last module loaded in the GRUB configuration~~
11. Reboot
12. ???
13. Trusted boot works

### except from working env:
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

## Status

Strategy | Status | Notes
-------- | ------ | -----
combined | fail   | this script
oat      | incomplete | |
tboot docs | fail | |
fedora wiki | fail | this one used a custom policy, which I don't understand |
gentoo wiki | fail | this one ignores the kernel in the measurement, which defeats the purpose |

As far as I can tell, the tboot console log is telling me I don't have a MLE policy loaded, but the script provided here explicitly loads one. The error code is available here, along with the lookup table: https://gist.github.com/jeefberkey/f62fa202cebfee99083886ad3d338fc4#file-docs-txt-L228
Also, the policy it generates is supposed to be failsafe, meaning if tboot were to fail, the boot would continue anyway. However, the host always reboots after tboot fails.

## Items to do

- [ ] Lock kernel version in yum
- [ ] Remove untrusted items from grub
- [ ] Make tboot only entry and default entry in grub
