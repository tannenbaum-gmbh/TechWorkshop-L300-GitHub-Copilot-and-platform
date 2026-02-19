using Azure;
using Azure.AI.ContentSafety;
using Azure.Identity;

namespace ZavaStorefront.Services
{
    public class ContentSafetyService
    {
        private readonly ContentSafetyClient? _client;
        private readonly ILogger<ContentSafetyService> _logger;
        private readonly bool _isConfigured;

        public ContentSafetyService(IConfiguration configuration, ILogger<ContentSafetyService> logger)
        {
            _logger = logger;

            var endpoint = configuration["AzureContentSafety:Endpoint"];

            if (!string.IsNullOrWhiteSpace(endpoint))
            {
                _logger.LogInformation("ContentSafetyService: configured with endpoint {Endpoint}", endpoint);
                _client = new ContentSafetyClient(new Uri(endpoint), new DefaultAzureCredential());
                _isConfigured = true;
            }
            else
            {
                _logger.LogWarning("AzureContentSafety endpoint is not configured. Content safety checks will be skipped.");
                _client = null;
                _isConfigured = false;
            }
        }

        /// <summary>
        /// Evaluates user text against Azure AI Content Safety.
        /// Returns (isSafe, message). If unsafe, message contains a friendly warning.
        /// </summary>
        public async Task<(bool IsSafe, string? Message)> EvaluateAsync(string text)
        {
            if (!_isConfigured || _client is null)
            {
                _logger.LogDebug("Content safety not configured; allowing message through.");
                return (true, null);
            }

            try
            {
                // --- Text analysis ---
                var textOptions = new AnalyzeTextOptions(text);
                var textResult = await _client.AnalyzeTextAsync(textOptions);

                foreach (var category in textResult.Value.CategoriesAnalysis)
                {
                    _logger.LogInformation(
                        "Content Safety text result — Category: {Category}, Severity: {Severity}",
                        category.Category, category.Severity);

                    if (category.Severity.HasValue && category.Severity.Value >= 2)
                    {
                        _logger.LogWarning(
                            "Content flagged as UNSAFE — Category: {Category}, Severity: {Severity}",
                            category.Category, category.Severity);
                        return (false,
                            "Your message was flagged by our content safety system and cannot be processed. " +
                            "Please rephrase your message and try again.");
                    }
                }

                _logger.LogInformation("Content safety check passed for user message.");
                return (true, null);
            }
            catch (RequestFailedException ex)
            {
                _logger.LogError(ex,
                    "Content Safety API call failed. Status: {Status}, ErrorCode: {ErrorCode}",
                    ex.Status, ex.ErrorCode);
                // Fail-open: allow the message if the safety service is unavailable.
                return (true, null);
            }
        }
    }
}
