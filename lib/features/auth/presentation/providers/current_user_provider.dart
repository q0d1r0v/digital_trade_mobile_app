import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_entity.dart';
import 'auth_providers.dart';

/// Loads and caches the authenticated user. Invalidated on login/logout
/// via the auth state stream, so widgets get the fresh profile without
/// any manual refresh.
final currentUserProvider = FutureProvider<UserEntity?>((ref) async {
  final authAsync = ref.watch(authStateProvider);
  final isAuthed = authAsync.maybeWhen(data: (v) => v, orElse: () => false);
  if (!isAuthed) return null;

  final repo = ref.watch(authRepositoryProvider);
  final result = await repo.getCurrentUser();
  return result.fold((_) => null, (user) => user);
});
