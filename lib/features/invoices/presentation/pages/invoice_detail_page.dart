import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/shell/app_drawer.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/shell_back_handler.dart';
import '../../../catalog/catalog_providers.dart';

/// Read-only detail for both input and sale invoices with status-change
/// actions that mirror the web frontend:
///   - Input invoice: approve (posts stock into the repository) /
///     cancel (marks canceled)
///   - Sale invoice: approve / pay (registers a payment) / cancel
///
/// Detail payload is parsed loosely — backend fields vary (number/date/
/// total/items/status), and each variant is resolved at render time.
enum InvoiceKind { input, sale }

class InvoiceDetailPage extends ConsumerStatefulWidget {
  const InvoiceDetailPage({super.key, required this.id, required this.kind});
  final int id;
  final InvoiceKind kind;

  @override
  ConsumerState<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends ConsumerState<InvoiceDetailPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  String get _path => widget.kind == InvoiceKind.input
      ? ApiEndpoints.inputInvoice
      : ApiEndpoints.saleInvoice;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await ref.read(catalogServiceProvider).detail(_path, widget.id);
    if (!mounted) return;
    r.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (data) => setState(() {
        _data = data;
        _loading = false;
      }),
    );
  }

  Future<void> _runAction(
    String label,
    String verb, {
    bool isPut = false,
    Map<String, dynamic>? body,
    bool destructive = false,
    required String confirmTitle,
  }) async {
    final ok = await confirmDialog(
      context,
      title: confirmTitle,
      confirmLabel: label,
      destructive: destructive,
    );
    if (!ok) return;
    setState(() => _busy = true);
    final r = await ref
        .read(catalogServiceProvider)
        .action(_path, widget.id, verb, isPut: isPut, body: body);
    if (!mounted) return;
    setState(() => _busy = false);
    r.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        if (widget.kind == InvoiceKind.input) {
          ref.invalidate(inputInvoiceListProvider);
        } else {
          ref.invalidate(saleInvoiceListProvider);
        }
        context.showSnack(ref.t('common.done'));
        _load();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShellBackHandler(
      child: Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text('#${widget.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildActions(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.danger, size: 44),
              const SizedBox(height: AppSpacing.md),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final data = _data ?? const {};
    final status = (data['status'] ?? '').toString();
    final products = (data['products'] as List?) ?? const [];
    final total = products.fold<double>(0, (s, p) {
      if (p is! Map) return s;
      final qty = _asDouble(p['quantity']);
      final price = _asDouble(p['price']);
      return s + qty * price;
    });

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _StatusChip(status: status),
        const SizedBox(height: AppSpacing.md),
        _InfoCard(
          rows: [
            _InfoRow(
              label: 'Date',
              value: _formatDate(data['date'] ?? data['created_at']),
            ),
            if (widget.kind == InvoiceKind.input)
              _InfoRow(
                label: 'Supplier',
                value: (data['supplier']?['name'] ?? '—').toString(),
              ),
            if (widget.kind == InvoiceKind.sale)
              _InfoRow(
                label: 'Client',
                value: (data['client']?['name'] ?? '—').toString(),
              ),
            _InfoRow(
              label: 'Repository',
              value: (data['repository']?['name'] ?? '—').toString(),
            ),
            if (widget.kind == InvoiceKind.sale)
              _InfoRow(
                label: 'Cashbox',
                value: (data['cashbox']?['name'] ?? '—').toString(),
              ),
            _InfoRow(
              label: 'Currency',
              value: (data['currency']?['name'] ??
                      data['currency']?['code'] ??
                      '—')
                  .toString(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          ref.t('nav.products'),
          style: context.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final p in products)
          if (p is Map<String, dynamic>) _ProductLine(data: p),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                total.toStringAsFixed(2),
                style: context.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget? _buildActions() {
    if (_loading || _error != null || _data == null) return null;
    final status = (_data?['status'] ?? '').toString();
    if (status == 'canceled') return null;

    final buttons = <Widget>[];
    if (status == 'waiting') {
      buttons.add(
        Expanded(
          child: AppButton(
            label: 'Approve',
            icon: Icons.check,
            loading: _busy,
            onPressed: () => _runAction(
              'Approve',
              'approve',
              isPut: widget.kind == InvoiceKind.sale,
              confirmTitle: 'Approve invoice?',
            ),
          ),
        ),
      );
      buttons.add(const SizedBox(width: AppSpacing.sm));
      buttons.add(
        Expanded(
          child: AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.danger,
            onPressed: _busy
                ? null
                : () => _runAction(
                      'Cancel',
                      'changeStatus',
                      isPut: true,
                      body: const {'status': 'canceled'},
                      destructive: true,
                      confirmTitle: 'Cancel invoice?',
                    ),
          ),
        ),
      );
    }
    if (widget.kind == InvoiceKind.sale && status == 'approved') {
      buttons.add(
        Expanded(
          child: AppButton(
            label: 'Pay',
            icon: Icons.payments_outlined,
            onPressed: _busy
                ? null
                : () => _runAction(
                      'Pay',
                      'pay',
                      body: {'payments': _currentPayments()},
                      confirmTitle: 'Register payment?',
                    ),
          ),
        ),
      );
    }
    if (buttons.isEmpty) return null;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(children: buttons),
      ),
    );
  }

  List<Map<String, dynamic>> _currentPayments() {
    final products = (_data?['products'] as List?) ?? const [];
    final total = products.fold<double>(0, (s, p) {
      if (p is! Map) return s;
      final qty = _asDouble(p['quantity']);
      final price = _asDouble(p['price']);
      return s + qty * price;
    });
    return [
      {'payment_type': 'cash', 'value': total},
    ];
  }

  double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    final s = raw.toString();
    try {
      return s.substring(0, 10);
    } catch (_) {
      return s;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' => AppColors.success,
      'canceled' => AppColors.danger,
      _ => AppColors.warning,
    };
    final label = status.isEmpty ? '—' : status.toUpperCase();
    return Container(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1) const Divider(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: context.textTheme.bodySmall
                ?.copyWith(color: AppColors.gray500),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ProductLine extends StatelessWidget {
  const _ProductLine({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final name = (data['product']?['name'] ??
            data['name'] ??
            '#${data['product_id'] ?? data['id']}')
        .toString();
    final qty = _asDouble(data['quantity']);
    final price = _asDouble(data['price']);
    final subtotal = qty * price;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${qty.toStringAsFixed(0)} × ${price.toStringAsFixed(2)}',
                  style: context.textTheme.bodySmall
                      ?.copyWith(color: AppColors.gray500),
                ),
              ],
            ),
          ),
          Text(
            subtotal.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
