class XtreamCategory {
  final String categoryId;
  final String categoryName;
  final int? parentId;

  XtreamCategory({
    required this.categoryId,
    required this.categoryName,
    this.parentId,
  });

  factory XtreamCategory.fromJson(Map<String, dynamic> json) {
    return XtreamCategory(
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name'] ?? '',
      parentId: json['parent_id'] != null ? int.tryParse(json['parent_id'].toString()) : null,
    );
  }
}

class XtreamStream {
  final String streamId;
  final String name;
  final String? streamType;
  final String? streamIcon;
  final String? categoryId;
  final int? num;
  final dynamic rating;
  final dynamic added;
  final String? containerExtension;

  XtreamStream({
    required this.streamId,
    required this.name,
    this.streamType,
    this.streamIcon,
    this.categoryId,
    this.num,
    this.rating,
    this.added,
    this.containerExtension,
  });

  factory XtreamStream.fromJson(Map<String, dynamic> json) {
    return XtreamStream(
      streamId: json['stream_id']?.toString() ?? json['series_id']?.toString() ?? '',
      name: json['name'] ?? '',
      streamType: json['stream_type'],
      streamIcon: json['stream_icon'] ?? json['cover'],
      categoryId: json['category_id']?.toString(),
      num: json['num'] is int ? json['num'] : int.tryParse(json['num']?.toString() ?? ''),
      rating: json['rating'],
      added: json['added'],
      containerExtension: json['container_extension'],
    );
  }
}

class XtreamSeriesInfo {
  final Map<String, dynamic> info;
  final Map<String, List<XtreamEpisode>> episodes;

  XtreamSeriesInfo({
    required this.info,
    required this.episodes,
  });

  factory XtreamSeriesInfo.fromJson(Map<String, dynamic> json) {
    final episodesMap = <String, List<XtreamEpisode>>{};

    if (json['episodes'] != null) {
      final episodesJson = json['episodes'] as Map<String, dynamic>;
      episodesJson.forEach((season, epList) {
        if (epList is List) {
          episodesMap[season] = epList.map((e) => XtreamEpisode.fromJson(e)).toList();
        }
      });
    }

    return XtreamSeriesInfo(
      info: json['info'] ?? {},
      episodes: episodesMap,
    );
  }
}

class XtreamEpisode {
  final String id;
  final String title;
  final String containerExtension;
  final int season;
  final int episodeNum;
  final String? infoUrl;

  XtreamEpisode({
    required this.id,
    required this.title,
    required this.containerExtension,
    required this.season,
    required this.episodeNum,
    this.infoUrl,
  });

  factory XtreamEpisode.fromJson(Map<String, dynamic> json) {
    return XtreamEpisode(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      containerExtension: json['container_extension'] ?? 'mp4',
      season: json['season'] is int ? json['season'] : int.tryParse(json['season']?.toString() ?? '0') ?? 0,
      episodeNum: json['episode_num'] is int ? json['episode_num'] : int.tryParse(json['episode_num']?.toString() ?? '0') ?? 0,
    );
  }
}
