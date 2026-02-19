# Zava Storefront - ASP.NET Core MVC

A simple e-commerce storefront application built with .NET 10 and ASP.NET Core MVC.

## Features

- **Product Listing**: Browse a catalog of 8 sample products with images, descriptions, and prices
- **Shopping Cart**: Add products to cart with session-based storage
- **Cart Management**: View cart, update quantities, remove items
- **Checkout**: Simple checkout process that clears cart and shows success message
- **AI Chat**: Chat with a Phi-4 Mini Instruct model via Microsoft Azure AI Foundry
- **Responsive Design**: Mobile-friendly layout using Bootstrap 5

## Technology Stack

- .NET 10
- ASP.NET Core MVC
- Azure.AI.Inference SDK (Phi-4 Mini Instruct)
- Bootstrap 5
- Bootstrap Icons
- Session-based state management (no database)

## Project Structure

```
ZavaStorefront/
├── Controllers/
│   ├── HomeController.cs      # Products listing and add to cart
│   ├── CartController.cs       # Cart operations and checkout
│   └── ChatController.cs      # AI chat page and AJAX endpoint
├── Models/
│   ├── Product.cs              # Product model
│   └── CartItem.cs             # Cart item model
├── Services/
│   ├── ProductService.cs       # Static product data
│   ├── CartService.cs          # Session-based cart management
│   └── ChatService.cs          # Azure AI Foundry chat completions
├── Views/
│   ├── Home/
│   │   └── Index.cshtml        # Products listing page
│   ├── Cart/
│   │   ├── Index.cshtml        # Shopping cart page
│   │   └── CheckoutSuccess.cshtml  # Checkout success page
│   ├── Chat/
│   │   └── Index.cshtml        # AI chat page
│   └── Shared/
│       └── _Layout.cshtml      # Main layout with cart icon and chat link
└── wwwroot/
    ├── css/
    │   └── site.css            # Custom styles
    └── images/
        └── products/           # Product images directory
```

## How to Run

1. Navigate to the project directory:
   ```bash
   cd ZavaStorefront
   ```

2. Run the application:
   ```bash
   dotnet run
   ```

3. Open your browser and navigate to:
   ```
   https://localhost:5001
   ```

## Product Images

The application includes 8 sample products. Product images are referenced from:
- `/wwwroot/images/products/`

If images are not found, the application automatically falls back to placeholder images from placeholder.com.

To add custom product images, place JPG files in `wwwroot/images/products/` with these names:
- headphones.jpg
- smartwatch.jpg
- speaker.jpg
- charger.jpg
- usb-hub.jpg
- keyboard.jpg
- mouse.jpg
- webcam.jpg

## Sample Products

1. Wireless Bluetooth Headphones - $89.99
2. Smart Fitness Watch - $199.99
3. Portable Bluetooth Speaker - $49.99
4. Wireless Charging Pad - $29.99
5. USB-C Hub Adapter - $39.99
6. Mechanical Gaming Keyboard - $119.99
7. Ergonomic Wireless Mouse - $34.99
8. HD Webcam - $69.99

## Application Flow

1. **Landing Page**: Displays all products in a responsive grid
2. **Add to Cart**: Click "Buy" button to add products to cart
3. **View Cart**: Click cart icon (top right) to view cart contents
4. **Update Cart**: Modify quantities or remove items
5. **Checkout**: Click "Checkout" button to complete purchase
6. **Success**: View confirmation and return to products

## Session Management

- Cart data is stored in session
- Session timeout: 30 minutes
- No data persistence (cart clears when session expires)
- Cart is cleared after successful checkout

## Logging

The application includes structured logging for:
- Product page loads
- Adding products to cart
- Cart operations (update, remove)
- Checkout process
- Chat messages and AI responses

Logs are written to console during development.

## AI Chat Feature

The `/Chat` page connects to an Azure AI Foundry **Phi-4 Mini Instruct** model deployment. Users can send messages and receive AI-generated responses in real time.

### Configuration

The chat feature requires three settings under the `AzureAIFoundry` section:

| Setting     | Description                                   | Default                |
|-------------|-----------------------------------------------|------------------------|
| `Endpoint`  | Azure AI Services endpoint URL                | *(empty — required)*   |
| `ApiKey`    | API key for the Azure AI Services resource    | *(empty — required)*   |
| `ModelName` | Deployed model name                           | `Phi-4-mini-instruct`  |

These can be provided via `appsettings.json`, `appsettings.Development.json`, or **environment variables** (using `__` as the section separator).

### Local Development Setup

#### Option A — Retrieve values automatically with `azd`

If infrastructure has already been provisioned with `azd provision`:

```bash
# Refresh environment values from deployed infrastructure
azd env refresh

# Read values
ENDPOINT=$(azd env get-values --output json | jq -r '.AZURE_AI_FOUNDRY_ENDPOINT')
AI_NAME=$(azd env get-values --output json | jq -r '.AZURE_AI_FOUNDRY_NAME')
RG=$(azd env get-values --output json | jq -r '.AZURE_RESOURCE_GROUP')

# Retrieve the API key
API_KEY=$(az cognitiveservices account keys list \
  --name "$AI_NAME" \
  --resource-group "$RG" \
  --query "key1" -o tsv)

echo "Endpoint : $ENDPOINT"
echo "API Key  : $API_KEY"
```

Then either:

1. **Set environment variables** (recommended, avoids committing secrets):
   ```bash
   export AzureAIFoundry__Endpoint="$ENDPOINT"
   export AzureAIFoundry__ApiKey="$API_KEY"
   export AzureAIFoundry__ModelName="Phi-4-mini-instruct"
   dotnet run
   ```

2. **Edit `appsettings.Development.json`** (git-ignored):
   ```json
   {
     "AzureAIFoundry": {
       "Endpoint": "<your-endpoint>",
       "ApiKey": "<your-api-key>",
       "ModelName": "Phi-4-mini-instruct"
     }
   }
   ```

#### Option B — User Secrets (best practice for local secrets)

```bash
cd src
dotnet user-secrets init
dotnet user-secrets set "AzureAIFoundry:Endpoint" "<your-endpoint>"
dotnet user-secrets set "AzureAIFoundry:ApiKey" "<your-api-key>"
dotnet user-secrets set "AzureAIFoundry:ModelName" "Phi-4-mini-instruct"
```

### Azure Deployment

When deployed via the **Build and Deploy App** GitHub Actions workflow (`.github/workflows/deploy-app.yml`), the AI Foundry environment variables are automatically configured:

1. The workflow retrieves `AZURE_AI_FOUNDRY_ENDPOINT` and `AZURE_AI_FOUNDRY_NAME` from `azd env get-values`.
2. It fetches the API key using `az cognitiveservices account keys list`.
3. It sets the App Service app settings (`AzureAIFoundry__Endpoint`, `AzureAIFoundry__ApiKey`, `AzureAIFoundry__ModelName`) via `az webapp config appsettings set`.

The Bicep infrastructure (`infra/modules/appService.bicep`) also sets these app settings during `azd provision`, so they are available immediately after provisioning.
