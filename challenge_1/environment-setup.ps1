$Name = 'SoS-challenge1'
$Location = 'West Europe'
$TemplateFile = '.\template.json'

if (Get-AzResourceGroup "$Name-RG" -ErrorAction SilentlyContinue) {
    write-error "RG exists. Change name or.. do something else."
} else { 
    $RGSplat = @{
        'Name' = "$Name-RG"
        'Location' = $Location
    }
    $RG = New-AzResourceGroup @RGSplat

    $TemplateParams = @{
        'subscriptionId' = (Get-AzSubscription).id
        'location' = $RG.Location
        'serverFarmResourceGroup' = $RG.ResourceGroupName
        'Name' = $Name
        'storageAccountName' = "${Name}sa".ToLower() -replace '[^a-zA-Z]',''
    }

    $TemplateSplat = @{
        'Name' = "$Name-template"
        'ResourceGroupName' = $RG.ResourceGroupName
        'TemplateFile' = $TemplateFile
        'TemplateParameterObject' = $TemplateParams 
        'Verbose' = $true
    }

    New-AzResourceGroupDeployment @TemplateSplat
}