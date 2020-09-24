<#
    .DESCRIPTION
        An example runbook which deploys basic metric alert rules using the Run As Account (Service Principal)
#>

$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName 
    Connect-AzAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint `
        -EnvironmentName AzureUSGovernment
 }
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

Function create-VMMonitorBasicAlerts {
    [cmdletbinding()]
    Param (
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$vm
    )
    $dependencyAgent = $false
    $logAAgent = $false
    $vmextensions = Get-AzVMExtension -VMName $vm.Name -ResourceGroupName $vm.ResourceGroupName
    if ($vmextensions | where { $_.ExtensionType.ToString() -contains "DependencyAgentWindows" }) {
        $dependencyAgent = $true
    }
    if ($vmextensions | where { $_.ExtensionType.ToString() -contains "MicrosoftMonitoringAgent" }) {
        $logAAgent = $true
    }
    
    if ($dependencyAgent -and $logAAgent) {
    
        $deploymentName = "Deploy_Baseline_Alert_" + $vm.Name
        $alertName = "High Sustained CPU Utilization Alert - " + $vm.Name
        $storContext = New-AzStorageContext -ConnectionString $armAlertTemplates
        Get-AzStorageBlobContent -Container "alertrules" -Blob "deployMetricAlert.json" -Context $storContext -Force
        Get-AzStorageBlobContent -Container "alertrules" -Blob "deployAlertRuleParameters.json" -Context $storContext -Force
        New-AzResourceGroupDeployment -Name $deploymentName -ResourceGroupName "aadMonitor"-TemplateFile .\deployMetricAlert.json -TemplateParameterFile .\deployAlertRuleParameters.json -alertName $alertName -resourceId $vm.Id
        $deploymentName = $null
    
    }
    else {
        write-host "Monitoring not enabled"
    }

    $dependencyAgent = $false
    $logAAgent = $false
    $vmextensions = $null
}

Function validate-VMBasicAlerts {
    [cmdletbinding()]
    Param (
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$vm
    )
    If (!($vmAlertRules | where { $_.TargetResourceID -eq $vm.Id })) {
        create-VMMonitorBasicAlerts -vm $vm
    }

}

$armAlertTemplates = Get-AutomationVariable -Name 'armAlertTemplates'
$vms = Get-AzVM
$vmAlertRules = Get-AzMetricAlertRuleV2
$vms | ForEach-Object { validate-VMBasicAlerts -vm $_ }
$vmAlertRules = $null
$vms = $null