using Microsoft.EntityFrameworkCore;
using quizzAPI.Models;

namespace quizzAPI.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

        // Tabela de usuários existente
        public DbSet<User> Users { get; set; }

        // Tabela para perguntas do quiz
        public DbSet<Pergunta> Perguntas { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // Configuração da tabela User
            modelBuilder.Entity<User>()
                .HasIndex(u => u.Email)
                .IsUnique();

            // Configuração da tabela Pergunta
            modelBuilder.Entity<Pergunta>(entity =>
            {
                // Mapeia para a tabela correta
                entity.ToTable("Perguntas");

                // Textos longos como NVARCHAR(MAX)
                entity.Property(e => e.PerguntaTexto)
                      .HasColumnType("NVARCHAR(MAX)")
                      .IsRequired();

                entity.Property(e => e.AlternativaA)
                      .HasColumnType("NVARCHAR(MAX)")
                      .IsRequired();

                entity.Property(e => e.AlternativaB)
                      .HasColumnType("NVARCHAR(MAX)")
                      .IsRequired();

                entity.Property(e => e.AlternativaC)
                      .HasColumnType("NVARCHAR(MAX)")
                      .IsRequired();

                entity.Property(e => e.AlternativaD)
                      .HasColumnType("NVARCHAR(MAX)")
                      .IsRequired();

                // Resposta correta
                entity.Property(e => e.RespostaCorreta)
                      .HasMaxLength(1)
                      .IsRequired();

                // Campos extras opcionais
                entity.Property(e => e.NivelEscolar)
                      .HasMaxLength(50)
                      .IsRequired(false);

                entity.Property(e => e.Tema)
                      .HasMaxLength(100)
                      .IsRequired(false);

                entity.Property(e => e.Dificuldade)
                      .HasMaxLength(50)
                      .IsRequired(false);
            });

            base.OnModelCreating(modelBuilder);
        }
    }
}
