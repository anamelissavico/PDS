namespace quizzAPI.Models.DTOs
{
    public class QuizRequest
    {
        public string NivelEscolar { get; set; } = string.Empty;
        public string Tema { get; set; } = string.Empty;
        public int NumeroPerguntas { get; set; }
        public string Dificuldade { get; set; } = string.Empty;
    }
}
