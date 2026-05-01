import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/admin/application/ads_provider.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_app_bar.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_modal.dart';

class ManageAdsScreen extends ConsumerStatefulWidget {
  const ManageAdsScreen({super.key});

  @override
  ConsumerState<ManageAdsScreen> createState() => _ManageAdsScreenState();
}

class _ManageAdsScreenState extends ConsumerState<ManageAdsScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _uploadMedia() async {
    final XFile? media = await _picker.pickMedia();
    if (media == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final file = File(media.path);
      final fileExt = media.name.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      
      await Supabase.instance.client.storage
          .from('banners')
          .upload(fileName, file);

      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.success,
          title: 'Success',
          subtitle: 'Media uploaded successfully.',
        );
        // Refresh the list
        ref.invalidate(adsListProvider);
      }
    } catch (e) {
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.error,
          title: 'Upload Failed',
          subtitle: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _deleteMedia(BannerMedia media) async {
    // Show confirmation first
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Media?'),
        content: const Text('Are you sure you want to remove this banner?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.storage
                    .from('banners')
                    .remove([media.name]);
                if (mounted) {
                  SayfoodsModal.show(
                    context: context,
                    type: SayfoodsModalType.success,
                    title: 'Deleted',
                    subtitle: 'Banner removed successfully.',
                  );
                  ref.invalidate(adsListProvider);
                }
              } catch (e) {
                if (mounted) {
                  SayfoodsModal.show(
                    context: context,
                    type: SayfoodsModalType.error,
                    title: 'Error',
                    subtitle: 'Could not delete: $e',
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adsAsync = ref.watch(adsListProvider);

    return Scaffold(
      appBar: const SayfoodsAppBar(
        showBackButton: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _uploadMedia,
        backgroundColor: const Color(0xFF5A189A),
        icon: _isUploading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.add_photo_alternate, color: Colors.white),
        label: Text(_isUploading ? 'Uploading...' : 'Upload Media', style: const TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Ads',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload images or videos to display on the homepage banner carousel.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: adsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                data: (ads) {
                  if (ads.isEmpty) {
                    return const Center(
                      child: Text('No banners uploaded yet.', style: TextStyle(color: Colors.grey)),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: ads.length,
                    itemBuilder: (context, index) {
                      final ad = ads[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ad.isVideo
                                ? Container(
                                    color: Colors.black12,
                                    child: const Center(
                                      child: Icon(Icons.videocam, size: 40, color: Colors.grey),
                                    ),
                                  )
                                : Image.network(
                                    ad.url,
                                    fit: BoxFit.cover,
                                  ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: InkWell(
                                onTap: () => _deleteMedia(ad),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.delete, color: Colors.red, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
