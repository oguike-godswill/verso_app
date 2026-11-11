import 'package:flutter/material.dart';
import 'state.dart';
import 'theme.dart';
import 'screens/auth.dart';
import 'screens/welcome.dart';
import 'screens/shell.dart';

void main() => runApp(const VersoApp());

class VersoApp extends StatefulWidget {
  final bool? enableDiskPersistence;
  const VersoApp({super.key, this.enableDiskPersistence = true});
  @override
  State<VersoApp> createState() => _VersoAppState();
}

class _VersoAppState extends State<VersoApp> {
  late final AppState state = AppState(enableDiskPersistence: widget.enableDiskPersistence != false);

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Marginalia',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const WelcomeScreen(),
        routes: {
          '/home': (_) => const Shell(),
          '/auth': (_) => const AuthScreen(),
        },
      ),
    );
  }
}
