# Getting Trusted Boot working on EL7

X. Enable the TPM
X. Install trousers and start the tcsd daemon: `yum install -y trousers; systemctl start tcsd`
X. Own the TPM using the well-known SRK password (`tpm_takewnership -z`)
X. Make sure you're running the version of the kernel you will be trusting
X. Install `tboot`: `yum install -y tboot`
X. As root, download these scripts
X. Run `./create-lcp-tboot-policy.sh $tpm_owner_password` to create and install policy
X. Run `grub2-mkconfig -o /etc/grub2.cfg`
X. Manually edit `/etc/grub2.cfg`:
  1. Add ``--unrestricted` to the tboot entries
  2. Add `module /list.data` as the last thing in the grub entry
X. Reboot
X. ???
X. Trusted boot works

# Items to do

- [ ] Lock kernel version in yum
- [ ] Remove untrusted items from grub
- [ ] Make tboot only entry and default entry in grub
