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
- Azure.Identity (DefaultAzureCredential / Managed Identity)
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

### Authentication

The chat service uses **Managed Identity (MSI)** by default — no API keys are stored or transmitted. The Bicep infrastructure assigns the **Cognitive Services User** role to the App Service's system-assigned managed identity on the AI Foundry resource.

For local development, `DefaultAzureCredential` from the `Azure.Identity` SDK is used, which automatically picks up your `az login` session. An optional API key fallback is available if needed.

### Configuration

The chat feature uses the `AzureAIFoundry` section in configuration:

| Setting     | Description                                   | Default                | Required |
|-------------|-----------------------------------------------|------------------------|----------|
| `Endpoint`  | Azure AI Foundry inference endpoint URL       | *(empty)*              | Yes      |
| `ApiKey`    | API key (optional, for local dev fallback)    | *(empty)*              | No       |
| `ModelName` | Deployed model name                           | `Phi-4-mini-instruct`  | No       |

> **Note:** When `ApiKey` is empty, the service authenticates via `DefaultAzureCredential` (MSI in Azure, `az login` locally). When `ApiKey` is set, it is used instead.

Settings can be provided via `appsettings.json`, `appsettings.Development.json`, environment variables (using `__` as the section separator), or user secrets.

### Local Development Setup

#### Option A — Use the setup script (recommended)

The `scripts/run-local.sh` script automatically retrieves the endpoint from `azd` and starts the app using `DefaultAzureCredential` (your `az login` session):

```bash
# Ensure you are logged in
az login

# Run the script (defaults to azd env "twl300")
bash scripts/run-local.sh

# Or specify a different azd environment
bash scripts/run-local.sh my-env-name
```

#### Option B — Set environment variables manually

```bash
# Refresh environment values from deployed infrastructure
azd env refresh

# Read the endpoint
ENDPOINT=$(azd env get-values --output json | jq -r '.AZURE_AI_FOUNDRY_ENDPOINT')

# Start the app — DefaultAzureCredential picks up your az login session
export AzureAIFoundry__Endpoint="$ENDPOINT"
export AzureAIFoundry__ModelName="Phi-4-mini-instruct"
cd src && dotnet run
```

#### Option C — Edit `appsettings.Development.json` (git-ignored)

```json
{
  "AzureAIFoundry": {
    "Endpoint": "https://<your-ai-name>.services.ai.azure.com/",
    "ModelName": "Phi-4-mini-instruct"
  }
}
```

#### Option D — User Secrets

```bash
cd src
dotnet user-secrets set "AzureAIFoundry:Endpoint" "https://<your-ai-name>.services.ai.azure.com/"
dotnet user-secrets set "AzureAIFoundry:ModelName" "Phi-4-mini-instruct"
```

> **Tip:** If your subscription has local key auth disabled, ensure your user account has the **Cognitive Services User** role on the AI Services resource, then just `az login` and set the endpoint.

### Azure Deployment

When deployed via the **Build and Deploy App** GitHub Actions workflow (`.github/workflows/deploy-app.yml`), the AI Foundry configuration is handled automatically:

1. **Infrastructure (`azd provision`):** The Bicep templates assign the **Cognitive Services User** role to the App Service's managed identity and set `AzureAIFoundry__Endpoint` and `AzureAIFoundry__ModelName` as app settings.
2. **CI/CD workflow:** After deploying the container image, the workflow retrieves `AZURE_AI_FOUNDRY_ENDPOINT` from `azd env get-values` and ensures the app settings are up to date on the App Service.

No API keys are used in production — the App Service authenticates to AI Foundry via its system-assigned managed identity.
