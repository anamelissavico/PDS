namespace quizzAPI.Models.DTOs
{
    public class PerguntaValidacaoDTO
    {
        public int Index { get; set; }
        public bool Valid { get; set; }
        public List<string> Issues { get; set; }
        public bool CorrectAnswerVerified { get; set; }
        public string? Justification { get; set; }
        public Dictionary<string, string>? SuggestedCorrections { get; set; }
        public string? SuggestedDifficulty { get; set; }
    }
}
