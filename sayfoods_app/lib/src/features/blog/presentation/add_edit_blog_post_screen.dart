import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayfoods_app/src/features/blog/application/blog_provider.dart';
import 'package:sayfoods_app/src/features/blog/domain/blog_post_model.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_app_bar.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_modal.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_text_field.dart';
import 'package:sayfoods_app/src/shared/utils/error_handler.dart';

class AddEditBlogPostScreen extends ConsumerStatefulWidget {
  final BlogPostModel? post; // null = create, non-null = edit
  const AddEditBlogPostScreen({super.key, this.post});

  @override
  ConsumerState<AddEditBlogPostScreen> createState() =>
      _AddEditBlogPostScreenState();
}

class _AddEditBlogPostScreenState
    extends ConsumerState<AddEditBlogPostScreen> {
  static const _purple = Color(0xFF5B1380);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _category;
  late final TextEditingController _excerpt;
  late final TextEditingController _author;
  late final TextEditingController _authorRole;
  late final TextEditingController _readTime;
  late final List<TextEditingController> _paragraphs;
  late bool _published;
  late bool _featured;
  bool _saving = false;
  File? _coverImageFile; // newly picked file (not yet uploaded)
  String? _coverImageUrl; // existing URL (from DB when editing)

  bool get _isEditing => widget.post != null;

  @override
  void initState() {
    super.initState();
    final p = widget.post;
    _title = TextEditingController(text: p?.title ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _excerpt = TextEditingController(text: p?.excerpt ?? '');
    _author =
        TextEditingController(text: p?.author ?? 'SayFoods Team');
    _authorRole =
        TextEditingController(text: p?.authorRole ?? 'Content Team');
    _readTime =
        TextEditingController(text: p?.readTime ?? '3 min read');
    _paragraphs = (p?.body.isNotEmpty == true)
        ? p!.body.map((t) => TextEditingController(text: t)).toList()
        : [TextEditingController()];
    _published = p?.published ?? true;
    _featured = p?.featured ?? false;
    _coverImageUrl = p?.coverImage;
  }

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _excerpt.dispose();
    _author.dispose();
    _authorRole.dispose();
    _readTime.dispose();
    for (final c in _paragraphs) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (picked != null) {
      setState(() => _coverImageFile = File(picked.path));
    }
  }

  // Uploads the picked file to blog_images bucket and returns the public URL.
  Future<String?> _uploadCoverImage() async {
    if (_coverImageFile == null) return _coverImageUrl;
    try {
      final bytes = await _coverImageFile!.readAsBytes();
      final ext = _coverImageFile!.path.split('.').last.toLowerCase();
      final fileName =
          'cover_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final supabase = Supabase.instance.client;
      await supabase.storage
          .from('blog_images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$ext',
              upsert: true,
            ),
          );
      return supabase.storage
          .from('blog_images')
          .getPublicUrl(fileName);
    } catch (e) {
      return _coverImageUrl; // keep existing URL on upload error
    }
  }

  String _generateSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // Upload cover image first if a new one was picked
    final coverUrl = await _uploadCoverImage();

    final body = _paragraphs
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final data = <String, dynamic>{
      'title': _title.text.trim(),
      'slug': _isEditing
          ? widget.post!.slug
          : _generateSlug(_title.text.trim()),
      'category': _category.text.trim(),
      'category_color': '#5B1380',
      'excerpt': _excerpt.text.trim(),
      'body': body,
      'author': _author.text.trim(),
      'author_role': _authorRole.text.trim(),
      'read_time': _readTime.text.trim(),
      'cover_image': coverUrl,
      'published': _published,
      'featured': _featured,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      if (_isEditing) {
        await ref
            .read(blogNotifierProvider.notifier)
            .updatePost(widget.post!.id, data);
      } else {
        data['created_by'] =
            null; // optionally set to current user id
        await ref
            .read(blogNotifierProvider.notifier)
            .createPost(data);
      }
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.success,
          title: _isEditing ? 'Post Updated' : 'Post Created',
          subtitle: _isEditing
              ? '"${_title.text.trim()}" has been updated.'
              : '"${_title.text.trim()}" has been published.',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.error,
          title: 'Error',
          subtitle: ErrorHelper.getErrorMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: SayfoodsAppBar(
        title: _isEditing ? 'Edit Post' : 'New Post',
        showBackButton: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Cover image picker
            _CoverImagePicker(
              existingUrl: _coverImageUrl,
              pickedFile: _coverImageFile,
              onPick: _pickCoverImage,
              onRemove: () => setState(() {
                _coverImageFile = null;
                _coverImageUrl = null;
              }),
            ),
            const SizedBox(height: 16),

            _field('Title', _title, required: true, maxLines: 2),
            _field('Category', _category, required: true),
            _field('Excerpt', _excerpt,
                required: true, maxLines: 3,
                hint: 'Short summary shown in the list view'),
            _field('Author', _author),
            _field('Author Role', _authorRole),
            _field('Read Time', _readTime,
                hint: 'e.g. 5 min read'),
            const SizedBox(height: 8),

            // Toggles
            _toggle('Published', _published,
                (v) => setState(() => _published = v)),
            _toggle('Featured', _featured,
                (v) => setState(() => _featured = v)),

            const SizedBox(height: 24),

            // Body paragraphs
            Row(
              children: [
                const Text('Body',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add paragraph'),
                  style: TextButton.styleFrom(
                      foregroundColor: _purple),
                  onPressed: () => setState(() =>
                      _paragraphs.add(TextEditingController())),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_paragraphs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Add your first paragraph using the button above.',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 14),
                  ),
                ),
              )
            else
              ...List.generate(_paragraphs.length, (i) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _paragraphs[i],
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Paragraph ${i + 1}…',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                      ),
                      if (_paragraphs.length > 1)
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline_rounded,
                              color: Colors.red.shade300, size: 20),
                          onPressed: () {
                            _paragraphs[i].dispose();
                            setState(() => _paragraphs.removeAt(i));
                          },
                        ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {bool required = false, int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _purple)),
            ),
            validator: required
                ? (v) => (v == null || v.trim().isEmpty)
                    ? '$label is required'
                    : null
                : null,
          ),
        ],
      ),
    );
  }

  Widget _toggle(
      String label, bool value, void Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          Switch(
            value: value,
            activeThumbColor: _purple,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ── Cover image picker widget ─────────────────────────────────────────────────

class _CoverImagePicker extends StatelessWidget {
  final String? existingUrl;
  final File? pickedFile;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _CoverImagePicker({
    required this.existingUrl,
    required this.pickedFile,
    required this.onPick,
    required this.onRemove,
  });

  static const _purple = Color(0xFF5B1380);

  @override
  Widget build(BuildContext context) {
    final hasImage = pickedFile != null || existingUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cover Image',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPick,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasImage ? _purple : Colors.grey.shade300,
                width: hasImage ? 1.5 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      pickedFile != null
                          ? Image.file(pickedFile!, fit: BoxFit.cover)
                          : Image.network(existingUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image_rounded,
                                      color: Colors.grey)),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded,
                          size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 6),
                      Text('Tap to add cover image',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
