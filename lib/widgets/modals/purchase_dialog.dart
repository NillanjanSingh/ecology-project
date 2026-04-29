import 'package:flutter/material.dart';

/// Modal dialog shown when ESP32 sends a prompt_purchase message.
class PurchaseDialog extends StatelessWidget {
  final String infrastructureName;
  final String description;
  final int providerCost;
  final int? takerCost;
  final bool providerAvailable;
  final bool takerAvailable;
  final bool isOwned;
  final String? ownerFaction;
  final int currentBalance;
  final Map<String, dynamic> effects;
  final VoidCallback onRefreshOwnership;
  final ValueChanged<String> onAction;

  const PurchaseDialog({
    super.key,
    required this.infrastructureName,
    this.description = '',
    required this.providerCost,
    this.takerCost,
    this.providerAvailable = true,
    this.takerAvailable = true,
    this.isOwned = false,
    this.ownerFaction,
    required this.currentBalance,
    this.effects = const {},
    required this.onRefreshOwnership,
    required this.onAction,
  });

  bool get canAffordProvider =>
      providerAvailable && currentBalance >= providerCost;
  bool get canAffordTaker =>
      takerAvailable && takerCost != null && currentBalance >= takerCost!;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 380,
              maxHeight: constraints.maxHeight * 0.9,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A2332), Color(0xFF0D1520)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2A3A4E), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_rounded,
                        color: Color(0xFF42A5F5),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'INFRASTRUCTURE AVAILABLE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Color(0xFF64B5F6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      infrastructureName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                    if (isOwned) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCA28).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFFFCA28).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          ownerFaction == null
                              ? 'Already provider-owned'
                              : 'Already provider-owned by $ownerFaction',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFFCA28),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Cost vs Balance
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statColumn(
                            'PROVIDER',
                            '¤$providerCost',
                            const Color(0xFFEF5350),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          _statColumn(
                            'BALANCE',
                            '¤$currentBalance',
                            canAffordProvider
                                ? const Color(0xFF66BB6A)
                                : const Color(0xFFEF5350),
                          ),
                        ],
                      ),
                    ),
                    // Effects
                    if (effects.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: effects.entries.map((e) {
                          final val = e.value;
                          final positive = val is num && val > 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (positive
                                          ? const Color(0xFF66BB6A)
                                          : const Color(0xFFEF5350))
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${positive ? "+" : ""}$val ${e.key}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: positive
                                    ? const Color(0xFF66BB6A)
                                    : const Color(0xFFEF5350),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => onAction('skip'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'SKIP',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: canAffordProvider
                                ? () => onAction('provider')
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              disabledBackgroundColor: Colors.grey.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              providerAvailable
                                  ? (canAffordProvider
                                        ? 'PROVIDER'
                                        : 'CAN\'T AFFORD')
                                  : 'PROVIDER UNAVAILABLE',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (takerCost != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: canAffordTaker
                              ? () => onAction('taker')
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7CB342),
                            disabledBackgroundColor: Colors.grey.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            takerAvailable
                                ? 'TAKER (¤$takerCost)'
                                : 'TAKER UNAVAILABLE',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onRefreshOwnership,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh from server'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
