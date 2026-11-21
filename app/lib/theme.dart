import 'package:material_ui/material_ui.dart';

const brandSeed = Color(0xFF5B5FEF);

/// Result colours. Deliberately not pink / blue.
const femaleColor = Color(0xFFFFB020);
const maleColor = Color(0xFF2EC4B6);
const neutralColor = Color(0xFFE0E0E0);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: brandSeed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    appBarTheme: const AppBarTheme(centerTitle: true),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
