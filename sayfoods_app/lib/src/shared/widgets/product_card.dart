import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sayfoods_app/src/features/products/application/favorites_provider.dart';
import 'package:sayfoods_app/src/shared/theme/app_colors.dart';

class ProductCard extends ConsumerStatefulWidget {
  final String productId;
  final String title;
  final String description;
  final String price;
  final double rating;
  final String imagePath;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.productId,
    required this.title,
    required this.description,
    required this.price,
    required this.rating,
    required this.imagePath,
    this.onTap,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _pressed = false;
  bool _heartPopped = false;

  void _handleHeartTap() {
    setState(() => _heartPopped = true);
    ref.read(favoritesProvider.notifier).toggle(widget.productId);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _heartPopped = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final favIds = ref.watch(favoritesProvider);
    final isFavourite = favIds.contains(widget.productId);

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image + heart icon
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                        image: DecorationImage(
                          image: widget.imagePath.startsWith('http')
                              ? NetworkImage(widget.imagePath)
                              : AssetImage(widget.imagePath) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Heart toggle with pop micro-animation
                    Positioned(
                      top: 8,
                      right: 8, // Moved to right for a more standard premium feel
                      child: GestureDetector(
                        onTap: widget.productId.isEmpty ? null : _handleHeartTap,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: AnimatedScale(
                            scale: _heartPopped ? 1.3 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.elasticOut,
                            child: Icon(
                              isFavourite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFavourite ? AppColors.error : AppColors.textDisabled,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Details
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.description,
                            style: const TextStyle(
                              color: AppColors.textSecondary, 
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.price,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700, 
                              fontSize: 15,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(LucideIcons.star,
                                  color: AppColors.warning, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                widget.rating.toString(),
                                style: const TextStyle(
                                    fontSize: 13, 
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
