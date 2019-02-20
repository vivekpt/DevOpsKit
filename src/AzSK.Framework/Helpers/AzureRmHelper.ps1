class AzureRmHelper
{
static [void] UploadStorageBlobContent([string] $fileName, [string] $blobName, [string] $containerName, [object] $stgCtx)
	{
        if([FeatureFlightingManager]::GetFeatureStatus("IsSetAzStorageBlobAvailable","*") -eq $true)
        {
            Set-AzStorageBlobContent -Blob $blobName -Container $containerName -File $fileName -Context $stgCtx -Force | Out-Null
        }
        else {
            $blob = $stgCtx.StorageAccount.CreateCloudBlobClient().GetContainerReference($containerName).GetBlockBlobReference($blobName)
            $task = $blob.UploadFromFileAsync($fileName)
            $task.Wait()
            if (-not ($task.IsCompleted -and !$task.IsFaulted))
            {
				#Need to change write method
				Write-Debug "Transferring file" + $fileName + "to storage has failed!!"
            }
        }
    }

    static [object] GetStorageBlobContent([string] $folderName, [string] $fileName, [string] $blobName, [string] $containerName, [object] $stgCtx)
	{
             $fileName = $folderName +"\" + $fileName
             return GetStorageBlobContent($fileName, $blobName, $containerName, $stgCtx)
    }


    static [object] GetStorageBlobContent([string] $fileName, [string] $blobName, [string] $containerName, [object] $stgCtx)
	{
        if([FeatureFlightingManager]::GetFeatureStatus("IsSetAzStorageBlobAvailable","*") -eq $true)
        {
            $result = Get-AzStorageBlobContent -Blob $blobName -Container $containerName -Destination $fileName -Context $stgCtx -Force | Out-Null
        }
        else {
            $blob = Get-AzStorageBlob -Container $containerName -Blob $blobName -Context $stgCtx
            $blob.ICloudBlob.DownloadToFileAsync($fileName,[System.IO.FileMode]::Create).Wait()
            if (-not ($task.IsCompleted -and !$task.IsFaulted))
            {
				#Need to change write method
				Write-Debug "Downloading file from" + $blobName + " has failed!!"
            }
            $result = $blob 
        }
        return $result
    }
}