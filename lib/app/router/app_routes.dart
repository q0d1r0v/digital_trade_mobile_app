/// Single source of truth for every route name and path.
/// Never hard-code a route string anywhere else — import from here.
class AppRoutes {
  const AppRoutes._();

  // Path
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String welcome = '/welcome';
  static const String help = '/help';

  // Shell
  static const String home = '/home';
  static const String products = '/products';
  static const String clients = '/clients';
  static const String invoices = '/invoices';
  static const String settings = '/settings';

  // Onboarding-driven flows (reached from checklist + shell)
  static const String companyEdit = '/company/edit';
  static const String cashboxes = '/cashboxes';
  static const String cashboxNew = '/cashboxes/new';
  static String cashboxEdit(int id) => '/cashboxes/$id/edit';
  static const String categories = '/categories';
  static const String categoryNew = '/categories/new';
  static String categoryEdit(int id) => '/categories/$id/edit';
  static const String brands = '/brands';
  static const String brandNew = '/brands/new';
  static String brandEdit(int id) => '/brands/$id/edit';
  static const String suppliers = '/suppliers';
  static const String supplierNew = '/suppliers/new';
  static String supplierEdit(int id) => '/suppliers/$id/edit';
  static const String productNew = '/products/new';
  static String productEdit(int id) => '/products/$id/edit';
  static const String clientNew = '/clients/new';
  static String clientEdit(int id) => '/clients/$id/edit';
  static const String inputInvoiceNew = '/invoices/input/new';
  static String inputInvoiceDetail(int id) => '/invoices/input/$id';
  static const String saleNew = '/invoices/sale/new';
  static String saleDetail(int id) => '/invoices/sale/$id';
  static const String salesHistory = '/sales/history';
  static const String teamMembers = '/team';
  static const String teamInvite = '/team/invite';
  static String teamEdit(int id) => '/team/$id/edit';

  // Names (for pushNamed)
  static const String nameSplash = 'splash';
  static const String nameLogin = 'login';
  static const String nameRegister = 'register';
  static const String nameWelcome = 'welcome';
  static const String nameHelp = 'help';
  static const String nameHome = 'home';
  static const String nameProducts = 'products';
  static const String nameClients = 'clients';
  static const String nameInvoices = 'invoices';
  static const String nameSettings = 'settings';
}
