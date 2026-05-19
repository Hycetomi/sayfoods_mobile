class BlogPostModel {
  final String id;
  final String slug;
  final String title;
  final String category;
  final String categoryColor;
  final String excerpt;
  final List<String> body;
  final String? coverImage;
  final String author;
  final String authorRole;
  final String readTime;
  final bool featured;
  final bool published;
  final DateTime createdAt;

  const BlogPostModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.category,
    required this.categoryColor,
    required this.excerpt,
    required this.body,
    this.coverImage,
    required this.author,
    required this.authorRole,
    required this.readTime,
    required this.featured,
    required this.published,
    required this.createdAt,
  });

  factory BlogPostModel.fromJson(Map<String, dynamic> json) {
    return BlogPostModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      categoryColor: json['category_color'] as String? ?? '#5B1380',
      excerpt: json['excerpt'] as String,
      body: List<String>.from(json['body'] as List? ?? []),
      coverImage: json['cover_image'] as String?,
      author: json['author'] as String? ?? 'SayFoods Team',
      authorRole: json['author_role'] as String? ?? 'Content Team',
      readTime: json['read_time'] as String? ?? '3 min read',
      featured: json['featured'] as bool? ?? false,
      published: json['published'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
