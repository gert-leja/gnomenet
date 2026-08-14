# gnomenet
Second edition of a Terraform constructed network and Ansible managed CML network.

## Project Goals
The goal of this project is to improve the configuration of the original "terraform-my-cml" project. Some key points to be added:
- Ansible should run with an interactive shell but non-login account so user input is not needed
- Terraform and Ansible should run on the same host device instead of 2 separate devices, in this case it will be an Ubuntu Server VM that will run the configuration files.