import 'package:flutter/material.dart';

/// Design tokens derived from DESIGN.md for Bok Mai
class AppColors {
  // Primary (Civic Trust Blue)
  static const Color primary = Color(0xFF00629E);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFCFE5FF);
  static const Color onPrimaryContainer = Color(0xFF001D34);

  // Secondary (Responsive Teal)
  static const Color secondary = Color(0xFF006A60);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF73F8E7);
  static const Color onSecondaryContainer = Color(0xFF00201D);

  // Neutral Surfaces (M3 Tonal Surface Elevation)
  static const Color surface = Color(0xFFFDFCFF);
  static const Color onSurface = Color(0xFF1A1C1E);
  static const Color surfaceVariant = Color(0xFFDEE3EB);
  static const Color onSurfaceVariant = Color(0xFF42474E);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF7F9FD);
  static const Color surfaceContainer = Color(0xFFF1F4F9);
  static const Color surfaceContainerHigh = Color(0xFFEBEFF4);
  static const Color surfaceContainerHighest = Color(0xFFE2E5EA);
  static const Color outline = Color(0xFF73777F);
  static const Color outlineVariant = Color(0xFFC2C7CF);

  // Semantic Ticket Statuses
  static const Color statusPending = Color(0xFFD97706);
  static const Color statusPendingContainer = Color(0xFFFEF3C7);
  static const Color statusPendingOnContainer = Color(0xFF78350F);

  static const Color statusInProgress = Color(0xFF0284C7);
  static const Color statusInProgressContainer = Color(0xFFE0F2FE);
  static const Color statusInProgressOnContainer = Color(0xFF0369A1);

  static const Color statusResolved = Color(0xFF16A34A);
  static const Color statusResolvedContainer = Color(0xFFDCFCE7);
  static const Color statusResolvedOnContainer = Color(0xFF15803D);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);
}

class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 28.0;
  static const double full = 9999.0;
}

class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double section = 48.0;
}

