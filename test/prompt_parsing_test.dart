import 'package:ecology_project/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Prompt parsing', () {
    test('CardDecisionPrompt parses nested choice objects', () {
      final prompt = CardDecisionPrompt.fromMap({
        'card_title': 'Carbon Tax',
        'choice_a': {
          'name': 'Aggressive',
          'effects': {'sustainability': 9, 'economy': -3},
        },
        'choice_b': {
          'name': 'Moderate',
          'effects': {'sustainability': 6, 'economy': 2},
        },
      });

      expect(prompt.choiceA, 'Aggressive');
      expect(prompt.choiceADescription, contains('+9 sustainability'));
      expect(prompt.choiceADescription, contains('-3 economy'));
      expect(prompt.choiceB, 'Moderate');
    });

    test('PurchasePrompt parses provider/taker costs from protocol format', () {
      final prompt = PurchasePrompt.fromMap({
        'name': 'Solar Power Plant',
        'budget': 100,
        'provider_option': {'cost_points': 100},
        'taker_option': {'cost_points': 25},
        'immediate_scores': {'sustainability': 8},
      });

      expect(prompt.providerCost, 100);
      expect(prompt.takerCost, 25);
      expect(prompt.effects['sustainability'], 8);
    });
  });
}
