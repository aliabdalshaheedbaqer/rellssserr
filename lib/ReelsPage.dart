import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rellssserr/ReelsCubit.dart';
import 'package:rellssserr/ReelsState.dart';
import 'package:rellssserr/VideoModel.dart';


class ReelsPage extends StatefulWidget {
  const ReelsPage({Key? key}) : super(key: key);

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> with WidgetsBindingObserver {
  late PageController _pageController;
  final Map<int, BetterPlayerController?> _controllerMap = {};
  int _currentVideoIndex = 0;
  bool _isDisposed = false;
  bool _isChangingPage = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    
    // Initialize the first video controller after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _initializeControllerAtIndex(0);
      }
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pauseAllControllers();
    } else if (state == AppLifecycleState.resumed) {
      _playControllerAtIndex(_currentVideoIndex);
    }
  }
  
  /// Safely pause all active controllers
  void _pauseAllControllers() {
    if (_isDisposed) return;
    
    _controllerMap.forEach((_, controller) {
      if (controller != null) {
        controller.pause();
      }
    });
  }
  
  /// Safely play the controller at the specified index
  void _playControllerAtIndex(int index) {
    if (_isDisposed) return;
    
    // Pause all controllers first
    _pauseAllControllers();
    
    // Play only the controller at the specified index
    final controller = _controllerMap[index];
    if (controller != null) {
      controller.play();
    } else {
      // If controller doesn't exist yet, create it
      _initializeControllerAtIndex(index);
    }
  }

  /// Initialize the controller at the specified index
  void _initializeControllerAtIndex(int index) {
    if (_isDisposed || !mounted) return;
    
    final state = context.read<ReelsCubit>().state;
    if (state is! ReelsLoaded) return;
    
    if (index >= 0 && index < state.videos.length && _controllerMap[index] == null) {
      final video = state.videos[index];
      final controller = _createController(video);
      
      if (mounted && !_isDisposed) {
        setState(() {
          _controllerMap[index] = controller;
        });
        
        if (index == _currentVideoIndex) {
          controller.play();
        }
      }
    }
  }

  /// Create a new controller for the specified video
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
      autoPlay: false,
      looping: true,
      fit: BoxFit.cover,
      handleLifecycle: false, // We'll handle lifecycle ourselves
      controlsConfiguration: const BetterPlayerControlsConfiguration(
        showControls: false,
        enableMute: false,
        enableFullscreen: false,
        enablePlayPause: false,
        enableProgressBar: false,
        enableSkips: false,
        enablePlaybackSpeed: false,
      ),
      placeholder: Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      ),
      autoDispose: false, // We'll handle disposal manually
      deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
    );

    return BetterPlayerController(betterPlayerConfiguration)
      ..setupDataSource(betterPlayerDataSource);
  }

  /// Safely dispose of the controller at the specified index
  void _disposeControllerAtIndex(int index) {
    final controller = _controllerMap[index];
    if (controller != null) {
      // Remove the controller from the map first
      _controllerMap.remove(index);
      
      // Then dispose it
      controller.pause();
      controller.dispose();
    }
  }

  /// Safely manage controllers when changing pages
  void _handlePageChange(int index, BuildContext context) {
    if (_isDisposed || _isChangingPage) return;
    
    // Set flag to prevent concurrent page changes from interfering
    _isChangingPage = true;
    
    final state = context.read<ReelsCubit>().state;
    if (state is! ReelsLoaded) {
      _isChangingPage = false;
      return;
    }
    
    // Update current index
    _currentVideoIndex = index;
    context.read<ReelsCubit>().changeVideo(index);
    
    // Determine which controllers to keep and which to dispose
    final Set<int> indicesToKeep = {index};
    if (index > 0) indicesToKeep.add(index - 1);
    if (index < state.videos.length - 1) indicesToKeep.add(index + 1);
    
    // Create a list of indices to dispose (those not in indicesToKeep)
    final List<int> indicesToDispose = _controllerMap.keys
        .where((i) => !indicesToKeep.contains(i))
        .toList();
    
    // Dispose controllers that are no longer needed
    for (final i in indicesToDispose) {
      _disposeControllerAtIndex(i);
    }
    
    // Initialize controllers that need to be created
    for (final i in indicesToKeep) {
      if (_controllerMap[i] == null) {
        _initializeControllerAtIndex(i);
      }
    }
    
    // Play the current controller and pause others
    _playControllerAtIndex(index);
    
    // Reset the flag
    _isChangingPage = false;
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    
    // Dispose all controllers
    final controllerKeys = _controllerMap.keys.toList();
    for (final index in controllerKeys) {
      _disposeControllerAtIndex(index);
    }
    
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildVideoPlayer(VideoModel video, int index) {
    // Initialize controller if needed
    if (_controllerMap[index] == null) {
      return AspectRatio(
        aspectRatio: 9 / 16,
        child: Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    
    return GestureDetector(
      onTap: () {
        final controller = _controllerMap[index];
        if (controller != null) {
          if (controller.isPlaying() ?? false) {
            controller.pause();
          } else {
            controller.play();
          }
        }
      },
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 9 / 16,
            child: BetterPlayer(controller: _controllerMap[index]!),
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
      onWillPop: () async {
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