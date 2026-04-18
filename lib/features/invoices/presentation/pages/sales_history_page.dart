import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/shell/app_drawer.dart';
import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/models/named_ref.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/named_list_tile.dart';
import '../../../../core/widgets/shell_back_handler.dart';
import '../../../catalog/catalog_providers.dart';
import '../../../catalog/paginated_list_notifier.dart';

/// Dedicated "Sales history" screen: every completed sale invoice the
/// user has logged. Same list data as the Invoices → Sale tab but
/// reachable as a top-level drawer entry so users don't have to dig
/// through tabs when they just want to see past sales.
class SalesHistoryPage extends ConsumerStatefulWidget {
  const SalesHistoryPage({super.key});

  @override
  ConsumerState<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends ConsumerState<SalesHistoryPage> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

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
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      ref.read(saleInvoiceListProvider.notifier).loadMore();
    }
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref.read(saleInvoiceListProvider.notifier).setQuery(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saleInvoiceListProvider);
    final visible = state.query.isEmpty
        ? state.items
        : state.items
            .where((i) =>
                i.name.toLowerCase().contains(state.query.toLowerCase()))
            .toList();

    return ShellBackHandler(
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: Text(ref.t('sales.historyTitle')),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  ref.read(saleInvoiceListProvider.notifier).refresh(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.saleNew),
          icon: const Icon(Icons.add_shopping_cart),
          label: Text(ref.t('sales.newSale')),
        ),
        body: Column(
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
                decoration: InputDecoration(
                  hintText: ref.t('common.search'),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(saleInvoiceListProvider.notifier).refresh(),
                child: _body(state, visible),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(PaginatedListState state, List<NamedRef> visible) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.danger, size: 44),
              const SizedBox(height: AppSpacing.md),
              Text(state.error!.message),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(saleInvoiceListProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: Text(ref.t('common.retry')),
              ),
            ],
          ),
        ),
      );
    }
    if (visible.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.shopping_cart_outlined,
            size: 56,
            color: AppColors.gray300,
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              ref.t('sales.empty'),
              style: context.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.gray500),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: FilledButton.icon(
              onPressed: () => context.push(AppRoutes.saleNew),
              icon: const Icon(Icons.add),
              label: Text(ref.t('sales.firstSale')),
            ),
          ),
        ],
      );
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
          icon: Icons.shopping_cart_outlined,
          onTap: () => context.push(AppRoutes.saleDetail(it.id)),
        );
      },
    );
  }
}
