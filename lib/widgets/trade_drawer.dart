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
  PlayerData? _selectedOpponent;
  final TextEditingController _amountController = TextEditingController();

  void _sendTrade(GameStateProvider gs) {
    if (_selectedOpponent == null) return;
    
    final amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || amount > gs.bankBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount or insufficient funds.')),
      );
      return;
    }

    final msg = ProtocolMessage(
      type: MessageType.actionTransferFunds,
      payload: {
        'target_faction': _selectedOpponent!.faction.name,
        'amount': amount,
      },
    );
    
    gs.network.sendMessage(msg.toJsonString());
    _amountController.clear();
    setState(() {
      _selectedOpponent = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transferred ¤$amount to ${_selectedOpponent?.faction.displayName}')),
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
                    'OPPONENTS & TRADE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Expanded(
                  child: opponents.isEmpty
                      ? const Center(child: Text('No opponents found.', style: TextStyle(color: Colors.white54)))
                      : ListView.builder(
                          itemCount: opponents.length,
                          itemBuilder: (context, index) {
                            final opp = opponents[index];
                            final isSelected = _selectedOpponent == opp;
                            
                            return ListTile(
                              leading: Icon(opp.faction.icon, color: opp.faction.color),
                              title: Text(opp.faction.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                opp.isEliminated ? 'ELIMINATED' : 'Bank: ¤${opp.bankBalance}',
                                style: TextStyle(color: opp.isEliminated ? Colors.redAccent : Colors.white70),
                              ),
                              tileColor: isSelected ? opp.faction.color.withValues(alpha: 0.2) : null,
                              onTap: opp.isEliminated ? null : () {
                                setState(() {
                                  _selectedOpponent = opp;
                                });
                              },
                            );
                          },
                        ),
                ),
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
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _selectedOpponent == null ? null : () => _sendTrade(gs),
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
            ),
          ),
        );
      }
    );
  }
}
