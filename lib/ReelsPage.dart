import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rellssserr/ReelsCubit.dart';
import 'package:rellssserr/ReelsState.dart';
import 'package:rellssserr/Video%20Model.dart';


class ReelsPage extends StatefulWidget {
  const ReelsPage({Key? key}) : super(key: key);

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}
//
class _ReelsPageState extends State<ReelsPage> {
  late PageController _pageController;
  List<BetterPlayerController?> _controllers = [];
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
  
    final videos = VideoModel.getSampleVideos();
    _controllers = List.generate(videos.length, (_) => null);
    
    // تحميل مسبق لأول فيديو وثاني فيديو لتحسين الأداء
    _preloadInitialVideos();
  }
  
  void _preloadInitialVideos() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        final state = context.read<ReelsCubit>().state;
        if (state is ReelsLoaded) {
          // تحميل الفيديو الأول
          _controllers[0] = _createController(state.videos[0]);
          _controllers[0]?.play();
          
          // تحميل مسبق للفيديو الثاني
          if (state.videos.length > 1) {
            _controllers[1] = _createController(state.videos[1]);
            // إيقاف الفيديو الثاني مؤقتًا ولكن تحميله في الخلفية
            _controllers[1]?.pause();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    
    // التخلص من جميع المتحكمين النشطة
    for (final controller in _controllers) {
      controller?.dispose();
    }
    
    super.dispose();
  }

  BetterPlayerController _createController(VideoModel video) {
    final betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      video.url,
      cacheConfiguration: const BetterPlayerCacheConfiguration(
        useCache: true,
        preCacheSize: 10 * 1024 * 1024, // 10MB تخزين مؤقت مسبق
        maxCacheSize: 100 * 1024 * 1024, // 100MB الحد الأقصى للتخزين المؤقت
        maxCacheFileSize: 10 * 1024 * 1024, // 10MB لكل ملف
      ),
      bufferingConfiguration: const BetterPlayerBufferingConfiguration(
        minBufferMs: 50000, // 50 ثانية
        maxBufferMs: 120000, // دقيقتان
        bufferForPlaybackMs: 2500, // 2.5 ثانية قبل بدء التشغيل
        bufferForPlaybackAfterRebufferMs: 5000, // 5 ثواني بعد إعادة التخزين المؤقت
      ),
    );

    final betterPlayerConfiguration = BetterPlayerConfiguration(
      autoPlay: true,
      looping: true,
      fit: BoxFit.cover,
      controlsConfiguration: const BetterPlayerControlsConfiguration(
        showControls: false, // إخفاء عناصر التحكم لتجربة مماثلة للريلز
        enableMute: false,
        enableFullscreen: false,
        enablePlayPause: false,
        enableProgressBar: false,
        enableSkips: false,
        enablePlaybackSpeed: false,
      ),
      placeholder: Image.network(
        video.thumbnailUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Container(color: Colors.black),
      ),
      autoDispose: false, // سنتعامل مع التخلص يدويًا
      deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
    );

    return BetterPlayerController(betterPlayerConfiguration)
      ..setupDataSource(betterPlayerDataSource);
  }

  void _handlePageChange(int index, BuildContext context) {
    final videos = (context.read<ReelsCubit>().state as ReelsLoaded).videos;
    
    // تحديث حالة الـ cubit
    context.read<ReelsCubit>().changeVideo(index);
    
    // إيقاف جميع الفيديوهات باستثناء الفيديو الحالي
    for (int i = 0; i < _controllers.length; i++) {
      if (i == index) {
        // تهيئة المتحكم إذا كان فارغًا
        _controllers[i] ??= _createController(videos[i]);
        _controllers[i]?.play();
        
        // تحميل مسبق للفيديو التالي
        if (i + 1 < videos.length && _controllers[i + 1] == null) {
          _controllers[i + 1] = _createController(videos[i + 1]);
          _controllers[i + 1]?.pause();
        }
        
        // تحميل مسبق للفيديو السابق أيضًا
        if (i - 1 >= 0 && _controllers[i - 1] == null) {
          _controllers[i - 1] = _createController(videos[i - 1]);
          _controllers[i - 1]?.pause();
        }
      } else if (_controllers[i] != null) {
        _controllers[i]?.pause();
        
        // التخلص من المتحكمين البعيدين عن العرض الحالي لتوفير الذاكرة
        if ((i - index).abs() > 2) {
          _controllers[i]?.dispose();
          _controllers[i] = null;
        }
      }
    }
  }

  Widget _buildVideoPlayer(VideoModel video, int index) {
    if (_controllers[index] == null) {
      _controllers[index] = _createController(video);
    }
    
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 9 / 16, // فيديو عمودي للريلز
          child: BetterPlayer(controller: _controllers[index]!),
        ),
        
        // واجهة المستخدم للفيديو
        Positioned(
          bottom: 20,
          left: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'فيديو #${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'اضغط للتفاعل',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        // أزرار التفاعل الافتراضية (مثل اليوتيوب)
        Positioned(
          right: 10,
          bottom: 100,
          child: Column(
            children: [
              _buildIconButton(Icons.favorite, '10K'),
              _buildIconButton(Icons.comment, '1.5K'),
              _buildIconButton(Icons.share, 'مشاركة'),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildIconButton(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<ReelsCubit, ReelsState>(
        builder: (context, state) {
          if (state is ReelsLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            );
          } else if (state is ReelsLoaded) {
            return Stack(
              children: [
                PageView.builder(
                  scrollDirection: Axis.vertical,
                  controller: _pageController,
                  itemCount: state.videos.length,
                  onPageChanged: (index) => _handlePageChange(index, context),
                  itemBuilder: (context, index) {
                    final video = state.videos[index];
                    return _buildVideoPlayer(video, index);
                  },
                ),
                // زر الرجوع
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else if (state is ReelsError) {
            return Center(
              child: Text(
                'حدث خطأ: ${state.message}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          } else {
            return const Center(
              child: Text(
                'حدث خطأ غير متوقع',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
        },
      ),
    );
  }
}