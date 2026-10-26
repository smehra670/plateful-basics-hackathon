import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

class CookModeScreen extends StatefulWidget {
  const CookModeScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<CookModeScreen> createState() => _CookModeScreenState();
}

class _CookModeScreenState extends State<CookModeScreen> {
  final _page = PageController();
  int _index = 0;
  Timer? _timer;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  int? _minutes(String step) {
    final match = RegExp(
      r'(\d+)\s*(minutes|minute|mins|min)',
      caseSensitive: false,
    ).firstMatch(step);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  void _startTimer(int minutes) {
    _timer?.cancel();
    setState(() => _remaining = minutes * 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining <= 1) {
        timer.cancel();
        setState(() => _remaining = 0);
        return;
      }
      setState(() => _remaining -= 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.recipe.instructions;
    final step = steps[_index];
    final minutes = _minutes(step);
    final clock = _remaining == 0
        ? null
        : '${_remaining ~/ 60}:${(_remaining % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppBar(
        title: Text(
          'Step ${_index + 1} of ${steps.length}',
          style: AppText.title(fontSize: 18),
        ),
      ),
      body: PageView.builder(
        controller: _page,
        itemCount: steps.length,
        onPageChanged: (i) => setState(() {
          _index = i;
          _timer?.cancel();
          _remaining = 0;
        }),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.recipe.title, style: AppText.caption()),
                const SizedBox(height: 16),
                Text(
                  steps[index],
                  style: AppText.h1Small().copyWith(height: 1.25),
                ),
                const Spacer(),
                if (index == _index && minutes != null)
                  FilledButton(
                    onPressed: () => _startTimer(minutes),
                    child: Text(
                      clock ?? 'Start $minutes min timer',
                      style: AppText.button(),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  index == steps.length - 1
                      ? 'Last step. Swipe back if you need it.'
                      : 'Swipe for the next step.',
                  style: AppText.body(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
