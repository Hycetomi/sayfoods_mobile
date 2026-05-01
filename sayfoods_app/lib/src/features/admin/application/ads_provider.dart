import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BannerMedia {
  final String name;
  final String url;
  final bool isVideo;

  BannerMedia({required this.name, required this.url, required this.isVideo});
}

final adsListProvider = FutureProvider<List<BannerMedia>>((ref) async {
  final supabase = Supabase.instance.client;
  
  try {
    final List<FileObject> objects = await supabase.storage.from('banners').list();
    
    // Filter out hidden files or folders without extensions
    final validObjects = objects.where((obj) => obj.name.contains('.')).toList();
    
    return validObjects.map((obj) {
      final url = supabase.storage.from('banners').getPublicUrl(obj.name);
      final ext = obj.name.split('.').last.toLowerCase();
      final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(ext);
      
      return BannerMedia(
        name: obj.name,
        url: url,
        isVideo: isVideo,
      );
    }).toList();
  } catch (e) {
    print('Error fetching banners: $e');
    return [];
  }
});
