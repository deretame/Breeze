import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/cs/cs.dart';
import 'package:zephyr/type/enum.dart';

class CsRemoteShelfPage extends StatelessWidget {
  const CsRemoteShelfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('服务端书架'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '收藏'),
              Tab(text: '历史'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RemoteLibraryList(kind: 'favorites'),
            _RemoteLibraryList(kind: 'history'),
          ],
        ),
      ),
    );
  }
}

class _RemoteLibraryList extends StatefulWidget {
  const _RemoteLibraryList({required this.kind});

  final String kind;

  @override
  State<_RemoteLibraryList> createState() => _RemoteLibraryListState();
}

class _RemoteLibraryListState extends State<_RemoteLibraryList>
    with AutomaticKeepAliveClientMixin {
  late Future<List<CsLibraryRecord>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<CsLibraryRecord>> _load() {
    final client = CsRuntimeContext.I.client;
    if (client == null) throw StateError('CS 会话未登录');
    return client.listLibrary(widget.kind);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<CsLibraryRecord>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('读取服务端书架失败：${snapshot.error}'));
        }
        final records = snapshot.data ?? const <CsLibraryRecord>[];
        if (records.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: const [
                SizedBox(height: 180),
                Center(child: Text('这里还没有内容')),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: records.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final record = records[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.menu_book)),
                title: Text(_title(record)),
                subtitle: Text('${record.source} · ${record.comicId}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.pushRoute(
                  ComicInfoRoute(
                    comicId: record.comicId,
                    from: record.source,
                    pluginId: record.source,
                    type: ComicEntryType.normal,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _title(CsLibraryRecord record) {
    final normalInfo = record.payload['normalInfo'];
    if (normalInfo is Map) {
      final comicInfo = normalInfo['comicInfo'];
      if (comicInfo is Map) {
        final title = comicInfo['title']?.toString().trim() ?? '';
        if (title.isNotEmpty) return title;
      }
    }
    final title = record.payload['title']?.toString().trim() ?? '';
    return title.isNotEmpty ? title : record.comicId;
  }
}
