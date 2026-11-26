# a02-e03-missing-forecast-alerts

## What was wrong
The budget had only Actual 50/80/100 notifications. Forecasted 80 and 100 were missing.

## Mechanism
Actual notifications fire on spend so far. Forecasted notifications fire on Azure's predicted end-of-period spend. Without Forecasted alerts, a mid-month runaway can hit 100% Actual before you see mail. The lab-up gate does not check notifications; this exercise does.

## Which tool showed it
The Pester test `has Forecasted notifications at 80 and 100`.
