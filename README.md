# gnomenet
Second edition of a Terraform constructed network and Ansible managed CML network.

## Project Goals
The main goal of this project is to create an automation script that creates 2 separate CML labs on 2 separate CML hosts, then interconnecting those labs so that both labs can be reached from one another. The automation script will also apply a full configuration to all devices, thus creating a fully functional network in an instant.

## Additionals

known_hosts file on the VM currently needs to be cleared manually if the user is manually ssh'ing into devices, every apply will generate new ssh keys for the routers, use this line of code:

```
ssh-keygen -f '/home/gnome/.ssh/known_hosts' -R '192.168.1.10'
```