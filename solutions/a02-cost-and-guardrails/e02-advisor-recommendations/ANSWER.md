# a02-e02-advisor-recommendations

## High cost
One High Cost recommendation: `rec-unattached-disk` on `lagb-disk-leftover` (unattached disk). The Low Cost SKU recommendation is not High.

## What you would do
Run `lab-down` on the lab that left the disk, which deletes the resource group and the disk. Deleting the VM alone often leaves the disk. Advisor is not real-time; the recommendation can appear hours later.

## Why Advisor is not a budget
Advisor inspects existing resources and suggests waste or misconfiguration. A budget watches spend against a monthly amount and emails you at thresholds. Advisor does not email at 50% of $25; the budget does not tell you an unattached disk exists.
