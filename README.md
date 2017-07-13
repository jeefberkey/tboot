# Getting Trusted Boot working on EL7

1. Enable the TPM
2. Install trousers and start the tcsd daemon: `yum install -y trousers; systemctl start tcsd`
3. Own the TPM using the well-known SRK password (`tpm_takewnership -z`)
4. Make sure you're running the version of the kernel you will be trusting
5. Install `tboot`: `yum install -y tboot`
6. As root, download these scripts
7. Run `./create-lcp-tboot-policy.sh $tpm_owner_password` to create and install policy
8. Run `grub2-mkconfig -o /etc/grub2.cfg`
9. Manually edit `/etc/grub2.cfg`:
  1. Add `--unrestricted` to the tboot entries
  2. Add `module /list.data` as the last thing in the grub entry
10. Reboot
11. ???
12. Trusted boot works

# Items to do

- [ ] Lock kernel version in yum
- [ ] Remove untrusted items from grub
- [ ] Make tboot only entry and default entry in grub
