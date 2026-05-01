import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

// --- Shared & Feature Widgets ---
import 'package:sayfoods_app/src/features/profile/presentation/widgets/profile_detail_row.dart';
import 'package:sayfoods_app/src/features/profile/presentation/widgets/settings_action_row.dart';
import 'package:sayfoods_app/src/features/profile/presentation/widgets/add_address_sheet.dart';
import 'package:sayfoods_app/src/shared/widgets/text_input_dialog.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_modal.dart';

// --- Providers ---
import 'package:sayfoods_app/src/features/profile/application/address_provider.dart';
import 'package:sayfoods_app/src/features/profile/application/delivery_zone_provider.dart';
import 'package:sayfoods_app/src/features/profile/application/profile_provider.dart';

// 1. Changed StatefulWidget to ConsumerStatefulWidget
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

// 2. Changed State to ConsumerState
class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final Color _primaryPurple = const Color(0xFF5A189A);
  final Color _bgColor = const Color(0xFFF3F3F3);

  // --- 1. The Supabase Database Updater (For Name & Phone) ---
  Future<void> _updateProfileDatabase(String column, String newValue) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null || newValue.isEmpty) return;

    try {
      await supabase
          .from('profiles')
          .update({column: newValue})
          .eq('id', user.id);

      // Tell Riverpod to fetch the fresh data so the UI updates instantly!
      ref.invalidate(userProfileProvider);

      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.success,
          title: 'Success',
          subtitle: 'Updated successfully!',
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

  // --- 2. The Supabase Auth Updater (For Email) ---
  Future<void> _updateEmailAuth(String newEmail) async {
    if (newEmail.isEmpty) return;
    try {
      // Emails live in Supabase Auth, not the profiles table!
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

  // --- 3. Avatar Upload Logic ---
  Future<void> _updateAvatarUrl(String url) async {
    await _updateProfileDatabase('avatar_url', url);
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile == null) return;
    
    try {
      // Show loading indicator or simple message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading avatar...')),
        );
      }

      final file = File(pickedFile.path);
      final fileExt = pickedFile.name.split('.').last;
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final fileName = '${user.id}/profile.$fileExt';
      
      await Supabase.instance.client.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);
          
      // Force cache break by appending timestamp
      final finalUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      await _updateAvatarUrl(finalUrl);
    } catch (e) {
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.error,
          title: 'Upload Failed',
          subtitle: e.toString(),
        );
      }
    }
  }

  void _showAvatarOptions() {
    SayfoodsModal.showBottomSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Change Avatar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Color(0xFF5A189A)),
            title: const Text('Upload from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickAndUploadAvatar();
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Or choose a food theme:', style: TextStyle(color: Colors.grey)),
            ),
          ),
          ListTile(
            leading: const CircleAvatar(backgroundImage: AssetImage('assets/images/meat.png')),
            title: const Text('Meat Theme'),
            onTap: () {
              Navigator.pop(context);
              _updateAvatarUrl('assets/images/meat.png');
            },
          ),
          ListTile(
            leading: const CircleAvatar(backgroundImage: AssetImage('assets/images/logo.png')),
            title: const Text('SayFoods Logo'),
            onTap: () {
              Navigator.pop(context);
              _updateAvatarUrl('assets/images/logo.png');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 3. Watch the data!
    final profileAsyncValue = ref.watch(userProfileProvider);
    final addressesAsyncValue = ref.watch(addressProvider);
    final zonesAsyncValue = ref.watch(deliveryZoneProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. Purple Header ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 40),
              decoration: BoxDecoration(
                color: _primaryPurple,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Top bar with back button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  // Avatar
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: profileAsyncValue.when(
                          data: (profile) {
                            final String? url = profile?.avatarUrl;
                            ImageProvider imageProvider;
                            if (url != null && url.isNotEmpty) {
                              if (url.startsWith('http')) {
                                imageProvider = NetworkImage(url);
                              } else {
                                imageProvider = AssetImage(url);
                              }
                            } else {
                              imageProvider = const AssetImage('assets/images/logo.png');
                            }
                            
                            return CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              backgroundImage: imageProvider,
                            );
                          },
                          loading: () => const CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: CircularProgressIndicator(),
                          ),
                          error: (_, __) => const CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            backgroundImage: AssetImage('assets/images/logo.png'),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _showAvatarOptions,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. Dynamic Profile Name
                  profileAsyncValue.when(
                    data: (profile) => Text(
                      profile?.fullName ?? 'Sayfoods User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    loading: () =>
                        const CircularProgressIndicator(color: Colors.white),
                    error: (_, __) => const Text(
                      'Sayfoods User',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 2. Profile Details Card ---
                  const Text(
                    'PROFILE DETAILS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    // 5. Dynamic Profile Details List
                    child: profileAsyncValue.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) => const Text('Error loading details'),
                      data: (profile) {
                        return Column(
                          children: [
                            ProfileDetailRow(
                              title: 'ACCOUNT NAME',
                              value: profile?.fullName ?? 'N/A',
                              onTap: () async {
                                final newValue = await TextInputDialog.show(
                                  context: context,
                                  title: 'Name',
                                  initialValue: profile?.fullName ?? '',
                                );
                                if (newValue != null &&
                                    newValue != profile?.fullName) {
                                  await _updateProfileDatabase(
                                    'full_name',
                                    newValue,
                                  );
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
                                if (newValue != null &&
                                    newValue != profile?.email) {
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
                                if (newValue != null &&
                                    newValue != profile?.phoneNumber) {
                                  await _updateProfileDatabase(
                                    'phone_number',
                                    newValue,
                                  );
                                }
                              },
                            ),
                            const Divider(height: 30),
                            ProfileDetailRow(
                              title: 'DATE OF BIRTH',
                              value: 'N/A',
                              onTap: () async {
                                final DateTime? pickedDate =
                                    await showDatePicker(
                                      context: context,
                                      initialDate: DateTime(2000, 1, 1),
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime.now(),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: ColorScheme.light(
                                              primary: _primaryPurple,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                if (pickedDate != null) {
                                  print('Selected Date: $pickedDate');
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- 3. Addresses Card ---
                  const Text(
                    'ADDRESSES',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Align properly
                      children: [
                        // Add New Address Button
                        InkWell(
                          onTap: () {
                            SayfoodsModal.showBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              child: const AddAddressSheet(),
                            );
                          }, // Triggers the bottom sheet!
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.home, size: 20),
                                SizedBox(width: 12),
                                Text(
                                  'Add new address',
                                  style: TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 6. Dynamic Address List
                        addressesAsyncValue.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, _) => Text(
                            'Error: $err',
                            style: const TextStyle(color: Colors.red),
                          ),
                          data: (addresses) {
                            if (addresses.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'No addresses saved yet.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }

                            // Ensure O(1) zone lookups!
                            final zoneMap = <String, String>{};
                            if (zonesAsyncValue.hasValue) {
                              for (final z in zonesAsyncValue.value!) {
                                zoneMap[z.id] = z.name;
                              }
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: addresses.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 24),
                              itemBuilder: (context, index) {
                                final address = addresses[index];

                                // Fast O(1) lookup
                                String zoneName = zoneMap[address.zoneId] ?? 'Unknown Zone';

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (address.label != null &&
                                              address.label!.isNotEmpty) ...[
                                            Text(
                                              address.label!,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                          ],
                                          Text(
                                            '${address.street},\n${address.city ?? 'Lagos'}',
                                            style: const TextStyle(height: 1.4),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Zone: $zoneName',
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(addressProvider.notifier)
                                            .deleteAddress(address.id);
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- 4. Settings Links ---
                  SettingsActionRow(
                    icon: Icons.phone,
                    title: 'CONTACT US',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  SettingsActionRow(
                    icon: Icons.description,
                    title: 'LEGAL',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  SettingsActionRow(
                    icon: Icons.card_giftcard,
                    title: 'REFERRALS',
                    onTap: () {},
                  ),
                  const SizedBox(height: 48),

                  // Sign Out
                  InkWell(
                    onTap: () async {
                      // Navigate back to the root before signing out to avoid orphaned navigator screens
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      await Supabase.instance.client.auth.signOut();
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SIGN OUT',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.logout, color: Colors.red),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
