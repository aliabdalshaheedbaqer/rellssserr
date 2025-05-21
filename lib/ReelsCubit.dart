import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rellssserr/ReelsState.dart';
import 'package:rellssserr/VideoModel.dart';

class ReelsCubit extends Cubit<ReelsState> {
  ReelsCubit() : super(ReelsInitial());

  void loadVideos() {
    emit(ReelsLoading());
    try {
      final videos = VideoModel.getSampleVideos();
      emit(ReelsLoaded(videos: videos, currentIndex: 0));
    } catch (e) {
      emit(ReelsError('Failed to load videos: ${e.toString()}'));
    }
  }

  void changeVideo(int index) {
    if (state is ReelsLoaded) {
      final currentState = state as ReelsLoaded;
      emit(currentState.copyWith(currentIndex: index));
    }
  }
}