import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:swara/components/component4/services/c4_flow.dart';
import 'package:swara/features/speech/data/models/speech_assessment.dart';

/// Real responses from server/contracts, so the app's parsing follows the services.
Map<String, dynamic> _contract(String path) =>
    jsonDecode(File('../server/contracts/$path').readAsStringSync()) as Map<String, dynamic>;

void main() {
  test('C1: the result screen values come from a completed assessment result', () {
    final result = _contract('c1/analyze-speech.response.example.json');
    final r = SpeechResult.fromResult(result);
    expect(r.totalSyllables, 66);
    expect(r.stutteredSyllables, 5);
    expect(r.percentSS, closeTo(7.58, 1e-9));
    expect(r.repetitions, 3); // 2 sound + 1 word repetitions
    expect(r.prolongations, 1);
    expect(r.blocks, 1);
    expect(r.typeEn, 'Repetition');
    expect(r.severityEn, 'Moderate');
    expect(r.severitySi, 'මධ්‍යම');
    expect(r.durationSec, closeTo(21.833, 1e-9));
    expect(r.warnings, isNotEmpty);
  });

  test('C1: no events reads as None, not as a stutter type', () {
    final r = SpeechResult.fromResult({
      'counts': {'block': 0, 'prolongation': 0, 'soundRepetition': 0, 'wordRepetition': 0, 'interjection': 0},
      'primaryType': null,
      'syllables': {'total': 120},
      'stutteredSyllables': 0,
      'percentSS': 0,
      'severity': {'label': 'none_very_mild', 'displayLabel': 'None / very mild'},
    });
    expect(r.typeEn, 'None');
    expect(r.severityEn, 'None / very mild');
    expect(r.severitySi, 'ඉතා මෘදු');
  });

  test('C4: the session and its analysed sample fill the C4 screens', () {
    final transcribe = _contract('c4/transcribe.response.example.json');
    final measures = _contract('c4/measures.response.example.json');
    C4Flow.rankedIds = ['animals', 'food', 'school', 'family', 'sports'];
    C4Flow.session = {
      'id': 's1',
      'ageBand': '5-10',
      'topic': {
        'id': 'animals-01',
        'categoryId': 'animals',
        'level': 'emerging',
        'title': {'si': 'මගේ සුරතල් සතා', 'en': 'My pet'},
        'mainPrompt': {'si': 'ඔයාගේ සුරතල් සතා ගැන කියන්න.', 'en': 'Tell me about your pet.'},
      },
      'selection': {
        'chosen': {'topicId': 'animals-01', 'categoryId': 'animals', 'probability': 0.31},
      },
      'prompts': {
        'current': {
          'kind': 'main',
          'text': {'si': 'ඔයාගේ සුරතල් සතා ගැන කියන්න.', 'en': 'Tell me about your pet.'},
        },
        'followUpsRemaining': 2,
      },
    };
    C4Flow.sample = {
      'status': 'completed',
      'asr': transcribe,
      'transcripts': [
        {'version': 1, 'kind': 'asr', 'text': transcribe['text']},
      ],
      'currentVersion': 1,
      'analysis': measures,
    };

    final v = C4Flow.view;
    expect(v.topicSi, 'මගේ සුරතල් සතා');
    expect(v.level, 'Easy');
    expect(v.ageBand, '5–10');
    expect(v.categoryRank, 1);
    expect(v.categoryRank, 1);
    expect(v.probability, 0.31);
    expect(v.questionSi, 'ඔයාගේ සුරතල් සතා ගැන කියන්න.');
    expect(v.transcript, transcribe['text']);
    expect(v.durationSec, (transcribe['audio']['durationSec'] as num).toDouble());
    expect(v.utterances, measures['measures']['utteranceCount']);
    expect(v.totalWords, measures['measures']['totalWords']);
    expect(v.ndw, measures['measures']['ndwAll']);
    expect(v.mlu, (measures['measures']['mluWords'] as num?)?.toDouble());
  });
}
