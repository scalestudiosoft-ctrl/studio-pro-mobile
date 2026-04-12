import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/database/app_database.dart';
import '../core/services/app_sync_bus.dart';
import 'theme.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._() {
    AppSyncBus.changes.addListener(_reloadFromBus);
  }

  static final ThemeController instance = ThemeController._();

  ThemeData _theme = buildStudioTheme(
    primaryButtonColor: colorFromHex(AppConstants.defaultPrimaryButtonColor),
    secondaryButtonColor: colorFromHex(AppConstants.defaultSecondaryButtonColor),
  );

  ThemeData get theme => _theme;

  Future<void> load() async {
    final profile = await AppDatabase.instance.firstRow('business_profile');
    final primaryHex = '${profile?['primary_button_color'] ?? AppConstants.defaultPrimaryButtonColor}';
    final secondaryHex = '${profile?['secondary_button_color'] ?? AppConstants.defaultSecondaryButtonColor}';
    _theme = buildStudioTheme(
      primaryButtonColor: colorFromHex(primaryHex),
      secondaryButtonColor: colorFromHex(secondaryHex),
    );
    notifyListeners();
  }

  void _reloadFromBus() {
    load();
  }
}
