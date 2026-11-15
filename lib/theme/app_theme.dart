import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppTheme {
  static const Color bgDark = Color(0xFF0A0E17);
  static const Color cardDark = Color(0xFF131A29);
  static const Color cardElevated = Color(0xFF1B2438);
  static const Color gold = Color(0xFFF59E0B);
  static const Color goldLight = Color(0xFFFCD34D);
  static const Color emerald = Color(0xFF10B981);
  static const Color rose = Color(0xFFF43F5E);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color borderSubtle = Color(0xFF232E47);

  // Peta ikon konstan agar kompilasi release icon tree-shaking sukses 100%
  static const Map<int, IconData> categoryIcons = {
    1: Icons.restaurant_rounded,
    2: Icons.directions_car_rounded,
    3: Icons.shopping_bag_rounded,
    4: Icons.receipt_long_rounded,
    5: Icons.movie_rounded,
    6: Icons.payments_rounded,
    7: Icons.trending_up_rounded,
    8: Icons.account_balance_rounded,
    9: Icons.medical_services_rounded,
    10: Icons.school_rounded,
    11: Icons.flight_takeoff_rounded,
    12: Icons.category_rounded,
  };

  static IconData getIcon(int? code) {
    return categoryIcons[code] ?? Icons.category_rounded;
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: emerald,
        surface: cardDark,
        error: rose,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),
    );
  }
}

class AppFormatters {
  static final _idr = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String rupiah(num amount) => _idr.format(amount);

  static String compactRupiah(num amount) {
    final absVal = amount.abs();
    final prefix = amount < 0 ? '-Rp ' : 'Rp ';
    if (absVal >= 1000000000) {
      return '$prefix${(absVal / 1000000000).toStringAsFixed(1)} M';
    } else if (absVal >= 1000000) {
      return '$prefix${(absVal / 1000000).toStringAsFixed(1)} Jt';
    } else if (absVal >= 1000) {
      return '$prefix${(absVal / 1000).toStringAsFixed(0)} Rb';
    }
    return _idr.format(amount);
  }

  static String formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy • HH:mm').format(dt);
    } catch (_) {
      return isoString;
    }
  }
}
