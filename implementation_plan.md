# Smart City Board Game Frontend Implementation

This document outlines the step-by-step plan to transform the current foundational Flutter application (which establishes a WebSocket connection and logs messages) into the fully functional "Mayor's Terminal" as specified in the Master Design Document.


> **State Ownership**: ESP32 sends the calculated metrics; Flutter mostly visualizes it.
> **Player Identification**: ESP32 assigns a role upon connection.

---

## Proposed Changes

### Phase 1: Dependencies & Data Models

Add necessary packages for state management and visualization, and create Dart classes to represent the game's data.

#### [MODIFY] pubspec.yaml
Add dependencies for charting and state management.
```yaml
dependencies:
  flutter:
    sdk: flutter
  web_socket_channel: ^3.0.1
  multicast_dns: ^0.3.2+6
  fl_chart: ^0.68.0   # For the Radar Chart
  provider: ^6.1.1    # For State Management
```

#### [NEW] lib/models/game_state.dart
Define the data structures matching the Master Design Document.
```dart
enum FactionType { naturalResources, software, industrial, financial }

class PlayerMetrics {
  final double sustainability;
  final double smart;
  final double livability;
  final double economy;
  final int bankBalance;
  final int totalScore;

  PlayerMetrics({
    required this.sustainability,
    required this.smart,
    required this.livability,
    required this.economy,
    required this.bankBalance,
    required this.totalScore,
  });
}

class ActiveCard {
  final String name;
  final String type; // Disaster, Policy, Event
  final int remainingLaps;

  ActiveCard({required this.name, required this.type, required this.remainingLaps});
}
```

---

### Phase 2: Protocol Extensions

Update the communication layer to handle specific game events like purchasing and state syncing.

#### [MODIFY] COMMUNICATION_PROTOCOL.md
Document the new message types:
- `sync_state`: ESP32 sends updated metrics and bank balance to the app.
- `purchase_prompt`: ESP32 asks the app if the player wants to buy an infrastructure tile.
- `purchase_response`: App tells the ESP32 "Buy" or "Skip".
- `card_decision_prompt`: ESP32 asks for Choice A or Choice B on a Policy/Event card.
- `card_decision_response`: App sends the selected choice back.

#### [MODIFY] lib/protocol.dart
Add the new `MessageType` enum values and corresponding payload classes.
```dart
enum MessageType {
  rfid,
  encoder,
  gameState, // Global state
  syncState, // Specific player metrics update
  purchasePrompt,
  purchaseResponse,
  cardDecisionPrompt,
  cardDecisionResponse,
  unknown
}
// Add payload parsers for these new types.
```

---

### Phase 3: Core UI Framework (Mayor's Terminal)

Transform `GamePage` from a message logger into the actual dashboard.

#### [MODIFY] lib/pages/game_page.dart
Refactor the UI to use the `Provider` for state and build out the distinct sections.
- **Header**: Display Faction Name and Bank Balance.
- **Progression Bar**: Track Total Score towards the 4,000-point Ascension goal.
- **Body Layout**: Use a `Column` or `CustomScrollView` to hold the Radar Chart and Status Log.

#### [NEW] lib/widgets/radar_chart_widget.dart
Implement the `fl_chart` Radar Chart to visualize the 4 main Factors (Sustainability, Smart, Livability, Economy).
```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MetricsRadarChart extends StatelessWidget {
  final PlayerMetrics metrics;
  // Use fl_chart's RadarChart widget to map the 4 properties
}
```

#### [NEW] lib/widgets/status_log.dart
A `ListView` displaying the active Disasters and Policies with their lap countdowns.

---

### Phase 4: Interaction Modals

Create the dialogs that pop up when the ESP32 sends a prompt.

#### [NEW] lib/widgets/modals/purchase_dialog.dart
A dialog shown when `purchase_prompt` is received.
```dart
class PurchaseDialog extends StatelessWidget {
  final String infrastructureName;
  final int cost;
  final VoidCallback onBuy;
  final VoidCallback onSkip;
  
  // UI showing cost vs current bank balance, with Buy/Skip buttons
}
```

#### [NEW] lib/widgets/modals/card_decision_dialog.dart
A dialog shown for Policy and Event-1 cards requiring an A/B choice.
```dart
class CardDecisionDialog extends StatelessWidget {
  final String cardTitle;
  final String choiceA;
  final String choiceB;
  final Function(String) onChoiceSelected;
  
  // UI showing the choices
}
```

## Verification Plan

### Automated Verification
- Run `flutter analyze` to ensure code syntax is correct.
- Write simple widget tests for `MetricsRadarChart` to verify it renders with dummy data without crashing.

### Manual Verification
- Modify the `_sendTestMessage` in `GamePage` to simulate incoming `sync_state`, `purchase_prompt`, and `card_decision_prompt` JSON messages from the ESP32.
- Verify the UI updates the Radar Chart and Bank Balance correctly.
- Verify the modals pop up and send the correct structured JSON back to the `NetworkManager`.
