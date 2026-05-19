import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sayfoods_app/src/features/blog/application/blog_provider.dart';
import 'package:sayfoods_app/src/features/blog/domain/blog_post_model.dart';
import 'package:sayfoods_app/src/features/blog/presentation/blog_detail_screen.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_app_bar.dart';

// ── Placeholder posts shown when the DB has no published content yet ──────────
final _placeholderPosts = [
  BlogPostModel(
    id: '_p1',
    slug: 'fresh-meat-guide',
    title: 'How to Choose the Freshest Meat for Your Family',
    category: 'Food Tips',
    categoryColor: '#5B1380',
    excerpt:
        'Learn the simple checks that separate premium cuts from average ones — colour, texture, and smell decoded.',
    body: const [
      'When shopping for fresh meat, colour is your first clue. Beef should be a bright cherry-red, while chicken should be pale pink with no grey patches.',
      'Always press the meat gently. Fresh meat springs back; older meat leaves an indentation. This quick test takes seconds and tells you a lot.',
      'At SayFoods, every product is sourced fresh daily and delivered the same day. No cold-chain shortcuts, no compromises.',
    ],
    author: 'SayFoods Team',
    authorRole: 'Food Quality',
    readTime: '3 min read',
    featured: true,
    published: true,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  BlogPostModel(
    id: '_p2',
    slug: 'grocery-delivery-benefits',
    title: '5 Reasons to Switch to Grocery Delivery in Lagos',
    category: 'Lifestyle',
    categoryColor: '#F28F2A',
    excerpt:
        'Traffic, queues, and spoilt produce — see how same-day delivery fixes the biggest grocery frustrations.',
    body: const [
      'Lagos traffic turns a 10-minute grocery run into an hour-long ordeal. With SayFoods, your order arrives at your door while you stay productive.',
      'Impulse buying accounts for up to 40% of most grocery bills. Ordering online lets you stick to your list and your budget.',
      'Our riders pick up from the market the same morning and deliver by afternoon — produce doesn\'t get fresher than that.',
    ],
    author: 'SayFoods Team',
    authorRole: 'Content Team',
    readTime: '4 min read',
    featured: false,
    published: true,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  BlogPostModel(
    id: '_p3',
    slug: 'dairy-storage-tips',
    title: 'Keep Your Dairy Fresh: Storage Tips That Actually Work',
    category: 'Food Tips',
    categoryColor: '#5B1380',
    excerpt:
        'Eggs on the door shelf? Milk at the front? Small habits that shorten shelf life — and how to fix them.',
    body: const [
      'The fridge door is the warmest spot in your refrigerator — not ideal for eggs or milk. Move them to the main shelf for longer freshness.',
      'Milk absorbs odours easily. Keep it sealed and away from strong-smelling foods like onions or leftover stews.',
      'At SayFoods, our dairy is sourced fresh weekly and stored at the correct temperature all the way to your door.',
    ],
    author: 'SayFoods Team',
    authorRole: 'Nutrition',
    readTime: '2 min read',
    featured: false,
    published: true,
    createdAt: DateTime.now().subtract(const Duration(days: 9)),
  ),
];

class BlogListScreen extends ConsumerWidget {
  const BlogListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(publishedBlogPostsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const SayfoodsAppBar(
        title: 'Blog',
        showBackButton: true,
      ),
      body: postsAsync.when(
        data: (posts) {
          // Show placeholder content while the blog DB is being populated
          final display = posts.isEmpty ? _placeholderPosts : posts;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: display.length,
            itemBuilder: (context, index) =>
                _BlogCard(post: display[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  final BlogPostModel post;
  const _BlogCard({required this.post});

  static const _purple = Color(0xFF5B1380);

  @override
  Widget build(BuildContext context) {
    Color catColor;
    try {
      final hex = post.categoryColor.replaceFirst('#', 'FF');
      catColor = Color(int.parse(hex, radix: 16));
    } catch (_) {
      catColor = _purple;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => BlogDetailScreen(post: post)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image or placeholder
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: post.coverImage != null
                  ? Image.network(
                      post.coverImage!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      post.category,
                      style: TextStyle(
                          color: catColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    post.title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Excerpt
                  Text(
                    post.excerpt,
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Author + read time row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: _purple.withValues(alpha: 0.1),
                        child: Text(
                          post.author.isNotEmpty
                              ? post.author[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                              color: _purple,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          post.author,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.access_time_rounded,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text(
                        post.readTime,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('MMM d').format(post.createdAt),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: _purple.withValues(alpha: 0.06),
      child: Icon(Icons.article_rounded,
          size: 48, color: _purple.withValues(alpha: 0.3)),
    );
  }
}
