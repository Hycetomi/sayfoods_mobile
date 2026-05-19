import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sayfoods_app/src/features/blog/application/blog_provider.dart';
import 'package:sayfoods_app/src/features/blog/domain/blog_post_model.dart';
import 'package:sayfoods_app/src/features/blog/presentation/add_edit_blog_post_screen.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_app_bar.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_modal.dart';
import 'package:sayfoods_app/src/shared/utils/error_handler.dart';

class AdminBlogScreen extends ConsumerWidget {
  const AdminBlogScreen({super.key});

  static const _purple = Color(0xFF5B1380);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(adminBlogPostsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const SayfoodsAppBar(
        title: 'Blog Posts',
        showBackButton: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _purple,
        child: const Icon(Icons.add_rounded, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AddEditBlogPostScreen()),
        ).then((_) => ref.invalidate(adminBlogPostsProvider)),
      ),
      body: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.article_outlined,
                      size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No blog posts yet.\nTap + to write your first post.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 15),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _AdminBlogTile(
                post: post,
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddEditBlogPostScreen(post: post)),
                ).then((_) => ref.invalidate(adminBlogPostsProvider)),
                onDelete: () => _confirmDelete(context, ref, post),
                onTogglePublish: () => _togglePublish(context, ref, post),
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

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, BlogPostModel post) async {
    bool confirmed = false;
    await SayfoodsModal.show(
      context: context,
      type: SayfoodsModalType.error,
      title: 'Delete Post',
      subtitle: 'Delete "${post.title}"? This cannot be undone.',
      primaryButtonText: 'Delete',
      onPrimaryPressed: () {
        confirmed = true;
        Navigator.pop(context);
      },
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () => Navigator.pop(context),
    );
    if (!confirmed) return;
    try {
      await ref.read(blogNotifierProvider.notifier).deletePost(post.id);
      ref.invalidate(adminBlogPostsProvider);
      if (context.mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.success,
          title: 'Deleted',
          subtitle: 'Post removed successfully.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.error,
          title: 'Error',
          subtitle: e.toString(),
        );
      }
    }
  }

  Future<void> _togglePublish(
      BuildContext context, WidgetRef ref, BlogPostModel post) async {
    try {
      await ref
          .read(blogNotifierProvider.notifier)
          .togglePublish(post.id, post.published);
      ref.invalidate(adminBlogPostsProvider);
    } catch (e) {
      if (context.mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.error,
          title: 'Error',
          subtitle: e.toString(),
        );
      }
    }
  }
}

class _AdminBlogTile extends StatelessWidget {
  final BlogPostModel post;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePublish;

  const _AdminBlogTile({
    required this.post,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublish,
  });

  static const _purple = Color(0xFF5B1380);

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  post.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onTogglePublish,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: post.published
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    post.published ? 'Published' : 'Draft',
                    style: TextStyle(
                      color: post.published
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            post.excerpt,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 13, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(post.author,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500)),
              const Spacer(),
              Text(
                DateFormat('MMM d, yyyy').format(post.createdAt),
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade400),
              ),
              const SizedBox(width: 12),
              // Edit
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.edit_rounded,
                      size: 18, color: _purple),
                ),
              ),
              const SizedBox(width: 8),
              // Delete
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 18, color: Colors.red.shade400),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
