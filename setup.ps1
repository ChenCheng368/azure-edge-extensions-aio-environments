Param(
    [string]
    [Parameter(mandatory=$true)]
    $ForkedRepo,

    [string]
    [Parameter(mandatory=$true)]
    $SubscriptionId,

    [string]
    [Parameter(mandatory=$true)]
    $ServicePrincipalName,

    [string]
    [Parameter(mandatory=$true)]
    $HciAksGroupName,

    [string]
    [Parameter(mandatory=$true)]
    $VmAdminUsername,

    [securestring]
    [Parameter(mandatory=$true)]
    $VmAdminPassword
)

# Create Service Principal
$azureCredentials = az ad sp create-for-rbac --name $ServicePrincipalName --role owner `
                                --scopes /subscriptions/$SubscriptionId `
                                --json-auth | ConvertFrom-Json

# Assign Grafana Admin Role to Service Principal
az role assignment create --assignee $azureCredentials.clientId --role "Grafana Admin" --scope /subscriptions/$SubscriptionId

# Get Service Principal Object Id
$spObjectId = az ad sp show --id $azureCredentials.clientId --query id -o tsv

# Get AzureStackHCI SP Object Id
$hciRpSpObjectId = az ad sp list --display-name "Microsoft.AzureStackHCI Resource Provider" | jq -r '.[0].id'

# Get Custom Location SP Object Id
$customLocationsObjectId = az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv

# Create Entra Id group for Azure Stack HCI AKS Workload Cluster
$hciboxGroupObjectId = az ad group create --display-name HciAksGroupName --mail-nickname HciAksGroupName --query id -o tsv

gh secret set AZURE_SUBSCRIPTION_ID -b $azureCredentials.subscriptionId -R $ForkedRepo
gh secret set AZURE_TENANT_ID -b $azureCredentials.tenantId -R $ForkedRepo
gh secret set AZURE_SP_CLIENT_ID -b $azureCredentials.clientId -R $ForkedRepo
gh secret set AZURE_SP_CLIENT_SECRET -b $azureCredentials.clientSecret -R $ForkedRepo
gh secret set AZURE_SP_OBJECT_ID -b $spObjectId -R $ForkedRepo
gh secret set AZURE_STACK_HCI_OBJECT_ID -b $hciRpSpObjectId -R $ForkedRepo
gh secret set CUSTOM_LOCATIONS_OBJECT_ID -b $customLocationsObjectId -R $ForkedRepo
gh secret set HCI_AKS_GROUP_OBJECT_ID -b $hciboxGroupObjectId -R $ForkedRepo
gh secret set VMADMINUSERNAME -b $VmAdminUsername -R $ForkedRepo
gh secret set VMADMINPASSWORD -b ($VmAdminPassword | ConvertFrom-SecureString -AsPlainText) -R $ForkedRepo

