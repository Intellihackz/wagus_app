import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/features/ai/bloc/ai_bloc.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AiWhitePaperGenerator extends HookWidget {
  const AiWhitePaperGenerator({super.key});

  @override
  Widget build(BuildContext context) {
    final projectNameController = useTextEditingController();
    final projectDescriptionController = useTextEditingController();
    final projectPurposeController = useTextEditingController();
    final projectTypeController = useTextEditingController();
    final projectContributorsController = useTextEditingController();

    final formKey = useMemoized(() => GlobalKey<FormState>());

    return Scaffold(
      body: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            spacing: 16.0,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'AI White Paper Generator',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: projectNameController,
                onTapOutside: (_) {
                  FocusScope.of(context).unfocus();
                },
                decoration: InputDecoration(
                  labelText: 'Project Name',
                  labelStyle: TextStyle(color: context.appColors.contrastLight),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a project name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: projectDescriptionController,
                onTapOutside: (_) {
                  FocusScope.of(context).unfocus();
                },
                decoration: const InputDecoration(
                  labelText: 'Project Description',
                  labelStyle: TextStyle(color: AppPalette.contrastLight),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a project description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: projectPurposeController,
                onTapOutside: (_) {
                  FocusScope.of(context).unfocus();
                },
                decoration: const InputDecoration(
                  labelText: 'Project Purpose',
                  labelStyle: TextStyle(color: AppPalette.contrastLight),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a project purpose';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: projectTypeController,
                onTapOutside: (_) {
                  FocusScope.of(context).unfocus();
                },
                decoration: const InputDecoration(
                  labelText: 'Project Type',
                  labelStyle: TextStyle(color: AppPalette.contrastLight),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a project type';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: projectContributorsController,
                onTapOutside: (_) {
                  FocusScope.of(context).unfocus();
                },
                decoration: const InputDecoration(
                  labelText: 'Project Contributors',
                  labelStyle: TextStyle(color: AppPalette.contrastLight),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the project contributors';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  if (formKey.currentState!.validate()) {
                    // Open the dialog immediately and handle loading inside it
                    showDialog(
                      context: context,
                      builder: (dialogContext) {
                        return BlocBuilder<AiBloc, AiState>(
                          builder: (context, state) {
                            return AlertDialog(
                              title: Text(
                                'Generated White Paper',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: context.appColors.contrastDark),
                              ),
                              content: SizedBox(
                                width: double.maxFinite,
                                height: 400,
                                child: _buildDialogContent(state, context),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    // Reset the state when closing the dialog
                                    context
                                        .read<AiBloc>()
                                        .add(AIResetStateEvent());
                                  },
                                  child: Text('Close'),
                                ),
                                if (state.whitePaperFormState ==
                                    AIWhitePaperFormState.success)
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        // Generate the PDF document
                                        final pdf = pw.Document();
                                        pdf.addPage(
                                          pw.Page(
                                            build: (pw.Context context) {
                                              return pw.Text(
                                                state.whitePaper!,
                                                style: pw.TextStyle(
                                                  fontSize: 12,
                                                  lineSpacing: 1.5,
                                                ),
                                              );
                                            },
                                          ),
                                        );

                                        // Get the documents directory to save the file
                                        final dir =
                                            await getApplicationDocumentsDirectory();
                                        final filePath =
                                            '${dir.path}/whitepaper_${DateTime.now().millisecondsSinceEpoch}.pdf';
                                        final file = File(filePath);

                                        // Save the PDF to the file
                                        final pdfBytes = await pdf.save();
                                        await file.writeAsBytes(pdfBytes);

                                        // Share the PDF using share_plus
                                        await Share.shareXFiles(
                                          [XFile(filePath)],
                                        );

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'White paper saved and shared'),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Error saving white paper as PDF: $e'),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: Text('Save as PDF'),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    );

                    // Dispatch the event to generate the white paper
                    context.read<AiBloc>().add(AISubmitWhitePaperFormEvent(
                          projectName: projectNameController.text,
                          projectDescription: projectDescriptionController.text,
                          projectPurpose: projectPurposeController.text,
                          projectType: projectTypeController.text,
                          projectContributors:
                              projectContributorsController.text,
                        ));

                    projectContributorsController.clear();
                    projectDescriptionController.clear();
                    projectPurposeController.clear();
                    projectTypeController.clear();
                    projectNameController.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Generate White Paper'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogContent(AiState state, BuildContext context) {
    if (state.whitePaperFormState == AIWhitePaperFormState.loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state.whitePaperFormState == AIWhitePaperFormState.failure) {
      return Center(
        child: Text(
          state.errorMessage ?? 'Failed to generate white paper',
          style: TextStyle(color: Colors.red),
        ),
      );
    } else if (state.whitePaper != null) {
      return SingleChildScrollView(
        child: Text(
          state.whitePaper!,
          style: TextStyle(
            color: context.appColors.contrastDark,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      );
    } else {
      return const Center(child: Text('Generating white paper...'));
    }
  }
}
