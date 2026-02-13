import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';

import '../../../../config/global/global.dart';
import '../../../../cubit/int_select.dart';
import '../../../../cubit/string_select.dart';
import '../../../../main.dart';
import '../../../../object_box/model.dart';
import '../../../../type/enum.dart';
import '../../../../widgets/comic_entry/comic_entry.dart';
import '../../../../widgets/comic_simplify_entry/comic_simplify_entry.dart';
import '../../../../widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final comicChoice = context.read<GlobalSettingCubit>().state.comicChoice;

    return BlocProvider(
      create: (_) => UserDownloadBloc()
        ..add(
          UserDownloadEvent(
            SearchEnter().copyWith(refresh: const Uuid().v4()),
            comicChoice,
          ),
        ),
      child: const _DownloadPage(),
    );
  }
}

class _DownloadPage extends StatefulWidget {
  const _DownloadPage();

  @override
  State<_DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<_DownloadPage>
    with AutomaticKeepAliveClientMixin {
  int totalComicCount = 0;
  bool notice = false;

  ScrollController get _scrollController => scrollControllers['download']!;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    eventBus.on<DownloadEvent>().listen((event) {
      if (!mounted) return;

      if (event.type == EventType.showInfo) {
        context.read<StringSelectCubit>().setDate(totalComicCount.toString());
      } else if (event.type == EventType.refresh) {
        _refresh(goToTop: true);
      }
    });
  }

  void _scrollListener() {
    final currentTabIndex = context.read<IntSelectCubit>().state;
    if (currentTabIndex == 2) {
      context.read<StringSelectCubit>().setDate(totalComicCount.toString());
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final currentTabIndex = context.watch<IntSelectCubit>().state;

    return BlocListener<UserDownloadBloc, UserDownloadState>(
      listener: (context, state) {
        if (state.status == UserDownloadStatus.success) {
          totalComicCount = state.comics.length;

          final tabIndex = context.read<IntSelectCubit>().state;
          if (tabIndex == 2) {
            context.read<StringSelectCubit>().setDate(
              totalComicCount.toString(),
            );
          }

          if (!notice && tabIndex == 1) {
            eventBus.fire(DownloadEvent(EventType.showInfo, false));
            notice = true;
          }
        }
      },
      child: BlocBuilder<UserDownloadBloc, UserDownloadState>(
        builder: (context, state) {
          return RefreshIndicator(
            displacement: 60.0,
            onRefresh: () async {
              if (currentTabIndex == 2) {
                _refresh(goToTop: true);
              }
            },
            child: _buildContent(state),
          );
        },
      ),
    );
  }

  Widget _buildContent(UserDownloadState state) {
    switch (state.status) {
      case UserDownloadStatus.initial:
        return const Center(child: CircularProgressIndicator());
      case UserDownloadStatus.failure:
        return _buildError(state);
      case UserDownloadStatus.success:
        return _buildList(state);
    }
  }

  Widget _buildError(UserDownloadState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${state.result}\n加载失败',
            style: const TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _refresh(goToTop: true),
            child: const Text('点击重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(UserDownloadState state) {
    if (state.comics.isEmpty) {
      return _buildEmptyState();
    }

    final globalState = context.watch<GlobalSettingCubit>().state;
    final bikaState = context.watch<BikaSettingCubit>().state;
    final comicChoice = globalState.comicChoice;
    final isBrevity = bikaState.brevity;

    if (comicChoice != 1 || isBrevity) {
      return _buildBrevityList(state.comics, comicChoice);
    }

    return _buildDetailedList(state.comics);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const Spacer(),
          const Text('啥都没有', style: TextStyle(fontSize: 20.0)),
          const SizedBox(height: 10),
          IconButton(
            onPressed: () => _refresh(),
            icon: const Icon(Icons.refresh),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBrevityList(List<dynamic> comics, int comicChoice) {
    final entryInfoList = _convertToEntryInfoList(comics, comicChoice);
    final elementsRows = generateResponsiveRows(context, entryInfoList);

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: elementsRows.length + 1,
      itemBuilder: (context, index) {
        if (index == elementsRows.length) {
          return _buildFooter();
        }
        return _buildRowItem(elementsRows[index]);
      },
    );
  }

  Widget _buildDetailedList(List<dynamic> comics) {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: comics.length + 1,
      itemBuilder: (context, index) {
        if (index == comics.length) {
          return _buildFooter();
        }
        return _buildDetailItem(comics[index] as BikaComicDownload);
      },
    );
  }

  Widget _buildRowItem(List<ComicSimplifyEntryInfo> entries) {
    return ComicSimplifyEntryRow(
      key: ValueKey(entries.map((e) => e.id).join(',')),
      entries: entries,
      type: ComicEntryType.download,
      refresh: () => _refresh(),
    );
  }

  Widget _buildDetailItem(BikaComicDownload comic) {
    return ComicEntryWidget(
      comicEntryInfo: downloadConvertToComicEntryInfo(comic),
      type: ComicEntryType.download,
      refresh: () => _refresh(goToTop: true),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 10),
          IconButton(
            onPressed: () => _refresh(goToTop: true),
            icon: const Icon(Icons.refresh),
          ),
          deletingDialog(
            context,
            () => _refresh(goToTop: true),
            DeleteType.download,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<ComicSimplifyEntryInfo> _convertToEntryInfoList(
    List<dynamic> comics,
    int comicChoice,
  ) {
    if (comicChoice == 1) {
      return comics.cast<BikaComicDownload>().map((element) {
        return ComicSimplifyEntryInfo(
          title: element.title,
          id: element.comicId,
          fileServer: element.thumbFileServer,
          path: element.thumbPath,
          pictureType: PictureType.cover,
          from: From.bika,
        );
      }).toList();
    } else {
      return comics.cast<JmDownload>().map((element) {
        return ComicSimplifyEntryInfo(
          title: element.name,
          id: element.comicId.toString(),
          fileServer: getJmCoverUrl(element.comicId.toString()),
          path: "${element.comicId}.jpg",
          pictureType: PictureType.cover,
          from: From.jm,
        );
      }).toList();
    }
  }

  void _refresh({bool goToTop = false, bool clean = false}) {
    final downloadCubit = context.read<DownloadCubit>();
    if (clean) downloadCubit.resetSearch();

    final searchStatus = downloadCubit.state;
    final comicChoice = context.read<GlobalSettingCubit>().state.comicChoice;

    context.read<UserDownloadBloc>().add(
      UserDownloadEvent(
        SearchEnter(
          keyword: searchStatus.keyword,
          sort: searchStatus.sort,
          categories: searchStatus.categories,
          refresh: const Uuid().v4(),
        ),
        comicChoice,
      ),
    );

    if (goToTop && _scrollController.hasClients) {
      Future.microtask(() {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
    notice = false;
  }
}
