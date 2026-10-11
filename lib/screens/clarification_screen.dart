import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/clarification_question.dart';

class ClarificationScreen extends StatefulWidget {
  const ClarificationScreen({super.key});

  @override
  State<ClarificationScreen> createState() => _ClarificationScreenState();
}

class _ClarificationScreenState extends State<ClarificationScreen> {
  int _index = 0;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final questions = state.lastAnalyse?.questions ?? [];
    if (questions.isEmpty) {
      return const Scaffold(body: Center(child: Text('Nothing to clarify')));
    }

    final q = questions[_index.clamp(0, questions.length - 1)];
    final answered = state.clarificationAnswers[q.id]?.isNotEmpty == true;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          'Quick check ${_index + 1} of ${questions.length}',
          style: AppText.label(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ClarificationQuestionCard(
                key: ValueKey(q.id),
                question: q,
                initialAnswer: state.clarificationAnswers[q.id],
                onAnswered: (value) =>
                    state.answerClarification(q.id, value),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: !answered || _submitting
                      ? null
                      : () async {
                          if (_index < questions.length - 1) {
                            setState(() => _index += 1);
                            return;
                          }
                          setState(() => _submitting = true);
                          await state.finalizeScanAndGenerate();
                          if (!context.mounted) return;
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    disabledBackgroundColor: AppColors.greenSoft,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _index < questions.length - 1
                        ? 'Continue'
                        : (_submitting ? 'Creating recipes…' : 'Find recipes'),
                    style: AppText.button(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
