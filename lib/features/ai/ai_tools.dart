import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/routing/router.dart';

class AITools extends StatelessWidget {
  const AITools({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      {
        'icon': Icons.analytics,
        'title': 'AI Analysis Prediction',
        'tagline': 'Forecast trends and market behavior.',
        'route': aiAnalysisPrediction,
      },
      {
        'icon': Icons.image,
        'title': 'AI Image Generation',
        'tagline': 'Turn text into stunning visuals.',
        'route': aiImageGeneration,
      },
      {
        'icon': Icons.description,
        'title': 'AI White Paper Generator',
        'tagline': 'Craft polished whitepapers in seconds.',
        'route': aiWhitePaperGeneration,
      },
      {
        'icon': Icons.map,
        'title': 'AI Roadmap Generator',
        'tagline': 'Strategically plan your project milestones.',
        'route': aiRoadmapGeneration,
      },
      {
        'icon': Icons.pie_chart,
        'title': 'AI Tokenomics Generator',
        'tagline': 'Design sustainable crypto economies.',
        'route': aiTokenomicsGeneration,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.only(top: 64.0, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Tools',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: tools.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final tool = tools[index];
                  return InkWell(
                    onTap: () {
                      final tier = context.read<PortalBloc>().state.tierStatus;
                      final gatedRoutes = [
                        aiWhitePaperGeneration,
                        aiRoadmapGeneration,
                        aiTokenomicsGeneration,
                      ];

                      final route = tool['route'] as String;
                      if (gatedRoutes.contains(route) &&
                          tier != TierStatus.adventurer) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Adventurer tier required to access this tool."),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      } else {
                        context.push(route);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: BlocSelector<PortalBloc, PortalState, TierStatus>(
                      selector: (state) {
                        return state.tierStatus;
                      },
                      builder: (context, state) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            border: Border.all(
                              color: state == TierStatus.adventurer
                                  ? TierStatus.adventurer.color
                                  : TierStatus.basic.color,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BlocSelector<PortalBloc, PortalState, TierStatus>(
                                selector: (state) {
                                  return state.tierStatus;
                                },
                                builder: (context, state) {
                                  return Icon(
                                    tool['icon'] as IconData,
                                    size: 20,
                                    color: state == TierStatus.adventurer
                                        ? TierStatus.adventurer.color
                                        : TierStatus.basic.color,
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tool['title'] as String,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tool['tagline'] as String,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white60,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
