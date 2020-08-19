# Azure Cosmos DB with gremlin API

Quick out of the box test deployment of azure cosmosdb gremlin graph with terraform for easy debugging and playground scenario.

Terrform Version: 0.13.0
Azurerm Provider: 2.23

The official example was not working out of the box for me it can be seen [here](https://www.terraform.io/docs/providers/azurerm/r/cosmosdb_gremlin_graph.html)

## Run

Enable debugging and log information

    export TF_LOG_PATH=./terraform.log
    export TF_LOG=TRACE
    export TF_VAR_subid=<yourazuresubscriptionid>

Init terraform

    terraform init

Run plan and apply it

    terraform plan --out=tf.bin && terraform apply tf.bin

# Notes:

If you get the following error:

    [ERROR] eval: *terraform.EvalSequence, err: Error checking for presence of creating Gremlin Database "gremlindb-cosmos" (Account: "tfex-db"): documentdb.GremlinResourcesClient#GetGremlinDatabase: Failure responding to request: StatusCode=405 -- Original Error: autorest/azure: Service returned an error. Status=405 Code="MethodNotAllowed" Message="Requests for API gremlin are not supported for this account.\r\nActivityId: <id>, Microsoft.Azure.Documents.Common/2.11.0"

You forgot to configure the `azurerm_cosmosdb_account` properly by adding the following capability set:

    capabilities {
        name = "EnableGremlin"
    }

This [this](https://github.com/terraform-providers/terraform-provider-azurerm/issues/4031) is reporting the issue.
