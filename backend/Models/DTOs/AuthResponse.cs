namespace quizzAPI.Models.DTOs
{
    public class AuthResponse
    {
        public string Token { get; set; }
        public DateTime ExpireAt { get; set; }
        public int UsuarioId { get; set; }   // adicionar esta linha
        public string Nome { get; set; }     // adicionar esta linha
    }
}
