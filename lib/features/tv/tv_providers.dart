import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/tv_channel.dart';
import 'data/tv_remote_datasource.dart';

final tvRemoteDatasourceProvider = Provider<TvRemoteDatasource>((ref) {
  return TvRemoteDatasource();
});

final tvChannelsProvider = FutureProvider<List<TvChannel>>((ref) {
  return ref.watch(tvRemoteDatasourceProvider).fetchChannels();
});

final primaryTvChannelProvider = FutureProvider<TvChannel?>((ref) {
  return ref.watch(tvRemoteDatasourceProvider).fetchPrimaryChannel();
});
