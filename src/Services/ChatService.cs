using Azure;
using Azure.AI.Inference;
using Azure.Core;
using Azure.Identity;

namespace ZavaStorefront.Services
{
    public class ChatService
    {
        private readonly ChatCompletionsClient _client;
        private readonly string _modelName;
        private readonly string _endpoint;
        private readonly ILogger<ChatService> _logger;
        private readonly bool _isConfigured;

        public ChatService(IConfiguration configuration, ILogger<ChatService> logger)
        {
            _logger = logger;

            var endpoint = configuration["AzureAIFoundry:Endpoint"];
            _modelName = configuration["AzureAIFoundry:ModelName"] ?? "Phi-4-mini-instruct";
            _endpoint = endpoint ?? string.Empty;

            if (!string.IsNullOrWhiteSpace(endpoint))
            {
                // Azure.AI.Inference does not automatically scope tokens to the Cognitive Services
                // audience for *.services.ai.azure.com endpoints, so we wrap the credential.
                _logger.LogInformation("ChatService: using DefaultAzureCredential for endpoint {Endpoint}", endpoint);
                _client = new ChatCompletionsClient(
                    new Uri(endpoint),
                    new CognitiveServicesCredential(new DefaultAzureCredential()));
                _isConfigured = true;
            }
            else
            {
                _logger.LogWarning("AzureAIFoundry endpoint is not configured. Chat feature will be unavailable.");
                _client = null!;
                _isConfigured = false;
            }
        }

        public async Task<string> GetChatResponseAsync(string userMessage)
        {
            if (!_isConfigured)
            {
                return "Chat service is not configured. Please set the AzureAIFoundry Endpoint in appsettings.json or environment variables.";
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
                _logger.LogError(ex, "Request to Azure AI Foundry endpoint failed. Status: {Status}, ErrorCode: {ErrorCode}, Endpoint: {Endpoint}",
                    ex.Status, ex.ErrorCode, _endpoint);
                return $"Error: Unable to get a response from the chat service at this time. (Status: {ex.Status}, Code: {ex.ErrorCode})";
            }
            catch (OperationCanceledException ex)
            {
                _logger.LogError(ex, "Request to Azure AI Foundry endpoint was canceled or timed out.");
                return "Error: The request to the chat service was canceled or timed out. Please try again.";
            }
        }
    }

    /// <summary>
    /// Forces the Cognitive Services token audience (https://cognitiveservices.azure.com)
    /// which Azure.AI.Inference does not set automatically for *.services.ai.azure.com endpoints.
    /// </summary>
    internal sealed class CognitiveServicesCredential : TokenCredential
    {
        private static readonly string[] Scopes = ["https://cognitiveservices.azure.com/.default"];
        private readonly TokenCredential _inner;

        public CognitiveServicesCredential(TokenCredential inner) => _inner = inner;

        public override AccessToken GetToken(TokenRequestContext _, CancellationToken ct) =>
            _inner.GetToken(new TokenRequestContext(Scopes), ct);

        public override ValueTask<AccessToken> GetTokenAsync(TokenRequestContext _, CancellationToken ct) =>
            _inner.GetTokenAsync(new TokenRequestContext(Scopes), ct);
    }
}
