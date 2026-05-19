import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/blog/domain/blog_post_model.dart';

// ── Client — published posts only ────────────────────────────────────────────

final publishedBlogPostsProvider =
    FutureProvider.autoDispose<List<BlogPostModel>>((ref) async {
  final response = await Supabase.instance.client
      .from('blog_posts')
      .select()
      .eq('published', true)
      .order('created_at', ascending: false);
  return (response as List)
      .map((json) => BlogPostModel.fromJson(json as Map<String, dynamic>))
      .toList();
});

// ── Admin — all posts including drafts ───────────────────────────────────────

final adminBlogPostsProvider =
    FutureProvider.autoDispose<List<BlogPostModel>>((ref) async {
  final response = await Supabase.instance.client
      .from('blog_posts')
      .select()
      .order('created_at', ascending: false);
  return (response as List)
      .map((json) => BlogPostModel.fromJson(json as Map<String, dynamic>))
      .toList();
});

// ── Admin CRUD notifier ───────────────────────────────────────────────────────

class BlogNotifier extends StateNotifier<AsyncValue<void>> {
  BlogNotifier() : super(const AsyncValue.data(null));

  final _db = Supabase.instance.client.from('blog_posts');

  Future<void> createPost(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _db.insert(data);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updatePost(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _db.update(data).eq('id', id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deletePost(String id) async {
    state = const AsyncValue.loading();
    try {
      await _db.delete().eq('id', id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> togglePublish(String id, bool current) async {
    state = const AsyncValue.loading();
    try {
      await _db.update({'published': !current}).eq('id', id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final blogNotifierProvider =
    StateNotifierProvider<BlogNotifier, AsyncValue<void>>(
  (ref) => BlogNotifier(),
);
