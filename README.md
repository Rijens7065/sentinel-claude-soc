# sentinel-claude-soc
Automated Azure SOC platform with AI agents powered by Claude

## Resources Not Managed by Terraform

The following resources are managed natively by Azure and are **not** controlled via Terraform:

| Resource | Reason |
|---|---|
| Sentinel Data Connector — Microsoft Defender XDR | Auto-enabled on Sentinel onboarding. The azurerm provider has an internal kind mismatch that prevents import or creation. Enable via Azure Portal: Sentinel → Configuration → Data connectors. |
| Sentinel Data Connector — Azure Security Center | Same limitation as above. Enable via Azure Portal. |
| Storage Account `stsocprodcae001` | Terraform remote state backend — bootstrapped manually before Terraform can init (chicken-and-egg). |
