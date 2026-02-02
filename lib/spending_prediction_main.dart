import 'package:flutter/material.dart';
import 'package:test_app/modules/SpendingPrediction/WidgetServices/bottom_navbar_widget.dart';

class SpendingPredictionApp extends StatelessWidget {
  const SpendingPredictionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spending Prediction',
      theme: ThemeData(
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 245, 245, 245),
        ).copyWith(
          primary: const Color.fromARGB(255, 30, 30, 30),
          onPrimary: const Color.fromARGB(255, 255, 255, 255),
          secondary: const Color.fromARGB(255, 96, 125, 139),
          onSecondary: const Color.fromARGB(255, 33, 33, 33),
          surface: const Color.fromARGB(255, 245, 245, 245),
          onSurface: const Color.fromARGB(255, 33, 33, 33),
          error: const Color.fromARGB(255, 211, 47, 47),
          onError: const Color.fromARGB(255, 255, 255, 255),
        ),
      ),
      home: const BottomNavWrapper(),
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
      },
    );
  }
}

class AppRoutes {
  static const home = '/home';
}
