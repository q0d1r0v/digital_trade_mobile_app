import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/shell/app_drawer.dart';
import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/named_list_tile.dart';
import '../../../../core/widgets/shell_back_handler.dart';
import '../../../catalog/catalog_providers.dart';
import '../../../catalog/paginated_list_notifier.dart';

/// Two-tab invoice listing — input on the left, sale on the right. Each
/// tab owns its own scroll + search state and FAB target.
class InvoicesPage extends ConsumerStatefulWidget {
  const InvoicesPage({super.key});

  @override
  ConsumerState<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends ConsumerState<InvoicesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShellBackHandler(
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: Text(ref.t('nav.invoices')),
          bottom: TabBar(
            controller: _tab,
            tabs: [
              Tab(text: ref.t('onboarding.checklist.tasks.firstInputInvoice')),
              Tab(text: ref.t('onboarding.checklist.tasks.firstSale')),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push(
            _tab.index == 0 ? AppRoutes.inputInvoiceNew : AppRoutes.saleNew,
          ),
          child: const Icon(Icons.add),
        ),
        body: TabBarView(
          controller: _tab,
          children: [
            _InvoiceTab(provider: inputInvoiceListProvider, isInput: true),
            _InvoiceTab(provider: saleInvoiceListProvider, isInput: false),
          ],
        ),
      ),
    );
  }
}

class _InvoiceTab extends ConsumerStatefulWidget {
  const _InvoiceTab({required this.provider, required this.isInput});
  final AutoDisposeStateNotifierProvider<PaginatedListNotifier,
      PaginatedListState> provider;
  final bool isInput;

  @override
  ConsumerState<_InvoiceTab> createState() => _InvoiceTabState();
}

class _InvoiceTabState extends ConsumerState<_InvoiceTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final position = _scrollCtrl.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(widget.provider.notifier).loadMore();
    }
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) ref.read(widget.provider.notifier).setQuery(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(widget.provider);
    final filtered = state.query.isEmpty
        ? state.items
        : state.items
            .where((i) => i.name.toLowerCase().contains(state.query.toLowerCase()))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            decoration: const InputDecoration(
              hintText: 'Search',
              prefixIcon: Icon(Icons.search, size: 20),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(widget.provider.notifier).refresh(),
            child: _buildList(state, filtered),
          ),
        ),
      ],
    );
  }

  Widget _buildList(PaginatedListState state, List visible) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        children: [
          const SizedBox(height: 48),
          const Icon(Icons.error_outline,
              size: 56, color: AppColors.danger),
          const SizedBox(height: AppSpacing.md),
          Center(child: Text(state.error!.message)),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => ref.read(widget.provider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }
    if (visible.isEmpty) {
      return _EmptyTab(isInput: widget.isInput);
    }
    return ListView.separated(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemCount: visible.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        if (i >= visible.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final it = visible[i];
        final title = it.name.isNotEmpty ? it.name : '#${it.id}';
        return NamedListTile(
          title: title,
          icon: widget.isInput
              ? Icons.move_to_inbox
              : Icons.shopping_cart_outlined,
          onTap: () => context.push(
            widget.isInput
                ? '/invoices/input/${it.id}'
                : '/invoices/sale/${it.id}',
          ),
        );
      },
    );
  }
}

class _EmptyTab extends ConsumerWidget {
  const _EmptyTab({required this.isInput});
  final bool isInput;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      children: [
        const SizedBox(height: 48),
        Icon(
          isInput ? Icons.move_to_inbox : Icons.shopping_cart_outlined,
          size: 56,
          color: AppColors.gray300,
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
            ref.t(isInput
                ? 'onboarding.checklist.tasks.firstInputInvoice'
                : 'onboarding.checklist.tasks.firstSale'),
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium
                ?.copyWith(color: AppColors.gray500),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: IconButton.filled(
            onPressed: () => context.push(
              isInput ? AppRoutes.inputInvoiceNew : AppRoutes.saleNew,
            ),
            icon: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
