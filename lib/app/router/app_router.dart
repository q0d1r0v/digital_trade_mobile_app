import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/brand/brand_pages.dart';
import '../../features/cashbox/cashbox_pages.dart';
import '../../features/category/category_pages.dart';
import '../../features/clients/presentation/pages/clients_page.dart';
import '../../features/company/company_edit_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/invoices/presentation/pages/input_invoice_new_page.dart';
import '../../features/invoices/presentation/pages/invoice_detail_page.dart';
import '../../features/invoices/presentation/pages/invoices_page.dart';
import '../../features/invoices/presentation/pages/sale_new_page.dart';
import '../../features/invoices/presentation/pages/sales_history_page.dart';
import '../../features/onboarding/presentation/pages/help_page.dart';
import '../../features/onboarding/presentation/pages/welcome_page.dart';
import '../../features/onboarding/presentation/providers/onboarding_providers.dart';
import '../../features/products/presentation/pages/products_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/supplier/supplier_pages.dart';
import '../../features/team/team_pages.dart';
import '../shell/home_shell.dart';
import 'app_routes.dart';

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellKey = GlobalKey<NavigatorState>();

/// Auth-aware router. Redirects are computed from [authStateProvider]
/// and [welcomeSeenProvider]; Riverpod `ref.listen` re-triggers the
/// redirect whenever those values change so navigation stays in sync
/// with state without polling.
final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);

  ref.listen<AsyncValue<bool>>(
    authStateProvider,
    (_, _) => refresh.value++,
    fireImmediately: true,
  );
  ref.listen<bool>(welcomeSeenProvider, (_, _) => refresh.value++);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      return authAsync.when(
        data: (isAuthed) => _computeRedirect(
          isAuthed: isAuthed,
          welcomeSeen: ref.read(welcomeSeenProvider),
          location: state.matchedLocation,
        ),
        loading: () => state.matchedLocation == AppRoutes.splash
            ? null
            : AppRoutes.splash,
        error: (_, _) => AppRoutes.login,
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.nameSplash,
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.nameLogin,
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRoutes.nameRegister,
        builder: (_, _) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        name: AppRoutes.nameWelcome,
        builder: (_, _) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.help,
        name: AppRoutes.nameHelp,
        builder: (_, _) => const HelpPage(),
      ),

      // ─── Onboarding task pages (pushed above the bottom-nav shell so
      // the form takes the whole screen without the tab bar stealing
      // focus away from the save button). ──────────────────────────────
      GoRoute(
        path: AppRoutes.companyEdit,
        builder: (_, _) => const CompanyEditPage(),
      ),
      GoRoute(
        path: AppRoutes.cashboxes,
        builder: (_, _) => const CashboxListPage(),
      ),
      GoRoute(
        path: AppRoutes.cashboxNew,
        builder: (_, _) => const CashboxFormPage(),
      ),
      GoRoute(
        path: '/cashboxes/:id/edit',
        builder: (_, s) =>
            CashboxFormPage(id: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: AppRoutes.categories,
        builder: (_, _) => const CategoryListPage(),
      ),
      GoRoute(
        path: AppRoutes.categoryNew,
        builder: (_, _) => const CategoryFormPage(),
      ),
      GoRoute(
        path: '/categories/:id/edit',
        builder: (_, s) =>
            CategoryFormPage(id: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: AppRoutes.brands,
        builder: (_, _) => const BrandListPage(),
      ),
      GoRoute(
        path: AppRoutes.brandNew,
        builder: (_, _) => const BrandFormPage(),
      ),
      GoRoute(
        path: '/brands/:id/edit',
        builder: (_, s) =>
            BrandFormPage(id: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: AppRoutes.suppliers,
        builder: (_, _) => const SupplierListPage(),
      ),
      GoRoute(
        path: AppRoutes.supplierNew,
        builder: (_, _) => const SupplierFormPage(),
      ),
      GoRoute(
        path: '/suppliers/:id/edit',
        builder: (_, s) =>
            SupplierFormPage(id: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: AppRoutes.productNew,
        builder: (_, _) => const ProductFormPage(),
      ),
      GoRoute(
        path: '/products/:id/edit',
        builder: (_, s) =>
            ProductFormPage(id: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: AppRoutes.clientNew,
        builder: (_, _) => const ClientFormPage(),
      ),
      GoRoute(
        path: '/clients/:id/edit',
        builder: (_, s) =>
            ClientFormPage(id: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: AppRoutes.inputInvoiceNew,
        builder: (_, _) => const InputInvoiceNewPage(),
      ),
      GoRoute(
        path: '/invoices/input/:id',
        builder: (_, s) => InvoiceDetailPage(
          id: int.parse(s.pathParameters['id']!),
          kind: InvoiceKind.input,
        ),
      ),
      GoRoute(
        path: AppRoutes.saleNew,
        builder: (_, _) => const SaleNewPage(),
      ),
      GoRoute(
        path: '/invoices/sale/:id',
        builder: (_, s) => InvoiceDetailPage(
          id: int.parse(s.pathParameters['id']!),
          kind: InvoiceKind.sale,
        ),
      ),
      GoRoute(
        path: AppRoutes.salesHistory,
        builder: (_, _) => const SalesHistoryPage(),
      ),
      GoRoute(
        path: AppRoutes.teamMembers,
        builder: (_, _) => const TeamListPage(),
      ),
      GoRoute(
        path: AppRoutes.teamInvite,
        builder: (_, _) => const TeamFormPage(),
      ),
      GoRoute(
        path: '/team/:id/edit',
        builder: (_, s) =>
            TeamFormPage(id: int.parse(s.pathParameters['id']!)),
      ),

      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: AppRoutes.nameHome,
            pageBuilder: (_, _) => _fadePage(const DashboardPage()),
          ),
          GoRoute(
            path: AppRoutes.products,
            name: AppRoutes.nameProducts,
            pageBuilder: (_, _) => _fadePage(const ProductsPage()),
          ),
          GoRoute(
            path: AppRoutes.clients,
            name: AppRoutes.nameClients,
            pageBuilder: (_, _) => _fadePage(const ClientsPage()),
          ),
          GoRoute(
            path: AppRoutes.invoices,
            name: AppRoutes.nameInvoices,
            pageBuilder: (_, _) => _fadePage(const InvoicesPage()),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: AppRoutes.nameSettings,
            pageBuilder: (_, _) => _fadePage(const SettingsPage()),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text(state.error?.toString() ?? 'Unknown route')),
    ),
  );
});

String? _computeRedirect({
  required bool isAuthed,
  required bool welcomeSeen,
  required String location,
}) {
  final isPublic = location == AppRoutes.login ||
      location == AppRoutes.register ||
      location == AppRoutes.splash;

  if (!isAuthed) {
    return isPublic && location != AppRoutes.splash ? null : AppRoutes.login;
  }

  if (location == AppRoutes.splash ||
      location == AppRoutes.login ||
      location == AppRoutes.register) {
    return welcomeSeen ? AppRoutes.home : AppRoutes.welcome;
  }
  return null;
}

CustomTransitionPage<void> _fadePage(Widget child) => CustomTransitionPage(
      child: child,
      transitionsBuilder: (_, anim, _, c) =>
          FadeTransition(opacity: anim, child: c),
    );
