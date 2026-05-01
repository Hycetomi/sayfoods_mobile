import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:sayfoods_app/src/features/admin/application/ads_provider.dart';

class AdsCarousel extends ConsumerStatefulWidget {
  const AdsCarousel({super.key});

  @override
  ConsumerState<AdsCarousel> createState() => _AdsCarouselState();
}

class _AdsCarouselState extends ConsumerState<AdsCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer(List<BannerMedia> ads) {
    _timer?.cancel();
    if (ads.length <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_videoController != null && _videoController!.value.isPlaying) {
        // Do not auto-scroll if video is currently playing
        return;
      }
      
      if (_pageController.hasClients) {
        int nextIndex = (_currentIndex + 1) % ads.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onPageChanged(int index, List<BannerMedia> ads) {
    setState(() {
      _currentIndex = index;
    });

    _videoController?.dispose();
    _videoController = null;

    final currentAd = ads[index];
    if (currentAd.isVideo) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(currentAd.url))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController!.play();
            _videoController!.addListener(() {
              // When video finishes playing, move to next
              if (_videoController!.value.position >= _videoController!.value.duration && !_videoController!.value.isPlaying) {
                if (_pageController.hasClients && ads.length > 1) {
                  int nextIndex = (_currentIndex + 1) % ads.length;
                  _pageController.animateToPage(
                    nextIndex,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              }
            });
          }
        });
    }
  }

  Widget _buildDefaultBanner() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/images/banner.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black.withOpacity(0.4),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SayFoods',
                style: TextStyle(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                'Introducing',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                'Eggs & Cousins',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adsAsync = ref.watch(adsListProvider);

    return adsAsync.when(
      loading: () => Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator(color: Colors.orange)),
      ),
      error: (err, stack) => _buildDefaultBanner(),
      data: (ads) {
        if (ads.isEmpty) {
          return _buildDefaultBanner();
        }

        // Only start timer if it's the first time we got data and timer isn't running
        if (_timer == null && ads.length > 1) {
          _startTimer(ads);
          // Manually trigger the first page logic if it's a video
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ads.isNotEmpty && mounted && _videoController == null) {
               _onPageChanged(0, ads);
            }
          });
        } else if (ads.length == 1) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
             if (mounted && _videoController == null && ads[0].isVideo) {
               _onPageChanged(0, ads);
             }
           });
        }

        return Column(
          children: [
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => _onPageChanged(index, ads),
                itemCount: ads.length,
                itemBuilder: (context, index) {
                  final ad = ads[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black12,
                    ),
                    child: ad.isVideo
                        ? (_videoController != null && _videoController!.value.isInitialized && _currentIndex == index)
                            ? FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _videoController!.value.size.width,
                                  height: _videoController!.value.size.height,
                                  child: VideoPlayer(_videoController!),
                                ),
                              )
                            : const Center(child: CircularProgressIndicator(color: Colors.orange))
                        : Image.network(
                            ad.url,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator(color: Colors.orange));
                            },
                            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                          ),
                  );
                },
              ),
            ),
            if (ads.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(ads.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentIndex == index ? Colors.orange : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }),
                ),
              ),
          ],
        );
      },
    );
  }
}
