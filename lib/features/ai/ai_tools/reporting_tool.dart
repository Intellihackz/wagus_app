import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/features/ai/bloc/ai_bloc.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/core/theme/app_palette.dart';

class ReportFloatingButton extends HookWidget {
  const ReportFloatingButton(
      {super.key, required this.aiGeneratedText, required this.aiState});

  final String aiGeneratedText;
  final AiState aiState;

  @override
  Widget build(BuildContext context) {
    final reasonController = useTextEditingController();
    final contentController = useTextEditingController();

    useEffect(() {
      contentController.text = aiGeneratedText;
      return null;
    }, [aiState]);

    return FloatingActionButton(
      tooltip: 'Report Content',
      child: const Icon(Icons.flag),
      onPressed: () =>
          _showReportDialog(context, reasonController, contentController),
    );
  }

  void _showReportDialog(
      BuildContext context,
      TextEditingController reasonController,
      TextEditingController contentController) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Report Content',
            style: TextStyle(color: context.appColors.contrastDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                  labelText: 'Reason (e.g., spam, inappropriate content)'),
              style: TextStyle(
                color: context.appColors.contrastDark,
              ),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Reported Content'),
              maxLines: 3,
              style: TextStyle(
                color: context.appColors.contrastDark,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Submit'),
            onPressed: () async {
              if (contentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cannot report empty content.')),
                );
                return;
              }

              final uid = context
                  .read<PortalBloc>()
                  .state
                  .user!
                  .embeddedSolanaWallets
                  .first
                  .address;
              await FirebaseFirestore.instance.collection('reports').add({
                'reason': reasonController.text.isEmpty
                    ? 'Other'
                    : reasonController.text,
                'content': contentController.text,
                'timestamp': FieldValue.serverTimestamp(),
                'userId': uid,
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted.')),
              );
            },
          ),
        ],
      ),
    );
  }
}
