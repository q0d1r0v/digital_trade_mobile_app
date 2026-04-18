/// Single source of truth for every REST path. All paths are **relative**
/// to `FlavorConfig.apiBaseUrl` — Dio prepends the base URL automatically.
///
/// Paths mirror the NestJS backend controllers under `src/modules/**`.
class ApiEndpoints {
  const ApiEndpoints._();

  // ─── Auth (common/auth.controller.ts) ────────────────────────────────
  static const String login = '/common/auth/login';
  static const String register = '/common/auth/register';
  static const String refresh = '/common/auth/refresh';
  static const String authUser = '/common/auth/auth-user';
  static const String profile = '/common/auth/profile';

  // ─── Plans (common/plans) ────────────────────────────────────────────
  static const String plans = '/common/plans';
  static const String enterpriseRequest = '/common/plans/enterprise-request';

  // ─── Company ─────────────────────────────────────────────────────────
  static String companyById(int id) => '/company/company/company/$id';

  // ─── Catalog resources ───────────────────────────────────────────────
  static const String cashbox = '/company/cashbox/cashbox';
  static const String category = '/company/product/category';
  static const String brand = '/company/product/brand';
  static const String supplier = '/company/supplier/supplier';
  static const String product = '/company/product/product';
  static const String productWithVariations =
      '/company/product/product/with-variations';
  static const String client = '/company/client/client';
  static const String repository = '/company/repository/repository';
  static const String currency = '/company/system/currency';
  static const String role = '/company/user/role';
  static const String productUnit = '/admin/product/product-unit';

  // ─── Invoices ────────────────────────────────────────────────────────
  static const String inputInvoice = '/company/invoice/input-invoice';
  static const String saleInvoice = '/company/invoice/output-invoice/sale';

  // ─── Dashboards (aggregated KPIs) ────────────────────────────────────
  static const String dashboardSoldProduct =
      '/company/dashboard/dashboard/sold-product';
  static const String dashboardSoldProductMonthly =
      '/company/dashboard/dashboard/sold-product/monthly';
  static const String dashboardStock = '/company/dashboard/dashboard/stock';
  static const String dashboardCurrency =
      '/company/dashboard/dashboard/currency';
  static const String dashboardGivenBonus =
      '/company/dashboard/dashboard/given-bonus';
  static const String dashboardInputInvoice =
      '/company/invoice/input-invoice/dashboard';
  static const String dashboardSaleInvoice =
      '/company/invoice/output-invoice/sale/dashboard';

  // ─── Users ───────────────────────────────────────────────────────────
  static const String companyUser = '/company/user/user';

  // ─── Onboarding probes (existence checks via list with limit=1) ──────
  static const String publicRecordsCashbox = '/common/public/records/cashbox';
}

class StorageKeys {
  const StorageKeys._();

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';

  static const String locale = 'locale';
  static const String themeMode = 'theme_mode';
  static const String onboardingWelcomeSeen = 'onboarding_welcome_seen';
  static const String onboardingDismissed = 'onboarding_dismissed';
}
