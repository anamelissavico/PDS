namespace quizzAPI.Services.Interfaces
{
    using System.Threading.Tasks;
    using quizzAPI.Models.DTOs;
    public interface IAuthService
    {
        public interface IAuthService
        {
            Task<(bool Success, string Error)> RegisterAsync(RegisterRequest req);
            Task<AuthResponse> LoginAsync(LoginRequest req);

        }
    }
}
