#Destroy-NTNXVM.ps1
#   Copyright 2016 NetVoyage Corporation d/b/a NetDocuments.
param(
    [Parameter(mandatory=$true)][String]$VMName,
    [Parameter(mandatory=$false)][String]$ClusterName
)
#first check if the NutanixCmdletsPSSnapin is loaded, load it if its not, Stop script if it fails to load
if ( (Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue) -eq $null ) {Add-PsSnapin NutanixCmdletsPSSnapin -ErrorAction Stop}
$connection = Get-NutanixCluster
if(!$connection.IsConnected){
    #if not already connected to a cluster, prompt for inputs on the cluster/username/password to connect
    #if the ClusterName Parameter is passed, connect to that cluster, otherwise prompt for the clustername
    if($ClusterName){$NutanixCluster = $ClusterName}
    else{$NutanixCluster = (Read-Host "Nutanix Cluster")}
    $NutanixClusterUsername = (Read-Host "Username for $NutanixCluster")
    $NutanixClusterPassword = (Read-Host "Password for $NutanixCluster" -AsSecureString)
    $connection = Connect-NutanixCluster -server $NutanixCluster -username $NutanixClusterUsername -password $NutanixClusterPassword -AcceptInvalidSSLCerts
    if ($connection.IsConnected){
        #connection success
        Write-Host "Connected to $($connection.server)" -ForegroundColor Green
    }
    else{
        #connection failure, stop script
        Write-Warning "Failed to connect to $NutanixCluster"
        Break
    }
}
else{
    #make sure we're connected to the right cluster
    if($ClusterName -and ($ClusterName -ne $($connection.server))){
        #we're connected to the wrong cluster, reconnect to the right one
        Disconnect-NTNXCluster $connection.server
        $connection = Get-NutanixCluster
        $NutanixCluster = $ClusterName
        $NutanixClusterUsername = (Read-Host "Username for $NutanixCluster")
        $NutanixClusterPassword = (Read-Host "Password for $NutanixCluster" -AsSecureString)
        $connection = Connect-NutanixCluster -server $NutanixCluster -username $NutanixClusterUsername -password $NutanixClusterPassword -AcceptInvalidSSLCerts
        if ($connection.IsConnected){
            #connection success
            Write-Host "Connected to $($connection.server)" -ForegroundColor Green
        }
        else{
            #connection failure, stop script
            Write-Warning "Failed to connect to $NutanixCluster"
            Break
        }
    }
}
#connection to cluster is all set up, now move on to the fun stuff
#check to make sure VM exists on the cluster
$VM = (Get-NTNXVM -SearchString $VMName)
if ($VM.vmid){
    Write-Host "Removing $VMName from $($connection.server)"
    $removeVMJobID = Remove-NTNXVirtualMachine -vmid $VM.vmid
    #make sure the job to remove the VM got submitted
    if($removeVMJobID){Write-Host "Successfully removed $VMName from $($connection.server)" -ForegroundColor Green}
    else{
        Write-Warning "Failed to remove $VMName from $($connection.server), exiting"
        Break
    }
}
else{
      Write-Host "$VMName does not exist on $($connection.server), exiting"
}
