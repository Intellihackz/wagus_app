import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/features/ai/bloc/ai_bloc.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AiRoadmapGenerator extends HookWidget {
  const AiRoadmapGenerator({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController();
    final milestonesController = useTextEditingController();
    final durationController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Stack(
              children: [
                const Positioned(
                  top: 32.0,
                  left: 0,
                  child: BackButton(color: AppPalette.contrastLight),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 100.0),
                  child: Column(
                    spacing: 16.0,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'AI Roadmap Generator',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      TextFormField(
                        onTapOutside: (_) {
                          FocusScope.of(context).unfocus();
                        },
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Project Name',
                          labelStyle:
                              TextStyle(color: AppPalette.contrastLight),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter a project name'
                            : null,
                      ),
                      TextFormField(
                        onTapOutside: (_) {
                          FocusScope.of(context).unfocus();
                        },
                        controller: milestonesController,
                        decoration: const InputDecoration(
                          labelText: 'Key Milestones',
                          labelStyle:
                              TextStyle(color: AppPalette.contrastLight),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter key milestones'
                            : null,
                      ),
                      TextFormField(
                        onTapOutside: (_) {
                          FocusScope.of(context).unfocus();
                        },
                        controller: durationController,
                        decoration: const InputDecoration(
                          labelText: 'Expected Duration (e.g. 6 months)',
                          labelStyle:
                              TextStyle(color: AppPalette.contrastLight),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter a time duration'
                            : null,
                      ),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          if (formKey.currentState!.validate()) {
                            showDialog(
                              context: context,
                              builder: (dialogContext) {
                                return BlocBuilder<AiBloc, AiState>(
                                  builder: (context, state) {
                                    return AlertDialog(
                                      title: Text(
                                        'Generated Roadmap',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: context.appColors.contrastDark,
                                        ),
                                      ),
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        height: 400,
                                        child:
                                            _buildDialogContent(state, context),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(dialogContext).pop();
                                            context
                                                .read<AiBloc>()
                                                .add(AIResetStateEvent());
                                          },
                                          child: const Text('Close'),
                                        ),
                                        if (state.roadmapFormState ==
                                            AIRoadmapFormState.success)
                                          TextButton(
                                            onPressed: () async {
                                              try {
                                                final pdf = pw.Document();
                                                pdf.addPage(
                                                  pw.Page(
                                                    build: (context) => pw.Text(
                                                      state.roadmap!,
                                                      style: pw.TextStyle(
                                                        fontSize: 12,
                                                        lineSpacing: 1.5,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                                final dir =
                                                    await getApplicationDocumentsDirectory();
                                                final filePath =
                                                    '${dir.path}/roadmap_${DateTime.now().millisecondsSinceEpoch}.pdf';
                                                final file = File(filePath);
                                                await file.writeAsBytes(
                                                    await pdf.save());
                                                await Share.shareXFiles(
                                                    [XFile(filePath)]);
                                              } catch (e) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Error saving roadmap: $e'),
                                                  ),
                                                );
                                              }
                                            },
                                            child: const Text('Save as PDF'),
                                          ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );

                            context.read<AiBloc>().add(
                                  AISubmitRoadmapFormEvent(
                                    projectName: nameController.text,
                                    milestones: milestonesController.text,
                                    duration: durationController.text,
                                  ),
                                );

                            nameController.clear();
                            milestonesController.clear();
                            durationController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Generate Roadmap'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogContent(AiState state, BuildContext context) {
    if (state.roadmapFormState == AIRoadmapFormState.loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state.roadmapFormState == AIRoadmapFormState.failure) {
      return Center(
        child: Text(
          state.errorMessage ?? 'Failed to generate roadmap',
          style: const TextStyle(color: Colors.red),
        ),
      );
    } else if (state.roadmap != null) {
      return SingleChildScrollView(
        child: Text(
          state.roadmap!,
          style: TextStyle(
            color: context.appColors.contrastDark,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      );
    } else {
      return Center(
          child: Text('Generating roadmap...',
              style: TextStyle(color: context.appColors.contrastDark)));
    }
  }
}
