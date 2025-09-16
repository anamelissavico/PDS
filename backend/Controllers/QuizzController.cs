using Microsoft.AspNetCore.Mvc;
using quizzAPI.Data;
using quizzAPI.Models.DTOs;
using quizzAPI.Models;
using quizzAPI.Services;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading.Tasks;

namespace QuizzAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class QuizzController : ControllerBase
    {
        private readonly OpenAIService _openAIService;
        private readonly ApplicationDbContext _context;

        public QuizzController(OpenAIService openAIService, ApplicationDbContext context)
        {
            _openAIService = openAIService;
            _context = context;
        }

        // Endpoint para gerar quiz via OpenAI e salvar no banco
        [HttpPost("gerar")]
        public async Task<IActionResult> GerarQuizz([FromBody] QuizRequest request)
        {
            if (request == null)
                return BadRequest("Requisição inválida.");

            try
            {
                // Chama o serviço que gera o quiz e retorna a lista já desserializada
                List<PerguntaQuizz> perguntasGeradas = await _openAIService.GerarQuizzDTOAsync(
                    request.NivelEscolar,
                    request.Tema,
                    request.NumeroPerguntas,
                    request.Dificuldade
                );

                if (perguntasGeradas == null || perguntasGeradas.Count == 0)
                    return BadRequest("Não foi possível gerar perguntas do quiz.");

                // Salva cada pergunta no banco com validação de nulos
                foreach (var p in perguntasGeradas)
                {
                    var pergunta = new Pergunta
                    {
                        PerguntaTexto = string.IsNullOrEmpty(p.PerguntaTexto) ? "Pergunta não definida" : p.PerguntaTexto,
                        AlternativaA = string.IsNullOrEmpty(p.AlternativaA) ? "A" : p.AlternativaA,
                        AlternativaB = string.IsNullOrEmpty(p.AlternativaB) ? "B" : p.AlternativaB,
                        AlternativaC = string.IsNullOrEmpty(p.AlternativaC) ? "C" : p.AlternativaC,
                        AlternativaD = string.IsNullOrEmpty(p.AlternativaD) ? "D" : p.AlternativaD,
                        RespostaCorreta = string.IsNullOrEmpty(p.RespostaCorreta) ? "A" : p.RespostaCorreta,
                        NivelEscolar = string.IsNullOrEmpty(request.NivelEscolar) ? null : request.NivelEscolar,
                        Tema = string.IsNullOrEmpty(request.Tema) ? null : request.Tema,
                        Dificuldade = string.IsNullOrEmpty(request.Dificuldade) ? null : request.Dificuldade
                    };

                    _context.Perguntas.Add(pergunta);
                }

                await _context.SaveChangesAsync();

                // Validação das perguntas usando DTO
                var perguntasJson = JsonSerializer.Serialize(perguntasGeradas);
                List<PerguntaValidacaoDTO> validacoes = await _openAIService.ValidarQuizzAsync(
                    request.Tema,
                    request.NivelEscolar,
                    request.Dificuldade,
                    perguntasJson
                );

                // Retorna perguntas + validações
                return Ok(new
                {
                    Perguntas = perguntasGeradas,
                    Validacoes = validacoes
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Erro: {ex.Message}\nStackTrace: {ex.StackTrace}\nInnerException: {ex.InnerException?.Message}");
            }
        }

        // Endpoint de teste rápido para salvar uma pergunta manualmente
        [HttpPost("salvando")]
        public IActionResult TesteSalvarPergunta()
        {
            var pergunta = new Pergunta
            {
                PerguntaTexto = "Qual é a capital do Brasil?",
                AlternativaA = "Rio de Janeiro",
                AlternativaB = "São Paulo",
                AlternativaC = "Brasília",
                AlternativaD = "Salvador",
                RespostaCorreta = "C",
                NivelEscolar = "Ensino Fundamental",
                Tema = "Geografia",
                Dificuldade = "Fácil"
            };

            _context.Perguntas.Add(pergunta);
            _context.SaveChanges();

            return Ok("Pergunta salva com sucesso!");
        }
    }
}
