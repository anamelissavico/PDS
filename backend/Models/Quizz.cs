using System.ComponentModel.DataAnnotations;

namespace quizzAPI.Models
{
    public class Quizz
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public string Tema { get; set; } = string.Empty;

        public string NivelEscolar { get; set; } = string.Empty;
        public string Dificuldade { get; set; } = string.Empty;

        public int NumeroPerguntas { get; set; }
        // Relação 1:N com Perguntas
        public List<Pergunta> Perguntas { get; set; } = new List<Pergunta>();
    }
}
