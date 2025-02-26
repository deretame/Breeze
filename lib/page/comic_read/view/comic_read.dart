import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_info/json/eps/eps.dart' as eps;
import 'package:zephyr/page/comic_read/comic_read.dart';

import '../../../config/global.dart';
import '../../../object_box/model.dart';
import '../../../object_box/objectbox.g.dart';
import '../../../widgets/comic_entry/comic_entry.dart';
import '../../comic_info/json/comic_info/comic_info.dart';
import '../../download/json/comic_all_info_json/comic_all_info_json.dart'
    as comic_all_info_json;

@RoutePage()
class ComicReadPage extends StatelessWidget {
  final Comic comicInfo;
  final List<eps.Doc> epsInfo;
  final eps.Doc doc;
  final String comicId;
  final ComicEntryType? type;

  const ComicReadPage({
    super.key,
    required this.comicInfo,
    required this.epsInfo,
    required this.doc,
    required this.comicId,
    this.type,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PageBloc()..add(GetPage(comicId, doc.order)),
      child: _ComicReadPage(
        comicInfo: comicInfo,
        epsInfo: epsInfo,
        doc: doc,
        comicId: comicId,
        type: type,
      ),
    );
  }
}

class _ComicReadPage extends StatefulWidget {
  final Comic comicInfo;
  final List<eps.Doc> epsInfo;
  final eps.Doc doc;
  final String comicId;
  final ComicEntryType? type;

  const _ComicReadPage({
    required this.comicInfo,
    required this.epsInfo,
    required this.doc,
    required this.comicId,
    this.type,
  });

  @override
  State<_ComicReadPage> createState() => _ComicReadPageState();
}

