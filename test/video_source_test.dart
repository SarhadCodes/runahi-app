import 'package:flutter_test/flutter_test.dart';
import 'package:rounahi/core/utils/video_source.dart';

void main() {
  test('parses common YouTube URLs', () {
    expect(VideoSource.youtubeId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
    expect(VideoSource.youtubeId('https://youtu.be/dQw4w9WgXcQ?t=43'), 'dQw4w9WgXcQ');
    expect(VideoSource.youtubeId('https://www.youtube.com/shorts/dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
    expect(VideoSource.youtubeId('https://www.youtube.com/embed/dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
    expect(VideoSource.youtubeId('dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
    expect(VideoSource.startSeconds('https://youtu.be/dQw4w9WgXcQ?t=1m30s'), 90);
  });
}
