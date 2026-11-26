# a02-e04-idle-resource-cost

## Still bills compute
A VM in **Stopped** (not deallocated) still bills compute, plus disk and public IP. Only **Stopped (deallocated)** (`az vm deallocate`) stops the compute meter.

## Disks and IPs
Deallocated or deleted, the managed OS disk still bills by size until the disk resource is gone. A Standard public IP bills hourly (~$0.005/hr) until the IP resource is deleted. Deleting the VM often *detaches* those resources (`deleteOption` default Detach) instead of deleting them.

## What lab-down does
`lab-down` deletes the lab resource group (`az group delete`). That removes the VM, disk, NIC, and public IP together. Leaving the group up overnight is what creates the surprise bill; Advisor may mention the waste later, not immediately.
