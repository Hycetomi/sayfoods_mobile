import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sayfoods_app/src/features/profile/application/profile_provider.dart';
import 'package:sayfoods_app/src/features/profile/presentation/widgets/profile_detail_row.dart';
import 'package:sayfoods_app/src/shared/widgets/text_input_dialog.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_modal.dart';

class EditAdminProfileScreen extends ConsumerStatefulWidget {
  const EditAdminProfileScreen({super.key});

  @override
  ConsumerState<EditAdminProfileScreen> createState() => _EditAdminProfileScreenState();
}

class _EditAdminProfileScreenState extends ConsumerState<EditAdminProfileScreen> {
  final Color _bgColor = const Color(0xFFFCFCFC);

  Future<void> _updateProfileDatabase(String column, String newValue) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null || newValue.isEmpty) return;

    try {
      await supabase
          .from('profiles')
          .update({column: newValue})
          .eq('id', user.id);

      ref.invalidate(userProfileProvider);

      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.success,
          title: 'Success',
          subtitle: 'Profile updated successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.error,
          title: 'Error',
          subtitle: e.toString(),
        );
      }
    }
  }

  Future<void> _updateEmailAuth(String newEmail) async {
    if (newEmail.isEmpty) return;
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(email: newEmail),
      );
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.success,
          title: 'Email Update',
          subtitle: 'Confirmation link sent! Please check your new email inbox.',
        );
      }
    } catch (e) {
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.error,
          title: 'Error',
          subtitle: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsyncValue = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Edit Admin Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update your administrator details below.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: profileAsyncValue.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => const Text('Error loading details'),
                data: (profile) {
                  return Column(
                    children: [
                      ProfileDetailRow(
                        title: 'FULL NAME',
                        value: profile?.fullName ?? 'N/A',
                        onTap: () async {
                          final newValue = await TextInputDialog.show(
                            context: context,
                            title: 'Name',
                            initialValue: profile?.fullName ?? '',
                          );
                          if (newValue != null && newValue != profile?.fullName) {
                            await _updateProfileDatabase('full_name', newValue);
                          }
                        },
                      ),
                      const Divider(height: 30),
                      ProfileDetailRow(
                        title: 'EMAIL',
                        value: profile?.email ?? 'N/A',
                        onTap: () async {
                          final newValue = await TextInputDialog.show(
                            context: context,
                            title: 'Email',
                            initialValue: profile?.email ?? '',
                          );
                          if (newValue != null && newValue != profile?.email) {
                            await _updateEmailAuth(newValue);
                          }
                        },
                      ),
                      const Divider(height: 30),
                      ProfileDetailRow(
                        title: 'PHONE NUMBER',
                        value: profile?.phoneNumber ?? 'N/A',
                        onTap: () async {
                          final newValue = await TextInputDialog.show(
                            context: context,
                            title: 'Phone Number',
                            initialValue: profile?.phoneNumber ?? '',
                          );
                          if (newValue != null && newValue != profile?.phoneNumber) {
                            await _updateProfileDatabase('phone_number', newValue);
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
