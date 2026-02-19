using Microsoft.AspNetCore.Mvc;
using ZavaStorefront.Services;

namespace ZavaStorefront.Controllers;

public class ChatController : Controller
{
    private readonly ChatService _chatService;
    private readonly ILogger<ChatController> _logger;

    public ChatController(ChatService chatService, ILogger<ChatController> logger)
    {
        _chatService = chatService;
        _logger = logger;
    }

    public IActionResult Index()
    {
        return View();
    }

    [HttpPost]
    public async Task<IActionResult> SendMessage([FromBody] ChatRequest request)
    {
        if (string.IsNullOrWhiteSpace(request?.Message))
        {
            return BadRequest(new { response = "Please enter a message." });
        }

        _logger.LogInformation(
            "Chat message received: {MessagePreview}",
            request.Message[..Math.Min(50, request.Message.Length)]
                .Replace("\r", string.Empty)
                .Replace("\n", string.Empty));

        var response = await _chatService.GetChatResponseAsync(request.Message);

        return Json(new { response });
    }
}

public class ChatRequest
{
    public string Message { get; set; } = string.Empty;
}
