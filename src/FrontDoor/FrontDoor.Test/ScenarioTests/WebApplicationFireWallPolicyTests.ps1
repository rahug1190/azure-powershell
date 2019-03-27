﻿# ----------------------------------------------------------------------------------
#
# Copyright Microsoft Corporation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------------

<#
.SYNOPSIS
Full WAF policy CRUD cycle
#>
function Test-PolicyCrud
{
    $Name = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
    $resourceGroupName = $resourceGroup.ResourceGroupName
    $tags = @{"tag1" = "value1"; "tag2" = "value2"}
    $matchCondition1 = New-AzFrontDoorMatchConditionObject -MatchVariable RequestHeader -OperatorProperty Contains -Selector "UserAgent" -MatchValue "Windows"
    $customRule1 = New-AzFrontDoorCustomRuleObject -Name "Rule1" -RuleType MatchRule -MatchCondition $matchCondition1 -Action Block -Priority 2

    $ruleOverride = New-AzFrontDoorManagedRuleOverrideObject -RuleId "942100" -Action Log -EnabledState Enabled
    $override1 = New-AzFrontDoorRuleGroupOverrideObject -RuleGroupName SQLI -ManagedRuleOverride $ruleOverride
    $managedRule1 = New-AzFrontDoorManagedRuleObject -Type DefaultRuleSet -Version "preview-0.1" -RuleGroupOverride $override1

    New-AzFrontDoorFireWallPolicy -Name $Name -ResourceGroupName $resourceGroupName -Customrule $customRule1 -ManagedRule $managedRule1 -EnabledState Enabled -Mode Prevention
	
    $retrievedPolicy = Get-AzFrontDoorFireWallPolicy -Name $Name -ResourceGroupName $resourceGroupName 
    Assert-NotNull $retrievedPolicy
    Assert-AreEqual $Name $retrievedPolicy.Name
    Assert-AreEqual $customRule1.Name $retrievedPolicy.CustomRules[0].Name
    Assert-AreEqual $customRule1.RuleType $retrievedPolicy.CustomRules[0].RuleType
    Assert-AreEqual $customRule1.Action $retrievedPolicy.CustomRules[0].Action
    Assert-AreEqual $customRule1.Priority $retrievedPolicy.CustomRules[0].Priority
    Assert-AreEqual $managedRule1.RuleGroupOverrides[0].ManagedRuleOverrides[0].Action $retrievedPolicy.ManagedRules[0].RuleGroupOverrides[0].ManagedRuleOverrides[0].Action

    $customRule2 = New-AzFrontDoorCustomRuleObject -Name "Rule2" -RuleType MatchRule -MatchCondition $matchCondition1 -Action Log -Priority 2
    $updatedPolicy = Set-AzFrontDoorFireWallPolicy -Name $Name -ResourceGroupName $resourceGroupName -Customrule $customRule2
    Assert-NotNull $updatedPolicy
    Assert-AreEqual $Name $updatedPolicy.Name
    Assert-AreEqual $customRule2.Name $updatedPolicy.CustomRules[0].Name
    Assert-AreEqual $customRule2.Action $updatedPolicy.CustomRules[0].Action
    Assert-AreEqual $customRule2.Priority $updatedPolicy.CustomRules[0].Priority
    Assert-AreEqual $managedRule1.RuleGroupOverrides[0].ManagedRuleOverrides[0].Action $updatedPolicy.ManagedRules[0].RuleGroupOverrides[0].ManagedRuleOverrides[0].Action

    $removed = Remove-AzFrontDoorFireWallPolicy -Name $Name -ResourceGroupName $resourceGroupName -PassThru
    Assert-True { $removed }
    Assert-ThrowsContains { Get-AzFrontDoorFireWallPolicy -Name $Name -ResourceGroupName $resourceGroupName } "does not exist."
}

<#
.SYNOPSIS
WAF policy cycle with piping
#>
function Test-PolicyCrudWithPiping
{
    $Name = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
    $resourceGroupName = $resourceGroup.ResourceGroupName
    $tag = @{"tag1" = "value1"; "tag2" = "value2"}
    $matchCondition1 = New-AzFrontDoorMatchConditionObject -MatchVariable RequestHeader -OperatorProperty Contains -Selector "UserAgent" -MatchValue "Windows"
    $customRule1 = New-AzFrontDoorCustomRuleObject -Name "Rule1" -RuleType MatchRule -MatchCondition $matchCondition1 -Action Block -Priority 2

    $ruleOverride = New-AzFrontDoorManagedRuleOverrideObject -RuleId "942100" -Action Log -EnabledState Enabled
    $override1 = New-AzFrontDoorRuleGroupOverrideObject -RuleGroupName SQLI -ManagedRuleOverride $ruleOverride
    $managedRule1 = New-AzFrontDoorManagedRuleObject -Type DefaultRuleSet -Version "preview-0.1" -RuleGroupOverride $override1

    New-AzFrontDoorFireWallPolicy -Name $Name -ResourceGroupName $resourceGroupName -Customrule $customRule1 -ManagedRule $managedRule1 -EnabledState Enabled -Mode Prevention

    $customRule2 = New-AzFrontDoorCustomRuleObject -Name "Rule2" -RuleType MatchRule -MatchCondition $matchCondition1 -Action Log -Priority 2
    $updatedPolicy = Get-AzFrontDoorFireWallPolicy -Name $Name -ResourceGroupName $resourceGroupName | Set-AzFrontDoorFireWallPolicy -Customrule $customRule2
    Assert-NotNull $updatedPolicy
    Assert-AreEqual $Name $updatedPolicy.Name
    Assert-AreEqual $customRule2.Name $updatedPolicy.CustomRules[0].Name
    Assert-AreEqual $customRule2.Action $updatedPolicy.CustomRules[0].Action
    Assert-AreEqual $customRule2.Priority $updatedPolicy.CustomRules[0].Priority
    Assert-AreEqual $managedRule1.RuleGroupOverrides[0].ManagedRuleOverrides[0].Action $updatedPolicy.ManagedRules[0].RuleGroupOverrides[0].ManagedRuleOverrides[0].Action

    $removed = Get-AzFrontDoorFireWallPolicy -Name $Name -ResourceGroupName $resourceGroupName | Remove-AzFrontDoorFireWallPolicy -PassThru
    Assert-True { $removed }
    Assert-ThrowsContains { Get-AzFrontDoorFireWallPolicy -Name $Name -ResourceGroupName $resourceGroupName } "does not exist."
}