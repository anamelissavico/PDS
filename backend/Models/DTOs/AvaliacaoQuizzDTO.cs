namespace quizzAPI.Models.DTOs
{
   public class RespostaUsuario
    {
        public int PerguntaId { get; set; }
        public string AlternativaEscolhida { get; set; } = string.Empty;
    }

    public class AvaliacaoQuizzRequest
    {
        public int UserId { get; set; }
        public int QuizzId { get; set; }
        public List<RespostaUsuario> Respostas { get; set; } = new();
    }
}
