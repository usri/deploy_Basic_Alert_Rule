# Automate Deployment of Metric Alert Rules to VM's, Sample

## Details

This repository provides the necessary sample files for deploying version 2 metric alert rules to virtual machines deployed within your Azure environment.  It functions using an automation account that runs on a set scheduled.  Once implmented, the workflow functions in the following fashion:

1. Runbook, "deployBasicAlertRule.ps1" is executed according to the schedule linked to the runbook within the Azure Automation Account.
2. DeployBasicAlertRule.ps1 checks all VM's within the subscription and gathers all currently deployed v2 metric rules and applies logic as defined in steps 3 & 4.
3. If a VM is enabled for Azure Monitoring for VM's AND the number of Metric Alert Rules applied to the VM is 0, THEN goto 4, else do nothing.
4. Download 'deployMetricAlert.json' & 'deployAlertRuleParameters.json', perform deployment of Metric Alert rule to current VM.

## Build Steps

After following the instructions below, all VM's within the subscription will be enabled for monitoring by Azure Monitor for VM's, and any new VM's which are deployed will be automatically enabled for Monitoring.  All VM's will recieve a single metric alert rule if they do not have anything already configured.  This architecture can be used for multi-rule deployment as needed.

For deployment to be successful, please ensure the following pre-requisites:

* Log Analytics Workspace has been created. The Log Analytics workspace is where the monitored data from VM's will reside.
* Azure Storage Account has been created.  The storage account is where the deployment json files will reside and is the endpoint that will be targted for downloading of files.  Please remember to update the script to use this storage account.
* Action Groups have been created.  Alert groups define the action to take when an alert rule is triggered.  For example an Action Group might send an SMS message, send an email, or trigger another runbook to take action.  Please remember to call the appropriate action group, see sample in the parameters file (param: actionGroupID)
* Assign Azure Policy Initative "Azure monitor for VM's" to subscription (or management group, resource group)
  * Create remediation tasks for pre-existing infrastructure to deploy the Log Analytics Agent & Dependency Agent for all VM's.
* Deploy Automation Account with RunAs account capabilities

## Update Automation Account Details

1. Import required Azure modules into automation account from Modules Gallery:  Az.Accounts, Az.Resources, Az.Network, Az.Compute, Az.Storage, Az.Automation, Az.Monitor
2. Create encrypted variable named "armAlertTemplates" within automation account with the connection string value of the storage account which will store the deployment json files.
3. Import deployBasicAllertRule.ps1 into Automation Account.  If you used a different variable name in step 2, plesae update the runbook to call the correct name.
4. After testing the run book, publish it, and link to appropratie schedule.

At this point, the runbook should execute according to the set schedule and update all VM's(using the logic mentioned above) with a single "High CPU Percentage" rule that will take the action defined in your Action Group.

## ToDo

Some ideas on how to further improve this solution, currently it is scoped to provide understanding and a sample

* Instead of using a set schedule for runbook execution, set up automatic execution of runbook as needed using Active Log events associated with enabling Azure Monitor for VM's.
* Utilize a zipped archive of basic alert rules which can then be downloaded and applied recurseivly to all VM's.
* Add logic which will prevent the re-downloading of deployment files if the data is already present and has not been modified.

## NOTICE/WARNING

* This solution is explicitly designed for a lab/classroom environment and is intended to offer a way to move forward by allowing the code to be imported and made your own, fully compliant with the organizations security controls which you represent.

## Contributing

This project welcomes contributions and suggestions.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) with any additional questions or comments.
