import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/models/named_ref.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// Reusable dropdown over an async `NamedRef` list. Shows a "create"
/// shortcut when the list is empty and a create-route is available, so
/// users can't dead-end on a required picker.
class RefDropdown extends ConsumerWidget {
  const RefDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.async,
    required this.onChanged,
    this.onCreateRoute,
    this.optional = false,
  });

  final String label;
  final NamedRef? value;
  final IconData icon;
  final AsyncValue<List<NamedRef>> async;
  final ValueChanged<NamedRef?> onChanged;
  final String? onCreateRoute;
  final bool optional;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        async.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(e.toString()),
          data: (items) {
            if (items.isEmpty && onCreateRoute != null) {
              return OutlinedButton.icon(
                onPressed: () => context.push(onCreateRoute!),
                icon: const Icon(Icons.add),
                label: Text(label),
              );
            }
            return DropdownButtonFormField<NamedRef>(
              initialValue: value,
              decoration: InputDecoration(prefixIcon: Icon(icon)),
              items: [
                for (final it in items)
                  DropdownMenuItem(value: it, child: Text(it.name)),
              ],
              onChanged: onChanged,
              validator: optional
                  ? null
                  : (v) =>
                      v == null ? ref.t('validation.required') : null,
            );
          },
        ),
      ],
    );
  }
}
