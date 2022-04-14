##############################
##### Create a Scale Set #####
##############################  
#The following example defines variables for the scale set named myScaleSet in the resource group
# named myResourceGroup and in the East US region. 
#Your subscription ID is obtained with Get-AzureRmSubscription. 
#If you have multiple subscriptions associated with your account, 
#only the first subscription is returned. Adjust the names and subscription ID as follows:

$mySubscriptionId = (Get-AzureRmSubscription)[0].Id
$myResourceGroup = "myResourceGroup"
$myScaleSet = "myScaleSet"
$myLocation = "East US"

#Now create a virtual machine scale set with New-AzureRmVmss.
#To distribute traffic to the individual VM instances, a load balancer is also created.
#The load balancer includes rules to distribute traffic on TCP port 80, 
#as well as allow remote desktop traffic on TCP port 3389 and PowerShell remoting on TCP port 5985. 
#When prompted, provide your own desired administrative credentials for the VM instances in the scale set:

New-AzureRmVmss `
  -ResourceGroupName $myResourceGroup `
  -VMScaleSetName $myScaleSet `
  -Location $myLocation `
  -VirtualNetworkName "myVnet" `
  -SubnetName "mySubnet" `
  -PublicIpAddressName "myPublicIPAddress" `
  -LoadBalancerName "myLoadBalancer"

##########################################
##### Create a rule to autoscale out #####
##########################################
#The following parameters are used for this rule:
## PARAMETERS ------------- EXPLANATION ---------------------- VALUE ##
# -MetricName              Monitor and apply scale              Percentage CPU
# -TimeGrain               Collection of metrics                1 minute 
# -MetricStatistic         Collection Aggrigation               Average 
# -TimeWindow              Time monitored before Compaired      5 minutes 
# -Operator                Operator used to compare             Greater Than 
# -Threshold               Cause of Trigger                     70%
# -ScaleActionDirection    Scale UP or DOWN                     Increase
# -ScaleActionScaleType    Number of VMs to Change              Change Count 
# -ScaleActionValue        % of VMs to Changed by rule          3
# -ScaleActionCoolDown     Time between scaling actions         5 Minutes
#
#The following example creates an object named myRuleScaleOut that holds this scale up rule.
# The -MetricResourceId uses the variables previously defined for the subscription ID,
#
$myRuleScaleOut = New-AzureRmAutoscaleRule `
  -MetricName "Percentage CPU" `
  -MetricResourceId /subscriptions/$mySubscriptionId/resourceGroups/$myResourceGroup/providers/Microsoft.Compute/virtualMachineScaleSets/$myScaleSet `
  -TimeGrain 00:01:00 `
  -MetricStatistic "Average" `
  -TimeWindow 00:05:00 `
  -Operator "GreaterThan" `
  -Threshold 70 `
  -ScaleActionDirection "Increase" `
  -ScaleActionScaleType "ChangeCount" `
  -ScaleActionValue 3 `
  -ScaleActionCooldown 00:05:00

#########################################
##### Create a Rule to AutoScale in #####
#########################################
#On an evening or weekend, your application demand may decrease.
#If this decreased load is consistent over a period of time, you can configure autoscale
#rules to decrease the number of VM instances in the scale set.
#This scale-in action reduces the cost to run your scale set as you only run the number 
#of instances required to meet the current demand.
#Create another rule with New-AzureRmAutoscaleRule that decreases the number of VM instances
#in a scale set when the average CPU load then drops below 30% over a 5-minute period.
#When the rule triggers, the number of VM instances is decreased by one.
#The following example creates an object named myRuleScaleDown that holds this scale down rule.
#The -MetricResourceId uses the variables previously defined for the subscription ID,
#resource group name, and scale set name:

$myRuleScaleIn = New-AzureRmAutoscaleRule `
  -MetricName "Percentage CPU" `
  -MetricResourceId /subscriptions/$mySubscriptionId/resourceGroups/$myResourceGroup/providers/Microsoft.Compute/virtualMachineScaleSets/$myScaleSet `
  -Operator "LessThan" `
  -MetricStatistic "Average" `
  -Threshold 30 `
  -TimeGrain 00:01:00 `
  -TimeWindow 00:05:00 `
  -ScaleActionCooldown 00:05:00 `
  -ScaleActionDirection "Decrease" `
  -ScaleActionScaleType "ChangeCount" `
  -ScaleActionValue 1

################################################
#####Apply autoscale profile to a scale set#####
################################################
#Apply the autoscale profile to your scale set. 
#Your scale set is then able to automatically scale in or out based on the application demand.
#Apply the autoscale profile with Add-AzureRmAutoscaleSetting as follows:

Add-AzureRmAutoscaleSetting `
  -Location $myLocation `
  -Name "autosetting" `
  -ResourceGroup $myResourceGroup `
  -TargetResourceId /subscriptions/$mySubscriptionId/resourceGroups/$myResourceGroup/providers/Microsoft.Compute/virtualMachineScaleSets/$myScaleSet `
  -AutoscaleProfile $myScaleProfile
