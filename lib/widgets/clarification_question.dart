import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ClarificationQuestionCard extends StatefulWidget {
  const ClarificationQuestionCard({
    super.key,
    required this.question,
    required this.onAnswered,
    this.initialAnswer,
  });

  final ClarificationQuestion question;
  final ValueChanged<String> onAnswered;
  final String? initialAnswer;

  @override
  State<ClarificationQuestionCard> createState() =>
      _ClarificationQuestionCardState();
}

class _ClarificationQuestionCardState extends State<ClarificationQuestionCard> {
  String? selected;
  final _otherController = TextEditingController();
  bool otherMode = false;

  @override
  void initState() {
    super.initState();
    selected = widget.initialAnswer;
    if (selected != null &&
        !widget.question.options.contains(selected)) {
      otherMode = true;
      _otherController.text = selected!;
    }
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.question.prompt, style: AppText.title(fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            'A quick check so we get this right.',
            style: AppText.body(),
          ),
          const SizedBox(height: 20),
          ...widget.question.options.map((option) {
            final isSelected = selected == option && !otherMode;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: isSelected ? AppColors.sageMuted : AppColors.cream,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      otherMode = false;
                      selected = option;
                    });
                    widget.onAnswered(option);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: AppColors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(option, style: AppText.label(fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          if (widget.question.allowOther) ...[
            Material(
              color: otherMode ? AppColors.sageMuted : AppColors.cream,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => otherMode = true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        otherMode
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: AppColors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text('Other', style: AppText.label(fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
            if (otherMode) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _otherController,
                decoration: InputDecoration(
                  hintText: 'Type your answer',
                  filled: true,
                  fillColor: AppColors.cream,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  selected = value;
                  widget.onAnswered(value);
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}
