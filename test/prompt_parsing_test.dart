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
        'is_owned': true,
        'owner_faction': 'Natural',
        'provider_option': {'cost_points': 100},
        'taker_option': {'cost_points': 25, 'available': true},
        'immediate_scores': {'sustainability': 8},
      });

      expect(prompt.providerCost, 100);
      expect(prompt.takerCost, 25);
      expect(prompt.isOwned, isTrue);
      expect(prompt.ownerFaction, 'Natural');
      expect(prompt.takerAvailable, isTrue);
      expect(prompt.effects['sustainability'], 8);
    });

    test('PurchasePrompt honors provider/taker availability flags', () {
      final prompt = PurchasePrompt.fromMap({
        'name': 'Solar Power Plant',
        'budget': 100,
        'provider_option': {'cost_points': 100, 'available': false},
        'taker_option': {'cost_points': 25, 'available': true},
      });

      expect(prompt.providerAvailable, isFalse);
      expect(prompt.takerAvailable, isTrue);
    });

    test('PlayerData parses legacy keys and numeric faction ids', () {
      final p = PlayerData.fromMap({
        'faction': 3,
        'bankBalance': 1450.0,
        'isEliminated': false,
        'factors': {
          'sustainability': 11,
          'smart': 12,
          'livability': 13,
          'economy': 14,
        },
      }, FactionType.natural);

      expect(p.faction, FactionType.technological);
      expect(p.bankBalance, 1450);
      expect(p.metrics.smart, 12);
    });
  });
}
