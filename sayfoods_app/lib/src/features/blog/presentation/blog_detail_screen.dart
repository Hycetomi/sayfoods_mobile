import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sayfoods_app/src/features/blog/domain/blog_post_model.dart';

class BlogDetailScreen extends StatelessWidget {
  final BlogPostModel post;
  const BlogDetailScreen({super.key, required this.post});

  static const _purple = Color(0xFF5B1380);
  static const _orange = Color(0xFFF28F2A);

  @override
  Widget build(BuildContext context) {
    Color catColor;
    try {
      final hex = post.categoryColor.replaceFirst('#', 'FF');
      catColor = Color(int.parse(hex, radix: 16));
    } catch (_) {
      catColor = _purple;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── Hero image app bar ────────────────────────────────────────
          SliverAppBar(
            expandedHeight: post.coverImage != null ? 260 : 120,
            pinned: true,
            backgroundColor: _purple,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.black87),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: post.coverImage != null
                  ? Image.network(
                      post.coverImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: _purple),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_purple, Color(0xFF8B21C0)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.article_rounded,
                            size: 64, color: Colors.white24),
                      ),
                    ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      post.category,
                      style: TextStyle(
                          color: catColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Author row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: _purple.withValues(alpha: 0.1),
                        child: Text(
                          post.author.isNotEmpty
                              ? post.author[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                              color: _purple,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.author,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                          Text(post.authorRole,
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11)),
                        ],
                      ),
                      const Spacer(),
                      Icon(Icons.access_time_rounded,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(post.readTime,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMM d, yyyy').format(post.createdAt),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade100),
                  const SizedBox(height: 20),

                  // Excerpt (lead paragraph)
                  Text(
                    post.excerpt,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Body paragraphs
                  if (post.body.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Full article coming soon.',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    ...post.body.asMap().entries.map((entry) {
                      final isFirst = entry.key == 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: isFirst ? 16 : 15,
                            color: Colors.black87,
                            height: 1.7,
                            fontWeight: isFirst
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 32),

                  // Footer tag
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _orange.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _orange.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.storefront_rounded,
                            color: _orange, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Brought to you by SayFoods — your go-to for fresh grocery delivery.',
                            style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
