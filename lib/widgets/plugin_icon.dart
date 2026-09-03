import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/widgets/picture_bloc/picture_bloc.dart';

/// 发现页和插件商店共用的图标，按 URL 缓存，不依赖插件是否已安装。
class PluginIcon extends StatelessWidget {
  const PluginIcon({super.key, required this.url, required this.placeholder});

  final String url;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final iconUrl = url.trim();
    if (iconUrl.isEmpty) return placeholder;

    final pictureInfo = PictureInfo(
      from: 'plugin_icons',
      url: iconUrl,
      path: sha256.convert(utf8.encode(iconUrl)).toString(),
      pictureType: PictureType.avatar,
    );

    return BlocProvider(
      key: ValueKey(iconUrl),
      create: (_) =>
          PictureBloc()..add(GetPicture(pictureInfo, usePlugin: false)),
      child: BlocBuilder<PictureBloc, PictureLoadState>(
        builder: (context, state) {
          switch (state.status) {
            case PictureLoadStatus.initial:
            case PictureLoadStatus.failure:
              return placeholder;
            case PictureLoadStatus.success:
              return Image.file(
                File(state.imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              );
          }
        },
      ),
    );
  }
}
