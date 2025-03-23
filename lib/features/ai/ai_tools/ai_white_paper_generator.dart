import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/theme/app_palette.dart';

class AiWhitePaperGenerator extends HookWidget {
  const AiWhitePaperGenerator({super.key});

  @override
  Widget build(BuildContext context) {
    final projectNameController = useTextEditingController();
    final projectDescriptionController = useTextEditingController();
    final projectPurposeController = useTextEditingController();
    final projectTypeController = useTextEditingController();
    final projectContributorsController = useTextEditingController();

    // Create a form that includes all the text fields that will be vaildated when submitted
    final formKey = useMemoized(() => GlobalKey<FormState>());

    return Scaffold(
      body: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16,
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
                    labelStyle:
                        TextStyle(color: context.appColors.contrastLight)),
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
                    labelStyle: TextStyle(color: AppPalette.contrastLight)),
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
                    labelStyle: TextStyle(color: AppPalette.contrastLight)),
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
                    labelStyle: TextStyle(color: AppPalette.contrastLight)),
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
                    labelStyle: TextStyle(color: AppPalette.contrastLight)),
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
                      // Process data
                      print('Generating white paper...');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Generate White Paper'))
            ],
          ),
        ),
      ),
    );
  }
}
