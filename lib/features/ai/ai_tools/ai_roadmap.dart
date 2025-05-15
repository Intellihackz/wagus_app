import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/features/ai/bloc/ai_bloc.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
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

    return BlocSelector<PortalBloc, PortalState, TierStatus>(
      selector: (state) {
        return state.tierStatus;
      },
      builder: (context, portalState) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      BackButton(color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'AI Roadmap Generator',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    label: 'Project Name',
                    controller: nameController,
                    validator: (val) => val == null || val.isEmpty
                        ? 'Please enter a project name'
                        : null,
                    context: context,
                    tierStatus: portalState,
                  ),
                  _buildInputField(
                    label: 'Key Milestones',
                    controller: milestonesController,
                    validator: (val) => val == null || val.isEmpty
                        ? 'Please enter key milestones'
                        : null,
                    context: context,
                    tierStatus: portalState,
                  ),
                  _buildInputField(
                    label: 'Expected Duration (e.g. 6 months)',
                    controller: durationController,
                    validator: (val) => val == null || val.isEmpty
                        ? 'Please enter a time duration'
                        : null,
                    context: context,
                    tierStatus: portalState,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: portalState == TierStatus.adventurer
                            ? TierStatus.adventurer.color
                            : TierStatus.basic.color,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        if (formKey.currentState!.validate()) {
                          _handleGenerate(
                              context,
                              nameController,
                              milestonesController,
                              durationController,
                              portalState);
                        }
                      },
                      child: const Text('Generate Roadmap'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required BuildContext context,
    required TierStatus tierStatus,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.grey[850],
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: tierStatus == TierStatus.adventurer
                  ? TierStatus.adventurer.color
                  : TierStatus.basic.color,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: tierStatus == TierStatus.adventurer
                    ? TierStatus.adventurer.color
                    : TierStatus.basic.color),
          ),
        ),
      ),
    );
  }

  void _handleGenerate(
    BuildContext context,
    TextEditingController nameController,
    TextEditingController milestonesController,
    TextEditingController durationController,
    TierStatus tierStatus,
  ) {
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

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocSelector<PortalBloc, PortalState, TierStatus>(
          selector: (state) {
            return state.tierStatus;
          },
          builder: (context, state) {
            return BlocBuilder<AiBloc, AiState>(
              builder: (context, state) {
                return AlertDialog(
                  backgroundColor: Colors.black,
                  title: const Text(
                    'Generated Roadmap',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 400,
                    child: _buildDialogContent(state, context, tierStatus),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.read<AiBloc>().add(AIResetStateEvent());
                      },
                      child: const Text('Close',
                          style: TextStyle(color: Colors.white)),
                    ),
                    if (state.roadmapFormState == AIRoadmapFormState.success)
                      TextButton(
                        onPressed: () async {
                          final pdf = pw.Document();
                          pdf.addPage(
                            pw.Page(
                              build: (context) => pw.Text(
                                state.roadmap!,
                                style: const pw.TextStyle(
                                    fontSize: 12, lineSpacing: 1.5),
                              ),
                            ),
                          );
                          final dir = await getApplicationDocumentsDirectory();
                          final filePath =
                              '${dir.path}/roadmap_${DateTime.now().millisecondsSinceEpoch}.pdf';
                          final file = File(filePath);
                          await file.writeAsBytes(await pdf.save());
                          await Share.shareXFiles([XFile(filePath)]);
                        },
                        child:
                            BlocSelector<PortalBloc, PortalState, TierStatus>(
                          selector: (state) {
                            return state.tierStatus;
                          },
                          builder: (context, state) {
                            return Text('Save as PDF',
                                style: TextStyle(
                                  color: state == TierStatus.adventurer
                                      ? TierStatus.adventurer.color
                                      : TierStatus.basic.color,
                                ));
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDialogContent(
      AiState state, BuildContext context, TierStatus tierStatus) {
    if (state.roadmapFormState == AIRoadmapFormState.loading) {
      return Center(
          child: CircularProgressIndicator(
        color: tierStatus == TierStatus.adventurer
            ? TierStatus.adventurer.color
            : TierStatus.basic.color,
      ));
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
            color: context.appColors.contrastLight,
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
