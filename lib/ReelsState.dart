import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:rellssserr/Video%20Model.dart';


@immutable
abstract class ReelsState extends Equatable {
  const ReelsState();

  @override
  List<Object> get props => [];
}

class ReelsInitial extends ReelsState {}

class ReelsLoading extends ReelsState {}

class ReelsLoaded extends ReelsState {
  final List<VideoModel> videos;
  final int currentIndex;

  const ReelsLoaded({
    required this.videos,
    required this.currentIndex,
  });

  @override
  List<Object> get props => [videos, currentIndex];

  ReelsLoaded copyWith({
    List<VideoModel>? videos,
    int? currentIndex,
  }) {
    return ReelsLoaded(
      videos: videos ?? this.videos,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class ReelsError extends ReelsState {
  final String message;

  const ReelsError(this.message);

  @override
  List<Object> get props => [message];
}