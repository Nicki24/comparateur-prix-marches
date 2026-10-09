import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:comparateur_prix_app/theme/app_theme.dart';

/// Monte un widget dans l'application thémée MarketScope.
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    ThemeData? theme,
    bool disableAnimations = false,
  }) {
    return pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Scaffold(body: widget),
        ),
      ),
    );
  }
}
