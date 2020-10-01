Set-StrictMode -Version Latest 
class LoadBalancer: AzSVTBase
{       
    hidden [PSObject] $ResourceObject;

    LoadBalancer([string] $subscriptionId, [SVTResource] $svtResource): 
        Base($subscriptionId, $svtResource) 
    { 
		$this.GetResourceObject();
	}
	[ControlItem[]] ApplyServiceFilters([ControlItem[]] $controls)
	{
		$result = $controls;
		# Applying filter to exclude certain controls based on Tag Key-Value 
		if([Helpers]::CheckMember($this.ControlSettings.LoadBalancer, "ControlExclusionsByService") -and [Helpers]::CheckMember($this.ResourceObject, "Tag")){
			$this.ControlSettings.LoadBalancer.ControlExclusionsByService | ForEach-Object {
				if($this.ResourceObject.Tag[$_.ResourceTag] -like $_.ResourceTagValue){
					$controlTag = $_.ControlTag
					$result=$result | Where-Object { $_.Tags -notcontains $controlTag };
				}
			}
		}
		return $result;
	}
	hidden [PSObject] GetResourceObject()
    {
		if (-not $this.ResourceObject) {
            $this.ResourceObject = Get-AzLoadBalancer -ResourceGroupName $this.ResourceContext.ResourceGroupName -Name $this.ResourceContext.ResourceName  -WarningAction SilentlyContinue 

            if(-not $this.ResourceObject)
            {
                throw ([SuppressedException]::new(("Resource '{0}' not found under Resource Group '{1}'" -f ($this.ResourceContext.ResourceName), ($this.ResourceContext.ResourceGroupName)), [SuppressedExceptionType]::InvalidOperation))
            }
			
		}
		return $this.ResourceObject;
	}

	hidden [ControlResult] CheckPublicIP([ControlResult] $controlResult)
	{	
		$publicIps = @();
		#$loadBalancer = Get-AzLoadBalancer -ResourceGroupName $this.ResourceContext.ResourceGroupName -Name $this.ResourceContext.ResourceName
		if([Helpers]::CheckMember($this.ResourceObject,"FrontendIpConfigurations"))
        {
			$this.ResourceObject.FrontendIpConfigurations | 
				ForEach-Object {
					Set-Variable -Name feIpConfigurations -Scope Local -Value $_
					if(($feIpConfigurations | Get-Member -Name "PublicIpAddress") -and $feIpConfigurations.PublicIpAddress)
					{
						$ipResource = Get-AzResource -ResourceId $feIpConfigurations.PublicIpAddress.Id 
						if($ipResource)
						{
						   $publicIpObject = Get-AzPublicIpAddress -Name $ipResource.Name -ResourceGroupName $ipResource.ResourceGroupName
						   if($publicIpObject)
						   {
								$_.PublicIpAddress = $publicIpObject;
								$publicIps += $publicIpObject;
							}
						}
					}
				}
		 }
		if($publicIps.Count -gt 0)
		{              
			$controlResult.AddMessage([VerificationResult]::Verify, "Validate Public IP(s) associated with Load Balancer. Total - $($publicIps.Count)", $publicIps);  
			$controlResult.SetStateData("Public IP(s) associated with Load Balancer", $publicIps);
		}
		else
		{
			$controlResult.AddMessage([VerificationResult]::Passed, "No Public IP is associated with Load Balancer");
		}
		return $controlResult;
	}
}
