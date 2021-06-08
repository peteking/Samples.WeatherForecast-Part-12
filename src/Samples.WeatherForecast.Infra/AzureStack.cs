using Pulumi;
using Pulumi.AzureNative.Resources;
using Pulumi.AzureNative.Web;
using Pulumi.AzureNative.Web.Inputs;

class AzureStack : Stack
{
    public AzureStack()
    {
        var config = new Pulumi.Config();
        
        // Obtain our docker image from config
        var dockerImage = config.Require("docker-image");

        // Resource Group
        var rg = new ResourceGroup("rg-weatherforecastapi-uks-");

        // AppService Plan
        var appServicePlan = new AppServicePlan("appplan-weatherforecastapi-uks-", new AppServicePlanArgs() {
            ResourceGroupName = rg.Name,
            Location = rg.Location,
            Kind = "Linux",
            Reserved = true,
            Sku = new SkuDescriptionArgs
            {
                Name = "B1",
                Tier = "BASIC"
            },
        });

        // WebApp for Containers
        var app = new WebApp("app-weatherforecastapi-uks-", new WebAppArgs() 
        { 
            ResourceGroupName = rg.Name,
            ServerFarmId = appServicePlan.Id,
            SiteConfig = new SiteConfigArgs
            {
                AppSettings = new[] 
                { 
                    new NameValuePairArgs
                    {
                        Name = "WEBSITES_ENABLE_APP_SERVICE_STORAGE",
                        Value = "false"
                    },
                    new NameValuePairArgs
                    {
                        Name = "DOCKER_REGISTRY_SERVER_URL",
                        Value = "https://ghcr.io"
                    },
                    new NameValuePairArgs
                    {
                        Name = "WEBSITES_PORT",
                        Value = "8080" // Our custom image exposes port 8080. Adjust for your app as needed.
                    }
                },
                AlwaysOn = true,
                LinuxFxVersion = $"DOCKER|{dockerImage}"
            },
            HttpsOnly = true
        });

        this.Endpoint = Output.Format($"https://{app.DefaultHostName}/weatherforecast");
        this.HealthEndpoint = Output.Format($"https://{app.DefaultHostName}/health"); 
    }

    [Output] public Output<string> Endpoint { get; set; }

    [Output] public Output<string> HealthEndpoint { get; set; }
}