class _ComicReadPageState extends State<_ComicReadPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Comic get comicInfo => widget.comicInfo;

  List<eps.Doc> get epsInfo => widget.epsInfo;

  eps.Doc get doc => widget.doc;

  String get comicId => widget.comicId;

  String _epId = ""; // 用来存储当前观看的章节id
  ComicEntryType? get type => widget.type;
  late final ComicEntryType _type;
  late final comic_all_info_json.Eps _downloadEpsInfo;
  late eps.Doc _doc;
  late bool isSkipped = false; // 是否跳转过
  late final ItemScrollController _itemScrollController;
  late final ItemPositionsListener _itemPositionsListener;
  late BikaComicHistory? comicHistory; // 记录阅读记录
  DateTime? _lastUpdateTime; // 记录上次更新时间
  bool _isInserting = false; // 检测数据插入状态
  int pageIndex = 0; // 当前页数
  String epPages = ""; // 章节总页数
  bool _isVisible = true; // 控制 AppBar 和 BottomAppBar 的可见性
  late int _lastScrollIndex = -1; // 用于记录上次滚动的索引
  double _currentSliderValue = 0; // 当前滑块的值
  int _totalSlots = 0; // 总槽位数量
  int displayedSlot = 1; // 显示的当前槽位
  bool _isSliderRolling = false; // 滑块是否在滑动
  bool _isComicRolling = false; // 漫画本身是否在滚动

  @override
  void initState() {
    super.initState();
    _currentSliderValue = 0;
    _type = type ?? ComicEntryType.normal;
    _doc = doc;
    _epId = epsInfo.firstWhere((doc) => doc.title == _doc.title).id;
    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();

    _itemPositionsListener.itemPositions.addListener(() {
      if (_itemPositionsListener.itemPositions.value.isNotEmpty) {
        final positions = _itemPositionsListener.itemPositions.value;
        getTopThirdItemIndex(positions);
        _detectScrollDirection(positions);
      }
    });

    // 首先查询一下有没有记录
    final query = objectbox.bikaHistoryBox.query(
      BikaComicHistory_.comicId.equals(comicId),
    );
    comicHistory = query.build().findFirst();
    // 如果没有记录就先插入一条记录
    if (comicHistory == null) {
      comicHistory = comicToBikaComicHistory(comicInfo, _doc.order);
      objectbox.bikaHistoryBox.put(comicHistory!);
    }

    if (_type == ComicEntryType.download ||
        _type == ComicEntryType.historyAndDownload) {
      // 首先查询一下有没有记录
      var temp =
          objectbox.bikaDownloadBox
              .query(BikaComicDownload_.comicId.equals(comicId))
              .build()
              .findFirst()!
              .comicInfoAll;
      var temp2 = comic_all_info_json.comicAllInfoJsonFromJson(temp);
      _downloadEpsInfo = temp2.eps;
    }

    debugPrint(_type.toString().split('.').last);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body:
          _type == ComicEntryType.download ||
                  _type == ComicEntryType.historyAndDownload
              ? _successWidget(null)
              : BlocBuilder<PageBloc, PageState>(
                builder: (context, state) {
                  switch (state.status) {
                    case PageStatus.initial:
                      return const Center(child: CircularProgressIndicator());
                    case PageStatus.failure:
                      return _failureWidget(state);
                    case PageStatus.success:
                      return _successWidget(state);
                  }
                },
              ),
    );
  }

  Widget _failureWidget(PageState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${state.result.toString()}\n加载失败',
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              context.read<PageBloc>().add(GetPage(comicId, _doc.order));
            },
            child: Text('点击重试'),
          ),
        ],
      ),
    );
  }

  Widget _successWidget(PageState? state) {
    // debugPrint(_currentSliderValue.toString());
    if (_isVisible == false) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
    var length = 0;
    List<Media> medias = [];
    if (state != null) {
      length = state.medias!.length;
      epPages = state.result!;
      medias = state.medias!;
    } else {
      try {
        var temp = _downloadEpsInfo.docs.firstWhere(
          (e) => e.order == _doc.order,
        );
        _doc = eps.Doc(
          id: temp.id,
          title: temp.title,
          order: temp.order,
          updatedAt: temp.updatedAt,
          docId: temp.docId,
        );
        medias =
            temp.pages.docs.map((e) {
              return Media(
                originalName: e.media.originalName,
                path: e.media.path,
                fileServer: e.media.fileServer,
              );
            }).toList();
        length = temp.pages.docs.length;
        epPages = temp.pages.docs.length.toString();
      } catch (e) {
        return Center(child: Text('章节未下载', style: TextStyle(fontSize: 20)));
      }
    }
    // 在成功加载状态下设置 _totalSlots
    if (_totalSlots == 0) {
      _totalSlots = length;
    }

    // 处理滚动到历史记录
    if ((_type == ComicEntryType.history ||
            _type == ComicEntryType.historyAndDownload) &&
        (comicHistory!.epPageCount - 1 != 0) &&
        isSkipped == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _itemScrollController.scrollTo(
          index: comicHistory!.epPageCount - 1,
          alignment: 0.0,
          duration: const Duration(milliseconds: 500),
        );
      });
    }
    isSkipped = true;

    // debugPrint('statusBarHeight : $statusBarHeight');
    return Container(
      color: Colors.black,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _isVisible = !_isVisible;
                });
                if (_isVisible) {
                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                }
              },
              child: InteractiveViewer(
                boundaryMargin: EdgeInsets.zero,
                minScale: 1.0,
                maxScale: 4.0,
                child: ListModeWidget(
                  comicId: comicId,
                  epsId: _doc.id,
                  chapterId: _epId,
                  length: length,
                  medias: medias,
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                ),
              ),
            ),
            ComicReadAppBar(
              title: _doc.title,
              isVisible: _isVisible,
              onThemeModeChanged: () {
                globalSetting.setThemeMode(0);
              },
            ),
            // _pageCountWidget(),
            PageCountWidget(pageIndex: pageIndex, epPages: epPages),
            BottomWidget(
              type: _type,
              isVisible: _isVisible,
              doc: _doc,
              epsInfo: epsInfo,
              comicInfo: comicInfo,
              sliderWidget: SliderWidget(
                totalSlots: _totalSlots,
                currentSliderValue: _currentSliderValue,
                changeSliderValue: (double newValue) {
                  setState(() => _currentSliderValue = newValue);
                },
                changeSliderRollState: (bool newValue) {
                  setState(() => _isSliderRolling = newValue);
                },
                changeComicRollState: (bool newValue) {
                  setState(() => _isComicRolling = newValue);
                },
                itemScrollController: _itemScrollController,
              ),
            ),
            // _bottomButton(),
          ],
        ),
      ),
    );
  }

  Future<void> updateIndex(Iterable<ItemPosition> positions) async {
    if (positions.isEmpty) return;

    // 提前计算屏幕的三分之一位置
    final viewportHeight = MediaQuery.of(context).size.height;
    final topThird = viewportHeight / 3 + statusBarHeight;

    // 找到最接近的项
    final closestPosition = _findClosestPosition(positions, topThird);

    // 更新索引
    if (closestPosition != null &&
        mounted &&
        !_isSliderRolling &&
        pageIndex != closestPosition.index) {
      debugPrint('更新索引：$pageIndex');

      setState(() {
        pageIndex = closestPosition.index;
        if (!_isComicRolling) {
          _currentSliderValue = pageIndex - 2;
        }
      });
    }
  }

  ItemPosition? _findClosestPosition(
    Iterable<ItemPosition> positions,
    double topThird,
  ) {
    ItemPosition? closestPosition;
    double minDistance = double.infinity;

    for (final position in positions) {
      // 计算项的中心位置
      final itemHeight = position.itemTrailingEdge - position.itemLeadingEdge;
      final itemMiddle = position.itemLeadingEdge + itemHeight / 2;
      final distance = (topThird - itemMiddle).abs();

      // 找到距离最小的项
      if (distance < minDistance) {
        minDistance = distance;
        closestPosition = position;
      }
    }

    return closestPosition;
  }

  Future<void> writeToDatabase() async {
    if (_isInserting ||
        _lastUpdateTime != null &&
            DateTime.now().difference(_lastUpdateTime!).inMilliseconds < 100) {
      return;
    }
    // 更新记录
    _isInserting = true;
    comicHistory!
      ..history = DateTime.now().toUtc()
      ..order = _doc.order
      ..epPageCount = pageIndex
      ..epTitle = _doc.title
      ..epId = _epId
      ..deleted = false
      ..deletedAt = DateTime.utc(2000);
    await objectbox.bikaHistoryBox.putAsync(comicHistory!);
    _isInserting = false;
    _lastUpdateTime = DateTime.now();
  }

  Future<void> getTopThirdItemIndex(Iterable<ItemPosition> positions) async {
    await updateIndex(positions);
    await writeToDatabase();
  }

  void _detectScrollDirection(Iterable<ItemPosition> positions) {
    if (positions.isNotEmpty) {
      // 获取当前滚动的第一个索引
      final firstItemIndex = positions.first.index;

      // 判断是否有滚动
      if (firstItemIndex != _lastScrollIndex && !_isSliderRolling) {
        debugPrint('滚动检测：隐藏组件');
        setState(() {
          _isVisible = false; // 只要滚动了就隐藏组件
        });
      }

      // 更新记录的滚动索引
      _lastScrollIndex = firstItemIndex;
    }
  }
}
