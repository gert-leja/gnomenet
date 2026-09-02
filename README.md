# gnomenet
Second edition of a Terraform constructed network and Ansible managed CML network.

## Project Goals
The main goal of this project is to create an automation script that creates 2 separate CML labs on 2 separate CML hosts, then interconnecting those labs so that both labs can be reached from one another. The automation script will also apply a full configuration to all devices, thus creating a fully functional network in an instant.

## Adding CML credentials
In order to keep the environment secure, no credentials should be published to the repo. Previously this was done because of how I had set up the environment on my side, but I have changed how credentials are stored now to replicate a more realistic production environment.

To do this, the credentials are now treated as environmental variables.

These values should be set **before** running **terraform plan / apply**, and can be done like this

**Update:** Pay attention to the _1 and _2 lines at the end, these represent individual CML instances, now that the code has been restructured to be modular, these exports are needed for each CML instance.
```
export TF_VAR_cml_address_1="https://192.168.1.1" # example URL
export TF_VAR_cml_username_1="USERNAME"
export TF_VAR_cml_password_1="PASSWORD"
export TF_VAR_cml_address_2="https://192.168.1.2" # example URL
export TF_VAR_cml_username_2="USERNAME"
export TF_VAR_cml_password_2="PASSWORD"
```

These exports only last for the current shell session, meaning these need to be re-exported every time.

Alternatively these can be put into a local script that's sourced before running Terraform, but this hasn't been explored for this project yet.

If you are running this locally, you can also create a **terraform.tfvars** file in the same folder as your other terraform files, where you can add the same variables and Terraform will automatically apply the .tfvars file whenever you use Terraform.

## Additionals

known_hosts file on the VM currently needs to be cleared manually if the user is manually ssh'ing into devices, every apply will generate new ssh keys for the routers, use this line of code:

```
ssh-keygen -f '~/.ssh/known_hosts' -R '192.168.1.10' # example address
```
