using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using quizzAPI.Data;
using quizzAPI.Models;
using quizzAPI.Models.DTOs;
using quizzAPI.Services;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;

namespace YourNamespace.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class QuizzController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly OpenAIService _openAIService;

        public QuizzController(ApplicationDbContext context, OpenAIService openAIService)
        {
            _context = context;
            _openAIService = openAIService;
        }

        [HttpPost("gerar")]
        public async Task<IActionResult> GerarQuizz([FromBody] Quizz request)
        {
            if (request == null)
                return BadRequest("Requisição inválida.");

            // 1) Criar quizz
            var quizz = new Quizz
            {
                Tema = $"Quiz sobre {request.Tema}",
                NivelEscolar = request.NivelEscolar,
                Dificuldade = request.Dificuldade,
                NumeroPerguntas = request.NumeroPerguntas
            };

            _context.Quizzes.Add(quizz);
            await _context.SaveChangesAsync();

            // 2) Gerar perguntas com justificativa
            List<PerguntaQuizz> perguntasGeradas = await _openAIService.GerarQuizzDTOAsync(
                request.NivelEscolar,
                request.Tema,
                request.NumeroPerguntas,
                request.Dificuldade
            );

            if (perguntasGeradas == null || !perguntasGeradas.Any())
                return BadRequest("Não foi possível gerar perguntas do quiz.");

            // 3) Serializar perguntas para validação
            string perguntasJson = JsonSerializer.Serialize(perguntasGeradas);

            // 4) Validar perguntas (não altera justificativa)
            await _openAIService.ValidarQuizzAsync(
                request.Tema,
                request.NivelEscolar,
                request.Dificuldade,
                perguntasJson
            );

            // 5) Salvar perguntas no banco
            foreach (var p in perguntasGeradas)
            {
                var pergunta = new Pergunta
                {
                    PerguntaTexto = p.PerguntaTexto,
                    AlternativaA = p.AlternativaA,
                    AlternativaB = p.AlternativaB,
                    AlternativaC = p.AlternativaC,
                    AlternativaD = p.AlternativaD,
                    RespostaCorreta = p.RespostaCorreta,
                    Justificativa = p.Justificativa, // mantém a justificativa original
                    NivelEscolar = request.NivelEscolar,
                    Tema = request.Tema,
                    Dificuldade = request.Dificuldade,
                    QuizzId = quizz.Id
                };

                _context.Perguntas.Add(pergunta);
            }

            await _context.SaveChangesAsync();

            // 6) Retornar perguntas já com justificativa
            return Ok(new
            {
                QuizzId = quizz.Id,
                Tema = quizz.Tema,
                Perguntas = perguntasGeradas.Select(p => new
                {
                    p.PerguntaTexto,
                    p.AlternativaA,
                    p.AlternativaB,
                    p.AlternativaC,
                    p.AlternativaD,
                    p.RespostaCorreta,
                    p.Justificativa
                })
            });
        }
        [HttpGet("{quizzId}/perguntas")]
        public async Task<IActionResult> ObterPerguntasPorQuizz(int quizzId)
        {
            var perguntas = await _context.Perguntas
                .Where(p => p.QuizzId == quizzId)
                .Select(p => new
                {
                    p.Id,
                    p.PerguntaTexto,
                    p.AlternativaA,
                    p.AlternativaB,
                    p.AlternativaC,
                    p.AlternativaD,
                    p.RespostaCorreta,
                    p.Justificativa
                })
                .ToListAsync();

            if (!perguntas.Any())
                return NotFound($"Nenhuma pergunta encontrada para o QuizzId {quizzId}.");

            return Ok(new { perguntas });
        }

        // POST: Avaliar respostas do usuário e calcular pontos
      
        [HttpPost("avaliar")]
        public async Task<IActionResult> AvaliarQuizz([FromBody] AvaliacaoQuizzRequest dto)
        {
            if (dto == null || dto.Respostas == null || !dto.Respostas.Any())
                return BadRequest("Nenhuma resposta enviada.");

            var user = await _context.Users.FindAsync(dto.UserId);
            if (user == null)
                return NotFound("Usuário não encontrado.");

            // Busca todas as perguntas do quizz de uma vez só
            var perguntas = await _context.Perguntas
                .Where(p => p.QuizzId == dto.QuizzId)
                .ToDictionaryAsync(p => p.Id);

            int pontosObtidos = 0;

            foreach (var resposta in dto.Respostas)
            {
                if (perguntas.TryGetValue(resposta.PerguntaId, out var pergunta))
                {
                    if (pergunta.RespostaCorreta == resposta.AlternativaEscolhida)
                    {
                        pontosObtidos += pergunta.Dificuldade switch
                        {
                            "Fácil" => 15,
                            "Média" => 20,
                            "Dificil" => 30,
                            _ => 0
                        };
                    }
                }
            }

            user.Pontos += pontosObtidos;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                Pontos = pontosObtidos,
                PontosTotaisUsuario = user.Pontos
            });
        }
    }
}
