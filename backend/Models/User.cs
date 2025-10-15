namespace quizzAPI.Models
{
    public class User
    {
        public int Id { get; set; }             // PK
        public string Nome { get; set; }
        public string Email { get; set; }
        public string SenhaHash { get; set; }
        public int Pontos { get; set; } = 0;
        public DateTime DataCriacao { get; set; } = DateTime.UtcNow;
    }
}
