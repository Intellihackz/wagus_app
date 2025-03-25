import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/features/ai/bloc/ai_bloc.dart';
import 'package:wagus/features/ai/data/ai_repository.dart';
import 'package:wagus/theme/app_palette.dart';

class AIImageGeneration extends HookWidget {
  const AIImageGeneration({super.key});

  @override
  Widget build(BuildContext context) {
    final promptController = useTextEditingController();
    final promptFocusNode = useFocusNode();
    final isFocused = useState(false);

    useEffect(() {
      void onFocusChange() {
        isFocused.value = promptFocusNode.hasFocus;
        if (!promptFocusNode.hasFocus) {
          FocusScope.of(context).unfocus();
        }
      }

      promptFocusNode.addListener(onFocusChange);

      return null;
    }, []);

    return PopScope(
      onPopInvokedWithResult: (onPop, result) async {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.read<AiBloc>().add(AIResetStateEvent());
          }
        });
      },
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(
              left: 16.0, right: 16.0, top: 100.0, bottom: 64.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'AI Image Generation',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: BlocBuilder<AiBloc, AiState>(
                  builder: (context, state) {
                    return _buildImageContent(state, context, isFocused.value);
                  },
                ),
              ),
              TextField(
                focusNode: promptFocusNode,
                controller: promptController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Enter your prompt here',
                  labelStyle: TextStyle(color: context.appColors.contrastLight),
                  border: OutlineInputBorder(),
                ),
                onTapOutside: (_) {
                  FocusScope.of(context).unfocus();
                },
              ),
              if (context.read<AiBloc>().state.errorMessage != null &&
                  context.read<AiBloc>().state.imageGenerationState !=
                      AIImageGenerationState.loading)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    context.read<AiBloc>().state.errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                onPressed: context.read<AiBloc>().state.imageGenerationState ==
                        AIImageGenerationState.loading
                    ? null
                    : () {
                        final prompt = promptController.text.trim();
                        if (prompt.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please enter a prompt')),
                          );
                          return;
                        }
                        context
                            .read<AiBloc>()
                            .add(AIGenerateImageEvent(prompt));

                        promptController.clear();
                      },
                child: context.read<AiBloc>().state.imageGenerationState ==
                        AIImageGenerationState.loading
                    ? CircularProgressIndicator()
                    : Text('Generate Image'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(
      AiState state, BuildContext context, bool isFocused) {
    if (state.imageGenerationState == AIImageGenerationState.loading) {
      return Center(child: CircularProgressIndicator());
    } else if (state.imageGenerationState == AIImageGenerationState.failure) {
      return Center(
        child: Text(
          state.errorMessage ?? 'Failed to generate image',
          style: TextStyle(color: Colors.red),
        ),
      );
    } else if (state.imageUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.1),
              BlendMode.darken,
            ),
            child: Image.network(
              state.imageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                    child: SizedBox(
                        height: 32,
                        width: 32,
                        child: CircularProgressIndicator()));
              },
              errorBuilder: (context, error, stackTrace) {
                return Text('Failed to load image');
              },
            ),
          ),
          Visibility(
            visible:
                state.imageGenerationState == AIImageGenerationState.success &&
                    !isFocused,
            child: Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  Icons.download,
                  color: context.appColors.contrastLight,
                ),
                onPressed: () async {
                  final hasSaved = await context
                      .read<AIRepository>()
                      .saveImage(imageUrl: state.imageUrl!);
                  if (context.mounted) {
                    if (hasSaved) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Image saved')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save image')),
                      );
                    }
                  } else {
                    print('Context is not mounted');
                  }
                },
              ),
            ),
          ),
        ],
      );
    } else {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Generated Image will appear here',
          textAlign: TextAlign.center,
        ),
      ));
    }
  }
}
