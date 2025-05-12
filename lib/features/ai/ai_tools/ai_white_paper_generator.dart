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

    void handleGenerate(BuildContext context) {
      showDialog(
        context: context,
        builder: (dialogContext) => BlocBuilder<AiBloc, AiState>(
          builder: (context, state) {
            return AlertDialog(
              backgroundColor: Colors.black,
              title: const Text(
                'Generated White Paper',
                style: TextStyle(color: Colors.white),
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
                    context.read<AiBloc>().add(AIResetStateEvent());
                  },
                  child: const Text('Close',
                      style: TextStyle(color: Colors.white)),
                ),
                if (state.whitePaperFormState == AIWhitePaperFormState.success)
                  TextButton(
                    onPressed: () async {
                      await _saveAndSharePDF(context, state.whitePaper!);
                    },
                    child: const Text('Save as PDF',
                        style: TextStyle(color: Colors.greenAccent)),
                  ),
              ],
            );
          },
        ),
      );

      context.read<AiBloc>().add(AISubmitWhitePaperFormEvent(
            projectName: projectNameController.text,
            projectDescription: projectDescriptionController.text,
            projectPurpose: projectPurposeController.text,
            projectType: projectTypeController.text,
            projectContributors: projectContributorsController.text,
          ));

      projectNameController.clear();
      projectDescriptionController.clear();
      projectPurposeController.clear();
      projectTypeController.clear();
      projectContributorsController.clear();
    }

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
                    'AI White Paper Generator',
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
                controller: projectNameController,
                validator: (val) => val == null || val.isEmpty
                    ? 'Please enter a project name'
                    : null,
                context: context,
              ),
              _buildInputField(
                label: 'Project Description',
                controller: projectDescriptionController,
                validator: (val) => val == null || val.isEmpty
                    ? 'Please enter a project description'
                    : null,
                context: context,
              ),
              _buildInputField(
                label: 'Project Purpose',
                controller: projectPurposeController,
                validator: (val) => val == null || val.isEmpty
                    ? 'Please enter a project purpose'
                    : null,
                context: context,
              ),
              _buildInputField(
                label: 'Project Type',
                controller: projectTypeController,
                validator: (val) => val == null || val.isEmpty
                    ? 'Please enter a project type'
                    : null,
                context: context,
              ),
              _buildInputField(
                label: 'Project Contributors',
                controller: projectContributorsController,
                validator: (val) => val == null || val.isEmpty
                    ? 'Please enter the project contributors'
                    : null,
                context: context,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    if (formKey.currentState!.validate()) {
                      handleGenerate(context);
                    }
                  },
                  child: const Text('Generate White Paper'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required BuildContext context,
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
            borderSide: const BorderSide(color: Colors.greenAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.green),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogContent(AiState state, BuildContext context) {
    if (state.whitePaperFormState == AIWhitePaperFormState.loading) {
      return const Center(
          child: CircularProgressIndicator(
        color: Colors.greenAccent,
      ));
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
            color: context.appColors.contrastLight,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      );
    } else {
      return const Center(child: Text('Generating white paper...'));
    }
  }

  Future<void> _saveAndSharePDF(BuildContext context, String content) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Text(
              content,
              style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
            );
          },
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          '${dir.path}/whitepaper_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);

      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles([XFile(filePath)]);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('White paper saved and shared')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving PDF: $e')),
        );
      }
    }
  }
}
