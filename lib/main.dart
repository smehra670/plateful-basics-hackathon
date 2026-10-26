import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/onboarding_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/notification_service.dart';
import 'shell/app_shell.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/skeleton.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.cream,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const PlatefulBoot());
}

class PlatefulBoot extends StatefulWidget {
  const PlatefulBoot({super.key});

  @override
  State<PlatefulBoot> createState() => _PlatefulBootState();
}

class _PlatefulBootState extends State<PlatefulBoot> {
  late final AppState _appState;
  var _ready = false;
  var _entered = false;
  var _onboarded = false;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _start();
  }

  Future<void> _start() async {
    await NotificationService.instance.init();
    await _appState.init();
    if (!mounted) return;
    setState(() {
      _ready = true;
      _entered = _appState.welcomeSeen;
      _onboarded = _appState.onboardingSeen;
    });
    await NotificationService.instance.sync(
      preferences: _appState.preferences,
      ingredients: _appState.ingredients,
      plan: _appState.mealPlan,
    );
  }

  Future<void> _enter() async {
    await _appState.markWelcomeSeen();
    if (!mounted) return;
    setState(() => _entered = true);
  }

  Future<void> _finishOnboarding() async {
    if (!mounted) return;
    setState(() => _onboarded = true);
    await NotificationService.instance.sync(
      preferences: _appState.preferences,
      ingredients: _appState.ingredients,
      plan: _appState.mealPlan,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (!_ready) {
      home = const RecipeLoadingView(message: 'Opening');
    } else if (!_entered) {
      home = WelcomeScreen(onContinue: _enter);
    } else if (!_onboarded) {
      home = OnboardingScreen(onDone: _finishOnboarding);
    } else {
      home = const AppShell();
    }

    return ChangeNotifierProvider.value(
      value: _appState,
      child: MaterialApp(
        title: 'Plateful',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: home,
      ),
    );
  }
}
