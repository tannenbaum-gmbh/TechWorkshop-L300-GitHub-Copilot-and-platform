using Azure;
using Azure.AI.Inference;

namespace ZavaStorefront.Services
{
    public class ChatService
    {
        private readonly ChatCompletionsClient _client;
        private readonly string _modelName;
        private readonly ILogger<ChatService> _logger;
        private readonly bool _isConfigured;

        public ChatService(IConfiguration configuration, ILogger<ChatService> logger)
        {
            _logger = logger;

            var endpoint = configuration["AzureAIFoundry:Endpoint"];
            var apiKey = configuration["AzureAIFoundry:ApiKey"];
            _modelName = configuration["AzureAIFoundry:ModelName"] ?? "Phi-4-mini-instruct";

            if (!string.IsNullOrWhiteSpace(endpoint) && !string.IsNullOrWhiteSpace(apiKey))
            {
                _client = new ChatCompletionsClient(
                    new Uri(endpoint),
                    new AzureKeyCredential(apiKey));
                _isConfigured = true;
            }
            else
            {
                _logger.LogWarning("AzureAIFoundry endpoint or API key is not configured. Chat feature will be unavailable.");
                _client = null!;
                _isConfigured = false;
            }
        }

        public async Task<string> GetChatResponseAsync(string userMessage)
        {
            if (!_isConfigured)
            {
                return "Chat service is not configured. Please set the AzureAIFoundry Endpoint and ApiKey in appsettings.json or environment variables.";
            }

            try
            {
                var requestOptions = new ChatCompletionsOptions()
                {
                    Messages =
                    {
                        new ChatRequestSystemMessage("You are a helpful assistant for the Zava Storefront. Answer questions concisely and helpfully."),
                        new ChatRequestUserMessage(userMessage)
                    },
                    Model = _modelName
                };

                ChatCompletions response = await _client.CompleteAsync(requestOptions);

                return response.Content ?? "No response received from the model.";
            }
            catch (RequestFailedException ex)
            {
                _logger.LogError(ex, "Request to Azure AI Foundry endpoint failed.");
                return "Error: Unable to get a response from the chat service at this time.";
            }
            catch (OperationCanceledException ex)
            {
                _logger.LogError(ex, "Request to Azure AI Foundry endpoint was canceled or timed out.");
                return "Error: The request to the chat service was canceled or timed out. Please try again.";
            }
        }
    }
}
