import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/routes/app_routes.dart';
import 'package:makerere_fintech_app/screens/home_dashboard.dart';
import 'package:makerere_fintech_app/screens/sacco_dashboard.dart';
import 'package:makerere_fintech_app/screens/profile_screen.dart';
import 'package:makerere_fintech_app/screens/transactions_screen.dart';
import 'package:makerere_fintech_app/screens/deposit_screen.dart';
import 'package:makerere_fintech_app/screens/transfer_screen.dart';
import 'package:makerere_fintech_app/screens/settings_screen.dart';
import 'package:makerere_fintech_app/screens/edit_profile_screen.dart';
import 'package:makerere_fintech_app/screens/tenant_registration_screen.dart';
import 'package:makerere_fintech_app/screens/login_screen.dart';
import 'package:makerere_fintech_app/screens/dashboard_reports_screen.dart';
import 'package:makerere_fintech_app/features/transactions/presentation/views/realtime_ledger_audit_view.dart';

class AppPages {
  AppPages._();

  static Map<String, WidgetBuilder> get routes => {
        AppRoutes.home: (_) => const HomeDashboard(),
        AppRoutes.saccos: (_) => const SaccoDashboard(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.transactions: (_) => const TransactionsScreen(),
        AppRoutes.deposit: (_) => const DepositScreen(),
        AppRoutes.transfer: (_) => const TransferScreen(),
        AppRoutes.settings: (_) => const SettingsScreen(),
        AppRoutes.editProfile: (_) => const EditProfileScreen(),
        AppRoutes.tenantRegistration: (_) => const TenantRegistrationScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.dashboardReports: (_) => const DashboardReportsScreen(),
        AppRoutes.realtimeLedger: (_) => const RealtimeLedgerAuditView(),
      };
}
