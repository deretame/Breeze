class IOSBackgroundResource {
  final String url;
  final String path;
  final String cartoonId;
  final String chapterId;
  final String from;
  final String pictureType;
  final int? proxy;
  final bool allowNotFound;

  const IOSBackgroundResource({
    required this.url,
    required this.path,
    required this.cartoonId,
    required this.chapterId,
    required this.from,
    required this.pictureType,
    required this.proxy,
    required this.allowNotFound,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'path': path,
      'cartoonId': cartoonId,
      'chapterId': chapterId,
      'from': from,
      'pictureType': pictureType,
      'proxy': proxy,
      'allowNotFound': allowNotFound,
    };
  }

  factory IOSBackgroundResource.fromJson(Map<String, dynamic> json) {
    return IOSBackgroundResource(
      url: (json['url'] ?? '').toString(),
      path: (json['path'] ?? '').toString(),
      cartoonId: (json['cartoonId'] ?? '').toString(),
      chapterId: (json['chapterId'] ?? '').toString(),
      from: (json['from'] ?? '').toString(),
      pictureType: (json['pictureType'] ?? '').toString(),
      proxy: json['proxy'] == null
          ? null
          : int.tryParse(json['proxy'].toString()),
      allowNotFound: json['allowNotFound'] == true,
    );
  }
}

class IOSBackgroundPlan {
  final String from;
  final String comicId;
  final String comicName;
  final List<IOSBackgroundResource> resources;
  final Map<String, dynamic> payload;

  const IOSBackgroundPlan({
    required this.from,
    required this.comicId,
    required this.comicName,
    required this.resources,
    required this.payload,
  });

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'comicId': comicId,
      'comicName': comicName,
      'resources': resources.map((e) => e.toJson()).toList(),
      'payload': payload,
    };
  }

  factory IOSBackgroundPlan.fromJson(Map<String, dynamic> json) {
    final resourcesRaw = (json['resources'] as List?) ?? const [];
    final payloadRaw = json['payload'];

    return IOSBackgroundPlan(
      from: (json['from'] ?? '').toString(),
      comicId: (json['comicId'] ?? '').toString(),
      comicName: (json['comicName'] ?? '').toString(),
      resources: resourcesRaw
          .map(
            (e) => IOSBackgroundResource.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      payload: payloadRaw is Map<String, dynamic>
          ? payloadRaw
          : Map<String, dynamic>.from(payloadRaw as Map? ?? const {}),
    );
  }
}
