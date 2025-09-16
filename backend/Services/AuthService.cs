namespace quizzAPI.Services
{
    using BCrypt.Net;
    using Microsoft.EntityFrameworkCore;
    using Microsoft.IdentityModel.Tokens;
    using quizzAPI.Data;
    using quizzAPI.Models.DTOs;
    using quizzAPI.Models;
    using quizzAPI.Services.Interfaces;
    using System.IdentityModel.Tokens.Jwt;
    using System.Security.Claims;
    using System.Text;

    public class AuthService : IAuthService
    {
        private readonly ApplicationDbContext _context;
        private readonly IConfiguration _configuration;

        public AuthService(ApplicationDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        public async Task<(bool Success, string Error)> RegisterAsync(RegisterRequest req)
        {
            if (await _context.Users.AnyAsync(u => u.Email == req.Email))
                return (false, "Email já cadastrado");

            string senhaHash = BCrypt.HashPassword(req.Senha);

            var user = new User
            {
                Nome = req.Nome,
                Email = req.Email,
                SenhaHash = senhaHash,
                DataCriacao = DateTime.UtcNow
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return (true, null);
        }

        public async Task<AuthResponse> LoginAsync(LoginRequest req)
        {
            var user = await _context.Users.SingleOrDefaultAsync(u => u.Email == req.Email);
            if (user == null)
                return null;

            bool senhaValida = BCrypt.Verify(req.Senha, user.SenhaHash);
            if (!senhaValida)
                return null;

            var token = GenerateJwtToken(user, out DateTime expires);

            return new AuthResponse
            {
                Token = token,
                ExpireAt = expires,
                UsuarioId = user.Id,
                Nome = user.Nome
            };
        }

        private string GenerateJwtToken(User user, out DateTime expires)
        {
            var key = Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]);
            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.Email, user.Email),
                new Claim("nome", user.Nome)
            };

            var creds = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256);
            expires = DateTime.UtcNow.AddMinutes(Convert.ToDouble(_configuration["Jwt:DurationMinutes"]));

            var token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"],
                audience: _configuration["Jwt:Audience"],
                claims: claims,
                expires: expires,
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
