namespace quizzAPI.Models.DTOs
{
    public class QuizzResponseDto
    {
        public List<PerguntaDto> Perguntas { get; set; } = new List<PerguntaDto>();
    }

    public class PerguntaDto
    {
        public int Id { get; set; }
        public string PerguntaTexto { get; set; } = string.Empty;
        public string AlternativaA { get; set; } = string.Empty;
        public string AlternativaB { get; set; } = string.Empty;
        public string AlternativaC { get; set; } = string.Empty;
        public string AlternativaD { get; set; } = string.Empty;
        public string RespostaCorreta { get; set; } = string.Empty;
        public string Justificativa { get; set; } = string.Empty;

        public String Dificuldade { get; set; } = string.Empty;
        public int QuizzId { get; set; } // Novo campo
    }
}
