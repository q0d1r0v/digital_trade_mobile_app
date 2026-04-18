import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shell/app_drawer.dart';
import '../i18n/translations_extension.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/extensions/context_extensions.dart';
import 'app_button.dart';
import 'shell_back_handler.dart';

/// Shared visual shell for every create/edit form in the app.
///
/// Takes care of:
///   - AppBar with centered title + back chevron
///   - Subtitle/hint under the title
///   - Scrollable content with consistent padding
///   - Sticky bottom "Save" button with loading state
///
/// Feature pages just supply [children] (the fields) and wire [onSubmit].
/// Keeps per-feature code focused on the actual data, not layout plumbing.
class FormScaffold extends ConsumerWidget {
  const FormScaffold({
    super.key,
    required this.title,
    required this.children,
    required this.onSubmit,
    required this.saving,
    this.formKey,
    this.subtitle,
    this.submitLabel,
    this.submitIcon,
    this.extraBottom,
    this.onDelete,
    this.deleting = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback? onSubmit;
  final bool saving;
  final GlobalKey<FormState>? formKey;
  final String? submitLabel;
  final IconData? submitIcon;
  final Widget? extraBottom;

  /// If non-null, a trash icon appears in the AppBar; tapping it invokes
  /// this callback (after a confirmation dialog that the feature wires up).
  final VoidCallback? onDelete;
  final bool deleting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Text(
              subtitle!,
              style: context.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.gray500),
            ),
          ),
        ...children,
      ],
    );

    return ShellBackHandler(
      child: Scaffold(
      // Every form page exposes the drawer too, so navigation stays
      // accessible without the user having to pop back to a list first.
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (onDelete != null)
            IconButton(
              tooltip: 'Delete',
              icon: deleting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              onPressed: deleting ? null : onDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: formKey == null
                  ? content
                  : Form(key: formKey, child: content),
            ),
            _SubmitBar(
              label: submitLabel ?? ref.t('common.save'),
              icon: submitIcon ?? Icons.check,
              onPressed: onSubmit,
              saving: saving,
              extra: extraBottom,
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.saving,
    this.extra,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool saving;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (extra != null) ...[
            extra!,
            const SizedBox(height: AppSpacing.sm),
          ],
          AppButton(
            label: label,
            icon: icon,
            loading: saving,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

/// Section divider used inside [FormScaffold] to group related fields.
class FormSection extends StatelessWidget {
  const FormSection({super.key, required this.label, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        4,
        AppSpacing.md,
        4,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}
