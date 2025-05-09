import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/features/ai/bloc/ai_bloc.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AiTokenomicsGenerator extends HookWidget {
  const AiTokenomicsGenerator({super.key});

  @override
  Widget build(BuildContext context) {
    final projectNameController = useTextEditingController();
    final tokenSupplyController = useTextEditingController();
    final tokenUtilityController = useTextEditingController();
    final tokenDistributionController = useTextEditingController();
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
                        'AI Tokenomics Generator',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextFormField(
                        onTapOutside: (_) {
                          FocusScope.of(context).unfocus();
                        },
                        controller: projectNameController,
                        decoration: const InputDecoration(
                          labelText: 'Project Name',
                          labelStyle:
                              TextStyle(color: AppPalette.contrastLight),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter project name'
                            : null,
                      ),
                      TextFormField(
                        onTapOutside: (_) {
                          FocusScope.of(context).unfocus();
                        },
                        controller: tokenSupplyController,
                        decoration: const InputDecoration(
                          labelText: 'Total Token Supply',
                          labelStyle:
                              TextStyle(color: AppPalette.contrastLight),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter token supply'
                            : null,
                      ),
                      TextFormField(
                        onTapOutside: (_) {
                          FocusScope.of(context).unfocus();
                        },
                        controller: tokenUtilityController,
                        decoration: const InputDecoration(
                          labelText: 'Token Utility',
                          labelStyle:
                              TextStyle(color: AppPalette.contrastLight),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter token utility'
                            : null,
                      ),
                      TextFormField(
                        onTapOutside: (_) {
                          FocusScope.of(context).unfocus();
                        },
                        controller: tokenDistributionController,
                        decoration: const InputDecoration(
                          labelText: 'Token Distribution',
                          labelStyle:
                              TextStyle(color: AppPalette.contrastLight),
                          hintText:
                              'Example: 30% Public Sale, 25% Ecosystem, 20% Team, 15% Treasury, 10% Advisors',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter token distribution'
                            : null,
                        maxLines: 2,
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
                                        'Generated Tokenomics',
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
                                        if (state.tokenomicsFormState ==
                                            AITokenomicsFormState.success)
                                          TextButton(
                                            onPressed: () async {
                                              try {
                                                final pdf = pw.Document();
                                                pdf.addPage(
                                                  pw.Page(
                                                    build: (context) => pw.Text(
                                                      state.tokenomics!,
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
                                                    '${dir.path}/tokenomics_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
                                                        'Error saving tokenomics: $e'),
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
                                  AISubmitTokenomicsFormEvent(
                                    projectName: projectNameController.text,
                                    tokenSupply: tokenSupplyController.text,
                                    tokenUtility: tokenUtilityController.text,
                                    tokenDistribution:
                                        tokenDistributionController.text,
                                  ),
                                );

                            projectNameController.clear();
                            tokenSupplyController.clear();
                            tokenUtilityController.clear();
                            tokenDistributionController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Generate Tokenomics'),
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
    if (state.tokenomicsFormState == AITokenomicsFormState.loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state.tokenomicsFormState == AITokenomicsFormState.failure) {
      return Center(
        child: Text(
          state.errorMessage ?? 'Failed to generate tokenomics',
          style: const TextStyle(color: Colors.red),
        ),
      );
    } else if (state.tokenomics != null) {
      return SingleChildScrollView(
        child: Text(
          state.tokenomics!,
          style: TextStyle(
            color: context.appColors.contrastDark,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      );
    } else {
      return Center(
          child: Text('Generating tokenomics...',
              style: TextStyle(color: context.appColors.contrastDark)));
    }
  }
}
