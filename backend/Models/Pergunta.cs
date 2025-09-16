namespace quizzAPI.Models
{
    public class Pergunta
    {
        public int Id { get; set; }
        public string PerguntaTexto { get; set; }
        public string AlternativaA { get; set; }
        public string AlternativaB { get; set; }
        public string AlternativaC { get; set; }
        public string AlternativaD { get; set; }
        public string RespostaCorreta { get; set; } // Ex: "A", "B", "C", "D"
        public string NivelEscolar { get; set; } // Ex: "Ensino Fundamental", "Ensino Médio"
        public string Tema { get; set; } // Ex: "Matemática", "História"
        public string Dificuldade { get; set; } // Ex: "Fácil", "Médio", "Difícil"
    }
}
