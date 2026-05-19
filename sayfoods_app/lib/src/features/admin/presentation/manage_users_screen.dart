import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_app_bar.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_modal.dart';
import 'package:sayfoods_app/src/shared/utils/error_handler.dart';

final _allUsersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final response = await Supabase.instance.client
      .from('profiles')
      .select('id, full_name, role, created_at')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response as List);
});

class ManageUsersScreen extends ConsumerWidget {
  const ManageUsersScreen({super.key});

  static const _purple = Color(0xFF5B1380);
  static const _orange = Color(0xFFF28F2A);
  static const _roles = ['client', 'staff', 'rider', 'admin'];

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return _purple;
      case 'rider':
        return _orange;
      case 'staff':
        return Colors.teal;
      default:
        return Colors.blue; // client
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(_allUsersProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const SayfoodsAppBar(
        title: 'Manage Users',
        showBackButton: true,
      ),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Text('No users found.',
                  style: TextStyle(color: Colors.grey.shade400)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final name =
                  user['full_name'] as String? ?? 'Unnamed User';
              final role = user['role'] as String? ?? 'client';
              final createdAt = user['created_at'] != null
                  ? DateFormat('MMM d, yyyy').format(
                      DateTime.parse(user['created_at'] as String))
                  : '';
              final roleColor = _roleColor(role);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _purple.withValues(alpha: 0.1),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: _purple,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          if (createdAt.isNotEmpty)
                            Text(
                              'Joined $createdAt',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: role,
                          isDense: true,
                          icon: Icon(Icons.expand_more_rounded,
                              size: 14, color: roleColor),
                          style: TextStyle(
                              color: roleColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                          items: _roles
                              .map((r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(
                                      r[0].toUpperCase() +
                                          r.substring(1),
                                      style: TextStyle(
                                          color: _roleColor(r),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (newRole) {
                            if (newRole == null || newRole == role) {
                              return;
                            }
                            _confirmRoleChange(
                                context, ref, user, name, newRole);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Future<void> _confirmRoleChange(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> user,
    String name,
    String newRole,
  ) async {
    final label =
        newRole[0].toUpperCase() + newRole.substring(1);
    bool confirmed = false;
    await SayfoodsModal.show(
      context: context,
      type: SayfoodsModalType.info,
      title: 'Change Role',
      subtitle: 'Change $name\'s role to "$label"?',
      primaryButtonText: 'Confirm',
      onPrimaryPressed: () {
        confirmed = true;
        Navigator.pop(context);
      },
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () => Navigator.pop(context),
    );
    if (!confirmed) return;

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'role': newRole})
          .eq('id', user['id'] as String);
      ref.invalidate(_allUsersProvider);
      if (context.mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.success,
          title: 'Role Updated',
          subtitle: '$name is now a $label.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.error,
          title: 'Error',
          subtitle: ErrorHelper.getErrorMessage(e),
        );
      }
    }
  }
}
