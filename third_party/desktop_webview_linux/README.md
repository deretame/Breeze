# desktop_webview_linux

[![pub version](https://img.shields.io/pub/v/desktop_webview_linux?logo=dart)](https://pub.dev/packages/desktop_webview_linux)
[![pub likes](https://img.shields.io/pub/likes/desktop_webview_linux?logo=dart)](https://pub.dev/packages/desktop_webview_linux)
[![dart style](https://img.shields.io/badge/style-carapacik__lints%20-brightgreen?logo=dart)](https://pub.dev/packages/carapacik_lints)
[![Star on Github](https://img.shields.io/github/stars/Carapacik/desktop_webview_linux?logo=github)](https://github.com/Carapacik/desktop_webview_linux)
[![Last commit on Github](https://img.shields.io/github/last-commit/Carapacik/desktop_webview_linux?logo=github)](https://github.com/Carapacik/desktop_webview_linux)

Linux-only package split from `desktop_webview_window`.

## Usage

```dart
import 'package:desktop_webview_linux/desktop_webview_linux.dart';

final webview = await WebviewWindow.create();
webview.launch('https://example.com');
```

## Title bar setup

To show the webview title bar on Linux, handle the title bar isolate before
starting your app:

```dart
import 'dart:io';

import 'package:desktop_webview_linux/desktop_webview_linux.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Required to show webview title bar.
  if (!kIsWeb && Platform.isLinux && runWebViewTitleBarWidget(args)) {
    return;
  }

  runApp(MyApp());
}
```

## Linux dependencies

Debian / Ubuntu:

```bash
sudo apt install \
  libwebkit2gtk-4.1-0 \
  libwebkit2gtk-4.1-dev \
  libsoup-3.0-0 \
  libsoup-3.0-dev
```

Fedora / RPM:

```bash
sudo dnf install \
  webkit2gtk4.1 \
  webkit2gtk4.1-devel \
  libsoup3 \
  libsoup3-devel
```
