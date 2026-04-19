import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/util/json/json_value.dart';

import 'home_scheme_renderer.dart';

@RoutePage()
class PluginFunctionPage extends StatefulWidget {
  const PluginFunctionPage({
    super.key,
    required this.from,
    required this.functionId,
    required this.title,
    required this.onAction,
  });

  final String from;
  final String functionId;
  final String title;
  final Future<void> Function(Map<String, dynamic> action) onAction;

  @override
  State<PluginFunctionPage> createState() => _PluginFunctionPageState();
}

class _PluginFunctionPageState extends State<PluginFunctionPage> {
  final HomeSchemeRenderer _renderer = const HomeSchemeRenderer();
  bool _loading = true;
  String _error = '';
  Map<String, dynamic> _scheme = const <String, dynamic>{};
  Map<String, dynamic> _data = const <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      Map<String, dynamic> response;
      try {
        response = await callUnifiedComicPlugin(
          from: widget.from,
          fnPath: 'getFunctionPage',
          core: {'id': widget.functionId},
          extern: const <String, dynamic>{},
        );
      } catch (_) {
        response = await callUnifiedComicPlugin(
          from: widget.from,
          fnPath: 'get_function_page',
          core: {'id': widget.functionId},
          extern: const <String, dynamic>{},
        );
      }
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      if (!mounted) return;
      setState(() {
        _scheme = envelope.scheme;
        _data = asMap(envelope.data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: const Text('重试')),
                ],
              ),
            )
          : _renderer.buildPage(
              context,
              from: widget.from,
              scheme: _scheme,
              data: _data,
              onReachBottom: () async {},
              onAction: _onAction,
              isLoadingMore: false,
              showLoadMoreRetry: false,
              onRetryLoadMore: () {},
            ),
    );
  }

  Future<void> _onAction(Map<String, dynamic> action) async {
    final type = action['type']?.toString().trim() ?? '';
    if (type.isEmpty) {
      await widget.onAction(action);
      return;
    }

    if (type == 'openPluginFunction' ||
        type == 'openCloudFavorite' ||
        type == 'openSearch' ||
        type == 'openComicList') {
      final payload = Map<String, dynamic>.from(asJsonMap(action['payload']));
      payload['source'] = widget.from;
      if (type == 'openComicList') {
        final scene = Map<String, dynamic>.from(asJsonMap(payload['scene']));
        scene['source'] = widget.from;
        payload['scene'] = scene;
      }
      final next = Map<String, dynamic>.from(action)..['payload'] = payload;
      await widget.onAction(next);
      return;
    }

    await widget.onAction(action);
  }
}
