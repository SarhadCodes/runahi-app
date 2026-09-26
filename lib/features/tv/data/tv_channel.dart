import 'package:equatable/equatable.dart';

import '../../../../data/models/core_models.dart';

class TvChannel extends Equatable {
  const TvChannel({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.sortOrder = 0,
  });

  final String id;
  final LocalizedText name;
  final String streamUrl;
  final int sortOrder;

  bool get hasStream => streamUrl.trim().isNotEmpty;

  @override
  List<Object?> get props => [id, streamUrl, sortOrder];
}
