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

class _ReelsPageState extends State<ReelsPage> with WidgetsBindingObserver {
  late PageController _pageController;
  List<BetterPlayerController?> _controllers = [];
  int _currentVideoIndex = 0;
  bool _isDisposed = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // إضافة مراقب دورة حياة التطبيق
    _pageController = PageController();
    
    final videos = VideoModel.getSampleVideos();
    _controllers = List.generate(videos.length, (_) => null);
    
    // تحميل مسبق لأول فيديو فقط
    _preloadInitialVideos();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // التعامل مع تغييرات دورة حياة التطبيق
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // إيقاف جميع الفيديوهات عند مغادرة التطبيق
      _pauseAllControllers();
    } else if (state == AppLifecycleState.resumed) {
      // عند العودة للتطبيق، تشغيل الفيديو الحالي فقط
      _playCurrentVideoOnly();
    }
  }
  
  void _pauseAllControllers() {
    // إيقاف جميع المشغلات
    for (final controller in _controllers) {
      if (controller != null) {
        controller.pause();
      }
    }
  }
  
  void _playCurrentVideoOnly() {
    // التأكد من أن الفيديو الحالي فقط هو الذي يتم تشغيله
    if (!_isDisposed && _controllers.isNotEmpty) {
      for (int i = 0; i < _controllers.length; i++) {
        if (i == _currentVideoIndex && _controllers[i] != null) {
          _controllers[i]!.play();
        } else if (_controllers[i] != null) {
          _controllers[i]!.pause();
        }
      }
    }
  }
  
  void _preloadInitialVideos() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && !_isDisposed) {
        final state = context.read<ReelsCubit>().state;
        if (state is ReelsLoaded) {
          // تحميل الفيديو الأول فقط
          _controllers[0] = _createController(state.videos[0]);
          _controllers[0]?.play();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // إزالة المراقب
    _isDisposed = true;
    _pageController.dispose();
    
    // التخلص من جميع المتحكمين بشكل صحيح
    for (int i = 0; i < _controllers.length; i++) {
      if (_controllers[i] != null) {
        _controllers[i]!.pause();
        _controllers[i]!.dispose();
        _controllers[i] = null;
      }
    }
    
    super.dispose();
  }

  BetterPlayerController _createController(VideoModel video) {
    final betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      video.url,
      cacheConfiguration: const BetterPlayerCacheConfiguration(
        useCache: true,
        preCacheSize: 10 * 1024 * 1024,
        maxCacheSize: 100 * 1024 * 1024,
        maxCacheFileSize: 10 * 1024 * 1024,
      ),
      bufferingConfiguration: const BetterPlayerBufferingConfiguration(
        minBufferMs: 50000,
        maxBufferMs: 120000,
        bufferForPlaybackMs: 2500,
        bufferForPlaybackAfterRebufferMs: 5000,
      ),
    );

    final betterPlayerConfiguration = BetterPlayerConfiguration(
      autoPlay: false, // تم تغييره إلى false لتجنب التشغيل التلقائي المتعدد
      looping: true,
      fit: BoxFit.cover,
      handleLifecycle: true, // التعامل مع دورة حياة التطبيق
      controlsConfiguration: const BetterPlayerControlsConfiguration(
        showControls: false,
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
      autoDispose: true,
      deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
    );

    return BetterPlayerController(betterPlayerConfiguration)
      ..setupDataSource(betterPlayerDataSource);
  }

  void _handlePageChange(int index, BuildContext context) {
    final videos = (context.read<ReelsCubit>().state as ReelsLoaded).videos;
    
    // تخزين الفهرس الحالي
    _currentVideoIndex = index;
    
    // تحديث حالة الـ cubit
    context.read<ReelsCubit>().changeVideo(index);
    
    // إيقاف وتفريغ جميع الفيديوهات باستثناء المجاورة للفيديو الحالي
    for (int i = 0; i < _controllers.length; i++) {
      if (i == index) {
        // تهيئة المتحكم إذا كان فارغًا
        _controllers[i] ??= _createController(videos[i]);
        
        // توقف قصير قبل التشغيل للتأكد من توقف أي فيديوهات أخرى
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!_isDisposed && _controllers[i] != null) {
            _controllers[i]!.play();
          }
        });
      } 
      // التعامل مع الفيديوهات المجاورة - تحميل مسبق لكن إيقاف التشغيل
      else if (i == index - 1 || i == index + 1) {
        if (_controllers[i] == null && i >= 0 && i < videos.length) {
          _controllers[i] = _createController(videos[i]);
        }
        
        if (_controllers[i] != null) {
          _controllers[i]!.pause();
        }
      }
      // التخلص من الفيديوهات البعيدة عن العرض الحالي
      else if (_controllers[i] != null) {
        _controllers[i]!.pause();
        
        // تأخير قصير للتأكد من توقف الفيديو قبل التخلص منه
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!_isDisposed && _controllers[i] != null) {
            _controllers[i]!.dispose();
            _controllers[i] = null;
          }
        });
      }
    }
  }

  Widget _buildVideoPlayer(VideoModel video, int index) {
    // تهيئة المتحكم إذا كان فارغًا، مع تأخير التشغيل للفيديوهات غير الحالية
    if (_controllers[index] == null) {
      _controllers[index] = _createController(video);
      
      // تشغيل الفيديو الحالي فقط
      if (index == _currentVideoIndex) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!_isDisposed && _controllers[index] != null) {
            _controllers[index]!.play();
          }
        });
      }
    }
    
    return GestureDetector(
      // إضافة خاصية النقر لإيقاف/تشغيل الفيديو
      onTap: () {
        if (_controllers[index] != null) {
          if (_controllers[index]!.isPlaying() ?? false) {
            _controllers[index]!.pause();
          } else {
            _controllers[index]!.play();
          }
        }
      },
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 9 / 16, // فيديو عمودي للريلز
            child: _controllers[index] != null
                ? BetterPlayer(controller: _controllers[index]!)
                : Container(
                    color: Colors.black,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
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
          
          // أزرار التفاعل الافتراضية
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
      ),
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
    return WillPopScope(
      // إضافة WillPopScope للتعامل مع الخروج من الصفحة
      onWillPop: () async {
        // إيقاف جميع الفيديوهات قبل الخروج
        _pauseAllControllers();
        return true;
      },
      child: Scaffold(
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
                        onTap: () {
                          // إيقاف جميع الفيديوهات قبل الخروج
                          _pauseAllControllers();
                          Navigator.of(context).pop();
                        },
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
      ),
    );
  }
}