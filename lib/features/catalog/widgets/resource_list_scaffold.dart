import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/named_ref.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../core/widgets/named_list_tile.dart';
import '../../../core/widgets/shell_back_handler.dart';
import '../paginated_list_notifier.dart';

/// Reusable scaffold for "list + FAB → create" screens. Drives a
/// [PaginatedListNotifier]:
///   - pull-to-refresh → page 1
///   - scroll near bottom → next page
///   - search box (debounced) → filters client-side by default;
///     flip `useServerSearch=true` on the notifier once the backend
///     gains a `?search=` param.
///
/// Feature pages only supply the title/icon/provider/FAB target; the
/// scaffold covers the rest.
class ResourceListScaffold extends ConsumerStatefulWidget {
  const ResourceListScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.listProvider,
    required this.onCreate,
    this.drawer,
    this.emptyMessage,
    this.subtitleBuilder,
    this.searchHint,
    this.onItemTap,
    this.onItemDelete,
  });

  final String title;
  final IconData icon;
  final AutoDisposeStateNotifierProvider<PaginatedListNotifier,
      PaginatedListState> listProvider;
  final VoidCallback onCreate;
  final Widget? drawer;
  final String? emptyMessage;
  final String? Function(NamedRef)? subtitleBuilder;
  final String? searchHint;

  /// Default action when the user taps a row. If unset, rows stay
  /// non-interactive.
  final ValueChanged<NamedRef>? onItemTap;

  /// Long-press / trailing-menu action. Typical use: soft-delete. Set
  /// alongside [onItemTap] for an edit+delete combo.
  final ValueChanged<NamedRef>? onItemDelete;

  @override
  ConsumerState<ResourceListScaffold> createState() =>
      _ResourceListScaffoldState();
}

class _ResourceListScaffoldState
    extends ConsumerState<ResourceListScaffold> {
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
    final position = _scrollCtrl.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(widget.listProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref.read(widget.listProvider.notifier).setQuery(value);
      // Reset scroll to top after query changes.
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(0);
      }
    });
  }

  List<NamedRef> _filterLocal(List<NamedRef> items, String query) {
    if (query.isEmpty) return items;
    final q = query.toLowerCase();
    return items.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.listProvider);
    final visible = _filterLocal(state.items, state.query);

    return ShellBackHandler(
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        drawer: widget.drawer,
        floatingActionButton: FloatingActionButton(
          onPressed: widget.onCreate,
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            _SearchBar(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              hint: widget.searchHint,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(widget.listProvider.notifier).refresh(),
                child: _buildBody(state, visible),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(PaginatedListState state, List<NamedRef> visible) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return _ErrorView(
        message: state.error!.message,
        onRetry: () => ref.read(widget.listProvider.notifier).refresh(),
      );
    }
    if (visible.isEmpty) {
      return _EmptyView(
        icon: widget.icon,
        message: widget.emptyMessage ?? '',
        onCreate: widget.onCreate,
        isSearching: state.query.isNotEmpty,
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
          return const _LoadMoreTile();
        }
        final item = visible[i];
        return NamedListTile(
          title: item.name,
          subtitle: widget.subtitleBuilder?.call(item),
          icon: widget.icon,
          onTap: widget.onItemTap == null
              ? null
              : () => widget.onItemTap!(item),
          trailing: widget.onItemDelete == null
              ? null
              : PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (v) {
                    if (v == 'delete') widget.onItemDelete!(item);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: AppColors.danger),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    this.hint,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint ?? 'Search',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          isDense: true,
        ),
      ),
    );
  }
}

class _LoadMoreTile extends StatelessWidget {
  const _LoadMoreTile();

  @override
  Widget build(BuildContext context) {
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
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.icon,
    required this.message,
    required this.onCreate,
    required this.isSearching,
  });

  final IconData icon;
  final String message;
  final VoidCallback onCreate;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      children: [
        const SizedBox(height: 48),
        Icon(
          isSearching ? Icons.search_off : icon,
          size: 56,
          color: AppColors.gray300,
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
            isSearching ? 'No results' : message,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium
                ?.copyWith(color: AppColors.gray500),
          ),
        ),
        if (!isSearching) ...[
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: IconButton.filled(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      children: [
        const SizedBox(height: 48),
        const Icon(Icons.error_outline, size: 56, color: AppColors.danger),
        const SizedBox(height: AppSpacing.md),
        Center(child: Text(message, textAlign: TextAlign.center)),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}
