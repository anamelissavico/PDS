namespace quizzAPI.Controllers
{
    using BCrypt.Net;   
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.EntityFrameworkCore;
    using quizzAPI.Data;
    using quizzAPI.Models;
    using quizzAPI.Models.DTOs;

    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public AuthController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest req)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == req.Email);

            if (user == null || !BCrypt.Verify(req.Senha, user.SenhaHash))
            {
                return Unauthorized(new { message = "Email ou senha inválidos." });
            }

            var token = GenerateJwtToken(user);

            return Ok(new AuthResponse
            {
                Token = token,
                ExpireAt = DateTime.UtcNow.AddHours(1),
                UsuarioId = user.Id,
                Nome = user.Nome
            });
        }

        private string GenerateJwtToken(User user)
        {
            // Aqui você coloca seu método de geração de token JWT
            // Exemplo simples:
            var tokenHandler = new System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler();
            var key = System.Text.Encoding.ASCII.GetBytes("P@ssw0rdNaoEhSeguro_UseAlgoAssim_9fB1&8zQ#L2xK7"); // use a mesma do Program.cs
            var tokenDescriptor = new Microsoft.IdentityModel.Tokens.SecurityTokenDescriptor
            {
                Subject = new System.Security.Claims.ClaimsIdentity(new[]
                {
                new System.Security.Claims.Claim("id", user.Id.ToString()),
                new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.Name, user.Nome)
            }),
                Expires = DateTime.UtcNow.AddHours(1),
                SigningCredentials = new Microsoft.IdentityModel.Tokens.SigningCredentials(
                    new Microsoft.IdentityModel.Tokens.SymmetricSecurityKey(key),
                    Microsoft.IdentityModel.Tokens.SecurityAlgorithms.HmacSha256Signature)
            };
            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest req)
        {
            // Verifica se o email já existe
            var existingUser = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == req.Email);

            if (existingUser != null)
            {
                return BadRequest(new { message = "Email já cadastrado." });
            }

            // Cria novo usuário com senha criptografada
            var newUser = new User
            {
                Nome = req.Nome,
                Email = req.Email,
                SenhaHash = BCrypt.HashPassword(req.Senha)
            };

            // Salva no banco
            _context.Users.Add(newUser);
            await _context.SaveChangesAsync();

            // Retorna sucesso (pode retornar token se desejar)
            return Ok(new { message = "Usuário registrado com sucesso." });
        }
    }
}
