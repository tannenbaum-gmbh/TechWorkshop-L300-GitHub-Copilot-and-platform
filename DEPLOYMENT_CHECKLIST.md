# ZavaStorefront - Azure Deployment Checklist

## Pre-Deployment Validation ✅

### Infrastructure Files
- [x] `azure.yaml` - AZD configuration
- [x] `Dockerfile` - Container build definition
- [x] `.dockerignore` - Build exclusions
- [x] `infra/main.bicep` - Main infrastructure template
- [x] `infra/main.parameters.json` - Deployment parameters
- [x] `infra/modules/acr.bicep` - Container Registry
- [x] `infra/modules/appService.bicep` - App Service
- [x] `infra/modules/appInsights.bicep` - Monitoring
- [x] `infra/modules/aiFoundry.bicep` - AI Services

### Validation Tests
- [x] All Bicep files compile successfully
- [x] Docker image builds successfully
- [x] No compilation errors or warnings
- [x] Security scan passed
- [x] Configuration validated

## Required Configurations ✅

### Managed Identity
- [x] System-assigned identity enabled on App Service
- [x] Identity principal ID exposed in outputs
- [x] Used for ACR authentication

### RBAC
- [x] AcrPull role assigned to App Service identity
- [x] Correct role definition ID (7f951dda-4ed3-4680-a7ca-43fe172d538d)
- [x] ACR admin user disabled

### Application Insights
- [x] Application Insights resource configured
- [x] Log Analytics Workspace created
- [x] Connection string passed to App Service
- [x] Agent extension configured (~3)

### AI Services
- [x] Azure AI Services deployed (S0 SKU)
- [x] GPT-4 model deployment configured
- [x] Phi-4 model deployment configured
- [x] Proper dependency ordering

### Docker
- [x] remoteBuild enabled in azure.yaml
- [x] Container registry URL configured
- [x] Managed Identity credentials enabled
- [x] Port mapping configured (80)

## Deployment Steps

### 1. Prerequisites
```bash
# Verify tools installed
azd version
az version
docker version
```

### 2. Azure Authentication
```bash
azd auth login
# Follow browser authentication flow
```

### 3. Environment Configuration
```bash
# Set environment name (lowercase, alphanumeric, 1-64 chars)
azd env set AZURE_ENV_NAME dev-zava-storefront

# Set Azure region
azd env set AZURE_LOCATION westus3
```

### 4. Deploy Infrastructure
```bash
# One command to provision and deploy
azd up

# Or separate steps:
azd provision  # Create infrastructure only
azd deploy     # Deploy application only
```

### 5. Verify Deployment
```bash
# Show deployment details
azd show

# Get resource group
azd env get-values | grep AZURE_RESOURCE_GROUP

# Test application
curl https://<your-app>.azurewebsites.net
```

## Post-Deployment Verification

### Check Resources
```bash
# List all resources in the resource group
az resource list --resource-group <resource-group-name> --output table
```

### Verify App Service
```bash
# Get App Service details
az webapp show --name <app-name> --resource-group <rg-name>

# Check logs
az webapp log tail --name <app-name> --resource-group <rg-name>
```

### Verify Container Registry
```bash
# List repositories
az acr repository list --name <acr-name>

# List tags
az acr repository show-tags --name <acr-name> --repository web
```

### Verify Application Insights
```bash
# Query recent logs
az monitor app-insights query \
  --app <app-insights-name> \
  --analytics-query "requests | take 10"
```

### Test AI Services
```bash
# Get endpoint
az cognitiveservices account show \
  --name <ai-service-name> \
  --resource-group <rg-name> \
  --query properties.endpoint
```

## Health Checks

- [ ] Web application is accessible via HTTPS
- [ ] Application logs appear in Application Insights
- [ ] Container successfully pulled from ACR
- [ ] AI services endpoints are accessible
- [ ] No errors in App Service logs

## Production Hardening (Optional)

### Security Enhancements
- [ ] Configure ACR private endpoint
- [ ] Implement VNet integration
- [ ] Add non-root user to Dockerfile
- [ ] Configure Azure Key Vault for secrets
- [ ] Enable Managed Identity for AI Services

### Monitoring & Alerts
- [ ] Configure Application Insights alerts
- [ ] Set up availability tests
- [ ] Create monitoring dashboard
- [ ] Configure log retention policy (90+ days)

### Performance
- [ ] Enable autoscaling rules
- [ ] Configure CDN for static assets
- [ ] Optimize container image size
- [ ] Review App Service Plan SKU

### Compliance
- [ ] Enable diagnostic logging
- [ ] Configure Azure Policy
- [ ] Implement backup strategy
- [ ] Document disaster recovery plan

## Troubleshooting

### Common Issues

**Issue:** azd up fails with authentication error
```bash
# Solution: Re-authenticate
azd auth login --use-device-code
```

**Issue:** Docker build fails
```bash
# Solution: Build locally to test
docker build -t test:latest -f Dockerfile .
```

**Issue:** Container won't start
```bash
# Solution: Check logs
az webapp log tail --name <app-name> --resource-group <rg-name>

# Check container settings
az webapp config show --name <app-name> --resource-group <rg-name>
```

**Issue:** Can't pull from ACR
```bash
# Solution: Verify RBAC assignment
az role assignment list --assignee <managed-identity-principal-id>

# Verify ACR settings
az acr show --name <acr-name> --query "{AdminEnabled:adminUserEnabled,Identity:identity}"
```

## Cleanup

### Remove All Resources
```bash
# Delete entire environment
azd down

# Or delete resource group manually
az group delete --name <resource-group-name> --yes --no-wait
```

### Remove Local Environment
```bash
# Remove azd environment
azd env remove <environment-name>
```

## Cost Management

### Monitor Costs
```bash
# View resource group costs
az consumption usage list \
  --start-date <YYYY-MM-DD> \
  --end-date <YYYY-MM-DD> \
  | grep <resource-group-name>
```

### Cost Optimization Tips
- Use B1 SKU for dev/test (current configuration)
- Stop App Service when not in use (dev/test)
- Monitor AI Services token usage
- Review Log Analytics ingestion volume
- Consider Reserved Instances for production

## Support Resources

- **Azure Developer CLI:** https://learn.microsoft.com/azure/developer/azure-developer-cli/
- **Bicep Documentation:** https://learn.microsoft.com/azure/azure-resource-manager/bicep/
- **App Service:** https://learn.microsoft.com/azure/app-service/
- **Azure AI Services:** https://learn.microsoft.com/azure/ai-services/
- **Application Insights:** https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview

## Validation Status

✅ **All checks passed - Ready for deployment**

- Infrastructure: Validated
- Security: Compliant
- Configuration: Complete
- Documentation: Available

**Last Validated:** February 18, 2026  
**Validation Report:** See `VALIDATION_REPORT.md`

---

**Quick Deploy:**
```bash
azd auth login
azd env set AZURE_ENV_NAME <name>
azd env set AZURE_LOCATION <region>
azd up
```
