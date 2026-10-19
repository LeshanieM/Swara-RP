import unittest

from app.processing.language_analysis import analyze_transcript, calculate_mattr, normalize_sinhala, tokenize


class LanguageAnalysisTests(unittest.TestCase):
    def test_normalization_and_repetitions(self):
        self.assertEqual(normalize_sinhala("මම  මම\u200b හරි"), "මම මම හරි")
        self.assertEqual(normalize_sinhala("බ\u200d"), "බ\u200d")
        self.assertEqual(tokenize("මම මම අම්මේ"), ["මම", "මම", "අම්මේ"])

    def test_word_mlu_and_ndw(self):
        result = analyze_transcript("මම ගෙදර ගියා. මම සෙල්ලම් කළා.")
        self.assertEqual(result["measures"]["MLU_words"], 3)
        self.assertEqual(result["measures"]["NDW"], 5)
        self.assertTrue(result["shortSample"])

    def test_mattr_short_and_window(self):
        self.assertEqual(calculate_mattr([], 3)["value"], None)
        self.assertEqual(calculate_mattr(["a", "a"], 3)["value"], 0.5)
        self.assertEqual(calculate_mattr(["a", "b", "a", "c"], 3)["windows"], 2)

    def test_ndw_uses_first_fifty_words(self):
        text = " ".join(f"වචනය{i}" for i in range(51))
        self.assertEqual(analyze_transcript(text)["measures"]["NDW"], 50)


if __name__ == "__main__":
    unittest.main()
