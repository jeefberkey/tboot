# Getting Trusted Boot working on EL7

I sources the original versions of these scripts from https://github.com/yocum137/txt-oat/blob/master/scripts

Other sources include (in order of perceived helpfulness):
* https://software.intel.com/sites/default/files/managed/2f/7f/Config_Guide_for_Trusted_Compute_Pools_in_RHEL_OpenStack_Platform.pdf
* `tboot` docs, found at `/usr/share/doc/tboot-1.9.5/`
* https://wiki.gentoo.org/wiki/Trusted_Boot
* https://fedoraproject.org/wiki/Tboot

## Steps 

1. Enable the TPM
2. Install trousers and start the tcsd daemon: `yum install -y trousers; systemctl start tcsd`
3. Own the TPM using the well-known SRK password (`tpm_takewnership -z`)
4. Make sure you're running the version of the kernel you will be trusting
5. Install `tboot`: `yum install -y tboot`
6. Download the appropriate SINIT for your platform
  1. Extract
  2. Copy the `.BIN` file to `/boot`
7. Download these scripts
8. Run `./create-lcp-tboot-policy.sh $tpm_owner_password` to create and install policy
9. Run `grub2-mkconfig -o /etc/grub2.cfg`
10. Manually edit `/etc/grub2.cfg`:
  1. Add `--unrestricted` to the tboot entries
  2. Add `module /list.data` as the last thing in the grub entry
11. Reboot
12. ???
13. Trusted boot works

## Items to do

- [ ] Lock kernel version in yum
- [ ] Remove untrusted items from grub
- [ ] Make tboot only entry and default entry in grub
