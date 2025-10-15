using OpenAI.Chat;
using quizzAPI.Models;
using quizzAPI.Models.DTOs;
using System.ClientModel;
using System.Text.Json;

namespace quizzAPI.Services
{
    public class OpenAIService
    {
        private readonly ChatClient _client;

        public OpenAIService(IConfiguration configuration)
        {
            var apiKey = Environment.GetEnvironmentVariable("OPENAI_API_KEY")
                         ?? configuration["OpenAI:ApiKey"];

            if (string.IsNullOrEmpty(apiKey))
                throw new ArgumentException("API Key do OpenAI não encontrada.");

            _client = new ChatClient("gpt-4o-mini", new ApiKeyCredential(apiKey));
        }

        /// <summary>
        /// Gera um quiz conforme parâmetros solicitados, incluindo justificativa detalhada.
        /// </summary>
        public async Task<string> GerarQuizzAsync(string nivelEscolar, string tema, int numeroPerguntas, string dificuldade)
        {
            string prompt = $@"
Você é um professor do '{nivelEscolar}'.
Crie {numeroPerguntas} perguntas de múltipla escolha sobre '{tema}' com dificuldade '{dificuldade}'.
Cada pergunta deve conter:
- perguntaTexto
- alternativas A, B, C, D
- respostaCorreta (A|B|C|D)
- justificativa explicando de forma bem resumida por que a alternativa correta é a certa, relacionando-a ao conteúdo da pergunta.
Responda SOMENTE em JSON no formato:

[
  {{
    ""perguntaTexto"": ""string"",
    ""alternativaA"": ""string"",
    ""alternativaB"": ""string"",
    ""alternativaC"": ""string"",
    ""alternativaD"": ""string"",
    ""respostaCorreta"": ""A|B|C|D"",
    ""justificativa"": ""string detalhada""
  }}
]
";

            var messages = new List<ChatMessage>
            {
                new SystemChatMessage("Você é um gerador de quizzes garanta que as perguntas geradas e as respostas condizam com otema e a escolaridade do usuario. Responda somente em JSON sem caracteres ou palavras extras antes ou depois."),
                new UserChatMessage(prompt)
            };

            var response = await _client.CompleteChatAsync(messages);
            return response.Value.Content[0].Text ?? "[]";
        }

        /// <summary>
        /// Gera o quiz e retorna a lista de PerguntaQuizz já desserializada, incluindo justificativa.
        /// </summary>
        public async Task<List<PerguntaQuizz>> GerarQuizzDTOAsync(string nivelEscolar, string tema, int numeroPerguntas, string dificuldade)
        {
            string json = await GerarQuizzAsync(nivelEscolar, tema, numeroPerguntas, dificuldade);

            var jsonArray = ExtractJsonArray(json);
            if (jsonArray == null) throw new Exception("O serviço OpenAI não retornou JSON válido.");

            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            var perguntasGeradas = JsonSerializer.Deserialize<List<PerguntaQuizz>>(jsonArray, options);

            // Garantir que todas as perguntas tenham justificativa
            foreach (var p in perguntasGeradas ?? new List<PerguntaQuizz>())
            {
                if (string.IsNullOrWhiteSpace(p.Justificativa))
                    p.Justificativa = "Justificativa não gerada corretamente";
            }

            return perguntasGeradas ?? new List<PerguntaQuizz>();
        }

        /// <summary>
        /// Valida perguntas já geradas, apenas checando consistência, não precisa gerar justificativa.
        /// </summary>
        public async Task<List<PerguntaValidacaoDTO>> ValidarQuizzAsync(
            string tema, string nivelEscolar, string dificuldade, string perguntasJson)
        {
            string prompt = $@"
Você é um revisor pedagógico. Valide as perguntas enviadas abaixo.
Regras:
1) Verifique se todos os campos existem (perguntaTexto, alternativaA..D, respostaCorreta, justificativa).
2) Confirme se respostaCorreta corresponde à alternativa indicada e se ela é de fato correta.
3) Cheque ambiguidade (mais de uma resposta possível).
4) Cheque adequação ao tema '{tema}', nível '{nivelEscolar}', dificuldade '{dificuldade}'.
5) Verifique gramática/ortografia.
6) Retorne SOMENTE em JSON no formato:

[
  {{
    ""index"": number,
    ""valid"": true|false,
    ""issues"": [""string"", ...],
    ""correctAnswerVerified"": true|false
  }}
]

Aqui está o JSON das perguntas:
{perguntasJson}
";

            var messages = new List<ChatMessage>
            {
                new SystemChatMessage("Você é um revisor pedagógico e linguístico. Responda somente em JSON sem caracteres ou palavras extras antes ou depois."),
                new UserChatMessage(prompt)
            };

            var options = new ChatCompletionOptions
            {
                Temperature = 0.0f,
                TopP = 1.0f
            };

            var response = await _client.CompleteChatAsync(messages, options);
            var raw = response.Value.Content[0].Text?.Trim();

            var json = ExtractJsonArray(raw);
            if (json == null) throw new Exception("Resposta da IA não continha JSON válido.");

            var opts = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            var results = JsonSerializer.Deserialize<List<ValidationResult>>(json, opts) ?? new List<ValidationResult>();

            // Mapeia para DTO
            var dtos = results.Select(r => new PerguntaValidacaoDTO
            {
                Index = r.Index,
                Valid = r.Valid,
                Issues = r.Issues,
                CorrectAnswerVerified = r.CorrectAnswerVerified
            }).ToList();

            return dtos;
        }

        // Privado: usado internamente para extrair o array JSON
        private string? ExtractJsonArray(string raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return null;
            var start = raw.IndexOf('[');
            var end = raw.LastIndexOf(']');
            if (start >= 0 && end > start)
                return raw.Substring(start, end - start + 1);
            return null;
        }

        // Interno: usado apenas para mapear o resultado do OpenAI antes do DTO
        internal class ValidationResult
        {
            public int Index { get; set; }
            public bool Valid { get; set; }
            public List<string> Issues { get; set; } = new();
            public bool CorrectAnswerVerified { get; set; }
        }
    }
}
