namespace quizzAPI.Models
{
    public class PerguntaQuizz
    {
        public string PerguntaTexto { get; set; }

        public int Index { get; set; } // Novo campo Index adicionado para validação
        public string AlternativaA { get; set; }
        public string AlternativaB { get; set; }
        public string AlternativaC { get; set; }
        public string AlternativaD { get; set; }
        public string RespostaCorreta { get; set; }
        public string Justificativa { get; set; }
    }
}
