import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/app/routes/app_pages.dart';
import 'package:makerere_fintech_app/app/routes/app_routes.dart';
import 'package:makerere_fintech_app/features/auth/presentation/controllers/auth_bloc/auth_bloc.dart';
import 'package:makerere_fintech_app/services/supabase_service.dart';
import 'package:makerere_fintech_app/services/theme_state.dart';

// ── IMPORT THE NEW APPLICATION MODULES ───────────────────────────────────────
import 'package:makerere_fintech_app/screens/sacco_join_request_screen.dart';
import 'package:makerere_fintech_app/screens/sacco_admin_portal_screen.dart';
import 'package:makerere_fintech_app/screens/payment_web_view_screen.dart';
import 'package:makerere_fintech_app/screens/sacco_loan_application_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await SupabaseService.initialize();

  // ⚡ LISTEN FOR AUTH CHANGES STATE: Ensures that whenever a login or logout event happens,
  // the app clears out or populates the Supabase user profile data streams accurately.
  SupabaseService.client.auth.onAuthStateChange.listen((data) {
    debugPrint("🔄 Auth State Sync Handshake triggered: ${data.event} -> User: ${data.session?.user.email}");
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc()..add(const CheckAuthSession()),
        ),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeState.themeMode,
        builder: (context, themeMode, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeMode,
            initialRoute: AppRoutes.home,

            // ── ROUTING MATRIX REGISTRATION ──────────────────────────────────
            routes: {
              ...AppPages.routes, // Preserves all your original existing pages safely


              // Appends the brand new multi-tenant onboarding screen structures
              '/sacco-join': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                return SaccoJoinRequestScreen(
                  saccoId: args['saccoId'] ?? '',
                  saccoName: args['saccoName'] ?? '',
                  schemaName: args['schemaName'] ?? '',
                );
              },
              '/sacco-admin': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                return SaccoAdminPortalScreen(
                  saccoName: args['saccoName'] ?? '',
                  schemaName: args['schemaName'] ?? '',
                );
              },
              '/payment-webview': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                return PaymentWebViewScreen(
                  initialUrl: args['initialUrl'] ?? '',
                  redirectUrl: args['redirectUrl'] ?? '',
                );
              },
              '/sacco-loan': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                return SaccoLoanApplicationScreen(
                  saccoId: args['saccoId'] ?? '',
                  saccoName: args['saccoName'] ?? '',
                  schemaName: args['schemaName'] ?? '',
                );
              },
            },

            builder: (context, child) {
              return BlocListener<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthSignedOut) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                          (_) => false,
                    );
                  }
                },
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppConstants.emerald,
      scaffoldBackgroundColor: AppConstants.lightBg,
      colorScheme: ColorScheme.light(
        primary: AppConstants.emerald,
        secondary: AppConstants.emerald,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFF0F172A),
        error: AppConstants.coral,
      ),
      cardColor: Colors.white,
      dividerColor: AppConstants.lightBorder,
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'SF Pro Display', fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        headlineLarge: TextStyle(fontFamily: 'SF Pro Display', fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        headlineMedium: TextStyle(fontFamily: 'SF Pro Display', fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        titleLarge: TextStyle(fontFamily: 'SF Pro Display', fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        titleMedium: TextStyle(fontFamily: 'SF Pro Display', fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
        bodyLarge: TextStyle(fontFamily: 'SF Pro Text', color: Color(0xFF0F172A)),
        bodyMedium: TextStyle(fontFamily: 'SF Pro Text', color: Color(0xFF475569)),
        bodySmall: TextStyle(fontFamily: 'SF Pro Text', color: Color(0xFF94A3B8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.emerald,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.emerald,
          side: const BorderSide(color: AppConstants.emerald, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIconColor: AppConstants.emerald,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.emerald, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.coral),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppConstants.emerald,
      scaffoldBackgroundColor: AppConstants.darkBg,
      colorScheme: ColorScheme.dark(
        primary: AppConstants.emerald,
        secondary: AppConstants.emerald,
        surface: AppConstants.darkCard,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: const Color(0xFFEEF2F6),
        error: AppConstants.coral,
      ),
      cardColor: AppConstants.darkCard,
      dividerColor: AppConstants.darkBorder,
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'SF Pro Display', fontWeight: FontWeight.w700, color: Color(0xFFEEF2F6)),
        headlineLarge: TextStyle(fontFamily: 'SF Pro Display', fontWeight: FontWeight.w600, color: Color(0xFFEEF2F6)),
        headlineMedium: TextStyle(fontFamily: 'SF Pro Display', fontWeight: FontWeight.w600, color: Color(0xFFEEF2F6)),
        titleLarge: TextStyle(fontFamily: 'SF Pro Display', fontWeight: FontWeight.w600, color: Color(0xFFEEF2F6)),
        titleMedium: TextStyle(fontFamily: 'SF Pro Display', fontWeight: FontWeight.w500, color: Color(0xFFEEF2F6)),
        bodyLarge: TextStyle(fontFamily: 'SF Pro Text', color: Color(0xFFEEF2F6)),
        bodyMedium: TextStyle(fontFamily: 'SF Pro Text', color: Color(0xFF94A3B8)),
        bodySmall: TextStyle(fontFamily: 'SF Pro Text', color: Color(0xFF64748B)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.emerald,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.emerald,
          side: const BorderSide(color: AppConstants.emerald, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D1528),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        prefixIconColor: AppConstants.emerald,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF162033)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.emerald, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.coral),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Color(0xFFEEF2F6),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: Color(0xFFEEF2F6)),
      ),
    );
  }
}