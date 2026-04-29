import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../protocol.dart';

class TradeDrawer extends StatefulWidget {
  const TradeDrawer({super.key});

  @override
  State<TradeDrawer> createState() => _TradeDrawerState();
}

class _TradeDrawerState extends State<TradeDrawer> {
  bool _showOwnership = false;
  PlayerData? _selectedOpponent;
  final TextEditingController _amountController = TextEditingController();

  void _sendTrade(GameStateProvider gs) {
    if (_selectedOpponent == null) return;
    final selected = _selectedOpponent!;
    final amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || amount > gs.bankBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount or insufficient funds.')),
      );
      return;
    }

    final msg = ProtocolMessage(
      type: MessageType.actionTransferFunds,
      payload: gs.transferFundsPayload(
        targetFaction: selected.faction,
        targetDeviceId: selected.deviceId,
        amount: amount,
      ),
    );
    
    gs.network.sendMessage(msg.toJsonString());
    _amountController.clear();
    setState(() {
      _selectedOpponent = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transferred ¤$amount to ${selected.faction.displayName}')),
    );
    
    Navigator.of(context).pop(); // Close drawer
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameStateProvider>(
      builder: (context, gs, _) {
        final opponents = gs.opponents;
        final me = gs.myPlayerData;

        return Drawer(
          backgroundColor: const Color(0xFF121A23),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white.withValues(alpha: 0.05),
                  child: const Text(
                    'PLAYERS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Trade'),
                        icon: Icon(Icons.swap_horiz_rounded),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Ownership'),
                        icon: Icon(Icons.inventory_2_rounded),
                      ),
                    ],
                    selected: {_showOwnership},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _showOwnership = selection.first;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _showOwnership
                      ? _buildOwnershipView(gs, me, opponents)
                      : opponents.isEmpty
                      ? const Center(
                          child: Text(
                            'No opponents found.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          itemCount: opponents.length,
                          itemBuilder: (context, index) {
                            final opp = opponents[index];
                            final isSelected = _selectedOpponent == opp;

                            return ListTile(
                              leading: Icon(
                                opp.faction.icon,
                                color: opp.faction.color,
                              ),
                              title: Text(
                                opp.faction.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                opp.isEliminated
                                    ? 'ELIMINATED'
                                    : 'Bank: ¤${opp.bankBalance}',
                                style: TextStyle(
                                  color: opp.isEliminated
                                      ? Colors.redAccent
                                      : Colors.white70,
                                ),
                              ),
                              tileColor: isSelected
                                  ? opp.faction.color.withValues(alpha: 0.2)
                                  : null,
                              onTap: opp.isEliminated
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedOpponent = opp;
                                      });
                                    },
                            );
                          },
                        ),
                ),
                if (!_showOwnership) ...[
                  const Divider(color: Colors.white24, height: 1),
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _selectedOpponent == null
                              ? 'Select an opponent to trade'
                              : 'Trading with ${_selectedOpponent!.faction.displayName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          enabled: _selectedOpponent != null,
                          decoration: InputDecoration(
                            labelText: 'Amount (Max ¤${gs.bankBalance})',
                            labelStyle: const TextStyle(color: Colors.white54),
                            border: const OutlineInputBorder(),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _selectedOpponent == null
                              ? null
                              : () => _sendTrade(gs),
                          icon: const Icon(Icons.send_rounded),
                          label: const Text('Transfer Funds'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildOwnershipView(
    GameStateProvider gs,
    PlayerData? me,
    List<PlayerData> opponents,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => gs.requestOwnershipState(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh from server'),
          ),
        ),
        _ownershipCard(
          title: me == null ? 'You' : 'You (${me.faction.displayName})',
          items: me?.ownedItems ?? const [],
          color: me?.faction.color ?? Colors.white70,
        ),
        const SizedBox(height: 10),
        for (final opp in opponents) ...[
          _ownershipCard(
            title: opp.faction.displayName,
            items: opp.ownedItems,
            color: opp.faction.color,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _ownershipCard({
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('No items yet', style: TextStyle(color: Colors.white54))
          else
            Text(
              items.join(', '),
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
        ],
      ),
    );
  }
}
