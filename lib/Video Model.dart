class VideoModel {
  final String id;
  final String url;
  final String thumbnailUrl;

  VideoModel({
    required this.id,
    required this.url,
    required this.thumbnailUrl,
  });

  static List<VideoModel> getSampleVideos() {
    return [
      VideoModel(
        id: 'video_1',
        url: 'https://fsn1.your-objectstorage.com/777/895fdf06-e455-42b7-9449-bc396ea42d8b.mp4',
        thumbnailUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg',
      ),
      VideoModel(
        id: 'video_2',
        url: 'https://fsn1.your-objectstorage.com/777/d8c1ed81-fd6c-4c46-9d9c-4fabdb233a8b.mp4',
        thumbnailUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ElephantsDream.jpg',
      ),
      VideoModel(
        id: 'video_3',
        url: 'https://fsn1.your-objectstorage.com/777/fd1e000c-1fc6-4d1c-b3e7-72b03581dc00.mp4',
        thumbnailUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg',
      ),
      VideoModel(
        id: 'video_4',
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
        thumbnailUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerEscapes.jpg',
      ),
      VideoModel(
        id: 'video_5',
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
        thumbnailUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerFun.jpg',
      ),
      VideoModel(
        id: 'video_6',
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
        thumbnailUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerJoyrides.jpg',
      ),
      VideoModel(
        id: 'video_7',
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
        thumbnailUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerMeltdowns.jpg',
      ),
      VideoModel(
        id: 'video_8',
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
        thumbnailUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/Sintel.jpg',
      ),
      VideoModel(
        id: 'video_9',
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
        thumbnailUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/SubaruOutbackOnStreetAndDirt.jpg',
      ),
      VideoModel(
        id: 'video_10',
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
        thumbnailUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/TearsOfSteel.jpg',
      ),
    ];
  }
}