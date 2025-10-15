using Microsoft.EntityFrameworkCore;
using quizzAPI.Models;

namespace quizzAPI.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

        // Tabela de usuários existente
        public DbSet<User> Users { get; set; }

        // Tabela para quizzes
        public DbSet<Quizz> Quizzes { get; set; }

        // Tabela para perguntas do quiz
        public DbSet<Pergunta> Perguntas { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // Configuração da tabela User
            modelBuilder.Entity<User>()
                .HasIndex(u => u.Email)
                .IsUnique();

            // Configuração da tabela Quizz
            modelBuilder.Entity<Quizz>(entity =>
            {
                entity.ToTable("Quizz");

                entity.Property(e => e.Tema)
                      .HasMaxLength(255)
                      .IsRequired();

                entity.Property(e => e.NivelEscolar)
                      .HasMaxLength(100)
                      .IsRequired(false);

                entity.Property(e => e.Dificuldade)
                      .HasMaxLength(100)
                      .IsRequired(false);

                // Relacionamento 1:N com Perguntas
                entity.HasMany(q => q.Perguntas)
                      .WithOne(p => p.Quizz)
                      .HasForeignKey(p => p.QuizzId)
                      .OnDelete(DeleteBehavior.Cascade);
            });

            // Configuração da tabela Pergunta
            modelBuilder.Entity<Pergunta>(entity =>
            {
                entity.ToTable("Perguntas");

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

                entity.Property(e => e.RespostaCorreta)
                      .HasMaxLength(1)
                      .IsRequired();

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
