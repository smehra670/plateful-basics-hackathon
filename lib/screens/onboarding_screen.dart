import 'package:flutter/material.dart';

import '../shell/app_shell.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/plateful_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPage(
      eyebrow: 'Welcome to',
      title: 'plateful',
      body: 'A calmer way to cook what you already have — and waste a lot less.',
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=1200&q=80',
      hero: true,
    ),
    _OnboardingPage(
      eyebrow: 'Scan',
      title: 'See your food clearly',
      body:
          'Snap leftovers or labels in seconds. Plateful helps you track what is in the fridge before it spoils.',
      imageUrl:
          'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=1200&q=80',
    ),
    _OnboardingPage(
      eyebrow: 'AI ideas',
      title: 'Cook with what you have',
      body:
          'Ask for simple meals from the ingredients you already bought. Less guessing, fewer forgotten leftovers.',
      imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=1200&q=80',
    ),
    _OnboardingPage(
      eyebrow: 'Saved lists',
      title: 'Keep plans in one place',
      body:
          'Build shopping lists and meal plans you will actually use — and check them off as you go.',
      imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=1200&q=80',
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  void _goNext() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const AppShell(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 420),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_page];

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) {
              return _OnboardingPageView(page: _pages[index]);
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (!page.hero)
                        const PlatefulLogo(height: 22)
                      else
                        const SizedBox.shrink(),
                      const Spacer(),
                      if (!_isLast)
                        TextButton(
                          onPressed: _finish,
                          style: TextButton.styleFrom(
                            foregroundColor: page.hero
                                ? Colors.white.withValues(alpha: 0.9)
                                : AppColors.textSecondary,
                            textStyle: AppText.label(
                              color: page.hero
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                          child: const Text('Skip'),
                        ),
                    ],
                  ),
                  const Spacer(),
                  _PageDots(count: _pages.length, index: _page, light: page.hero),
                  const SizedBox(height: 18),
                  _OnboardingButton(
                    label: _isLast ? 'Get started' : 'Continue',
                    onPressed: _goNext,
                    lightSurface: page.hero,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.imageUrl,
    this.hero = false,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String imageUrl;
  final bool hero;
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    if (page.hero) {
      return _HeroPage(page: page);
    }
    return _ContentPage(page: page);
  }
}

class _HeroPage extends StatelessWidget {
  const _HeroPage({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          page.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(color: AppColors.forest),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.25),
                Colors.black.withValues(alpha: 0.72),
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 72, 28, 160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  page.eyebrow,
                  style: AppText.label(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                const PlatefulLogo(height: 56, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  page.body,
                  style: AppText.body(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ContentPage extends StatelessWidget {
  const _ContentPage({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 56, 24, 160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      page.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Container(color: AppColors.sage),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.forest.withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.sage,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                page.eyebrow,
                style: AppText.label(
                  fontSize: 12,
                  color: AppColors.forest,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              page.title,
              style: AppText.display(fontSize: 32),
            ),
            const SizedBox(height: 10),
            Text(
              page.body,
              style: AppText.body(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.index,
    required this.light,
  });

  final int count;
  final int index;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final active = light ? Colors.white : AppColors.forest;
    final idle = light
        ? Colors.white.withValues(alpha: 0.35)
        : AppColors.sage;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final selected = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: selected ? 24 : 8,
          decoration: BoxDecoration(
            color: selected ? active : idle,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

class _OnboardingButton extends StatelessWidget {
  const _OnboardingButton({
    required this.label,
    required this.onPressed,
    required this.lightSurface,
  });

  final String label;
  final VoidCallback onPressed;
  final bool lightSurface;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: lightSurface ? AppColors.sage : AppColors.forest,
          foregroundColor:
              lightSurface ? AppColors.forestDeep : Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: AppText.button(
            color: lightSurface ? AppColors.forestDeep : Colors.white,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
