import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';

Color _colorForToken(String ticker) {
  switch (ticker.toUpperCase()) {
    case 'WAGUS':
      return const Color.fromARGB(255, 106, 185, 212); // Light blue
    case 'SUGAW':
      return const Color.fromARGB(255, 255, 0, 0); // Yellow
    case 'SOL':
      return const Color(0xFFFFA726); // Orange
    case 'LUX':
      return const Color.fromARGB(255, 154, 61, 61); // Teal
    case 'BONK':
      return const Color.fromARGB(255, 247, 255, 129); // Pink
    case 'BUCKAZOIDS':
      return const Color.fromARGB(255, 241, 176, 24); // Purple
    case 'PAWS':
      return const Color.fromARGB(255, 44, 44, 44); // Green
    case 'SAMU':
      return const Color.fromARGB(255, 243, 214, 171); // Red
    default:
      return const Color(0xFF757575); // Grey for unknowns
  }
}

class AllocationBar extends StatelessWidget {
  final bool isCurrentUser;

  const AllocationBar({super.key, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    final holdersMap = context.read<PortalBloc>().state.holdersMap ?? {};

    if (isCurrentUser &&
        (context.read<PortalBloc>().state.holdersMap?.isEmpty ?? true)) {
      context.read<PortalBloc>().add(PortalListenSupportedTokensEvent());
    }

    if (holdersMap.isEmpty) return const SizedBox();

    final allocations = holdersMap.entries.map((e) {
      final token = e.key;
      final holder = e.value;
      return {
        'label': token,
        'value': holder.tokenAmount + holder.solanaAmount,
        'color': _colorForToken(token),
      };
    }).toList();

    final total =
        allocations.fold(0.0, (sum, item) => sum + (item['value'] as double));

    if (total == 0) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Wallet Allocation',
            style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: List.generate(allocations.length, (index) {
                final entry = allocations[index];
                final widthFactor = (entry['value'] as double) / total;

                return Expanded(
                  flex: (widthFactor * 1000).round(),
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: entry['color'] as Color,
                      gradient: LinearGradient(
                        colors: [
                          (entry['color'] as Color).withOpacity(0.8),
                          (entry['color'] as Color).withOpacity(1.0),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: allocations.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: entry['color'] as Color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${entry['label']} ${(entry['value'] as double).toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
