///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsZhCn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zhCn,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh-CN>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations

	/// zh-CN: 'Breeze'
	String get appName => 'Breeze';

	late final Translations$common$zh_CN common = Translations$common$zh_CN.internal(_root);
	late final Translations$error$zh_CN error = Translations$error$zh_CN.internal(_root);
	late final Translations$navigation$zh_CN navigation = Translations$navigation$zh_CN.internal(_root);
	late final Translations$settings$zh_CN settings = Translations$settings$zh_CN.internal(_root);
	late final Translations$bookshelf$zh_CN bookshelf = Translations$bookshelf$zh_CN.internal(_root);
	late final Translations$comicInfo$zh_CN comicInfo = Translations$comicInfo$zh_CN.internal(_root);
	late final Translations$reader$zh_CN reader = Translations$reader$zh_CN.internal(_root);
	late final Translations$plugin$zh_CN plugin = Translations$plugin$zh_CN.internal(_root);
	late final Translations$gestureLock$zh_CN gestureLock = Translations$gestureLock$zh_CN.internal(_root);
	late final Translations$appBootstrap$zh_CN appBootstrap = Translations$appBootstrap$zh_CN.internal(_root);
	late final Translations$comments$zh_CN comments = Translations$comments$zh_CN.internal(_root);
	late final Translations$cache$zh_CN cache = Translations$cache$zh_CN.internal(_root);
	late final Translations$dataBackup$zh_CN dataBackup = Translations$dataBackup$zh_CN.internal(_root);
	late final Translations$webdavSync$zh_CN webdavSync = Translations$webdavSync$zh_CN.internal(_root);
	late final Translations$realSr$zh_CN realSr = Translations$realSr$zh_CN.internal(_root);
	late final Translations$about$zh_CN about = Translations$about$zh_CN.internal(_root);
	late final Translations$oldHome$zh_CN oldHome = Translations$oldHome$zh_CN.internal(_root);
	late final Translations$more$zh_CN more = Translations$more$zh_CN.internal(_root);
	late final Translations$search$zh_CN search = Translations$search$zh_CN.internal(_root);
	late final Translations$discover$zh_CN discover = Translations$discover$zh_CN.internal(_root);
	late final Translations$searchResult$zh_CN searchResult = Translations$searchResult$zh_CN.internal(_root);
	late final Translations$comicList$zh_CN comicList = Translations$comicList$zh_CN.internal(_root);
	late final Translations$comicEntry$zh_CN comicEntry = Translations$comicEntry$zh_CN.internal(_root);
	late final Translations$comicFollow$zh_CN comicFollow = Translations$comicFollow$zh_CN.internal(_root);
	late final Translations$changelog$zh_CN changelog = Translations$changelog$zh_CN.internal(_root);
	late final Translations$webview$zh_CN webview = Translations$webview$zh_CN.internal(_root);
	late final Translations$oldRanking$zh_CN oldRanking = Translations$oldRanking$zh_CN.internal(_root);
	late final Translations$login$zh_CN login = Translations$login$zh_CN.internal(_root);
	late final Translations$fontSetting$zh_CN fontSetting = Translations$fontSetting$zh_CN.internal(_root);
	late final Translations$download$zh_CN download = Translations$download$zh_CN.internal(_root);
	late final Translations$foregroundTask$zh_CN foregroundTask = Translations$foregroundTask$zh_CN.internal(_root);
	late final Translations$notification$zh_CN notification = Translations$notification$zh_CN.internal(_root);
	late final Translations$update$zh_CN update = Translations$update$zh_CN.internal(_root);
	late final Translations$dialog$zh_CN dialog = Translations$dialog$zh_CN.internal(_root);
}

// Path: common
class Translations$common$zh_CN {
	Translations$common$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '确定'
	String get ok => '确定';

	/// zh-CN: '取消'
	String get cancel => '取消';

	/// zh-CN: '保存'
	String get save => '保存';

	/// zh-CN: '删除'
	String get delete => '删除';

	/// zh-CN: '编辑'
	String get edit => '编辑';

	/// zh-CN: '重命名'
	String get rename => '重命名';

	/// zh-CN: '添加'
	String get add => '添加';

	/// zh-CN: '新建'
	String get create => '新建';

	/// zh-CN: '刷新'
	String get refresh => '刷新';

	/// zh-CN: '加载中...'
	String get loading => '加载中...';

	/// zh-CN: '加载失败'
	String get loadingFailed => '加载失败';

	/// zh-CN: '重试'
	String get retry => '重试';

	/// zh-CN: '重新加载'
	String get reload => '重新加载';

	/// zh-CN: '确认'
	String get confirm => '确认';

	/// zh-CN: '关闭'
	String get close => '关闭';

	/// zh-CN: '返回'
	String get back => '返回';

	/// zh-CN: '帮助'
	String get help => '帮助';

	/// zh-CN: '知道了'
	String get gotIt => '知道了';

	/// zh-CN: '施工中'
	String get underConstruction => '施工中';

	/// zh-CN: '在写了，在写了'
	String get comingSoon => '在写了，在写了';

	/// zh-CN: '根目录'
	String get root => '根目录';

	/// zh-CN: '移除'
	String get remove => '移除';

	/// zh-CN: '覆盖'
	String get overwrite => '覆盖';

	/// zh-CN: '已取消'
	String get cancelled => '已取消';

	/// zh-CN: '搜索'
	String get search => '搜索';

	/// zh-CN: '清空'
	String get clear => '清空';

	/// zh-CN: '复制'
	String get copy => '复制';

	/// zh-CN: '粘贴'
	String get paste => '粘贴';

	/// zh-CN: '分享'
	String get share => '分享';

	/// zh-CN: '打开'
	String get open => '打开';

	/// zh-CN: '下载'
	String get download => '下载';

	/// zh-CN: '上传'
	String get upload => '上传';

	/// zh-CN: '导入'
	String get import => '导入';

	/// zh-CN: '导出'
	String get export => '导出';

	/// zh-CN: '成功'
	String get success => '成功';

	/// zh-CN: '失败'
	String get failed => '失败';

	/// zh-CN: '错误'
	String get error => '错误';

	/// zh-CN: '警告'
	String get warning => '警告';

	/// zh-CN: '提示'
	String get info => '提示';

	/// zh-CN: '未知'
	String get unknown => '未知';

	/// zh-CN: '暂无数据'
	String get empty => '暂无数据';

	/// zh-CN: '全部'
	String get all => '全部';

	/// zh-CN: '无'
	String get none => '无';

	/// zh-CN: '默认'
	String get default_ => '默认';

	/// zh-CN: '自定义'
	String get custom => '自定义';

	/// zh-CN: '已开启'
	String get enabled => '已开启';

	/// zh-CN: '已关闭'
	String get disabled => '已关闭';

	/// zh-CN: '跟随系统'
	String get followSystem => '跟随系统';

	/// zh-CN: '浅色模式'
	String get lightMode => '浅色模式';

	/// zh-CN: '深色模式'
	String get darkMode => '深色模式';

	/// zh-CN: '系统'
	String get system => '系统';

	/// zh-CN: '应用'
	String get apply => '应用';

	/// zh-CN: '重置'
	String get reset => '重置';

	/// zh-CN: '下一步'
	String get next => '下一步';

	/// zh-CN: '上一步'
	String get previous => '上一步';

	/// zh-CN: '完成'
	String get done => '完成';

	/// zh-CN: '选择'
	String get select => '选择';

	/// zh-CN: '已选择'
	String get selected => '已选择';

	/// zh-CN: '取消选择'
	String get deselect => '取消选择';

	/// zh-CN: '全选'
	String get selectAll => '全选';

	/// zh-CN: '是'
	String get yes => '是';

	/// zh-CN: '否'
	String get no => '否';

	/// zh-CN: '开'
	String get on => '开';

	/// zh-CN: '关'
	String get off => '关';

	/// zh-CN: '更多'
	String get more => '更多';

	/// zh-CN: '详情'
	String get detail => '详情';

	/// zh-CN: '设置已保存'
	String get settingSaved => '设置已保存';

	/// zh-CN: '设置成功，重启生效'
	String get restartToTakeEffect => '设置成功，重启生效';
}

// Path: error
class Translations$error$zh_CN {
	Translations$error$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '出错了'
	String get generic => '出错了';

	/// zh-CN: '网络错误'
	String get network => '网络错误';

	/// zh-CN: '下载失败'
	String get downloadFailed => '下载失败';

	/// zh-CN: '导入失败: $error'
	String importFailed({required Object error}) => '导入失败: ${error}';

	/// zh-CN: '加载失败'
	String get loadFailed => '加载失败';

	/// zh-CN: '保存失败'
	String get saveFailed => '保存失败';

	/// zh-CN: '权限被拒绝'
	String get permissionDenied => '权限被拒绝';

	/// zh-CN: '未找到'
	String get notFound => '未找到';

	/// zh-CN: '当前平台不支持此功能'
	String get unsupportedPlatform => '当前平台不支持此功能';

	/// zh-CN: '缺少插件来源，无法$action'
	String missingPluginSource({required Object action}) => '缺少插件来源，无法${action}';

	/// zh-CN: '操作失败'
	String get operationFailed => '操作失败';

	/// zh-CN: '执行失败'
	String get executionFailed => '执行失败';
}

// Path: navigation
class Translations$navigation$zh_CN {
	Translations$navigation$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '首页'
	String get home => '首页';

	/// zh-CN: '排行'
	String get rank => '排行';

	/// zh-CN: '书架'
	String get bookshelf => '书架';

	/// zh-CN: '发现'
	String get discover => '发现';

	/// zh-CN: '更多'
	String get more => '更多';

	/// zh-CN: '同步成功！'
	String get syncSuccess => '同步成功！';

	/// zh-CN: '自动同步成功！'
	String get autoSyncSuccess => '自动同步成功！';

	/// zh-CN: '同步失败'
	String get syncFailed => '同步失败';

	/// zh-CN: '自动同步失败'
	String get autoSyncFailed => '自动同步失败';

	/// zh-CN: '请检查网络连接或稍后再试。 $error'
	String syncFailedMessage({required Object error}) => '请检查网络连接或稍后再试。\n${error}';

	/// zh-CN: '登录过期，请重新登录'
	String get loginExpired => '登录过期，请重新登录';
}

// Path: settings
class Translations$settings$zh_CN {
	Translations$settings$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '设置'
	String get title => '设置';

	/// zh-CN: '设置'
	String get globalTitle => '设置';

	/// zh-CN: '外观与显示'
	String get appearance => '外观与显示';

	/// zh-CN: '主题模式'
	String get theme => '主题模式';

	/// zh-CN: '选择策略，切换明暗主题'
	String get themeSubtitle => '选择策略，切换明暗主题';

	/// zh-CN: '主题颜色'
	String get themeColor => '主题颜色';

	/// zh-CN: '选择主色，统一应用视觉'
	String get themeColorSubtitle => '选择主色，统一应用视觉';

	/// zh-CN: '语言'
	String get language => '语言';

	/// zh-CN: '切换应用显示语言'
	String get languageSubtitle => '切换应用显示语言';

	/// zh-CN: '跟随系统'
	String get followSystemLanguage => '跟随系统';

	/// zh-CN: '简体中文 (zh_CN)'
	String get languageZhCn => '简体中文 (zh_CN)';

	/// zh-CN: 'English (en_US)'
	String get languageEnUs => 'English (en_US)';

	/// zh-CN: '语言设置已保存，重启应用后全部生效'
	String get languageChangedRestartHint => '语言设置已保存，重启应用后全部生效';

	/// zh-CN: '动态取色'
	String get dynamicColor => '动态取色';

	/// zh-CN: '开启后自动提取内容主色'
	String get dynamicColorSubtitle => '开启后自动提取内容主色';

	/// zh-CN: '字体设置'
	String get fontSettings => '字体设置';

	/// zh-CN: '自定义显示字体'
	String get fontSettingsSubtitle => '自定义显示字体';

	/// zh-CN: '纯黑模式'
	String get amoled => '纯黑模式';

	/// zh-CN: '开启后使用纯黑背景，适配 AMOLED'
	String get amoledSubtitle => '开启后使用纯黑背景，适配 AMOLED';

	/// zh-CN: '异形屏适配'
	String get notchAdaptation => '异形屏适配';

	/// zh-CN: '开启后预留安全区，避免内容遮挡'
	String get notchAdaptationSubtitle => '开启后预留安全区，避免内容遮挡';

	/// zh-CN: '内容与网络'
	String get contentAndNetwork => '内容与网络';

	/// zh-CN: '内容'
	String get content => '内容';

	/// zh-CN: '网络'
	String get network => '网络';

	/// zh-CN: '屏蔽关键词'
	String get maskedKeywords => '屏蔽关键词';

	/// zh-CN: '添加关键词，过滤不想看到的内容（仅搜索生效）'
	String get maskedKeywordsSubtitle => '添加关键词，过滤不想看到的内容（仅搜索生效）';

	/// zh-CN: '暂无屏蔽词'
	String get maskedKeywordsEmpty => '暂无屏蔽词';

	/// zh-CN: '输入新关键词...'
	String get maskedKeywordsInputHint => '输入新关键词...';

	/// zh-CN: '简繁转换'
	String get chineseConvert => '简繁转换';

	/// zh-CN: '将漫画标题、简介、章节、评论等转为简体或繁体'
	String get chineseConvertSubtitle => '将漫画标题、简介、章节、评论等转为简体或繁体';

	/// zh-CN: '关闭'
	String get chineseConvertOff => '关闭';

	/// zh-CN: '简体中文'
	String get chineseConvertSimplified => '简体中文';

	/// zh-CN: '繁体中文'
	String get chineseConvertTraditional => '繁体中文';

	/// zh-CN: 'SOCKS5 代理'
	String get proxy => 'SOCKS5 代理';

	/// zh-CN: '配置 SOCKS5 代理'
	String get proxySubtitle => '配置 SOCKS5 代理';

	/// zh-CN: '关闭后将不使用 SOCKS5 代理'
	String get proxyEnabledSubtitle => '关闭后将不使用 SOCKS5 代理';

	/// zh-CN: '代理地址'
	String get proxyAddress => '代理地址';

	/// zh-CN: '请输入 SOCKS5 代理地址'
	String get proxyHint => '请输入 SOCKS5 代理地址';

	/// zh-CN: '当前代理：$currentProxy'
	String proxyCurrent({required Object currentProxy}) => '当前代理：${currentProxy}';

	/// zh-CN: '更新下载加速'
	String get updateAccelerate => '更新下载加速';

	/// zh-CN: '开启后优先使用代理加速 GitHub 更新链接'
	String get updateAccelerateSubtitle => '开启后优先使用代理加速 GitHub 更新链接';

	/// zh-CN: '同步'
	String get sync => '同步';

	/// zh-CN: '同步配置'
	String get syncConfig => '同步配置';

	/// zh-CN: '进入页面，配置地址与鉴权信息'
	String get syncConfigSubtitle => '进入页面，配置地址与鉴权信息';

	/// zh-CN: '同步服务'
	String get syncService => '同步服务';

	/// zh-CN: '选择服务，统一管理同步策略'
	String get syncServiceSubtitle => '选择服务，统一管理同步策略';

	/// zh-CN: '不启用'
	String get syncServiceNone => '不启用';

	/// zh-CN: 'WebDAV'
	String get syncServiceWebdav => 'WebDAV';

	/// zh-CN: 'S3'
	String get syncServiceS3 => 'S3';

	/// zh-CN: '自动同步'
	String get autoSync => '自动同步';

	/// zh-CN: '开启后在后台定期同步配置'
	String get autoSyncSubtitle => '开启后在后台定期同步配置';

	/// zh-CN: '自动同步通知'
	String get syncNotify => '自动同步通知';

	/// zh-CN: '开启后在同步开始与完成时提醒'
	String get syncNotifySubtitle => '开启后在同步开始与完成时提醒';

	/// zh-CN: '同步设置'
	String get syncSettings => '同步设置';

	/// zh-CN: '开启后使用云端设置覆盖本地设置'
	String get syncSettingsSubtitle => '开启后使用云端设置覆盖本地设置';

	/// zh-CN: '同步插件'
	String get syncPlugins => '同步插件';

	/// zh-CN: '开启后同步插件配置与安装状态'
	String get syncPluginsSubtitle => '开启后同步插件配置与安装状态';

	/// zh-CN: '应用行为'
	String get appBehavior => '应用行为';

	/// zh-CN: '开屏页'
	String get splashPage => '开屏页';

	/// zh-CN: '选择启动页，打开应用直达目标'
	String get splashPageSubtitle => '选择启动页，打开应用直达目标';

	/// zh-CN: '关闭行为'
	String get desktopCloseBehavior => '关闭行为';

	/// zh-CN: '选择点击关闭按钮时的行为'
	String get desktopCloseBehaviorSubtitle => '选择点击关闭按钮时的行为';

	/// zh-CN: '询问'
	String get desktopCloseAsk => '询问';

	/// zh-CN: '隐藏到托盘'
	String get desktopCloseHide => '隐藏到托盘';

	/// zh-CN: '直接关闭'
	String get desktopCloseClose => '直接关闭';

	/// zh-CN: '显示主界面'
	String get showMainWindow => '显示主界面';

	/// zh-CN: '退出'
	String get exitApp => '退出';

	/// zh-CN: '应用锁'
	String get appLock => '应用锁';

	/// zh-CN: '开启后进入应用需要验证'
	String get appLockSubtitle => '开启后进入应用需要验证';

	/// zh-CN: '旧版首页'
	String get oldPageRollback => '旧版首页';

	/// zh-CN: '开启后使用旧版首页布局'
	String get oldPageRollbackSubtitle => '开启后使用旧版首页布局';

	/// zh-CN: '后台保活'
	String get androidKeepAlive => '后台保活';

	/// zh-CN: '开启后通过前台服务尽量保持应用在后台运行，会显示常驻通知'
	String get androidKeepAliveSubtitle => '开启后通过前台服务尽量保持应用在后台运行，会显示常驻通知';

	/// zh-CN: '自定义导出路径'
	String get customExportPath => '自定义导出路径';

	/// zh-CN: '存储'
	String get storage => '存储';

	/// zh-CN: '缓存'
	String get cache => '缓存';

	/// zh-CN: '清理缓存'
	String get clearCache => '清理缓存';

	/// zh-CN: '确定要清理所有缓存文件吗？此操作不可撤销。'
	String get clearCacheConfirm => '确定要清理所有缓存文件吗？此操作不可撤销。';

	/// zh-CN: '计算中...'
	String get calculatingCache => '计算中...';

	/// zh-CN: '计算失败'
	String get calculateCacheFailed => '计算失败';

	/// zh-CN: '数据导入/导出'
	String get dataBackup => '数据导入/导出';

	/// zh-CN: '备份或恢复应用数据与下载的漫画'
	String get dataBackupSubtitle => '备份或恢复应用数据与下载的漫画';

	/// zh-CN: '包含下载的漫画'
	String get includeDownloaded => '包含下载的漫画';

	/// zh-CN: '导出时一并打包已下载的漫画文件'
	String get includeDownloadedSubtitle => '导出时一并打包已下载的漫画文件';

	/// zh-CN: '导出数据'
	String get exportData => '导出数据';

	/// zh-CN: '导入数据'
	String get importData => '导入数据';

	/// zh-CN: '图片处理'
	String get imageProcessing => '图片处理';

	/// zh-CN: '图片超分（实验性）'
	String get realSr => '图片超分（实验性）';

	/// zh-CN: '试验性功能，可能不稳定'
	String get realSrSubtitle => '试验性功能，可能不稳定';

	/// zh-CN: '自动超分'
	String get autoRealSr => '自动超分';

	/// zh-CN: '分辨率阈值'
	String get resolutionThreshold => '分辨率阈值';

	/// zh-CN: '调试'
	String get debug => '调试';

	/// zh-CN: '日志转发地址'
	String get logAddress => '日志转发地址';

	/// zh-CN: '配置后实时转发日志到指定地址'
	String get logAddressSubtitle => '配置后实时转发日志到指定地址';

	/// zh-CN: '内存调试'
	String get memoryDebug => '内存调试';

	/// zh-CN: '开启后在界面显示内存占用信息'
	String get memoryDebugSubtitle => '开启后在界面显示内存占用信息';

	/// zh-CN: '强制启用 Impeller'
	String get forceEnableImpeller => '强制启用 Impeller';

	/// zh-CN: 'Android 实验性渲染后端'
	String get forceEnableImpellerSubtitle => 'Android 实验性渲染后端';

	/// zh-CN: '整点颜色看看'
	String get colorPreview => '整点颜色看看';

	/// zh-CN: '打开调色页，快速预览主题色'
	String get colorPreviewSubtitle => '打开调色页，快速预览主题色';

	/// zh-CN: 'QJS 运行时调试'
	String get qjsRuntimeDebug => 'QJS 运行时调试';

	/// zh-CN: '手动输入运行时 ID，抓取调试快照'
	String get qjsRuntimeDebugSubtitle => '手动输入运行时 ID，抓取调试快照';

	/// zh-CN: '调试快照'
	String get qjsRuntimeSnapshot => '调试快照';

	/// zh-CN: '运行时 ID'
	String get qjsRuntimeIdLabel => '运行时 ID';

	/// zh-CN: '例如 0a0e5858-a467-4702-994a-79e608a4589d'
	String get qjsRuntimeIdHint => '例如 0a0e5858-a467-4702-994a-79e608a4589d';

	/// zh-CN: '抓取快照'
	String get qjsRuntimeCapture => '抓取快照';

	/// zh-CN: '抓取中'
	String get qjsRuntimeCapturing => '抓取中';

	/// zh-CN: '复制输出'
	String get qjsRuntimeCopyOutput => '复制输出';

	/// zh-CN: '暂无输出'
	String get qjsRuntimeNoOutput => '暂无输出';

	/// zh-CN: '请先输入运行时 ID'
	String get qjsRuntimeFillId => '请先输入运行时 ID';

	/// zh-CN: '已抓取 $dateTime'
	String qjsRuntimeCapturedAt({required Object dateTime}) => '已抓取 ${dateTime}';

	/// zh-CN: '抓取失败: $error'
	String qjsRuntimeCaptureFailed({required Object error}) => '抓取失败: ${error}';

	/// zh-CN: '当前没有可复制的内容'
	String get qjsRuntimeNoCopyContent => '当前没有可复制的内容';

	/// zh-CN: '已复制到剪贴板'
	String get qjsRuntimeCopied => '已复制到剪贴板';

	/// zh-CN: 'Variable Font 测试'
	String get colorPreviewVariableFont => 'Variable Font 测试';

	/// zh-CN: '已加载: $path'
	String colorPreviewFontLoaded({required Object path}) => '已加载: ${path}';

	/// zh-CN: '还没加载字体，先试推荐样本或者手动选一个 TTF/OTF 文件。'
	String get colorPreviewNoFont => '还没加载字体，先试推荐样本或者手动选一个 TTF/OTF 文件。';

	/// zh-CN: '加载推荐样本'
	String get colorPreviewLoadRecommended => '加载推荐样本';

	/// zh-CN: '选择字体文件'
	String get colorPreviewSelectFont => '选择字体文件';

	/// zh-CN: '按 fontWeight 渲染'
	String get colorPreviewByWeight => '按 fontWeight 渲染';

	/// zh-CN: '按 variable axis 渲染'
	String get colorPreviewByVariableAxis => '按 variable axis 渲染';

	/// zh-CN: '系统默认字体对照'
	String get colorPreviewSystemDefault => '系统默认字体对照';

	/// zh-CN: '正在加载字体...'
	String get colorPreviewLoadingFont => '正在加载字体...';

	/// zh-CN: '加载成功，可以直接对比不同字重。'
	String get colorPreviewLoadSuccess => '加载成功，可以直接对比不同字重。';

	/// zh-CN: '加载失败: $error'
	String colorPreviewLoadFailed({required Object error}) => '加载失败: ${error}';

	/// zh-CN: '红色'
	String get colorRed => '红色';

	/// zh-CN: '粉色'
	String get colorPink => '粉色';

	/// zh-CN: '紫色'
	String get colorPurple => '紫色';

	/// zh-CN: '深紫色'
	String get colorDeepPurple => '深紫色';

	/// zh-CN: '靛蓝色'
	String get colorIndigo => '靛蓝色';

	/// zh-CN: '蓝色'
	String get colorBlue => '蓝色';

	/// zh-CN: '浅蓝色'
	String get colorLightBlue => '浅蓝色';

	/// zh-CN: '青色'
	String get colorCyan => '青色';

	/// zh-CN: '水鸭色'
	String get colorTeal => '水鸭色';

	/// zh-CN: '绿色'
	String get colorGreen => '绿色';

	/// zh-CN: '浅绿色'
	String get colorLightGreen => '浅绿色';

	/// zh-CN: '酸橙色'
	String get colorLime => '酸橙色';

	/// zh-CN: '黄色'
	String get colorYellow => '黄色';

	/// zh-CN: '琥珀色'
	String get colorAmber => '琥珀色';

	/// zh-CN: '橙色'
	String get colorOrange => '橙色';

	/// zh-CN: '深橙色'
	String get colorDeepOrange => '深橙色';

	/// zh-CN: '棕色'
	String get colorBrown => '棕色';

	/// zh-CN: '灰色'
	String get colorGrey => '灰色';

	/// zh-CN: '蓝灰色'
	String get colorBlueGrey => '蓝灰色';

	/// zh-CN: 'CoreML 超分调试'
	String get coremlDebug => 'CoreML 超分调试';

	/// zh-CN: '使用绝对路径模型测试 CoreML 超分'
	String get coremlDebugSubtitle => '使用绝对路径模型测试 CoreML 超分';

	/// zh-CN: '关于与更多'
	String get aboutAndMore => '关于与更多';

	/// zh-CN: '更新日志'
	String get changelog => '更新日志';

	/// zh-CN: '查看各个版本的更新记录'
	String get changelogSubtitle => '查看各个版本的更新记录';

	/// zh-CN: '关于应用'
	String get aboutApp => '关于应用';

	/// zh-CN: '关于 Breeze 的详细信息'
	String get aboutAppSubtitle => '关于 Breeze 的详细信息';

	/// zh-CN: '插件管理'
	String get pluginManagement => '插件管理';

	/// zh-CN: '调试模式'
	String get debugMode => '调试模式';

	/// zh-CN: '调试地址'
	String get debugAddress => '调试地址';

	/// zh-CN: '未设置'
	String get notSet => '未设置';
}

// Path: bookshelf
class Translations$bookshelf$zh_CN {
	Translations$bookshelf$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '书架'
	String get title => '书架';

	/// zh-CN: '收藏'
	String get favorite => '收藏';

	/// zh-CN: '历史'
	String get history => '历史';

	/// zh-CN: '下载'
	String get download => '下载';

	/// zh-CN: '筛选'
	String get filter => '筛选';

	/// zh-CN: '搜索列表'
	String get searchList => '搜索列表';

	/// zh-CN: '新建文件夹'
	String get newFolder => '新建文件夹';

	/// zh-CN: '管理'
	String get manage => '管理';

	/// zh-CN: '导入漫画'
	String get importComic => '导入漫画';

	/// zh-CN: '书架说明'
	String get folderHint => '书架说明';

	/// zh-CN: '移出文件夹'
	String get removeFromFolder => '移出文件夹';

	/// zh-CN: '删除收藏'
	String get deleteFavorite => '删除收藏';

	/// zh-CN: '删除历史记录'
	String get deleteHistory => '删除历史记录';

	/// zh-CN: '删除下载记录'
	String get deleteDownload => '删除下载记录';

	/// zh-CN: '确定要删除选中的 $count 条记录吗？'
	String confirmDeleteSelected({required Object count}) => '确定要删除选中的 ${count} 条记录吗？';

	/// zh-CN: '已删除 $count 条记录'
	String deletedRecords({required Object count}) => '已删除 ${count} 条记录';

	/// zh-CN: '暂无可筛选的插件来源'
	String get noFilterSource => '暂无可筛选的插件来源';

	/// zh-CN: '排序'
	String get sort => '排序';

	/// zh-CN: '时间(晚→早)'
	String get sortDesc => '时间(晚→早)';

	/// zh-CN: '时间(早→晚)'
	String get sortAsc => '时间(早→晚)';

	/// zh-CN: '文件夹（已废弃）'
	String get folderDeprecated => '文件夹（已废弃）';

	/// zh-CN: '漫画源'
	String get source => '漫画源';

	/// zh-CN: '取消全选'
	String get deselectAll => '取消全选';

	/// zh-CN: '删除收藏夹'
	String get deleteFolder => '删除收藏夹';

	/// zh-CN: '重命名收藏夹'
	String get renameFolder => '重命名收藏夹';

	/// zh-CN: '是否删除当前文件夹「$name」？'
	String confirmDeleteFolder({required Object name}) => '是否删除当前文件夹「${name}」？';

	/// zh-CN: '请选择操作'
	String get folderAction => '请选择操作';

	/// zh-CN: '新建收藏夹'
	String get createFolder => '新建收藏夹';

	/// zh-CN: '输入收藏夹名称'
	String get createFolderHint => '输入收藏夹名称';

	/// zh-CN: '多选'
	String get multiSelect => '多选';

	/// zh-CN: '复制到'
	String get copyTo => '复制到';

	/// zh-CN: '批量导出'
	String get batchExport => '批量导出';

	/// zh-CN: '批量删除失败'
	String get batchDeleteFailed => '批量删除失败';

	/// zh-CN: '删除选中'
	String get deleteSelected => '删除选中';

	/// zh-CN: '取消选择'
	String get cancel => '取消选择';

	/// zh-CN: '加入收藏夹'
	String get addToFavorite => '加入收藏夹';

	/// zh-CN: '加入下载文件夹'
	String get addToDownloadFolder => '加入下载文件夹';

	/// zh-CN: '请先创建自定义收藏夹'
	String get createFavoriteFolderFirst => '请先创建自定义收藏夹';

	/// zh-CN: '已加入收藏夹'
	String get addedToFavorite => '已加入收藏夹';

	/// zh-CN: '请先创建自定义下载文件夹'
	String get createDownloadFolderFirst => '请先创建自定义下载文件夹';

	/// zh-CN: '已加入下载文件夹'
	String get addedToDownloadFolder => '已加入下载文件夹';

	/// zh-CN: '选择收藏夹（可多选）'
	String get selectFavoriteFolder => '选择收藏夹（可多选）';

	/// zh-CN: '选择下载文件夹（可多选）'
	String get selectDownloadFolder => '选择下载文件夹（可多选）';

	/// zh-CN: '已选择 $count 项'
	String selectedCount({required Object count}) => '已选择 ${count} 项';

	/// zh-CN: '选择目标文件夹（可多选）'
	String get selectTargetFolder => '选择目标文件夹（可多选）';

	/// zh-CN: '确认删除'
	String get confirmDeleteFolderTitle => '确认删除';

	/// zh-CN: '确定要删除该文件夹吗？文件夹内的内容会被递归删除。'
	String get confirmDeleteFolderContent => '确定要删除该文件夹吗？文件夹内的内容会被递归删除。';

	/// zh-CN: '从文件夹移除'
	String get confirmRemoveComicTitle => '从文件夹移除';

	/// zh-CN: '确定要从当前文件夹移除《$title》吗？'
	String confirmRemoveComicContent({required Object title}) => '确定要从当前文件夹移除《${title}》吗？';

	/// zh-CN: '开始导入漫画（仅支持 zip）'
	String get importComicZipOnly => '开始导入漫画（仅支持 zip）';

	/// zh-CN: '开始导入漫画（仅支持 zip）'
	String get importStarted => '开始导入漫画（仅支持 zip）';

	/// zh-CN: '导入完成：$title'
	String importCompleted({required Object title}) => '导入完成：${title}';

	/// zh-CN: '漫画已存在'
	String get comicExists => '漫画已存在';

	/// zh-CN: '《$title》已经存在于下载列表中，是否覆盖导入？'
	String confirmOverwriteImport({required Object title}) => '《${title}》已经存在于下载列表中，是否覆盖导入？';

	/// zh-CN: '选中的项目中没有可导出的漫画'
	String get noExportableComics => '选中的项目中没有可导出的漫画';

	/// zh-CN: '批量导出完成：$success/$total'
	String batchExportCompleted({required Object success, required Object total}) => '批量导出完成：${success}/${total}';

	/// zh-CN: '批量导出失败: $error'
	String batchExportFailed({required Object error}) => '批量导出失败: ${error}';

	/// zh-CN: '确认删除'
	String get confirmDeleteSelectedTitle => '确认删除';

	/// zh-CN: '确定要删除选中的文件夹和漫画吗？文件夹会递归删除。'
	String get confirmDeleteSelectedContent => '确定要删除选中的文件夹和漫画吗？文件夹会递归删除。';

	/// zh-CN: '取消选择'
	String get cancelSelect => '取消选择';

	/// zh-CN: '全选'
	String get selectAll => '全选';

	/// zh-CN: '移动到'
	String get moveTo => '移动到';

	/// zh-CN: '加入文件夹'
	String get addToFolder => '加入文件夹';

	/// zh-CN: '文件夹名称'
	String get folderName => '文件夹名称';

	/// zh-CN: '请输入文件夹名称'
	String get folderNameHint => '请输入文件夹名称';

	/// zh-CN: '• 收藏和书架是联动的：收藏一本漫画，它会出现在书架里；只有把这本漫画从所有收藏文件夹里都删除，才会自动取消收藏。 • 在漫画详情页“取消收藏”，会一次性从所有收藏文件夹里移除这本漫画。 • 下载也是一样：只有把一本漫画从所有下载文件夹里都删除，才会自动删除它的下载文件。'
	String get helpContent => '• 收藏和书架是联动的：收藏一本漫画，它会出现在书架里；只有把这本漫画从所有收藏文件夹里都删除，才会自动取消收藏。\n• 在漫画详情页“取消收藏”，会一次性从所有收藏文件夹里移除这本漫画。\n• 下载也是一样：只有把一本漫画从所有下载文件夹里都删除，才会自动删除它的下载文件。';

	/// zh-CN: '文件夹创建成功'
	String get folderCreated => '文件夹创建成功';

	/// zh-CN: '还没有漫画'
	String get noComic => '还没有漫画';

	/// zh-CN: '还没有阅读记录'
	String get noHistory => '还没有阅读记录';

	/// zh-CN: '还没有下载记录'
	String get noDownload => '还没有下载记录';

	/// zh-CN: '啥都没有'
	String get nothingHere => '啥都没有';

	/// zh-CN: '删除所有下载记录及其文件'
	String get deleteAllDownloadRecordsAndFiles => '删除所有下载记录及其文件';

	/// zh-CN: '清空历史记录'
	String get clearHistoryRecords => '清空历史记录';

	/// zh-CN: '确定要删除所有下载记录及其文件吗？此操作不可恢复！'
	String get confirmDeleteAllDownloadsContent => '确定要删除所有下载记录及其文件吗？此操作不可恢复！';

	/// zh-CN: '确定要清空历史记录吗？此操作不可恢复！'
	String get confirmClearHistoryContent => '确定要清空历史记录吗？此操作不可恢复！';

	/// zh-CN: '所有下载记录及其文件已删除'
	String get allDownloadRecordsAndFilesDeleted => '所有下载记录及其文件已删除';

	/// zh-CN: '历史记录已清空'
	String get historyRecordsCleared => '历史记录已清空';

	/// zh-CN: '选择导出方式'
	String get batchExportTitle => '选择导出方式';

	/// zh-CN: '请选择批量导出为压缩包或文件夹'
	String get batchExportSubtitle => '请选择批量导出为压缩包或文件夹';

	/// zh-CN: '已取消导入'
	String get importCancelled => '已取消导入';

	/// zh-CN: '第$index集'
	String importEpisodeFallback({required Object index}) => '第${index}集';

	/// zh-CN: '导入目录缺少必要的 JSON 文件'
	String get importMissingJson => '导入目录缺少必要的 JSON 文件';

	/// zh-CN: '该版本无法导入，请使用较新的软件版本导出后导入'
	String get importVersionUnsupported => '该版本无法导入，请使用较新的软件版本导出后导入';

	/// zh-CN: '该导出文件缺少来源信息，请使用新版软件重新导出后再导入'
	String get importMissingSource => '该导出文件缺少来源信息，请使用新版软件重新导出后再导入';

	/// zh-CN: '无法获取漫画 ID'
	String get importMissingComicId => '无法获取漫画 ID';

	/// zh-CN: '未在压缩包中找到可导入的漫画目录'
	String get importNoComicDir => '未在压缩包中找到可导入的漫画目录';

	/// zh-CN: '压缩包中包含多个漫画目录，请每次只导入一本'
	String get importMultipleComicDirs => '压缩包中包含多个漫画目录，请每次只导入一本';

	/// zh-CN: '漫画《$title》已存在，未覆盖导入'
	String importComicExistsUncovered({required Object title}) => '漫画《${title}》已存在，未覆盖导入';

	/// zh-CN: '文件夹名称不能为空'
	String get folderNameEmpty => '文件夹名称不能为空';

	/// zh-CN: '文件夹名称不能包含 /'
	String get folderNameSlash => '文件夹名称不能包含 /';

	/// zh-CN: '当前路径下已存在同名文件夹'
	String get folderNameExists => '当前路径下已存在同名文件夹';

	/// zh-CN: '目标位置已存在同名文件夹：$name'
	String targetFolderNameExists({required Object name}) => '目标位置已存在同名文件夹：${name}';

	/// zh-CN: '不能将文件夹移动到自身'
	String get cannotMoveFolderToSelf => '不能将文件夹移动到自身';

	/// zh-CN: '不能将父文件夹移动到子文件夹中'
	String get cannotMoveParentToChild => '不能将父文件夹移动到子文件夹中';

	/// zh-CN: '不能复制文件夹到自身或其子路径下'
	String get cannotCopyFolderToSelfOrChild => '不能复制文件夹到自身或其子路径下';

	/// zh-CN: '移动文件夹时只能选择一个目标文件夹'
	String get moveFoldersOnlyOneTarget => '移动文件夹时只能选择一个目标文件夹';

	/// zh-CN: '收藏夹名称不能为空'
	String get favoriteFolderNameEmpty => '收藏夹名称不能为空';

	/// zh-CN: '已存在同名收藏夹'
	String get favoriteFolderNameExists => '已存在同名收藏夹';

	/// zh-CN: '下载文件夹名称不能为空'
	String get downloadFolderNameEmpty => '下载文件夹名称不能为空';

	/// zh-CN: '已存在同名下载文件夹'
	String get downloadFolderNameExists => '已存在同名下载文件夹';

	/// zh-CN: '移出收藏夹'
	String get removeFromFavoriteFolder => '移出收藏夹';

	/// zh-CN: '移出下载文件夹'
	String get removeFromDownloadFolder => '移出下载文件夹';

	/// zh-CN: '是否要从本文件夹中移除'
	String get confirmRemoveFromCurrentFolder => '是否要从本文件夹中移除';

	/// zh-CN: '确定要删除选中的 $count 条收藏记录吗？'
	String confirmDeleteSelectedFavorites({required Object count}) => '确定要删除选中的 ${count} 条收藏记录吗？';

	/// zh-CN: '确定要删除选中的 $count 条历史记录吗？'
	String confirmDeleteSelectedHistory({required Object count}) => '确定要删除选中的 ${count} 条历史记录吗？';

	/// zh-CN: '确定要删除选中的 $count 条下载记录及文件吗？'
	String confirmDeleteSelectedDownloads({required Object count}) => '确定要删除选中的 ${count} 条下载记录及文件吗？';
}

// Path: comicInfo
class Translations$comicInfo$zh_CN {
	Translations$comicInfo$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '加入追更'
	String get follow => '加入追更';

	/// zh-CN: '不再追更'
	String get unfollow => '不再追更';

	/// zh-CN: '导出漫画'
	String get exportComic => '导出漫画';

	/// zh-CN: '收藏到云端'
	String get collectToCloud => '收藏到云端';

	/// zh-CN: '取消云端收藏'
	String get removeCloudCollection => '取消云端收藏';

	/// zh-CN: '云端收藏已关闭'
	String get cloudCollectDisabled => '云端收藏已关闭';

	/// zh-CN: '收藏到云端中...'
	String get collectingToCloud => '收藏到云端中...';

	/// zh-CN: '取消云端收藏中...'
	String get removingCloudCollection => '取消云端收藏中...';

	/// zh-CN: '云端收藏成功'
	String get cloudCollectSuccess => '云端收藏成功';

	/// zh-CN: '已取消云端收藏'
	String get cloudUncollectSuccess => '已取消云端收藏';

	/// zh-CN: '此漫画已下架'
	String get discontinued => '此漫画已下架';

	/// zh-CN: '点赞 $count'
	String likes({required Object count}) => '点赞 ${count}';

	/// zh-CN: '评论 $count'
	String comments({required Object count}) => '评论 ${count}';

	/// zh-CN: '已收藏'
	String get collected => '已收藏';

	/// zh-CN: '收藏'
	String get collect => '收藏';

	/// zh-CN: '下载'
	String get download => '下载';

	/// zh-CN: '禁止下载'
	String get downloadForbidden => '禁止下载';

	/// zh-CN: '已添加收藏'
	String get addedToCollection => '已添加收藏';

	/// zh-CN: '已取消收藏'
	String get removedFromCollection => '已取消收藏';

	/// zh-CN: '确认取消收藏'
	String get confirmUncollectTitle => '确认取消收藏';

	/// zh-CN: '此项操作会删除该漫画在所有文件夹的记录，是否确认删除？'
	String get confirmUncollectContent => '此项操作会删除该漫画在所有文件夹的记录，是否确认删除？';

	/// zh-CN: '该漫画禁止评论'
	String get commentForbidden => '该漫画禁止评论';

	/// zh-CN: '禁止评论'
	String get commentForbiddenTitle => '禁止评论';

	/// zh-CN: '返回'
	String get back => '返回';

	/// zh-CN: '选择导出方式'
	String get exportTitle => '选择导出方式';

	/// zh-CN: '请选择将漫画导出为压缩包还是文件夹：'
	String get exportSubtitle => '请选择将漫画导出为压缩包还是文件夹：';

	/// zh-CN: '文件夹'
	String get folder => '文件夹';

	/// zh-CN: '压缩包'
	String get zip => '压缩包';

	/// zh-CN: '导出成功'
	String get exportSuccess => '导出成功';

	/// zh-CN: '当前详情尚未加载完成'
	String get detailsNotLoaded => '当前详情尚未加载完成';

	/// zh-CN: '已加入追更'
	String get followed => '已加入追更';

	/// zh-CN: '已取消追更'
	String get unfollowed => '已取消追更';

	/// zh-CN: '取消追更'
	String get confirmUnfollowTitle => '取消追更';

	/// zh-CN: '确定不再追更《$title》吗？'
	String confirmUnfollowContent({required Object title}) => '确定不再追更《${title}》吗？';

	/// zh-CN: '暂无章节信息'
	String get noChapters => '暂无章节信息';

	/// zh-CN: '章节目录'
	String get chapterList => '章节目录';

	/// zh-CN: '$count 话'
	String episodeCount({required Object count}) => '${count} 话';

	/// zh-CN: '第$index话'
	String episodeFallback({required Object index}) => '第${index}话';

	/// zh-CN: '第$index话'
	String episodeLabel({required Object index}) => '第${index}话';

	/// zh-CN: '作者'
	String get author => '作者';

	/// zh-CN: '标签'
	String get tags => '标签';

	/// zh-CN: '作品'
	String get works => '作品';

	/// zh-CN: '浏览：$count'
	String views({required Object count}) => '浏览：${count}';

	/// zh-CN: '更新时间：$time'
	String updateTime({required Object time}) => '更新时间：${time}';

	/// zh-CN: '开始阅读'
	String get startRead => '开始阅读';

	/// zh-CN: '继续阅读'
	String get continueRead => '继续阅读';

	/// zh-CN: '上次读到'
	String get lastRead => '上次读到';

	/// zh-CN: '章节'
	String get chapters => '章节';

	/// zh-CN: '相关推荐'
	String get related => '相关推荐';

	/// zh-CN: '简介'
	String get description => '简介';

	/// zh-CN: '收起'
	String get collapse => '收起';

	/// zh-CN: '展开全文'
	String get expandFullText => '展开全文';

	/// zh-CN: '阅读记录'
	String get readHistory => '阅读记录';

	/// zh-CN: '已复制：$label'
	String copied({required Object label}) => '已复制：${label}';

	/// zh-CN: '已将 $name 复制到剪贴板'
	String copiedToClipboard({required Object name}) => '已将 ${name} 复制到剪贴板';

	/// zh-CN: '点赞中...'
	String get liking => '点赞中...';

	/// zh-CN: '取消点赞中...'
	String get unliking => '取消点赞中...';

	/// zh-CN: '点赞成功'
	String get likeSuccess => '点赞成功';

	/// zh-CN: '已取消点赞'
	String get unlikeSuccess => '已取消点赞';

	/// zh-CN: '本地收藏失败: $error'
	String localCollectFailed({required Object error}) => '本地收藏失败: ${error}';

	/// zh-CN: '点赞失败: $error'
	String likeFailed({required Object error}) => '点赞失败: ${error}';

	/// zh-CN: '$error 加载失败，请重试。'
	String loadFailedWithError({required Object error}) => '${error}\n加载失败，请重试。';

	/// zh-CN: '未授予所有文件访问权限，导出已取消'
	String get exportPermissionDenied => '未授予所有文件访问权限，导出已取消';

	/// zh-CN: '导出失败，请重试。 $error'
	String exportFailedWithError({required Object error}) => '导出失败，请重试。\n${error}';

	/// zh-CN: '导出目录：$displayPath'
	String exportDirectory({required Object displayPath}) => '导出目录：${displayPath}';

	/// zh-CN: '导出目录路径过长，无法创建有效的导出结构'
	String get exportPathTooLong => '导出目录路径过长，无法创建有效的导出结构';

	/// zh-CN: '指定的 zip 导出路径超出系统路径长度限制'
	String get zipExportPathTooLong => '指定的 zip 导出路径超出系统路径长度限制';

	/// zh-CN: '下载目录路径过长，无法创建有效的 zip 文件路径'
	String get downloadPathTooLong => '下载目录路径过长，无法创建有效的 zip 文件路径';

	/// zh-CN: '无法为章节创建不重复的文件名：超出路径长度限制'
	String get uniqueFileNameTooLong => '无法为章节创建不重复的文件名：超出路径长度限制';

	/// zh-CN: '漫画$title导出为文件夹完成'
	String exportFolderComplete({required Object title}) => '漫画${title}导出为文件夹完成';

	/// zh-CN: '漫画$title导出为 zip 完成'
	String exportZipComplete({required Object title}) => '漫画${title}导出为 zip 完成';

	/// zh-CN: '未找到可导出的下载漫画: $comicId'
	String exportComicNotFound({required Object comicId}) => '未找到可导出的下载漫画: ${comicId}';

	/// zh-CN: '插件未返回有效 favorited 状态'
	String get pluginInvalidFavorited => '插件未返回有效 favorited 状态';

	/// zh-CN: '插件未返回有效 liked 状态'
	String get pluginInvalidLiked => '插件未返回有效 liked 状态';

	/// zh-CN: '添加到自定义收藏夹'
	String get addToCustomFolder => '添加到自定义收藏夹';

	/// zh-CN: '已添加到收藏夹: $name'
	String addedToFolder({required Object name}) => '已添加到收藏夹: ${name}';

	/// zh-CN: '跳过/不添加'
	String get skipAdd => '跳过/不添加';

	/// zh-CN: '确定添加'
	String get confirmAdd => '确定添加';

	/// zh-CN: '无法解析阅读 comicId: $type'
	String resolveComicIdFailed({required Object type}) => '无法解析阅读 comicId: ${type}';

	/// zh-CN: '无法解析阅读章节数: $type'
	String resolveEpsCountFailed({required Object type}) => '无法解析阅读章节数: ${type}';
}

// Path: reader
class Translations$reader$zh_CN {
	Translations$reader$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '翻页模式'
	String get pageMode => '翻页模式';

	/// zh-CN: '全屏模式'
	String get fullscreen => '全屏模式';

	/// zh-CN: '左手模式'
	String get leftHandMode => '左手模式';

	/// zh-CN: '右手模式'
	String get rightHandMode => '右手模式';

	/// zh-CN: '阅读模式'
	String get readingMode => '阅读模式';

	/// zh-CN: '信息项显示'
	String get infoDisplay => '信息项显示';

	/// zh-CN: '页数'
	String get pageNumber => '页数';

	/// zh-CN: '显示当前页/总页数'
	String get pageNumberSubtitle => '显示当前页/总页数';

	/// zh-CN: '网络状态'
	String get networkStatus => '网络状态';

	/// zh-CN: 'Linux 下可能不准确'
	String get networkStatusSubtitle => 'Linux 下可能不准确';

	/// zh-CN: '电量'
	String get battery => '电量';

	/// zh-CN: '时间'
	String get time => '时间';

	/// zh-CN: '顶部'
	String get verticalPositionTop => '顶部';

	/// zh-CN: '底部'
	String get verticalPositionBottom => '底部';

	/// zh-CN: '左侧'
	String get horizontalPositionLeft => '左侧';

	/// zh-CN: '居中'
	String get horizontalPositionCenter => '居中';

	/// zh-CN: '右侧'
	String get horizontalPositionRight => '右侧';

	/// zh-CN: '从左到右'
	String get readingDirectionLtr => '从左到右';

	/// zh-CN: '从右到左'
	String get readingDirectionRtl => '从右到左';

	/// zh-CN: '从上到下'
	String get readingDirectionVertical => '从上到下';

	/// zh-CN: '条漫'
	String get webtoon => '条漫';

	/// zh-CN: '单页式（从左到右）'
	String get singlePageLtr => '单页式（从左到右）';

	/// zh-CN: '单页式（从右到左）'
	String get singlePageRtl => '单页式（从右到左）';

	/// zh-CN: '双页阅读'
	String get doublePage => '双页阅读';

	/// zh-CN: '在当前阅读模式中启用双页并排'
	String get doublePageSubtitle => '在当前阅读模式中启用双页并排';

	/// zh-CN: '首页留白'
	String get doublePageLeadingBlank => '首页留白';

	/// zh-CN: '在每章最前插入一页空白，使配对整体错一位'
	String get doublePageLeadingBlankSubtitle => '在每章最前插入一页空白，使配对整体错一位';

	/// zh-CN: '系统模式'
	String get themeMode => '系统模式';

	/// zh-CN: '自动阅读'
	String get autoRead => '自动阅读';

	/// zh-CN: '开启后自动滚动，并在右下角显示暂停/播放按钮'
	String get autoReadSubtitle => '开启后自动滚动，并在右下角显示暂停/播放按钮';

	/// zh-CN: '条漫滚动距离'
	String get webtoonScrollDistance => '条漫滚动距离';

	/// zh-CN: '条漫滚动间隔'
	String get webtoonScrollInterval => '条漫滚动间隔';

	/// zh-CN: '单页式滚动间隔'
	String get singlePageScrollInterval => '单页式滚动间隔';

	/// zh-CN: '阅读背景'
	String get background => '阅读背景';

	/// zh-CN: '自动'
	String get auto => '自动';

	/// zh-CN: '黑色'
	String get black => '黑色';

	/// zh-CN: '白色'
	String get white => '白色';

	/// zh-CN: '灰色'
	String get grey => '灰色';

	/// zh-CN: '阅读体验'
	String get readingExperience => '阅读体验';

	/// zh-CN: '关闭翻页动画'
	String get disableAnimation => '关闭翻页动画';

	/// zh-CN: '关闭整页翻页动画，小幅滚动动画不受影响'
	String get disableAnimationSubtitle => '关闭整页翻页动画，小幅滚动动画不受影响';

	/// zh-CN: '阅读滤镜（仅深色模式）'
	String get readFilter => '阅读滤镜（仅深色模式）';

	/// zh-CN: '仅在阅读界面生效，可降低夜间阅读亮度'
	String get readFilterSubtitle => '仅在阅读界面生效，可降低夜间阅读亮度';

	/// zh-CN: '滤镜强度'
	String get filterIntensity => '滤镜强度';

	/// zh-CN: '墨水屏优化（仅横向）'
	String get einkOptimization => '墨水屏优化（仅横向）';

	/// zh-CN: '翻页后先白屏再显示图片'
	String get einkOptimizationSubtitle => '翻页后先白屏再显示图片';

	/// zh-CN: '白屏时长'
	String get einkDelay => '白屏时长';

	/// zh-CN: '两侧留白'
	String get sidePadding => '两侧留白';

	/// zh-CN: '自定义左右留白比例'
	String get sidePaddingSubtitle => '自定义左右留白比例';

	/// zh-CN: '每侧留白比例'
	String get sidePaddingPercent => '每侧留白比例';

	/// zh-CN: '默认关闭，可按需开启'
	String get batterySubtitle => '默认关闭，可按需开启';

	/// zh-CN: '显示当前时间'
	String get timeSubtitle => '显示当前时间';

	/// zh-CN: '信息条位置'
	String get infoBarPosition => '信息条位置';

	/// zh-CN: '显示在状态栏'
	String get showInStatusBar => '显示在状态栏';

	/// zh-CN: '开启后，顶部信息条会进入系统状态栏区域'
	String get showInStatusBarSubtitle => '开启后，顶部信息条会进入系统状态栏区域';

	/// zh-CN: '边缘间距'
	String get edgePadding => '边缘间距';

	/// zh-CN: '信息条样式'
	String get infoBarStyle => '信息条样式';

	/// zh-CN: '背景透明度'
	String get backgroundOpacity => '背景透明度';

	/// zh-CN: '字体大小'
	String get fontSize => '字体大小';

	/// zh-CN: '当前已全部关闭，阅读页中的信息条会完全隐藏。'
	String get allHiddenNotice => '当前已全部关闭，阅读页中的信息条会完全隐藏。';

	/// zh-CN: '横向在中间时，边缘间距不会生效。'
	String get edgePaddingDisabled => '横向在中间时，边缘间距不会生效。';

	/// zh-CN: '阅读设置'
	String get settings => '阅读设置';

	/// zh-CN: '上一章'
	String get previousChapter => '上一章';

	/// zh-CN: '下一章'
	String get nextChapter => '下一章';

	/// zh-CN: '返回首页'
	String get backToHome => '返回首页';

	/// zh-CN: '跳转'
	String get jumpToChapterTitle => '跳转';

	/// zh-CN: '是否要跳转到$chapter？'
	String jumpToChapterMessage({required Object chapter}) => '是否要跳转到${chapter}？';

	/// zh-CN: '选择章节'
	String get selectChapter => '选择章节';

	/// zh-CN: '全屏（f11）'
	String get enterFullscreen => '全屏（f11）';

	/// zh-CN: '退出全屏'
	String get exitFullscreen => '退出全屏';

	/// zh-CN: '章节过渡中'
	String get chapterTransition => '章节过渡中';

	/// zh-CN: '继续翻页加载'
	String get transitionSwipeToLoad => '继续翻页加载';

	/// zh-CN: '加载完成'
	String get transitionLoaded => '加载完成';

	/// zh-CN: '加载失败，点击重试'
	String get transitionLoadFailedRetry => '加载失败，点击重试';

	/// zh-CN: '继续下拉到上一章'
	String get pullDownToPrevChapter => '继续下拉到上一章';

	/// zh-CN: '松手跳转到上一章'
	String get releaseToJumpPrevChapter => '松手跳转到上一章';

	/// zh-CN: '松手加载到上一章'
	String get releaseToLoadPrevChapter => '松手加载到上一章';

	/// zh-CN: '继续上拉到下一章'
	String get pullUpToNextChapter => '继续上拉到下一章';

	/// zh-CN: '松手跳转到下一章'
	String get releaseToJumpNextChapter => '松手跳转到下一章';

	/// zh-CN: '松手加载到下一章'
	String get releaseToLoadNextChapter => '松手加载到下一章';

	/// zh-CN: '章节未下载'
	String get chapterNotDownloaded => '章节未下载';

	/// zh-CN: '$result 加载失败'
	String loadFailedWithResult({required Object result}) => '${result}\n加载失败';

	/// zh-CN: '章节 $order'
	String chapterOrder({required Object order}) => '章节 ${order}';

	/// zh-CN: '双击操作'
	String get doubleTapAction => '双击操作';

	/// zh-CN: '双击缩放'
	String get doubleTapZoom => '双击缩放';

	/// zh-CN: '双击图片可在缩放和还原之间切换'
	String get doubleTapZoomSubtitle => '双击图片可在缩放和还原之间切换';

	/// zh-CN: '双击打开操作栏'
	String get doubleTapOpenMenu => '双击打开操作栏';

	/// zh-CN: '双击页面打开操作栏（与双击缩放互斥）'
	String get doubleTapOpenMenuSubtitle => '双击页面打开操作栏（与双击缩放互斥）';

	/// zh-CN: '音量键翻页'
	String get volumeKeyPageTurn => '音量键翻页';

	/// zh-CN: '启用音量键翻页'
	String get enableVolumeKeyPageTurn => '启用音量键翻页';

	/// zh-CN: '开启后可用音量键上下翻页/滑动'
	String get volumeKeyPageTurnSubtitle => '开启后可用音量键上下翻页/滑动';

	/// zh-CN: '% 屏高'
	String get screenHeightPercent => '% 屏高';

	/// zh-CN: 'ms'
	String get milliseconds => 'ms';

	/// zh-CN: '%'
	String get percent => '%';

	/// zh-CN: 'px'
	String get pixels => 'px';

	/// zh-CN: '手势'
	String get gesture => '手势';

	/// zh-CN: '信息条'
	String get infoBar => '信息条';

	/// zh-CN: '暂停自动阅读'
	String get pauseAutoRead => '暂停自动阅读';

	/// zh-CN: '继续自动阅读'
	String get resumeAutoRead => '继续自动阅读';

	/// zh-CN: '$error 加载失败，点击重试'
	String imageLoadFailedRetry({required Object error}) => '${error}\n加载失败，点击重试';

	/// zh-CN: '图片已保存至: $path'
	String imageSavedTo({required Object path}) => '图片已保存至: ${path}';

	/// zh-CN: '图片已保存到相册！'
	String get imageSavedToAlbum => '图片已保存到相册！';

	/// zh-CN: '图片保存失败！'
	String get imageSaveFailed => '图片保存失败！';

	/// zh-CN: '保存失败: 请在系统设置中授予相册访问权限'
	String get saveImagePermissionDenied => '保存失败: 请在系统设置中授予相册访问权限';

	/// zh-CN: '保存失败: $error'
	String imageSaveFailedWithError({required Object error}) => '保存失败: ${error}';
}

// Path: plugin
class Translations$plugin$zh_CN {
	Translations$plugin$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '插件商店'
	String get store => '插件商店';

	/// zh-CN: '搜索插件名称或作者...'
	String get searchHint => '搜索插件名称或作者...';

	/// zh-CN: '本地安装'
	String get localInstall => '本地安装';

	/// zh-CN: '网络安装'
	String get networkInstall => '网络安装';

	/// zh-CN: '云端组件'
	String get cloudComponents => '云端组件';

	/// zh-CN: '请在网页中完成登录，宿主会自动同步 Cookie'
	String get loginSuccess => '请在网页中完成登录，宿主会自动同步 Cookie';

	/// zh-CN: '当前平台不支持外部 Chromium 自动登录回退'
	String get chromiumFallbackUnsupported => '当前平台不支持外部 Chromium 自动登录回退';

	/// zh-CN: '内置 WebView 登录受限，正在切换外部浏览器...'
	String get switchingToExternalBrowser => '内置 WebView 登录受限，正在切换外部浏览器...';

	/// zh-CN: '未检测到 Chromium 浏览器，请先安装 Chrome'
	String get chromiumNotFound => '未检测到 Chromium 浏览器，请先安装 Chrome';

	/// zh-CN: '已切换到 $browser，登录完成后会自动同步 Cookie'
	String browserSwitched({required Object browser}) => '已切换到 ${browser}，登录完成后会自动同步 Cookie';

	/// zh-CN: '无效链接: $url'
	String invalidLink({required Object url}) => '无效链接: ${url}';

	/// zh-CN: '无法打开链接: $url'
	String cannotOpenLink({required Object url}) => '无法打开链接: ${url}';

	/// zh-CN: '读取本地插件失败: $error'
	String readLocalPluginFailed({required Object error}) => '读取本地插件失败: ${error}';

	/// zh-CN: '从网络添加插件'
	String get addFromNetwork => '从网络添加插件';

	/// zh-CN: 'URL 不能为空'
	String get urlCannotBeEmpty => 'URL 不能为空';

	/// zh-CN: '开始安装'
	String get startInstall => '开始安装';

	/// zh-CN: '$name 设置'
	String pluginSettingsTitle({required Object name}) => '${name} 设置';

	/// zh-CN: '插件调试配置已更新'
	String get debugConfigUpdated => '插件调试配置已更新';

	/// zh-CN: '删除插件'
	String get deletePlugin => '删除插件';

	/// zh-CN: '确认删除该插件？此操作将删除插件及其相关数据。'
	String get confirmDeletePlugin => '确认删除该插件？此操作将删除插件及其相关数据。';

	/// zh-CN: '删除失败: $error'
	String deleteFailed({required Object error}) => '删除失败: ${error}';

	/// zh-CN: '插件已删除'
	String get pluginDeleted => '插件已删除';

	/// zh-CN: '执行失败: $error'
	String executeFailed({required Object error}) => '执行失败: ${error}';

	/// zh-CN: '调试模式'
	String get debugMode => '调试模式';

	/// zh-CN: '调试地址'
	String get debugAddress => '调试地址';

	/// zh-CN: '彻底删除插件，并删除相关数据'
	String get deletePluginSubtitle => '彻底删除插件，并删除相关数据';

	/// zh-CN: '插件设置'
	String get pluginSettings => '插件设置';

	/// zh-CN: '暂无用户信息'
	String get noUserInfo => '暂无用户信息';

	/// zh-CN: '操作'
	String get operations => '操作';

	/// zh-CN: '插件管理'
	String get management => '插件管理';

	/// zh-CN: '已安装'
	String get installed => '已安装';

	/// zh-CN: '未安装'
	String get notInstalled => '未安装';

	/// zh-CN: '更新'
	String get update => '更新';

	/// zh-CN: '安装'
	String get install => '安装';

	/// zh-CN: '卸载'
	String get uninstall => '卸载';

	/// zh-CN: '作者'
	String get author => '作者';

	/// zh-CN: '版本'
	String get version => '版本';

	/// zh-CN: '描述'
	String get description => '描述';

	/// zh-CN: '仓库'
	String get repo => '仓库';

	/// zh-CN: '主页'
	String get homepage => '主页';

	/// zh-CN: '下载'
	String get download => '下载';

	/// zh-CN: '下载更新'
	String get downloadUpdate => '下载更新';

	/// zh-CN: '暂无云端组件'
	String get noCloudPlugins => '暂无云端组件';

	/// zh-CN: '没有匹配的插件'
	String get noMatchingPlugins => '没有匹配的插件';

	/// zh-CN: '请输入插件脚本 URL'
	String get networkInstallHint => '请输入插件脚本 URL';

	/// zh-CN: '云端组件列表加载失败: $error'
	String cloudPluginsLoadFailed({required Object error}) => '云端组件列表加载失败: ${error}';

	/// zh-CN: '正在下载并安装 $name...'
	String installingFromCloud({required Object name}) => '正在下载并安装 ${name}...';

	/// zh-CN: '正在安装本地插件...'
	String get installingFromLocal => '正在安装本地插件...';

	/// zh-CN: '正在下载网络插件...'
	String get installingFromNetwork => '正在下载网络插件...';

	/// zh-CN: '云端下载失败: $error'
	String cloudDownloadFailed({required Object error}) => '云端下载失败: ${error}';

	/// zh-CN: '网络下载插件失败: $error'
	String networkDownloadFailed({required Object error}) => '网络下载插件失败: ${error}';

	/// zh-CN: '云端 $version'
	String cloudVersion({required Object version}) => '云端 ${version}';

	/// zh-CN: '本地 $version'
	String localVersion({required Object version}) => '本地 ${version}';

	/// zh-CN: '$name 登录'
	String loginTitle({required Object name}) => '${name} 登录';

	/// zh-CN: '登录 Cookie 已同步'
	String get cookieSynced => '登录 Cookie 已同步';

	/// zh-CN: '执行成功'
	String get executeSuccess => '执行成功';

	/// zh-CN: '用户信息'
	String get userInfoTitle => '用户信息';

	/// zh-CN: '用户信息加载失败'
	String get userInfoLoadFailed => '用户信息加载失败';

	/// zh-CN: '未命名操作'
	String get unnamedAction => '未命名操作';

	/// zh-CN: '插件设置加载中...'
	String get pluginSettingsLoading => '插件设置加载中...';

	/// zh-CN: '插件设置加载失败'
	String get pluginSettingsLoadFailed => '插件设置加载失败';

	/// zh-CN: '动作不可执行: 缺少 fnPath'
	String get actionNotExecutable => '动作不可执行: 缺少 fnPath';

	/// zh-CN: '已保存'
	String get saved => '已保存';

	/// zh-CN: '关闭'
	String get close => '关闭';

	/// zh-CN: '同步'
	String get sync => '同步';

	/// zh-CN: '通过 npm / updateUrl 检查并更新插件'
	String get syncSubtitle => '通过 npm / updateUrl 检查并更新插件';

	/// zh-CN: '正在同步插件...'
	String get syncing => '正在同步插件...';

	/// zh-CN: '同步成功'
	String get syncSuccess => '同步成功';

	/// zh-CN: '同步失败: $error'
	String syncFailed({required Object error}) => '同步失败: ${error}';

	/// zh-CN: '通过网络 URL 或本地文件手动重装当前插件'
	String get updateSubtitle => '通过网络 URL 或本地文件手动重装当前插件';

	/// zh-CN: '从网络安装'
	String get updateFromNetwork => '从网络安装';

	/// zh-CN: '从本地安装'
	String get updateFromLocal => '从本地安装';

	/// zh-CN: '选择安装方式'
	String get updateChooseSource => '选择安装方式';

	/// zh-CN: '正在更新插件...'
	String get updating => '正在更新插件...';

	/// zh-CN: '更新成功'
	String get updateSuccess => '更新成功';

	/// zh-CN: '更新失败: $error'
	String updateFailed({required Object error}) => '更新失败: ${error}';

	/// zh-CN: '插件 id 不一致，无法安装'
	String get uuidMismatch => '插件 id 不一致，无法安装';

	/// zh-CN: '当前版本 $version'
	String currentVersion({required Object version}) => '当前版本 ${version}';

	/// zh-CN: '已是最新版本'
	String get alreadyLatest => '已是最新版本';
}

// Path: gestureLock
class Translations$gestureLock$zh_CN {
	Translations$gestureLock$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '手势解锁'
	String get gestureTitle => '手势解锁';

	/// zh-CN: '请绘制手势密码'
	String get gestureHint => '请绘制手势密码';

	/// zh-CN: '输入 PIN'
	String get pinTitle => '输入 PIN';

	/// zh-CN: '请输入重置 PIN'
	String get pinHint => '请输入重置 PIN';

	/// zh-CN: '至少连接 4 个点'
	String get atLeast4Points => '至少连接 4 个点';

	/// zh-CN: '请再次绘制以确认'
	String get confirmGesture => '请再次绘制以确认';

	/// zh-CN: '两次绘制不一致'
	String get gestureNotMatch => '两次绘制不一致';

	/// zh-CN: '设置成功'
	String get setSuccess => '设置成功';

	/// zh-CN: '忘记密码'
	String get forgotPassword => '忘记密码';

	/// zh-CN: '手势密码不正确，请重试'
	String get incorrectPassword => '手势密码不正确，请重试';

	/// zh-CN: '重置 PIN'
	String get resetPin => '重置 PIN';

	/// zh-CN: 'PIN'
	String get pin => 'PIN';

	/// zh-CN: 'PIN 可用于重置手势密码，遗忘手势密码与 PIN 后将无法进入软件，请妥善保管 Pin'
	String get pinDescription => 'PIN 可用于重置手势密码，遗忘手势密码与 PIN 后将无法进入软件，请妥善保管 Pin';

	/// zh-CN: 'PIN 需至少 4 位数字'
	String get pinMinLength => 'PIN 需至少 4 位数字';

	/// zh-CN: '两次输入的 PIN 不一致'
	String get pinNotMatch => '两次输入的 PIN 不一致';

	/// zh-CN: 'PIN 不正确，请重试'
	String get pinIncorrect => 'PIN 不正确，请重试';

	/// zh-CN: '应用已锁定'
	String get appLocked => '应用已锁定';

	/// zh-CN: '请先完成手势验证'
	String get verifyToUnlock => '请先完成手势验证';

	/// zh-CN: '重置手势密码'
	String get resetGesturePassword => '重置手势密码';

	/// zh-CN: '请输入设置时保存的重置 PIN'
	String get resetPinHint => '请输入设置时保存的重置 PIN';

	/// zh-CN: '密码已清空，请重新设置'
	String get passwordCleared => '密码已清空，请重新设置';

	/// zh-CN: '请连接至少 4 个点'
	String get setupHintFirst => '请连接至少 4 个点';

	/// zh-CN: '请再次绘制相同手势'
	String get setupHintConfirm => '请再次绘制相同手势';

	/// zh-CN: '至少连接 4 个点'
	String get setupErrorMinPoints => '至少连接 4 个点';

	/// zh-CN: '两次手势不一致，请重新设置'
	String get setupErrorMismatch => '两次手势不一致，请重新设置';

	/// zh-CN: '至少 4 位数字'
	String get pinHintMinDigits => '至少 4 位数字';
}

// Path: appBootstrap
class Translations$appBootstrap$zh_CN {
	Translations$appBootstrap$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '初始化中....'
	String get initializing => '初始化中....';

	/// zh-CN: '请验证手势密码'
	String get verifyGesture => '请验证手势密码';

	/// zh-CN: 'PIN 验证未通过'
	String get pinVerifyFailed => 'PIN 验证未通过';

	/// zh-CN: '已取消解锁'
	String get unlockCancelled => '已取消解锁';

	/// zh-CN: '验证成功，正在进入应用'
	String get enteringApp => '验证成功，正在进入应用';
}

// Path: comments
class Translations$comments$zh_CN {
	Translations$comments$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '重试'
	String get retry => '重试';

	/// zh-CN: '暂无评论'
	String get noComments => '暂无评论';

	/// zh-CN: '加载更多'
	String get loadMore => '加载更多';

	/// zh-CN: '收起回复'
	String get collapseReplies => '收起回复';

	/// zh-CN: '$count 条回复'
	String replyCount({required Object count}) => '${count} 条回复';

	/// zh-CN: '暂无子评论'
	String get noReplies => '暂无子评论';

	/// zh-CN: '加载更多回复'
	String get loadMoreReplies => '加载更多回复';

	/// zh-CN: '发表评论'
	String get postComment => '发表评论';

	/// zh-CN: '输入评论内容'
	String get postCommentHint => '输入评论内容';

	/// zh-CN: '回复评论'
	String get postReply => '回复评论';

	/// zh-CN: '输入回复内容'
	String get postReplyHint => '输入回复内容';

	/// zh-CN: '取消'
	String get cancel => '取消';

	/// zh-CN: '确认'
	String get confirm => '确认';

	/// zh-CN: '发布成功'
	String get postSuccess => '发布成功';

	/// zh-CN: '发布失败: $error'
	String postFailed({required Object error}) => '发布失败: ${error}';

	/// zh-CN: '匿名用户'
	String get anonymous => '匿名用户';
}

// Path: cache
class Translations$cache$zh_CN {
	Translations$cache$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '缓存设置'
	String get title => '缓存设置';

	/// zh-CN: '当前缓存'
	String get currentCache => '当前缓存';

	/// zh-CN: '清理缓存'
	String get clearCache => '清理缓存';

	/// zh-CN: '确定要清理所有缓存文件吗？此操作不可撤销。'
	String get clearCacheConfirm => '确定要清理所有缓存文件吗？此操作不可撤销。';

	/// zh-CN: '缓存已清理'
	String get cleared => '缓存已清理';

	/// zh-CN: '清理失败'
	String get clearFailed => '清理失败';

	/// zh-CN: '缓存大小'
	String get cacheSize => '缓存大小';

	/// zh-CN: '重新计算'
	String get recalculate => '重新计算';

	/// zh-CN: '手动清理缓存'
	String get manualClear => '手动清理缓存';

	/// zh-CN: '立即删除所有缓存文件'
	String get manualClearSubtitle => '立即删除所有缓存文件';

	/// zh-CN: '清理'
	String get clear => '清理';

	/// zh-CN: '缓存限制'
	String get cacheLimit => '缓存限制';

	/// zh-CN: '缓存上限'
	String get sizeLimit => '缓存上限';

	/// zh-CN: '达到上限后将自动清理旧缓存'
	String get sizeLimitSubtitle => '达到上限后将自动清理旧缓存';

	/// zh-CN: '自动清理缓存'
	String get autoClean => '自动清理缓存';

	/// zh-CN: '关闭后将不再自动清理任何缓存'
	String get autoCleanSubtitle => '关闭后将不再自动清理任何缓存';

	/// zh-CN: '计算中...'
	String get calculating => '计算中...';

	/// zh-CN: '计算失败'
	String get calculateFailed => '计算失败';
}

// Path: dataBackup
class Translations$dataBackup$zh_CN {
	Translations$dataBackup$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '数据导入/导出'
	String get title => '数据导入/导出';

	/// zh-CN: '导出'
	String get exportSection => '导出';

	/// zh-CN: '导入'
	String get importSection => '导入';

	/// zh-CN: '包含下载的漫画'
	String get includeDownloads => '包含下载的漫画';

	/// zh-CN: '导出时一并打包已下载的漫画文件'
	String get includeDownloadsSubtitle => '导出时一并打包已下载的漫画文件';

	/// zh-CN: '导出数据'
	String get exportData => '导出数据';

	/// zh-CN: '将设置与数据打包为 zip'
	String get exportDataSubtitle => '将设置与数据打包为 zip';

	/// zh-CN: '导入数据'
	String get importData => '导入数据';

	/// zh-CN: '从 zip 文件恢复数据'
	String get importDataSubtitle => '从 zip 文件恢复数据';

	/// zh-CN: '选择导出目录失败'
	String get selectExportDirFailed => '选择导出目录失败';

	/// zh-CN: '正在导出，请耐心等待…'
	String get exporting => '正在导出，请耐心等待…';

	/// zh-CN: '导出成功'
	String get exportSuccess => '导出成功';

	/// zh-CN: '已保存到：$path'
	String savedTo({required Object path}) => '已保存到：${path}';

	/// zh-CN: '请在弹出的分享面板中选择「存储到文件」以保存备份。'
	String get exportShareHint => '请在弹出的分享面板中选择「存储到文件」以保存备份。';

	/// zh-CN: '导出失败'
	String get exportFailed => '导出失败';

	/// zh-CN: '正在处理备份文件…'
	String get processingBackup => '正在处理备份文件…';

	/// zh-CN: '选择备份文件失败'
	String get selectBackupFailed => '选择备份文件失败';

	/// zh-CN: '正在读取备份信息…'
	String get readingBackup => '正在读取备份信息…';

	/// zh-CN: '读取备份失败'
	String get readBackupFailed => '读取备份失败';

	/// zh-CN: '正在导入，请稍后…'
	String get importing => '正在导入，请稍后…';

	/// zh-CN: '导入失败'
	String get importFailed => '导入失败';

	/// zh-CN: '导入数据'
	String get importTitle => '导入数据';

	/// zh-CN: '导入将覆盖当前应用内的所有数据，是否继续？'
	String get importConfirm => '导入将覆盖当前应用内的所有数据，是否继续？';

	/// zh-CN: '该备份包含下载的漫画文件，导入时会先删除本机现有的下载文件。'
	String get includesDownloadsWarning => '该备份包含下载的漫画文件，导入时会先删除本机现有的下载文件。';

	/// zh-CN: '版本不一致，数据导入可能会出问题，是否继续？'
	String get versionMismatch => '版本不一致，数据导入可能会出问题，是否继续？';

	/// zh-CN: '导出数据版本：$version'
	String exportedVersion({required Object version}) => '导出数据版本：${version}';

	/// zh-CN: '当前应用版本：$version'
	String currentVersion({required Object version}) => '当前应用版本：${version}';

	/// zh-CN: '继续'
	String get kContinue => '继续';

	/// zh-CN: '导入成功'
	String get importSuccess => '导入成功';

	/// zh-CN: '数据导入成功，请重启应用以生效。'
	String get restartPrompt => '数据导入成功，请重启应用以生效。';
}

// Path: webdavSync
class Translations$webdavSync$zh_CN {
	Translations$webdavSync$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '云同步配置'
	String get title => '云同步配置';

	/// zh-CN: '$service 同步配置'
	String serviceTitle({required Object service}) => '${service} 同步配置';

	/// zh-CN: '请先在设置里选择同步服务，再回到这里填写配置。'
	String get noneTip => '请先在设置里选择同步服务，再回到这里填写配置。';

	/// zh-CN: '删除配置'
	String get deleteConfig => '删除配置';

	/// zh-CN: '测试连接并保存'
	String get testAndSave => '测试连接并保存';

	/// zh-CN: '常见问题'
	String get faq => '常见问题';

	/// zh-CN: 'WebDAV 地址'
	String get webdavHost => 'WebDAV 地址';

	/// zh-CN: '账号'
	String get username => '账号';

	/// zh-CN: '密码'
	String get password => '密码';

	/// zh-CN: '服务地址(Endpoint)'
	String get s3Endpoint => '服务地址(Endpoint)';

	/// zh-CN: '如: s3.amazonaws.com'
	String get s3EndpointHint => '如: s3.amazonaws.com';

	/// zh-CN: 'Access Key'
	String get s3AccessKey => 'Access Key';

	/// zh-CN: 'Secret Key'
	String get s3SecretKey => 'Secret Key';

	/// zh-CN: '存储桶(Bucket)的名字'
	String get s3Bucket => '存储桶(Bucket)的名字';

	/// zh-CN: '区域(Region)（可选）'
	String get s3Region => '区域(Region)（可选）';

	/// zh-CN: '端口（可选）'
	String get s3Port => '端口（可选）';

	/// zh-CN: '使用 HTTPS/SSL'
	String get useSsl => '使用 HTTPS/SSL';

	/// zh-CN: '路径风格 (Path-Style)'
	String get pathStyle => '路径风格 (Path-Style)';

	/// zh-CN: '自建 MinIO 通常需要开启此选项'
	String get pathStyleSubtitle => '自建 MinIO 通常需要开启此选项';

	/// zh-CN: '正在连接 WebDAV 服务器...'
	String get connectingWebdav => '正在连接 WebDAV 服务器...';

	/// zh-CN: 'WebDAV连接成功，已保存设置。'
	String get webdavConnected => 'WebDAV连接成功，已保存设置。';

	/// zh-CN: '连接失败，请检查网络连接或WebDAV地址是否正确。 $error'
	String webdavConnectFailed({required Object error}) => '连接失败，请检查网络连接或WebDAV地址是否正确。\n${error}';

	/// zh-CN: '端口格式不正确，请输入 0-65535 的数字。'
	String get invalidPort => '端口格式不正确，请输入 0-65535 的数字。';

	/// zh-CN: '正在连接 S3 服务...'
	String get connectingS3 => '正在连接 S3 服务...';

	/// zh-CN: 'S3 连接成功，已保存设置。'
	String get s3Connected => 'S3 连接成功，已保存设置。';

	/// zh-CN: '连接失败，请检查 S3 配置是否正确。 $error'
	String s3ConnectFailed({required Object error}) => '连接失败，请检查 S3 配置是否正确。\n${error}';

	/// zh-CN: '关闭'
	String get close => '关闭';

	/// zh-CN: '成功'
	String get success => '成功';

	/// zh-CN: '错误'
	String get error => '错误';

	/// zh-CN: '### 可以同步哪些内容？ - 目前同步哔咔历史记录、禁漫收藏和禁漫历史。 ### WebDAV 如何配置？ - 填写 WebDAV 地址、账号、密码，点击测试连接并保存即可。 ### S3 如何配置？ - Endpoint 示例：`s3.amazonaws.com`、`s3.filebase.com`、`play.min.io`。 - 如果是自建 MinIO，可填写自定义端口，必要时关闭 SSL。 ### 自动同步间隔是多久？ - 每 5 分钟自动同步一次。 ### 如何手动触发一次同步？ - 在同步配置页测试连接并保存后会触发一次同步。 - 或在设置里切换一次自动同步开关。'
	String get faqMarkdown => '### 可以同步哪些内容？\n- 目前同步哔咔历史记录、禁漫收藏和禁漫历史。\n\n### WebDAV 如何配置？\n- 填写 WebDAV 地址、账号、密码，点击测试连接并保存即可。\n\n### S3 如何配置？\n- Endpoint 示例：`s3.amazonaws.com`、`s3.filebase.com`、`play.min.io`。\n- 如果是自建 MinIO，可填写自定义端口，必要时关闭 SSL。\n\n### 自动同步间隔是多久？\n- 每 5 分钟自动同步一次。\n\n### 如何手动触发一次同步？\n- 在同步配置页测试连接并保存后会触发一次同步。\n- 或在设置里切换一次自动同步开关。';
}

// Path: realSr
class Translations$realSr$zh_CN {
	Translations$realSr$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '图片超分（实验性）'
	String get title => '图片超分（实验性）';

	/// zh-CN: '不限制'
	String get unlimited => '不限制';

	/// zh-CN: '模型下载失败'
	String get modelDownloadFailed => '模型下载失败';

	/// zh-CN: '通用'
	String get generalSection => '通用';

	/// zh-CN: '自动超分'
	String get autoUpscaleSection => '自动超分';

	/// zh-CN: '自动超分'
	String get autoUpscale => '自动超分';

	/// zh-CN: '模型未下载，开启后无法自动超分'
	String get autoUpscaleSubtitleUnavailable => '模型未下载，开启后无法自动超分';

	/// zh-CN: '下载或加载图片时自动调用超分'
	String get autoUpscaleSubtitleAvailable => '下载或加载图片时自动调用超分';

	/// zh-CN: '超分条件'
	String get conditionSection => '超分条件';

	/// zh-CN: '分辨率阈值'
	String get resolutionThreshold => '分辨率阈值';

	/// zh-CN: '仅当图片宽度小于该值时才自动超分'
	String get resolutionThresholdSubtitle => '仅当图片宽度小于该值时才自动超分';

	/// zh-CN: '性能'
	String get performanceSection => '性能';

	/// zh-CN: '并发数量'
	String get concurrency => '并发数量';

	/// zh-CN: '高端显卡可适当提高，移动设备或性能较低时不建议设置高于1的并发量'
	String get concurrencySubtitle => '高端显卡可适当提高，移动设备或性能较低时不建议设置高于1的并发量';

	/// zh-CN: '分块大小'
	String get tileSize => '分块大小';

	/// zh-CN: '遇到崩溃可设置较小值，0为不分块，桌面端可尝试设置为0'
	String get tileSizeSubtitle => '遇到崩溃可设置较小值，0为不分块，桌面端可尝试设置为0';

	/// zh-CN: '模型'
	String get modelSection => '模型';

	/// zh-CN: '模型'
	String get model => '模型';

	/// zh-CN: '切换模型族会重置对应的变体选项'
	String get modelSubtitle => '切换模型族会重置对应的变体选项';

	/// zh-CN: '降噪级别'
	String get noiseLevel => '降噪级别';

	/// zh-CN: '该选项随所选模型变化'
	String get noiseLevelSubtitle => '该选项随所选模型变化';

	/// zh-CN: '分块信息'
	String get blockInfo => '分块信息';

	/// zh-CN: 'blockSize 是模型输入尺寸，包含反射边距； 内容块 = blockSize - 2×shrinkSize，才是真正拼接输出的区域。'
	String get blockInfoTooltip => 'blockSize 是模型输入尺寸，包含反射边距；\n内容块 = blockSize - 2×shrinkSize，才是真正拼接输出的区域。';

	/// zh-CN: '内容块 $contentSize×$contentSize，模型输入 $blockSize×$blockSize（含 ${shrinkSize}px 反射边距）'
	String blockInfoFormat({required Object contentSize, required Object blockSize, required Object shrinkSize}) => '内容块 ${contentSize}×${contentSize}，模型输入 ${blockSize}×${blockSize}（含 ${shrinkSize}px 反射边距）';

	/// zh-CN: 'Android 超分'
	String get androidSuperResolution => 'Android 超分';

	/// zh-CN: '当前使用 waifu2x upconv 动漫模型，2 倍放大'
	String get androidSuperResolutionSubtitle => '当前使用 waifu2x upconv 动漫模型，2 倍放大';

	/// zh-CN: '超分策略'
	String get desktopStrategy => '超分策略';

	/// zh-CN: '效率优先使用 waifu2x，质量优先使用 Real-CUGAN'
	String get desktopStrategySubtitle => '效率优先使用 waifu2x，质量优先使用 Real-CUGAN';

	/// zh-CN: '降噪级别'
	String get desktopNoiseLevel => '降噪级别';

	/// zh-CN: '保守适合普通漫画，降噪级别越高涂抹感越强'
	String get desktopNoiseLevelSubtitle => '保守适合普通漫画，降噪级别越高涂抹感越强';

	/// zh-CN: '模型管理'
	String get modelManagementSection => '模型管理';

	/// zh-CN: '正在下载模型'
	String get downloadingModel => '正在下载模型';

	/// zh-CN: '模型已就绪'
	String get modelReady => '模型已就绪';

	/// zh-CN: '重新下载'
	String get redownload => '重新下载';

	/// zh-CN: '删除模型'
	String get deleteModel => '删除模型';

	/// zh-CN: '确定要删除已下载的超分模型吗？删除后需要重新下载才能使用。'
	String get deleteModelConfirm => '确定要删除已下载的超分模型吗？删除后需要重新下载才能使用。';

	/// zh-CN: '模型已删除'
	String get modelDeleted => '模型已删除';

	/// zh-CN: '模型删除失败'
	String get modelDeleteFailed => '模型删除失败';

	/// zh-CN: '模型未下载'
	String get modelNotDownloaded => '模型未下载';

	/// zh-CN: '使用超分前需要先下载模型'
	String get modelNotDownloadedSubtitle => '使用超分前需要先下载模型';

	/// zh-CN: '下载模型'
	String get downloadModel => '下载模型';

	/// zh-CN: '效率优先'
	String get modeEfficiency => '效率优先';

	/// zh-CN: '质量优先'
	String get modeQuality => '质量优先';

	/// zh-CN: '保守'
	String get noiseConservative => '保守';

	/// zh-CN: '无降噪'
	String get noise0 => '无降噪';

	/// zh-CN: '降噪 1'
	String get noise1 => '降噪 1';

	/// zh-CN: '降噪 2'
	String get noise2 => '降噪 2';

	/// zh-CN: '降噪 3'
	String get noise3 => '降噪 3';

	/// zh-CN: 'waifu2x upconv 动漫'
	String get variantWaifu2xAnime => 'waifu2x upconv 动漫';

	/// zh-CN: 'Real-CUGAN 降噪 $noise'
	String variantRealCuganDenoise({required Object noise}) => 'Real-CUGAN 降噪 ${noise}';

	/// zh-CN: '速度优先 (waifu2x)'
	String get coremlSpeed => '速度优先 (waifu2x)';

	/// zh-CN: '质量优先 (Real-CUGAN)'
	String get coremlQuality => '质量优先 (Real-CUGAN)';

	/// zh-CN: '降噪 0'
	String get coremlNoise0 => '降噪 0';

	/// zh-CN: '无降噪'
	String get coremlNoDenoise => '无降噪';

	/// zh-CN: '输入图片绝对路径或 asset 路径'
	String get coremlInputHint => '输入图片绝对路径或 asset 路径';

	/// zh-CN: '开始超分'
	String get coremlStartUpscale => '开始超分';

	/// zh-CN: '请填写输入图片路径'
	String get coremlStatusFillInput => '请填写输入图片路径';

	/// zh-CN: '当前模型族没有可用的模型文件'
	String get coremlStatusNoModelFile => '当前模型族没有可用的模型文件';

	/// zh-CN: '正在准备资源...'
	String get coremlStatusPreparing => '正在准备资源...';

	/// zh-CN: '正在超分...'
	String get coremlStatusUpscaling => '正在超分...';

	/// zh-CN: '完成 $outputPath size: $size bytes'
	String coremlStatusDone({required Object outputPath, required Object size}) => '完成\n${outputPath}\nsize: ${size} bytes';

	/// zh-CN: '失败: $error'
	String coremlStatusFailed({required Object error}) => '失败: ${error}';

	/// zh-CN: '模型选项（降噪级别）'
	String get coremlModelOption => '模型选项（降噪级别）';

	/// zh-CN: '通用选项（放大倍率）'
	String get coremlGeneralOption => '通用选项（放大倍率）';

	/// zh-CN: '分块信息'
	String get coremlTileInfo => '分块信息';
}

// Path: about
class Translations$about$zh_CN {
	Translations$about$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '关于应用'
	String get title => '关于应用';

	/// zh-CN: '版本号: $version'
	String version({required Object version}) => '版本号: ${version}';

	/// zh-CN: '加载中...'
	String get loading => '加载中...';

	/// zh-CN: '获取失败'
	String get fetchFailed => '获取失败';

	/// zh-CN: '网络错误'
	String get networkError => '网络错误';

	/// zh-CN: '项目地址'
	String get projectAddress => '项目地址';

	/// zh-CN: '喜欢这个项目吗？点个star支持一下吧！'
	String get projectAddressDesc => '喜欢这个项目吗？点个star支持一下吧！';

	/// zh-CN: '前往 GitHub 仓库 (deretame/Breeze) ⭐'
	String get projectLink => '前往 GitHub 仓库 (deretame/Breeze) ⭐';

	/// zh-CN: '联系方式'
	String get contact => '联系方式';

	/// zh-CN: '有任何想法或问题，欢迎来找我聊聊~'
	String get contactDesc => '有任何想法或问题，欢迎来找我聊聊~';

	/// zh-CN: '反馈与建议'
	String get feedback => '反馈与建议';

	/// zh-CN: '发现BUG或者有新的点子？'
	String get feedbackDesc => '发现BUG或者有新的点子？';

	/// zh-CN: '在 GitHub Issues 中提出'
	String get feedbackLink => '在 GitHub Issues 中提出';

	/// zh-CN: '贡献者'
	String get contributors => '贡献者';

	/// zh-CN: '$count人'
	String contributorsCount({required Object count}) => '${count}人';

	/// zh-CN: '$login ($count 次提交)'
	String contributionsTooltip({required Object login, required Object count}) => '${login} (${count} 次提交)';

	/// zh-CN: '免责声明'
	String get disclaimer => '免责声明';

	/// zh-CN: '开源项目免责声明'
	String get disclaimerTitle => '开源项目免责声明';

	/// zh-CN: '1. 项目性质与声明'
	String get disclaimerItem1Title => '1. 项目性质与声明';

	/// zh-CN: '本项目为开源软件，由本人独立开发并维护。项目以"原样"形式提供，开发者不对项目的功能完整性、稳定性、安全性或适用性作出任何明示或暗示的担保。'
	String get disclaimerItem1Content => '本项目为开源软件，由本人独立开发并维护。项目以"原样"形式提供，开发者不对项目的功能完整性、稳定性、安全性或适用性作出任何明示或暗示的担保。';

	/// zh-CN: '2. 责任限制'
	String get disclaimerItem2Title => '2. 责任限制';

	/// zh-CN: '开发者对因使用、修改或分发本项目（包括但不限于直接使用、二次开发或集成至其他项目）而导致的任何直接、间接、特殊、附带或后果性损害不承担任何责任。这些损害可能包括但不限于数据丢失、设备损坏、业务中断、利润损失或其他经济损失。'
	String get disclaimerItem2Content => '开发者对因使用、修改或分发本项目（包括但不限于直接使用、二次开发或集成至其他项目）而导致的任何直接、间接、特殊、附带或后果性损害不承担任何责任。这些损害可能包括但不限于数据丢失、设备损坏、业务中断、利润损失或其他经济损失。';

	/// zh-CN: '3. 用户责任'
	String get disclaimerItem3Title => '3. 用户责任';

	/// zh-CN: '用户在使用本项目时，应自行评估其适用性并承担所有风险。用户须确保其使用行为符合所在国家或地区的法律法规及道德规范。开发者不对用户因违反法律法规或不当使用本项目而导致的任何后果负责。'
	String get disclaimerItem3Content => '用户在使用本项目时，应自行评估其适用性并承担所有风险。用户须确保其使用行为符合所在国家或地区的法律法规及道德规范。开发者不对用户因违反法律法规或不当使用本项目而导致的任何后果负责。';

	/// zh-CN: '4. 第三方依赖与资源'
	String get disclaimerItem4Title => '4. 第三方依赖与资源';

	/// zh-CN: '本项目可能依赖或引用第三方库、工具、服务或其他资源。开发者不对这些第三方资源的内容、功能、安全性或合法性负责。用户应自行评估并承担使用第三方资源的风险。'
	String get disclaimerItem4Content => '本项目可能依赖或引用第三方库、工具、服务或其他资源。开发者不对这些第三方资源的内容、功能、安全性或合法性负责。用户应自行评估并承担使用第三方资源的风险。';

	/// zh-CN: '5. 无担保声明'
	String get disclaimerItem5Title => '5. 无担保声明';

	/// zh-CN: '开发者明确声明不对本项目提供任何形式的担保，包括但不限于：适销性担保；特定用途适用性担保；不侵犯第三方权利担保；无错误或无中断运行担保。'
	String get disclaimerItem5Content => '开发者明确声明不对本项目提供任何形式的担保，包括但不限于：适销性担保；特定用途适用性担保；不侵犯第三方权利担保；无错误或无中断运行担保。';

	/// zh-CN: '6. 项目修改与终止'
	String get disclaimerItem6Title => '6. 项目修改与终止';

	/// zh-CN: '开发者保留随时修改、暂停或终止本项目的权利，且无需提前通知用户。开发者不对因项目修改、暂停或终止而导致的任何后果负责。'
	String get disclaimerItem6Content => '开发者保留随时修改、暂停或终止本项目的权利，且无需提前通知用户。开发者不对因项目修改、暂停或终止而导致的任何后果负责。';

	/// zh-CN: '7. 贡献者责任'
	String get disclaimerItem7Title => '7. 贡献者责任';

	/// zh-CN: '如果本项目接受外部贡献，贡献者的行为仅代表其个人立场，不代表开发者的观点或立场。开发者对贡献者的行为及其贡献内容不承担责任。'
	String get disclaimerItem7Content => '如果本项目接受外部贡献，贡献者的行为仅代表其个人立场，不代表开发者的观点或立场。开发者对贡献者的行为及其贡献内容不承担责任。';

	/// zh-CN: '8. 法律合规性'
	String get disclaimerItem8Title => '8. 法律合规性';

	/// zh-CN: '用户在使用本项目时，应确保其行为符合所在国家或地区的法律法规。开发者不对用户因违反法律法规而导致的任何后果负责。'
	String get disclaimerItem8Content => '用户在使用本项目时，应确保其行为符合所在国家或地区的法律法规。开发者不对用户因违反法律法规而导致的任何后果负责。';

	/// zh-CN: '重要提示'
	String get disclaimerImportant => '重要提示';

	/// zh-CN: '在使用本项目之前，请仔细阅读并理解本免责声明。如果您不同意本声明的任何条款，请立即停止使用本项目。继续使用本项目即表示您已阅读、理解并同意本免责声明的全部内容。'
	String get disclaimerImportantContent => '在使用本项目之前，请仔细阅读并理解本免责声明。如果您不同意本声明的任何条款，请立即停止使用本项目。继续使用本项目即表示您已阅读、理解并同意本免责声明的全部内容。';

	/// zh-CN: '检查更新'
	String get checkUpdate => '检查更新';

	/// zh-CN: '已是最新版本'
	String get alreadyLatest => '已是最新版本';

	/// zh-CN: '发现新版本'
	String get updateAvailable => '发现新版本';

	/// zh-CN: '开源许可'
	String get license => '开源许可';

	/// zh-CN: '隐私政策'
	String get privacy => '隐私政策';
}

// Path: oldHome
class Translations$oldHome$zh_CN {
	Translations$oldHome$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '首页'
	String get title => '首页';

	/// zh-CN: '搜索'
	String get search => '搜索';

	/// zh-CN: '热搜'
	String get hotSearch => '热搜';

	/// zh-CN: '导航'
	String get navigation => '导航';

	/// zh-CN: '推荐'
	String get recommend => '推荐';

	/// zh-CN: '最新'
	String get latest => '最新';

	/// zh-CN: '云端收藏'
	String get cloudFavorite => '云端收藏';

	/// zh-CN: '列表'
	String get list => '列表';

	/// zh-CN: '功能'
	String get function => '功能';

	/// zh-CN: '关闭'
	String get close => '关闭';

	/// zh-CN: '加载失败，请重试。'
	String get loadFailedRetry => '加载失败，请重试。';

	/// zh-CN: '加载 $title 失败 $error'
	String loadSectionFailed({required Object title, required Object error}) => '加载 ${title} 失败\n${error}';

	/// zh-CN: '暂无内容'
	String get empty => '暂无内容';

	/// zh-CN: '加载更多失败，点击重试'
	String get loadMoreFailed => '加载更多失败，点击重试';

	/// zh-CN: '点击加载更多'
	String get loadMore => '点击加载更多';

	/// zh-CN: '没有更多了'
	String get noMore => '没有更多了';
}

// Path: more
class Translations$more$zh_CN {
	Translations$more$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '常用'
	String get common => '常用';

	/// zh-CN: '其他'
	String get others => '其他';

	/// zh-CN: '下载任务'
	String get downloadTasks => '下载任务';

	/// zh-CN: '追更'
	String get comicFollow => '追更';

	/// zh-CN: '更新日志'
	String get changelog => '更新日志';
}

// Path: search
class Translations$search$zh_CN {
	Translations$search$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '搜索'
	String get title => '搜索';

	/// zh-CN: '搜索...'
	String get searchHint => '搜索...';

	/// zh-CN: '选择漫画源'
	String get selectSource => '选择漫画源';

	/// zh-CN: '当前插件不支持高级搜索'
	String get advancedSearchNotSupported => '当前插件不支持高级搜索';

	/// zh-CN: '高级搜索选项'
	String get advancedSearchOptions => '高级搜索选项';

	/// zh-CN: '未选择'
	String get notSelected => '未选择';

	/// zh-CN: '已选择 $count 项'
	String selectedCount({required Object count}) => '已选择 ${count} 项';

	/// zh-CN: '搜索历史'
	String get history => '搜索历史';

	/// zh-CN: '清空历史'
	String get clearHistory => '清空历史';

	/// zh-CN: '当前：最近搜索在前'
	String get newestFirst => '当前：最近搜索在前';

	/// zh-CN: '当前：最早搜索在前'
	String get oldestFirst => '当前：最早搜索在前';

	/// zh-CN: '时间倒序'
	String get descending => '时间倒序';

	/// zh-CN: '时间正序'
	String get ascending => '时间正序';

	/// zh-CN: '暂无搜索记录'
	String get noHistory => '暂无搜索记录';

	/// zh-CN: '🔍 搜索技巧'
	String get tipsTitle => '🔍 搜索技巧';

	/// zh-CN: '精准搜索（同时满足）'
	String get exactSearchTitle => '精准搜索（同时满足）';

	/// zh-CN: '全彩(空格)+人妻'
	String get exactSearchExample => '全彩(空格)+人妻';

	/// zh-CN: '显示同时包含这两个标签的结果'
	String get exactSearchDesc => '显示同时包含这两个标签的结果';

	/// zh-CN: '排除搜索（不要某类）'
	String get excludeSearchTitle => '排除搜索（不要某类）';

	/// zh-CN: '全彩(空格)-人妻'
	String get excludeSearchExample => '全彩(空格)-人妻';

	/// zh-CN: '显示"全彩"但排除含"人妻"的结果'
	String get excludeSearchDesc => '显示"全彩"但排除含"人妻"的结果';

	/// zh-CN: '模糊搜索（包含任一）'
	String get fuzzySearchTitle => '模糊搜索（包含任一）';

	/// zh-CN: '全彩(空格)人妻'
	String get fuzzySearchExample => '全彩(空格)人妻';

	/// zh-CN: '显示包含任意一个关键词的结果'
	String get fuzzySearchDesc => '显示包含任意一个关键词的结果';

	/// zh-CN: '选择分类'
	String get selectCategory => '选择分类';

	/// zh-CN: '数据来源'
	String get dataSource => '数据来源';

	/// zh-CN: '排序方式'
	String get sortBy => '排序方式';

	/// zh-CN: '从新到旧'
	String get newestToOldest => '从新到旧';

	/// zh-CN: '从旧到新'
	String get oldestToNewest => '从旧到新';

	/// zh-CN: '最多点赞'
	String get mostLikes => '最多点赞';

	/// zh-CN: '最多观看'
	String get mostViews => '最多观看';

	/// zh-CN: '选择漫画源'
	String get selectSourceTooltip => '选择漫画源';

	/// zh-CN: '有结果'
	String get hasResults => '有结果';

	/// zh-CN: '显示错误'
	String get showErrors => '显示错误';

	/// zh-CN: '$count 条'
	String resultCount({required Object count}) => '${count} 条';

	/// zh-CN: '无结果'
	String get noResults => '无结果';

	/// zh-CN: '$source 加载失败'
	String loadFailedForSource({required Object source}) => '${source} 加载失败';
}

// Path: discover
class Translations$discover$zh_CN {
	Translations$discover$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '发现'
	String get title => '发现';

	/// zh-CN: '搜索'
	String get search => '搜索';

	/// zh-CN: '设置'
	String get settings => '设置';

	/// zh-CN: '插件管理'
	String get pluginManagement => '插件管理';

	/// zh-CN: '暂无可用插件，去插件商店安装一个吧~'
	String get noPlugins => '暂无可用插件，去插件商店安装一个吧~';

	/// zh-CN: '插件商店'
	String get pluginStore => '插件商店';

	/// zh-CN: '浏览安装'
	String get browseInstall => '浏览安装';

	/// zh-CN: '暂无可用插件，无法搜索'
	String get noPluginForSearch => '暂无可用插件，无法搜索';

	/// zh-CN: '插件信息加载失败: $error'
	String pluginInfoLoadFailed({required Object error}) => '插件信息加载失败: ${error}';

	/// zh-CN: '插件能力'
	String get pluginCapability => '插件能力';

	/// zh-CN: '已关闭'
	String get disabled => '已关闭';

	/// zh-CN: '未命名'
	String get unnamed => '未命名';

	/// zh-CN: '插件启用失败: $error'
	String pluginEnableFailed({required Object error}) => '插件启用失败: ${error}';

	/// zh-CN: '插件关闭失败: $error'
	String pluginCloseFailed({required Object error}) => '插件关闭失败: ${error}';

	/// zh-CN: '插件调试加载失败，已回退数据库: $error'
	String pluginDebugLoadFailed({required Object error}) => '插件调试加载失败，已回退数据库: ${error}';
}

// Path: searchResult
class Translations$searchResult$zh_CN {
	Translations$searchResult$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '输入页数'
	String get enterPageNumber => '输入页数';

	/// zh-CN: '请输入数字'
	String get pleaseEnterNumber => '请输入数字';

	/// zh-CN: '返回顶部'
	String get returnToTop => '返回顶部';

	/// zh-CN: '跳转页面'
	String get jumpToPage => '跳转页面';

	/// zh-CN: '跳转'
	String get jump => '跳转';

	/// zh-CN: '点击重试'
	String get retry => '点击重试';
}

// Path: comicList
class Translations$comicList$zh_CN {
	Translations$comicList$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '漫画列表'
	String get defaultTitle => '漫画列表';

	/// zh-CN: '缺少插件来源，无法加载列表'
	String get missingSource => '缺少插件来源，无法加载列表';

	/// zh-CN: '重新加载'
	String get reload => '重新加载';

	/// zh-CN: '加载失败，请重试。'
	String get loadFailedRetry => '加载失败，请重试。';

	/// zh-CN: '啥都没有'
	String get nothingHere => '啥都没有';

	/// zh-CN: '筛选'
	String get filter => '筛选';

	/// zh-CN: '子分类'
	String get subCategory => '子分类';

	/// zh-CN: '第$level级分类'
	String levelCategory({required Object level}) => '第${level}级分类';

	/// zh-CN: '缺少列表请求配置'
	String get missingListConfig => '缺少列表请求配置';

	/// zh-CN: '列表请求缺少 fnPath'
	String get missingFnPath => '列表请求缺少 fnPath';
}

// Path: comicEntry
class Translations$comicEntry$zh_CN {
	Translations$comicEntry$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '更新: $time'
	String updatedAt({required Object time}) => '更新: ${time}';

	/// zh-CN: '完结'
	String get finished => '完结';

	/// zh-CN: '连载中'
	String get ongoing => '连载中';

	/// zh-CN: '喜欢 $count'
	String likes({required Object count}) => '喜欢 ${count}';

	/// zh-CN: '浏览 $count'
	String views({required Object count}) => '浏览 ${count}';

	/// zh-CN: '删除收藏'
	String get deleteFavorite => '删除收藏';

	/// zh-CN: '确定要删除（$title）的收藏记录吗？'
	String deleteFavoriteConfirm({required Object title}) => '确定要删除（${title}）的收藏记录吗？';

	/// zh-CN: '删除历史记录'
	String get deleteHistory => '删除历史记录';

	/// zh-CN: '确定要删除（$title）的历史记录吗？'
	String deleteHistoryConfirm({required Object title}) => '确定要删除（${title}）的历史记录吗？';

	/// zh-CN: '删除下载记录'
	String get deleteDownload => '删除下载记录';

	/// zh-CN: '确定要删除（$title）的下载记录及文件吗？'
	String deleteDownloadConfirm({required Object title}) => '确定要删除（${title}）的下载记录及文件吗？';

	/// zh-CN: '删除失败'
	String get deleteFailed => '删除失败';
}

// Path: comicFollow
class Translations$comicFollow$zh_CN {
	Translations$comicFollow$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '追更'
	String get title => '追更';

	/// zh-CN: '加载失败：$result'
	String loadFailed({required Object result}) => '加载失败：${result}';

	/// zh-CN: '暂无追更漫画'
	String get empty => '暂无追更漫画';

	/// zh-CN: '在漫画详情页点击追更按钮即可加入'
	String get emptyHint => '在漫画详情页点击追更按钮即可加入';

	/// zh-CN: '取消追更'
	String get unfollow => '取消追更';

	/// zh-CN: '确定不再追更《$title》吗？'
	String unfollowConfirm({required Object title}) => '确定不再追更《${title}》吗？';

	/// zh-CN: '已取消追更'
	String get unfollowed => '已取消追更';

	/// zh-CN: '最新章节获取失败'
	String get latestChapterFailed => '最新章节获取失败';

	/// zh-CN: '新增 $diff 话，共 $total 话'
	String newChapters({required Object diff, required Object total}) => '新增 ${diff} 话，共 ${total} 话';

	/// zh-CN: '最新 $count 话'
	String latestCount({required Object count}) => '最新 ${count} 话';

	/// zh-CN: '获取失败'
	String get fetchFailed => '获取失败';

	/// zh-CN: '新增 $diff 话'
	String newChaptersShort({required Object diff}) => '新增 ${diff} 话';

	/// zh-CN: '更新'
	String get update => '更新';

	/// zh-CN: '重试'
	String get retry => '重试';

	/// zh-CN: '漫画更新提醒'
	String get updateChannelName => '漫画更新提醒';

	/// zh-CN: '追更漫画检测到新章节时推送'
	String get updateChannelDesc => '追更漫画检测到新章节时推送';

	/// zh-CN: '追更更新'
	String get updateTitle => '追更更新';

	/// zh-CN: '有 1 部追更漫画更新了'
	String get updateBodySingle => '有 1 部追更漫画更新了';

	/// zh-CN: '有 $count 部追更漫画更新了'
	String updateBodyMultiple({required Object count}) => '有 ${count} 部追更漫画更新了';
}

// Path: changelog
class Translations$changelog$zh_CN {
	Translations$changelog$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '更新日志'
	String get title => '更新日志';

	/// zh-CN: '加载失败'
	String get loadFailed => '加载失败';

	/// zh-CN: '加载失败: $error'
	String loadFailedWithError({required Object error}) => '加载失败: ${error}';

	/// zh-CN: '无法打开链接: $url'
	String cannotOpenLink({required Object url}) => '无法打开链接: ${url}';

	/// zh-CN: '加载失败，请检查网络'
	String get checkNetwork => '加载失败，请检查网络';

	/// zh-CN: '重试'
	String get retry => '重试';

	/// zh-CN: '暂无更新日志'
	String get empty => '暂无更新日志';

	/// zh-CN: '发布于 $date'
	String publishedAt({required Object date}) => '发布于 ${date}';

	/// zh-CN: '在浏览器中查看'
	String get viewInBrowser => '在浏览器中查看';

	/// zh-CN: '附件下载'
	String get attachments => '附件下载';
}

// Path: webview
class Translations$webview$zh_CN {
	Translations$webview$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '网页'
	String get title => '网页';

	/// zh-CN: '无法打开链接: $uri'
	String cannotOpenLink({required Object uri}) => '无法打开链接: ${uri}';

	/// zh-CN: '链接无效，无法打开网页'
	String get invalidLink => '链接无效，无法打开网页';

	/// zh-CN: '(空链接)'
	String get emptyLink => '(空链接)';

	/// zh-CN: '网页加载失败'
	String get loadFailed => '网页加载失败';

	/// zh-CN: '重试'
	String get retry => '重试';

	/// zh-CN: '外部浏览器打开'
	String get openInExternalBrowser => '外部浏览器打开';

	/// zh-CN: 'WebView 窗口已关闭'
	String get windowClosed => 'WebView 窗口已关闭';

	/// zh-CN: '网页已在独立窗口中打开'
	String get openedInExternalWindow => '网页已在独立窗口中打开';

	/// zh-CN: '返回'
	String get back => '返回';

	/// zh-CN: '关闭 WebView 窗口'
	String get closeWindow => '关闭 WebView 窗口';

	/// zh-CN: '加载失败（$error）'
	String loadError({required Object error}) => '加载失败（${error}）';

	/// zh-CN: '服务器返回异常状态码：$statusCode'
	String httpErrorStatus({required Object statusCode}) => '服务器返回异常状态码：${statusCode}';
}

// Path: oldRanking
class Translations$oldRanking$zh_CN {
	Translations$oldRanking$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '哔咔排行榜'
	String get bikaRanking => '哔咔排行榜';

	/// zh-CN: '禁漫排行榜'
	String get jmRanking => '禁漫排行榜';

	/// zh-CN: '切换'
	String get switchSource => '切换';
}

// Path: login
class Translations$login$zh_CN {
	Translations$login$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '登录'
	String get title => '登录';

	/// zh-CN: '缺少插件标识，无法打开登录页'
	String get missingPluginId => '缺少插件标识，无法打开登录页';

	/// zh-CN: '登录配置加载失败: $error'
	String loadConfigFailed({required Object error}) => '登录配置加载失败: ${error}';

	/// zh-CN: '插件返回的登录字段不足'
	String get insufficientFields => '插件返回的登录字段不足';

	/// zh-CN: '用户名或密码错误，请重新输入'
	String get invalidCredentials => '用户名或密码错误，请重新输入';

	/// zh-CN: '登录配置未就绪，请稍后重试'
	String get configNotReady => '登录配置未就绪，请稍后重试';

	/// zh-CN: '正在登录，请耐心等待...'
	String get loggingIn => '正在登录，请耐心等待...';

	/// zh-CN: '登录成功'
	String get loginSuccess => '登录成功';

	/// zh-CN: '登录失败'
	String get loginFailed => '登录失败';

	/// zh-CN: '登录'
	String get loginButton => '登录';

	/// zh-CN: '重试'
	String get retry => '重试';
}

// Path: fontSetting
class Translations$fontSetting$zh_CN {
	Translations$fontSetting$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '字体设置'
	String get title => '字体设置';

	/// zh-CN: '清空'
	String get clear => '清空';

	/// zh-CN: '按字重分别选择字体文件。'
	String get hint => '按字重分别选择字体文件。';

	/// zh-CN: '字体加载失败'
	String get loadFailed => '字体加载失败';

	/// zh-CN: '已清除'
	String get cleared => '已清除';

	/// zh-CN: '已保存'
	String get saved => '已保存';

	/// zh-CN: '已清空'
	String get allCleared => '已清空';

	/// zh-CN: '未选择文件'
	String get noFileSelected => '未选择文件';

	/// zh-CN: '清除'
	String get clearFile => '清除';

	/// zh-CN: '选择文件'
	String get selectFile => '选择文件';

	/// zh-CN: 'Innovation in China 中国智造，慧及全球 0123456789'
	String get sampleText => 'Innovation in China 中国智造，慧及全球 0123456789';
}

// Path: download
class Translations$download$zh_CN {
	Translations$download$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '下载任务'
	String get title => '下载任务';

	/// zh-CN: '开始下载'
	String get startDownload => '开始下载';

	/// zh-CN: '请选择要下载的章节'
	String get selectChaptersPrompt => '请选择要下载的章节';

	/// zh-CN: '下载任务已启动'
	String get taskStarted => '下载任务已启动';

	/// zh-CN: '下载任务启动失败，$error'
	String taskStartFailed({required Object error}) => '下载任务启动失败，${error}';

	/// zh-CN: '暂无下载任务'
	String get noTasks => '暂无下载任务';

	/// zh-CN: '正在下载'
	String get downloading => '正在下载';

	/// zh-CN: '等待中 ($count)'
	String pending({required Object count}) => '等待中 (${count})';

	/// zh-CN: '已删除任务'
	String get taskDeleted => '已删除任务';

	/// zh-CN: '取消任务'
	String get cancelTask => '取消任务';

	/// zh-CN: '确定要取消下载 $comicName 吗？'
	String cancelTaskConfirm({required Object comicName}) => '确定要取消下载 ${comicName} 吗？';

	/// zh-CN: '已暂停'
	String get paused => '已暂停';

	/// zh-CN: '已完成'
	String get completed => '已完成';

	/// zh-CN: '失败'
	String get failed => '失败';

	/// zh-CN: '全部开始'
	String get startAll => '全部开始';

	/// zh-CN: '全部暂停'
	String get pauseAll => '全部暂停';

	/// zh-CN: '清除已完成'
	String get clearCompleted => '清除已完成';

	/// zh-CN: '获取漫画信息中...'
	String get statusFetchingComicInfo => '获取漫画信息中...';

	/// zh-CN: '下载封面中...'
	String get statusDownloadingCover => '下载封面中...';

	/// zh-CN: '获取章节信息中...'
	String get statusFetchingChapterInfo => '获取章节信息中...';

	/// zh-CN: '获取章节信息中... ($completed/$total, $percent%)'
	String statusFetchingChapterInfoProgress({required Object completed, required Object total, required Object percent}) => '获取章节信息中... (${completed}/${total}, ${percent}%)';

	/// zh-CN: '漫画下载进度: $percent%'
	String statusDownloadProgress({required Object percent}) => '漫画下载进度: ${percent}%';

	/// zh-CN: '漫画下载进度: 100%'
	String get statusDownloadProgressComplete => '漫画下载进度: 100%';

	/// zh-CN: '开始下载...'
	String get statusStartDownload => '开始下载...';

	/// zh-CN: '等待中'
	String get statusWaiting => '等待中';

	/// zh-CN: '取消中...'
	String get statusCancelling => '取消中...';

	/// zh-CN: '$comicName 下载完成'
	String toastDownloadComplete({required Object comicName}) => '${comicName} 下载完成';

	/// zh-CN: '$comicName 下载失败 $error'
	String toastDownloadFailed({required Object comicName, required Object error}) => '${comicName} 下载失败 ${error}';

	/// zh-CN: '$comicName 任务已存在'
	String toastTaskAlreadyExists({required Object comicName}) => '${comicName} 任务已存在';

	/// zh-CN: '下载完成'
	String get notificationCompleteTitle => '下载完成';

	/// zh-CN: '下载失败'
	String get notificationFailedTitle => '下载失败';
}

// Path: foregroundTask
class Translations$foregroundTask$zh_CN {
	Translations$foregroundTask$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '前台任务'
	String get channelName => '前台任务';

	/// zh-CN: '用于下载保活与后台保活，保持应用在后台继续运行'
	String get channelDescription => '用于下载保活与后台保活，保持应用在后台继续运行';

	/// zh-CN: '等待下载任务中...'
	String get waitingForTask => '等待下载任务中...';

	/// zh-CN: '正在保持后台运行'
	String get keepAliveRunning => '正在保持后台运行';

	/// zh-CN: '取消'
	String get cancel => '取消';

	/// zh-CN: '需要通知权限来启动前台任务，请在系统弹窗中允许通知权限'
	String get notificationPermissionRequired => '需要通知权限来启动前台任务，请在系统弹窗中允许通知权限';

	/// zh-CN: '无法启动前台任务：请先在系统设置中开启通知权限'
	String get cannotStartWithoutPermission => '无法启动前台任务：请先在系统设置中开启通知权限';

	/// zh-CN: '前台服务启动失败: $error'
	String startFailed({required Object error}) => '前台服务启动失败: ${error}';
}

// Path: notification
class Translations$notification$zh_CN {
	Translations$notification$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '请开启通知权限'
	String get permissionRequired => '请开启通知权限';

	/// zh-CN: '请在系统设置中开启通知权限'
	String get macPermissionRequired => '请在系统设置中开启通知权限';
}

// Path: update
class Translations$update$zh_CN {
	Translations$update$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '发现新版本'
	String get newVersion => '发现新版本';

	/// zh-CN: '前往GitHub'
	String get goToGitHub => '前往GitHub';

	/// zh-CN: '下载安装'
	String get downloadInstall => '下载安装';

	/// zh-CN: '下载失败，请稍后再试！'
	String get apkDownloadFailed => '下载失败，请稍后再试！';

	/// zh-CN: '请授予安装应用权限！'
	String get installPermissionRequired => '请授予安装应用权限！';

	/// zh-CN: '未知'
	String get unknownArch => '未知';
}

// Path: dialog
class Translations$dialog$zh_CN {
	Translations$dialog$zh_CN.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh-CN: '隐藏到托盘或关闭程序'
	String get hideOrClose => '隐藏到托盘或关闭程序';

	/// zh-CN: '记住我的选择'
	String get rememberChoice => '记住我的选择';
}

/// The flat map containing all translations for locale <zh-CN>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'Breeze',
			'common.ok' => '确定',
			'common.cancel' => '取消',
			'common.save' => '保存',
			'common.delete' => '删除',
			'common.edit' => '编辑',
			'common.rename' => '重命名',
			'common.add' => '添加',
			'common.create' => '新建',
			'common.refresh' => '刷新',
			'common.loading' => '加载中...',
			'common.loadingFailed' => '加载失败',
			'common.retry' => '重试',
			'common.reload' => '重新加载',
			'common.confirm' => '确认',
			'common.close' => '关闭',
			'common.back' => '返回',
			'common.help' => '帮助',
			'common.gotIt' => '知道了',
			'common.underConstruction' => '施工中',
			'common.comingSoon' => '在写了，在写了',
			'common.root' => '根目录',
			'common.remove' => '移除',
			'common.overwrite' => '覆盖',
			'common.cancelled' => '已取消',
			'common.search' => '搜索',
			'common.clear' => '清空',
			'common.copy' => '复制',
			'common.paste' => '粘贴',
			'common.share' => '分享',
			'common.open' => '打开',
			'common.download' => '下载',
			'common.upload' => '上传',
			'common.import' => '导入',
			'common.export' => '导出',
			'common.success' => '成功',
			'common.failed' => '失败',
			'common.error' => '错误',
			'common.warning' => '警告',
			'common.info' => '提示',
			'common.unknown' => '未知',
			'common.empty' => '暂无数据',
			'common.all' => '全部',
			'common.none' => '无',
			'common.default_' => '默认',
			'common.custom' => '自定义',
			'common.enabled' => '已开启',
			'common.disabled' => '已关闭',
			'common.followSystem' => '跟随系统',
			'common.lightMode' => '浅色模式',
			'common.darkMode' => '深色模式',
			'common.system' => '系统',
			'common.apply' => '应用',
			'common.reset' => '重置',
			'common.next' => '下一步',
			'common.previous' => '上一步',
			'common.done' => '完成',
			'common.select' => '选择',
			'common.selected' => '已选择',
			'common.deselect' => '取消选择',
			'common.selectAll' => '全选',
			'common.yes' => '是',
			'common.no' => '否',
			'common.on' => '开',
			'common.off' => '关',
			'common.more' => '更多',
			'common.detail' => '详情',
			'common.settingSaved' => '设置已保存',
			'common.restartToTakeEffect' => '设置成功，重启生效',
			'error.generic' => '出错了',
			'error.network' => '网络错误',
			'error.downloadFailed' => '下载失败',
			'error.importFailed' => ({required Object error}) => '导入失败: ${error}',
			'error.loadFailed' => '加载失败',
			'error.saveFailed' => '保存失败',
			'error.permissionDenied' => '权限被拒绝',
			'error.notFound' => '未找到',
			'error.unsupportedPlatform' => '当前平台不支持此功能',
			'error.missingPluginSource' => ({required Object action}) => '缺少插件来源，无法${action}',
			'error.operationFailed' => '操作失败',
			'error.executionFailed' => '执行失败',
			'navigation.home' => '首页',
			'navigation.rank' => '排行',
			'navigation.bookshelf' => '书架',
			'navigation.discover' => '发现',
			'navigation.more' => '更多',
			'navigation.syncSuccess' => '同步成功！',
			'navigation.autoSyncSuccess' => '自动同步成功！',
			'navigation.syncFailed' => '同步失败',
			'navigation.autoSyncFailed' => '自动同步失败',
			'navigation.syncFailedMessage' => ({required Object error}) => '请检查网络连接或稍后再试。\n${error}',
			'navigation.loginExpired' => '登录过期，请重新登录',
			'settings.title' => '设置',
			'settings.globalTitle' => '设置',
			'settings.appearance' => '外观与显示',
			'settings.theme' => '主题模式',
			'settings.themeSubtitle' => '选择策略，切换明暗主题',
			'settings.themeColor' => '主题颜色',
			'settings.themeColorSubtitle' => '选择主色，统一应用视觉',
			'settings.language' => '语言',
			'settings.languageSubtitle' => '切换应用显示语言',
			'settings.followSystemLanguage' => '跟随系统',
			'settings.languageZhCn' => '简体中文 (zh_CN)',
			'settings.languageEnUs' => 'English (en_US)',
			'settings.languageChangedRestartHint' => '语言设置已保存，重启应用后全部生效',
			'settings.dynamicColor' => '动态取色',
			'settings.dynamicColorSubtitle' => '开启后自动提取内容主色',
			'settings.fontSettings' => '字体设置',
			'settings.fontSettingsSubtitle' => '自定义显示字体',
			'settings.amoled' => '纯黑模式',
			'settings.amoledSubtitle' => '开启后使用纯黑背景，适配 AMOLED',
			'settings.notchAdaptation' => '异形屏适配',
			'settings.notchAdaptationSubtitle' => '开启后预留安全区，避免内容遮挡',
			'settings.contentAndNetwork' => '内容与网络',
			'settings.content' => '内容',
			'settings.network' => '网络',
			'settings.maskedKeywords' => '屏蔽关键词',
			'settings.maskedKeywordsSubtitle' => '添加关键词，过滤不想看到的内容（仅搜索生效）',
			'settings.maskedKeywordsEmpty' => '暂无屏蔽词',
			'settings.maskedKeywordsInputHint' => '输入新关键词...',
			'settings.chineseConvert' => '简繁转换',
			'settings.chineseConvertSubtitle' => '将漫画标题、简介、章节、评论等转为简体或繁体',
			'settings.chineseConvertOff' => '关闭',
			'settings.chineseConvertSimplified' => '简体中文',
			'settings.chineseConvertTraditional' => '繁体中文',
			'settings.proxy' => 'SOCKS5 代理',
			'settings.proxySubtitle' => '配置 SOCKS5 代理',
			'settings.proxyEnabledSubtitle' => '关闭后将不使用 SOCKS5 代理',
			'settings.proxyAddress' => '代理地址',
			'settings.proxyHint' => '请输入 SOCKS5 代理地址',
			'settings.proxyCurrent' => ({required Object currentProxy}) => '当前代理：${currentProxy}',
			'settings.updateAccelerate' => '更新下载加速',
			'settings.updateAccelerateSubtitle' => '开启后优先使用代理加速 GitHub 更新链接',
			'settings.sync' => '同步',
			'settings.syncConfig' => '同步配置',
			'settings.syncConfigSubtitle' => '进入页面，配置地址与鉴权信息',
			'settings.syncService' => '同步服务',
			'settings.syncServiceSubtitle' => '选择服务，统一管理同步策略',
			'settings.syncServiceNone' => '不启用',
			'settings.syncServiceWebdav' => 'WebDAV',
			'settings.syncServiceS3' => 'S3',
			'settings.autoSync' => '自动同步',
			'settings.autoSyncSubtitle' => '开启后在后台定期同步配置',
			'settings.syncNotify' => '自动同步通知',
			'settings.syncNotifySubtitle' => '开启后在同步开始与完成时提醒',
			'settings.syncSettings' => '同步设置',
			'settings.syncSettingsSubtitle' => '开启后使用云端设置覆盖本地设置',
			'settings.syncPlugins' => '同步插件',
			'settings.syncPluginsSubtitle' => '开启后同步插件配置与安装状态',
			'settings.appBehavior' => '应用行为',
			'settings.splashPage' => '开屏页',
			'settings.splashPageSubtitle' => '选择启动页，打开应用直达目标',
			'settings.desktopCloseBehavior' => '关闭行为',
			'settings.desktopCloseBehaviorSubtitle' => '选择点击关闭按钮时的行为',
			'settings.desktopCloseAsk' => '询问',
			'settings.desktopCloseHide' => '隐藏到托盘',
			'settings.desktopCloseClose' => '直接关闭',
			'settings.showMainWindow' => '显示主界面',
			'settings.exitApp' => '退出',
			'settings.appLock' => '应用锁',
			'settings.appLockSubtitle' => '开启后进入应用需要验证',
			'settings.oldPageRollback' => '旧版首页',
			'settings.oldPageRollbackSubtitle' => '开启后使用旧版首页布局',
			'settings.androidKeepAlive' => '后台保活',
			'settings.androidKeepAliveSubtitle' => '开启后通过前台服务尽量保持应用在后台运行，会显示常驻通知',
			'settings.customExportPath' => '自定义导出路径',
			'settings.storage' => '存储',
			'settings.cache' => '缓存',
			'settings.clearCache' => '清理缓存',
			'settings.clearCacheConfirm' => '确定要清理所有缓存文件吗？此操作不可撤销。',
			'settings.calculatingCache' => '计算中...',
			'settings.calculateCacheFailed' => '计算失败',
			'settings.dataBackup' => '数据导入/导出',
			'settings.dataBackupSubtitle' => '备份或恢复应用数据与下载的漫画',
			'settings.includeDownloaded' => '包含下载的漫画',
			'settings.includeDownloadedSubtitle' => '导出时一并打包已下载的漫画文件',
			'settings.exportData' => '导出数据',
			'settings.importData' => '导入数据',
			'settings.imageProcessing' => '图片处理',
			'settings.realSr' => '图片超分（实验性）',
			'settings.realSrSubtitle' => '试验性功能，可能不稳定',
			'settings.autoRealSr' => '自动超分',
			'settings.resolutionThreshold' => '分辨率阈值',
			'settings.debug' => '调试',
			'settings.logAddress' => '日志转发地址',
			'settings.logAddressSubtitle' => '配置后实时转发日志到指定地址',
			'settings.memoryDebug' => '内存调试',
			'settings.memoryDebugSubtitle' => '开启后在界面显示内存占用信息',
			'settings.forceEnableImpeller' => '强制启用 Impeller',
			'settings.forceEnableImpellerSubtitle' => 'Android 实验性渲染后端',
			'settings.colorPreview' => '整点颜色看看',
			'settings.colorPreviewSubtitle' => '打开调色页，快速预览主题色',
			'settings.qjsRuntimeDebug' => 'QJS 运行时调试',
			'settings.qjsRuntimeDebugSubtitle' => '手动输入运行时 ID，抓取调试快照',
			'settings.qjsRuntimeSnapshot' => '调试快照',
			'settings.qjsRuntimeIdLabel' => '运行时 ID',
			'settings.qjsRuntimeIdHint' => '例如 0a0e5858-a467-4702-994a-79e608a4589d',
			'settings.qjsRuntimeCapture' => '抓取快照',
			'settings.qjsRuntimeCapturing' => '抓取中',
			'settings.qjsRuntimeCopyOutput' => '复制输出',
			'settings.qjsRuntimeNoOutput' => '暂无输出',
			'settings.qjsRuntimeFillId' => '请先输入运行时 ID',
			'settings.qjsRuntimeCapturedAt' => ({required Object dateTime}) => '已抓取 ${dateTime}',
			'settings.qjsRuntimeCaptureFailed' => ({required Object error}) => '抓取失败: ${error}',
			'settings.qjsRuntimeNoCopyContent' => '当前没有可复制的内容',
			'settings.qjsRuntimeCopied' => '已复制到剪贴板',
			'settings.colorPreviewVariableFont' => 'Variable Font 测试',
			'settings.colorPreviewFontLoaded' => ({required Object path}) => '已加载: ${path}',
			'settings.colorPreviewNoFont' => '还没加载字体，先试推荐样本或者手动选一个 TTF/OTF 文件。',
			'settings.colorPreviewLoadRecommended' => '加载推荐样本',
			'settings.colorPreviewSelectFont' => '选择字体文件',
			'settings.colorPreviewByWeight' => '按 fontWeight 渲染',
			'settings.colorPreviewByVariableAxis' => '按 variable axis 渲染',
			'settings.colorPreviewSystemDefault' => '系统默认字体对照',
			'settings.colorPreviewLoadingFont' => '正在加载字体...',
			'settings.colorPreviewLoadSuccess' => '加载成功，可以直接对比不同字重。',
			'settings.colorPreviewLoadFailed' => ({required Object error}) => '加载失败: ${error}',
			'settings.colorRed' => '红色',
			'settings.colorPink' => '粉色',
			'settings.colorPurple' => '紫色',
			'settings.colorDeepPurple' => '深紫色',
			'settings.colorIndigo' => '靛蓝色',
			'settings.colorBlue' => '蓝色',
			'settings.colorLightBlue' => '浅蓝色',
			'settings.colorCyan' => '青色',
			'settings.colorTeal' => '水鸭色',
			'settings.colorGreen' => '绿色',
			'settings.colorLightGreen' => '浅绿色',
			'settings.colorLime' => '酸橙色',
			'settings.colorYellow' => '黄色',
			'settings.colorAmber' => '琥珀色',
			'settings.colorOrange' => '橙色',
			'settings.colorDeepOrange' => '深橙色',
			'settings.colorBrown' => '棕色',
			'settings.colorGrey' => '灰色',
			'settings.colorBlueGrey' => '蓝灰色',
			'settings.coremlDebug' => 'CoreML 超分调试',
			'settings.coremlDebugSubtitle' => '使用绝对路径模型测试 CoreML 超分',
			'settings.aboutAndMore' => '关于与更多',
			'settings.changelog' => '更新日志',
			'settings.changelogSubtitle' => '查看各个版本的更新记录',
			'settings.aboutApp' => '关于应用',
			'settings.aboutAppSubtitle' => '关于 Breeze 的详细信息',
			'settings.pluginManagement' => '插件管理',
			'settings.debugMode' => '调试模式',
			'settings.debugAddress' => '调试地址',
			'settings.notSet' => '未设置',
			'bookshelf.title' => '书架',
			'bookshelf.favorite' => '收藏',
			'bookshelf.history' => '历史',
			'bookshelf.download' => '下载',
			'bookshelf.filter' => '筛选',
			'bookshelf.searchList' => '搜索列表',
			'bookshelf.newFolder' => '新建文件夹',
			'bookshelf.manage' => '管理',
			'bookshelf.importComic' => '导入漫画',
			'bookshelf.folderHint' => '书架说明',
			'bookshelf.removeFromFolder' => '移出文件夹',
			'bookshelf.deleteFavorite' => '删除收藏',
			'bookshelf.deleteHistory' => '删除历史记录',
			'bookshelf.deleteDownload' => '删除下载记录',
			'bookshelf.confirmDeleteSelected' => ({required Object count}) => '确定要删除选中的 ${count} 条记录吗？',
			'bookshelf.deletedRecords' => ({required Object count}) => '已删除 ${count} 条记录',
			'bookshelf.noFilterSource' => '暂无可筛选的插件来源',
			'bookshelf.sort' => '排序',
			'bookshelf.sortDesc' => '时间(晚→早)',
			'bookshelf.sortAsc' => '时间(早→晚)',
			'bookshelf.folderDeprecated' => '文件夹（已废弃）',
			'bookshelf.source' => '漫画源',
			'bookshelf.deselectAll' => '取消全选',
			'bookshelf.deleteFolder' => '删除收藏夹',
			'bookshelf.renameFolder' => '重命名收藏夹',
			'bookshelf.confirmDeleteFolder' => ({required Object name}) => '是否删除当前文件夹「${name}」？',
			'bookshelf.folderAction' => '请选择操作',
			'bookshelf.createFolder' => '新建收藏夹',
			'bookshelf.createFolderHint' => '输入收藏夹名称',
			'bookshelf.multiSelect' => '多选',
			'bookshelf.copyTo' => '复制到',
			'bookshelf.batchExport' => '批量导出',
			'bookshelf.batchDeleteFailed' => '批量删除失败',
			'bookshelf.deleteSelected' => '删除选中',
			'bookshelf.cancel' => '取消选择',
			'bookshelf.addToFavorite' => '加入收藏夹',
			'bookshelf.addToDownloadFolder' => '加入下载文件夹',
			'bookshelf.createFavoriteFolderFirst' => '请先创建自定义收藏夹',
			'bookshelf.addedToFavorite' => '已加入收藏夹',
			'bookshelf.createDownloadFolderFirst' => '请先创建自定义下载文件夹',
			'bookshelf.addedToDownloadFolder' => '已加入下载文件夹',
			'bookshelf.selectFavoriteFolder' => '选择收藏夹（可多选）',
			'bookshelf.selectDownloadFolder' => '选择下载文件夹（可多选）',
			'bookshelf.selectedCount' => ({required Object count}) => '已选择 ${count} 项',
			'bookshelf.selectTargetFolder' => '选择目标文件夹（可多选）',
			'bookshelf.confirmDeleteFolderTitle' => '确认删除',
			'bookshelf.confirmDeleteFolderContent' => '确定要删除该文件夹吗？文件夹内的内容会被递归删除。',
			'bookshelf.confirmRemoveComicTitle' => '从文件夹移除',
			'bookshelf.confirmRemoveComicContent' => ({required Object title}) => '确定要从当前文件夹移除《${title}》吗？',
			'bookshelf.importComicZipOnly' => '开始导入漫画（仅支持 zip）',
			'bookshelf.importStarted' => '开始导入漫画（仅支持 zip）',
			'bookshelf.importCompleted' => ({required Object title}) => '导入完成：${title}',
			'bookshelf.comicExists' => '漫画已存在',
			'bookshelf.confirmOverwriteImport' => ({required Object title}) => '《${title}》已经存在于下载列表中，是否覆盖导入？',
			'bookshelf.noExportableComics' => '选中的项目中没有可导出的漫画',
			'bookshelf.batchExportCompleted' => ({required Object success, required Object total}) => '批量导出完成：${success}/${total}',
			'bookshelf.batchExportFailed' => ({required Object error}) => '批量导出失败: ${error}',
			'bookshelf.confirmDeleteSelectedTitle' => '确认删除',
			'bookshelf.confirmDeleteSelectedContent' => '确定要删除选中的文件夹和漫画吗？文件夹会递归删除。',
			'bookshelf.cancelSelect' => '取消选择',
			'bookshelf.selectAll' => '全选',
			'bookshelf.moveTo' => '移动到',
			'bookshelf.addToFolder' => '加入文件夹',
			'bookshelf.folderName' => '文件夹名称',
			'bookshelf.folderNameHint' => '请输入文件夹名称',
			'bookshelf.helpContent' => '• 收藏和书架是联动的：收藏一本漫画，它会出现在书架里；只有把这本漫画从所有收藏文件夹里都删除，才会自动取消收藏。\n• 在漫画详情页“取消收藏”，会一次性从所有收藏文件夹里移除这本漫画。\n• 下载也是一样：只有把一本漫画从所有下载文件夹里都删除，才会自动删除它的下载文件。',
			'bookshelf.folderCreated' => '文件夹创建成功',
			'bookshelf.noComic' => '还没有漫画',
			'bookshelf.noHistory' => '还没有阅读记录',
			'bookshelf.noDownload' => '还没有下载记录',
			'bookshelf.nothingHere' => '啥都没有',
			'bookshelf.deleteAllDownloadRecordsAndFiles' => '删除所有下载记录及其文件',
			'bookshelf.clearHistoryRecords' => '清空历史记录',
			'bookshelf.confirmDeleteAllDownloadsContent' => '确定要删除所有下载记录及其文件吗？此操作不可恢复！',
			'bookshelf.confirmClearHistoryContent' => '确定要清空历史记录吗？此操作不可恢复！',
			'bookshelf.allDownloadRecordsAndFilesDeleted' => '所有下载记录及其文件已删除',
			'bookshelf.historyRecordsCleared' => '历史记录已清空',
			'bookshelf.batchExportTitle' => '选择导出方式',
			'bookshelf.batchExportSubtitle' => '请选择批量导出为压缩包或文件夹',
			'bookshelf.importCancelled' => '已取消导入',
			'bookshelf.importEpisodeFallback' => ({required Object index}) => '第${index}集',
			'bookshelf.importMissingJson' => '导入目录缺少必要的 JSON 文件',
			'bookshelf.importVersionUnsupported' => '该版本无法导入，请使用较新的软件版本导出后导入',
			'bookshelf.importMissingSource' => '该导出文件缺少来源信息，请使用新版软件重新导出后再导入',
			'bookshelf.importMissingComicId' => '无法获取漫画 ID',
			'bookshelf.importNoComicDir' => '未在压缩包中找到可导入的漫画目录',
			'bookshelf.importMultipleComicDirs' => '压缩包中包含多个漫画目录，请每次只导入一本',
			'bookshelf.importComicExistsUncovered' => ({required Object title}) => '漫画《${title}》已存在，未覆盖导入',
			'bookshelf.folderNameEmpty' => '文件夹名称不能为空',
			'bookshelf.folderNameSlash' => '文件夹名称不能包含 /',
			'bookshelf.folderNameExists' => '当前路径下已存在同名文件夹',
			'bookshelf.targetFolderNameExists' => ({required Object name}) => '目标位置已存在同名文件夹：${name}',
			'bookshelf.cannotMoveFolderToSelf' => '不能将文件夹移动到自身',
			'bookshelf.cannotMoveParentToChild' => '不能将父文件夹移动到子文件夹中',
			'bookshelf.cannotCopyFolderToSelfOrChild' => '不能复制文件夹到自身或其子路径下',
			'bookshelf.moveFoldersOnlyOneTarget' => '移动文件夹时只能选择一个目标文件夹',
			'bookshelf.favoriteFolderNameEmpty' => '收藏夹名称不能为空',
			'bookshelf.favoriteFolderNameExists' => '已存在同名收藏夹',
			'bookshelf.downloadFolderNameEmpty' => '下载文件夹名称不能为空',
			'bookshelf.downloadFolderNameExists' => '已存在同名下载文件夹',
			'bookshelf.removeFromFavoriteFolder' => '移出收藏夹',
			'bookshelf.removeFromDownloadFolder' => '移出下载文件夹',
			'bookshelf.confirmRemoveFromCurrentFolder' => '是否要从本文件夹中移除',
			'bookshelf.confirmDeleteSelectedFavorites' => ({required Object count}) => '确定要删除选中的 ${count} 条收藏记录吗？',
			'bookshelf.confirmDeleteSelectedHistory' => ({required Object count}) => '确定要删除选中的 ${count} 条历史记录吗？',
			'bookshelf.confirmDeleteSelectedDownloads' => ({required Object count}) => '确定要删除选中的 ${count} 条下载记录及文件吗？',
			'comicInfo.follow' => '加入追更',
			'comicInfo.unfollow' => '不再追更',
			'comicInfo.exportComic' => '导出漫画',
			'comicInfo.collectToCloud' => '收藏到云端',
			'comicInfo.removeCloudCollection' => '取消云端收藏',
			'comicInfo.cloudCollectDisabled' => '云端收藏已关闭',
			'comicInfo.collectingToCloud' => '收藏到云端中...',
			'comicInfo.removingCloudCollection' => '取消云端收藏中...',
			'comicInfo.cloudCollectSuccess' => '云端收藏成功',
			'comicInfo.cloudUncollectSuccess' => '已取消云端收藏',
			'comicInfo.discontinued' => '此漫画已下架',
			'comicInfo.likes' => ({required Object count}) => '点赞 ${count}',
			'comicInfo.comments' => ({required Object count}) => '评论 ${count}',
			'comicInfo.collected' => '已收藏',
			'comicInfo.collect' => '收藏',
			'comicInfo.download' => '下载',
			'comicInfo.downloadForbidden' => '禁止下载',
			'comicInfo.addedToCollection' => '已添加收藏',
			'comicInfo.removedFromCollection' => '已取消收藏',
			'comicInfo.confirmUncollectTitle' => '确认取消收藏',
			'comicInfo.confirmUncollectContent' => '此项操作会删除该漫画在所有文件夹的记录，是否确认删除？',
			'comicInfo.commentForbidden' => '该漫画禁止评论',
			'comicInfo.commentForbiddenTitle' => '禁止评论',
			'comicInfo.back' => '返回',
			'comicInfo.exportTitle' => '选择导出方式',
			'comicInfo.exportSubtitle' => '请选择将漫画导出为压缩包还是文件夹：',
			'comicInfo.folder' => '文件夹',
			'comicInfo.zip' => '压缩包',
			'comicInfo.exportSuccess' => '导出成功',
			'comicInfo.detailsNotLoaded' => '当前详情尚未加载完成',
			'comicInfo.followed' => '已加入追更',
			'comicInfo.unfollowed' => '已取消追更',
			'comicInfo.confirmUnfollowTitle' => '取消追更',
			'comicInfo.confirmUnfollowContent' => ({required Object title}) => '确定不再追更《${title}》吗？',
			'comicInfo.noChapters' => '暂无章节信息',
			'comicInfo.chapterList' => '章节目录',
			'comicInfo.episodeCount' => ({required Object count}) => '${count} 话',
			'comicInfo.episodeFallback' => ({required Object index}) => '第${index}话',
			'comicInfo.episodeLabel' => ({required Object index}) => '第${index}话',
			'comicInfo.author' => '作者',
			'comicInfo.tags' => '标签',
			'comicInfo.works' => '作品',
			'comicInfo.views' => ({required Object count}) => '浏览：${count}',
			'comicInfo.updateTime' => ({required Object time}) => '更新时间：${time}',
			'comicInfo.startRead' => '开始阅读',
			'comicInfo.continueRead' => '继续阅读',
			'comicInfo.lastRead' => '上次读到',
			'comicInfo.chapters' => '章节',
			'comicInfo.related' => '相关推荐',
			'comicInfo.description' => '简介',
			'comicInfo.collapse' => '收起',
			'comicInfo.expandFullText' => '展开全文',
			'comicInfo.readHistory' => '阅读记录',
			'comicInfo.copied' => ({required Object label}) => '已复制：${label}',
			'comicInfo.copiedToClipboard' => ({required Object name}) => '已将 ${name} 复制到剪贴板',
			'comicInfo.liking' => '点赞中...',
			'comicInfo.unliking' => '取消点赞中...',
			'comicInfo.likeSuccess' => '点赞成功',
			'comicInfo.unlikeSuccess' => '已取消点赞',
			'comicInfo.localCollectFailed' => ({required Object error}) => '本地收藏失败: ${error}',
			'comicInfo.likeFailed' => ({required Object error}) => '点赞失败: ${error}',
			'comicInfo.loadFailedWithError' => ({required Object error}) => '${error}\n加载失败，请重试。',
			'comicInfo.exportPermissionDenied' => '未授予所有文件访问权限，导出已取消',
			'comicInfo.exportFailedWithError' => ({required Object error}) => '导出失败，请重试。\n${error}',
			'comicInfo.exportDirectory' => ({required Object displayPath}) => '导出目录：${displayPath}',
			'comicInfo.exportPathTooLong' => '导出目录路径过长，无法创建有效的导出结构',
			'comicInfo.zipExportPathTooLong' => '指定的 zip 导出路径超出系统路径长度限制',
			'comicInfo.downloadPathTooLong' => '下载目录路径过长，无法创建有效的 zip 文件路径',
			'comicInfo.uniqueFileNameTooLong' => '无法为章节创建不重复的文件名：超出路径长度限制',
			'comicInfo.exportFolderComplete' => ({required Object title}) => '漫画${title}导出为文件夹完成',
			'comicInfo.exportZipComplete' => ({required Object title}) => '漫画${title}导出为 zip 完成',
			'comicInfo.exportComicNotFound' => ({required Object comicId}) => '未找到可导出的下载漫画: ${comicId}',
			'comicInfo.pluginInvalidFavorited' => '插件未返回有效 favorited 状态',
			'comicInfo.pluginInvalidLiked' => '插件未返回有效 liked 状态',
			'comicInfo.addToCustomFolder' => '添加到自定义收藏夹',
			'comicInfo.addedToFolder' => ({required Object name}) => '已添加到收藏夹: ${name}',
			'comicInfo.skipAdd' => '跳过/不添加',
			'comicInfo.confirmAdd' => '确定添加',
			'comicInfo.resolveComicIdFailed' => ({required Object type}) => '无法解析阅读 comicId: ${type}',
			'comicInfo.resolveEpsCountFailed' => ({required Object type}) => '无法解析阅读章节数: ${type}',
			'reader.pageMode' => '翻页模式',
			'reader.fullscreen' => '全屏模式',
			'reader.leftHandMode' => '左手模式',
			'reader.rightHandMode' => '右手模式',
			'reader.readingMode' => '阅读模式',
			'reader.infoDisplay' => '信息项显示',
			'reader.pageNumber' => '页数',
			'reader.pageNumberSubtitle' => '显示当前页/总页数',
			'reader.networkStatus' => '网络状态',
			'reader.networkStatusSubtitle' => 'Linux 下可能不准确',
			'reader.battery' => '电量',
			'reader.time' => '时间',
			'reader.verticalPositionTop' => '顶部',
			'reader.verticalPositionBottom' => '底部',
			'reader.horizontalPositionLeft' => '左侧',
			'reader.horizontalPositionCenter' => '居中',
			'reader.horizontalPositionRight' => '右侧',
			'reader.readingDirectionLtr' => '从左到右',
			'reader.readingDirectionRtl' => '从右到左',
			'reader.readingDirectionVertical' => '从上到下',
			'reader.webtoon' => '条漫',
			'reader.singlePageLtr' => '单页式（从左到右）',
			'reader.singlePageRtl' => '单页式（从右到左）',
			'reader.doublePage' => '双页阅读',
			'reader.doublePageSubtitle' => '在当前阅读模式中启用双页并排',
			'reader.doublePageLeadingBlank' => '首页留白',
			'reader.doublePageLeadingBlankSubtitle' => '在每章最前插入一页空白，使配对整体错一位',
			'reader.themeMode' => '系统模式',
			'reader.autoRead' => '自动阅读',
			'reader.autoReadSubtitle' => '开启后自动滚动，并在右下角显示暂停/播放按钮',
			'reader.webtoonScrollDistance' => '条漫滚动距离',
			'reader.webtoonScrollInterval' => '条漫滚动间隔',
			'reader.singlePageScrollInterval' => '单页式滚动间隔',
			'reader.background' => '阅读背景',
			'reader.auto' => '自动',
			'reader.black' => '黑色',
			'reader.white' => '白色',
			'reader.grey' => '灰色',
			'reader.readingExperience' => '阅读体验',
			'reader.disableAnimation' => '关闭翻页动画',
			'reader.disableAnimationSubtitle' => '关闭整页翻页动画，小幅滚动动画不受影响',
			'reader.readFilter' => '阅读滤镜（仅深色模式）',
			'reader.readFilterSubtitle' => '仅在阅读界面生效，可降低夜间阅读亮度',
			'reader.filterIntensity' => '滤镜强度',
			'reader.einkOptimization' => '墨水屏优化（仅横向）',
			'reader.einkOptimizationSubtitle' => '翻页后先白屏再显示图片',
			'reader.einkDelay' => '白屏时长',
			'reader.sidePadding' => '两侧留白',
			'reader.sidePaddingSubtitle' => '自定义左右留白比例',
			'reader.sidePaddingPercent' => '每侧留白比例',
			'reader.batterySubtitle' => '默认关闭，可按需开启',
			'reader.timeSubtitle' => '显示当前时间',
			'reader.infoBarPosition' => '信息条位置',
			'reader.showInStatusBar' => '显示在状态栏',
			'reader.showInStatusBarSubtitle' => '开启后，顶部信息条会进入系统状态栏区域',
			'reader.edgePadding' => '边缘间距',
			'reader.infoBarStyle' => '信息条样式',
			'reader.backgroundOpacity' => '背景透明度',
			'reader.fontSize' => '字体大小',
			'reader.allHiddenNotice' => '当前已全部关闭，阅读页中的信息条会完全隐藏。',
			'reader.edgePaddingDisabled' => '横向在中间时，边缘间距不会生效。',
			'reader.settings' => '阅读设置',
			'reader.previousChapter' => '上一章',
			'reader.nextChapter' => '下一章',
			'reader.backToHome' => '返回首页',
			'reader.jumpToChapterTitle' => '跳转',
			'reader.jumpToChapterMessage' => ({required Object chapter}) => '是否要跳转到${chapter}？',
			'reader.selectChapter' => '选择章节',
			'reader.enterFullscreen' => '全屏（f11）',
			'reader.exitFullscreen' => '退出全屏',
			'reader.chapterTransition' => '章节过渡中',
			'reader.transitionSwipeToLoad' => '继续翻页加载',
			'reader.transitionLoaded' => '加载完成',
			'reader.transitionLoadFailedRetry' => '加载失败，点击重试',
			'reader.pullDownToPrevChapter' => '继续下拉到上一章',
			'reader.releaseToJumpPrevChapter' => '松手跳转到上一章',
			'reader.releaseToLoadPrevChapter' => '松手加载到上一章',
			'reader.pullUpToNextChapter' => '继续上拉到下一章',
			'reader.releaseToJumpNextChapter' => '松手跳转到下一章',
			_ => null,
		} ?? switch (path) {
			'reader.releaseToLoadNextChapter' => '松手加载到下一章',
			'reader.chapterNotDownloaded' => '章节未下载',
			'reader.loadFailedWithResult' => ({required Object result}) => '${result}\n加载失败',
			'reader.chapterOrder' => ({required Object order}) => '章节 ${order}',
			'reader.doubleTapAction' => '双击操作',
			'reader.doubleTapZoom' => '双击缩放',
			'reader.doubleTapZoomSubtitle' => '双击图片可在缩放和还原之间切换',
			'reader.doubleTapOpenMenu' => '双击打开操作栏',
			'reader.doubleTapOpenMenuSubtitle' => '双击页面打开操作栏（与双击缩放互斥）',
			'reader.volumeKeyPageTurn' => '音量键翻页',
			'reader.enableVolumeKeyPageTurn' => '启用音量键翻页',
			'reader.volumeKeyPageTurnSubtitle' => '开启后可用音量键上下翻页/滑动',
			'reader.screenHeightPercent' => '% 屏高',
			'reader.milliseconds' => 'ms',
			'reader.percent' => '%',
			'reader.pixels' => 'px',
			'reader.gesture' => '手势',
			'reader.infoBar' => '信息条',
			'reader.pauseAutoRead' => '暂停自动阅读',
			'reader.resumeAutoRead' => '继续自动阅读',
			'reader.imageLoadFailedRetry' => ({required Object error}) => '${error}\n加载失败，点击重试',
			'reader.imageSavedTo' => ({required Object path}) => '图片已保存至: ${path}',
			'reader.imageSavedToAlbum' => '图片已保存到相册！',
			'reader.imageSaveFailed' => '图片保存失败！',
			'reader.saveImagePermissionDenied' => '保存失败: 请在系统设置中授予相册访问权限',
			'reader.imageSaveFailedWithError' => ({required Object error}) => '保存失败: ${error}',
			'plugin.store' => '插件商店',
			'plugin.searchHint' => '搜索插件名称或作者...',
			'plugin.localInstall' => '本地安装',
			'plugin.networkInstall' => '网络安装',
			'plugin.cloudComponents' => '云端组件',
			'plugin.loginSuccess' => '请在网页中完成登录，宿主会自动同步 Cookie',
			'plugin.chromiumFallbackUnsupported' => '当前平台不支持外部 Chromium 自动登录回退',
			'plugin.switchingToExternalBrowser' => '内置 WebView 登录受限，正在切换外部浏览器...',
			'plugin.chromiumNotFound' => '未检测到 Chromium 浏览器，请先安装 Chrome',
			'plugin.browserSwitched' => ({required Object browser}) => '已切换到 ${browser}，登录完成后会自动同步 Cookie',
			'plugin.invalidLink' => ({required Object url}) => '无效链接: ${url}',
			'plugin.cannotOpenLink' => ({required Object url}) => '无法打开链接: ${url}',
			'plugin.readLocalPluginFailed' => ({required Object error}) => '读取本地插件失败: ${error}',
			'plugin.addFromNetwork' => '从网络添加插件',
			'plugin.urlCannotBeEmpty' => 'URL 不能为空',
			'plugin.startInstall' => '开始安装',
			'plugin.pluginSettingsTitle' => ({required Object name}) => '${name} 设置',
			'plugin.debugConfigUpdated' => '插件调试配置已更新',
			'plugin.deletePlugin' => '删除插件',
			'plugin.confirmDeletePlugin' => '确认删除该插件？此操作将删除插件及其相关数据。',
			'plugin.deleteFailed' => ({required Object error}) => '删除失败: ${error}',
			'plugin.pluginDeleted' => '插件已删除',
			'plugin.executeFailed' => ({required Object error}) => '执行失败: ${error}',
			'plugin.debugMode' => '调试模式',
			'plugin.debugAddress' => '调试地址',
			'plugin.deletePluginSubtitle' => '彻底删除插件，并删除相关数据',
			'plugin.pluginSettings' => '插件设置',
			'plugin.noUserInfo' => '暂无用户信息',
			'plugin.operations' => '操作',
			'plugin.management' => '插件管理',
			'plugin.installed' => '已安装',
			'plugin.notInstalled' => '未安装',
			'plugin.update' => '更新',
			'plugin.install' => '安装',
			'plugin.uninstall' => '卸载',
			'plugin.author' => '作者',
			'plugin.version' => '版本',
			'plugin.description' => '描述',
			'plugin.repo' => '仓库',
			'plugin.homepage' => '主页',
			'plugin.download' => '下载',
			'plugin.downloadUpdate' => '下载更新',
			'plugin.noCloudPlugins' => '暂无云端组件',
			'plugin.noMatchingPlugins' => '没有匹配的插件',
			'plugin.networkInstallHint' => '请输入插件脚本 URL',
			'plugin.cloudPluginsLoadFailed' => ({required Object error}) => '云端组件列表加载失败: ${error}',
			'plugin.installingFromCloud' => ({required Object name}) => '正在下载并安装 ${name}...',
			'plugin.installingFromLocal' => '正在安装本地插件...',
			'plugin.installingFromNetwork' => '正在下载网络插件...',
			'plugin.cloudDownloadFailed' => ({required Object error}) => '云端下载失败: ${error}',
			'plugin.networkDownloadFailed' => ({required Object error}) => '网络下载插件失败: ${error}',
			'plugin.cloudVersion' => ({required Object version}) => '云端 ${version}',
			'plugin.localVersion' => ({required Object version}) => '本地 ${version}',
			'plugin.loginTitle' => ({required Object name}) => '${name} 登录',
			'plugin.cookieSynced' => '登录 Cookie 已同步',
			'plugin.executeSuccess' => '执行成功',
			'plugin.userInfoTitle' => '用户信息',
			'plugin.userInfoLoadFailed' => '用户信息加载失败',
			'plugin.unnamedAction' => '未命名操作',
			'plugin.pluginSettingsLoading' => '插件设置加载中...',
			'plugin.pluginSettingsLoadFailed' => '插件设置加载失败',
			'plugin.actionNotExecutable' => '动作不可执行: 缺少 fnPath',
			'plugin.saved' => '已保存',
			'plugin.close' => '关闭',
			'plugin.sync' => '同步',
			'plugin.syncSubtitle' => '通过 npm / updateUrl 检查并更新插件',
			'plugin.syncing' => '正在同步插件...',
			'plugin.syncSuccess' => '同步成功',
			'plugin.syncFailed' => ({required Object error}) => '同步失败: ${error}',
			'plugin.updateSubtitle' => '通过网络 URL 或本地文件手动重装当前插件',
			'plugin.updateFromNetwork' => '从网络安装',
			'plugin.updateFromLocal' => '从本地安装',
			'plugin.updateChooseSource' => '选择安装方式',
			'plugin.updating' => '正在更新插件...',
			'plugin.updateSuccess' => '更新成功',
			'plugin.updateFailed' => ({required Object error}) => '更新失败: ${error}',
			'plugin.uuidMismatch' => '插件 id 不一致，无法安装',
			'plugin.currentVersion' => ({required Object version}) => '当前版本 ${version}',
			'plugin.alreadyLatest' => '已是最新版本',
			'gestureLock.gestureTitle' => '手势解锁',
			'gestureLock.gestureHint' => '请绘制手势密码',
			'gestureLock.pinTitle' => '输入 PIN',
			'gestureLock.pinHint' => '请输入重置 PIN',
			'gestureLock.atLeast4Points' => '至少连接 4 个点',
			'gestureLock.confirmGesture' => '请再次绘制以确认',
			'gestureLock.gestureNotMatch' => '两次绘制不一致',
			'gestureLock.setSuccess' => '设置成功',
			'gestureLock.forgotPassword' => '忘记密码',
			'gestureLock.incorrectPassword' => '手势密码不正确，请重试',
			'gestureLock.resetPin' => '重置 PIN',
			'gestureLock.pin' => 'PIN',
			'gestureLock.pinDescription' => 'PIN 可用于重置手势密码，遗忘手势密码与 PIN 后将无法进入软件，请妥善保管 Pin',
			'gestureLock.pinMinLength' => 'PIN 需至少 4 位数字',
			'gestureLock.pinNotMatch' => '两次输入的 PIN 不一致',
			'gestureLock.pinIncorrect' => 'PIN 不正确，请重试',
			'gestureLock.appLocked' => '应用已锁定',
			'gestureLock.verifyToUnlock' => '请先完成手势验证',
			'gestureLock.resetGesturePassword' => '重置手势密码',
			'gestureLock.resetPinHint' => '请输入设置时保存的重置 PIN',
			'gestureLock.passwordCleared' => '密码已清空，请重新设置',
			'gestureLock.setupHintFirst' => '请连接至少 4 个点',
			'gestureLock.setupHintConfirm' => '请再次绘制相同手势',
			'gestureLock.setupErrorMinPoints' => '至少连接 4 个点',
			'gestureLock.setupErrorMismatch' => '两次手势不一致，请重新设置',
			'gestureLock.pinHintMinDigits' => '至少 4 位数字',
			'appBootstrap.initializing' => '初始化中....',
			'appBootstrap.verifyGesture' => '请验证手势密码',
			'appBootstrap.pinVerifyFailed' => 'PIN 验证未通过',
			'appBootstrap.unlockCancelled' => '已取消解锁',
			'appBootstrap.enteringApp' => '验证成功，正在进入应用',
			'comments.retry' => '重试',
			'comments.noComments' => '暂无评论',
			'comments.loadMore' => '加载更多',
			'comments.collapseReplies' => '收起回复',
			'comments.replyCount' => ({required Object count}) => '${count} 条回复',
			'comments.noReplies' => '暂无子评论',
			'comments.loadMoreReplies' => '加载更多回复',
			'comments.postComment' => '发表评论',
			'comments.postCommentHint' => '输入评论内容',
			'comments.postReply' => '回复评论',
			'comments.postReplyHint' => '输入回复内容',
			'comments.cancel' => '取消',
			'comments.confirm' => '确认',
			'comments.postSuccess' => '发布成功',
			'comments.postFailed' => ({required Object error}) => '发布失败: ${error}',
			'comments.anonymous' => '匿名用户',
			'cache.title' => '缓存设置',
			'cache.currentCache' => '当前缓存',
			'cache.clearCache' => '清理缓存',
			'cache.clearCacheConfirm' => '确定要清理所有缓存文件吗？此操作不可撤销。',
			'cache.cleared' => '缓存已清理',
			'cache.clearFailed' => '清理失败',
			'cache.cacheSize' => '缓存大小',
			'cache.recalculate' => '重新计算',
			'cache.manualClear' => '手动清理缓存',
			'cache.manualClearSubtitle' => '立即删除所有缓存文件',
			'cache.clear' => '清理',
			'cache.cacheLimit' => '缓存限制',
			'cache.sizeLimit' => '缓存上限',
			'cache.sizeLimitSubtitle' => '达到上限后将自动清理旧缓存',
			'cache.autoClean' => '自动清理缓存',
			'cache.autoCleanSubtitle' => '关闭后将不再自动清理任何缓存',
			'cache.calculating' => '计算中...',
			'cache.calculateFailed' => '计算失败',
			'dataBackup.title' => '数据导入/导出',
			'dataBackup.exportSection' => '导出',
			'dataBackup.importSection' => '导入',
			'dataBackup.includeDownloads' => '包含下载的漫画',
			'dataBackup.includeDownloadsSubtitle' => '导出时一并打包已下载的漫画文件',
			'dataBackup.exportData' => '导出数据',
			'dataBackup.exportDataSubtitle' => '将设置与数据打包为 zip',
			'dataBackup.importData' => '导入数据',
			'dataBackup.importDataSubtitle' => '从 zip 文件恢复数据',
			'dataBackup.selectExportDirFailed' => '选择导出目录失败',
			'dataBackup.exporting' => '正在导出，请耐心等待…',
			'dataBackup.exportSuccess' => '导出成功',
			'dataBackup.savedTo' => ({required Object path}) => '已保存到：${path}',
			'dataBackup.exportShareHint' => '请在弹出的分享面板中选择「存储到文件」以保存备份。',
			'dataBackup.exportFailed' => '导出失败',
			'dataBackup.processingBackup' => '正在处理备份文件…',
			'dataBackup.selectBackupFailed' => '选择备份文件失败',
			'dataBackup.readingBackup' => '正在读取备份信息…',
			'dataBackup.readBackupFailed' => '读取备份失败',
			'dataBackup.importing' => '正在导入，请稍后…',
			'dataBackup.importFailed' => '导入失败',
			'dataBackup.importTitle' => '导入数据',
			'dataBackup.importConfirm' => '导入将覆盖当前应用内的所有数据，是否继续？',
			'dataBackup.includesDownloadsWarning' => '该备份包含下载的漫画文件，导入时会先删除本机现有的下载文件。',
			'dataBackup.versionMismatch' => '版本不一致，数据导入可能会出问题，是否继续？',
			'dataBackup.exportedVersion' => ({required Object version}) => '导出数据版本：${version}',
			'dataBackup.currentVersion' => ({required Object version}) => '当前应用版本：${version}',
			'dataBackup.kContinue' => '继续',
			'dataBackup.importSuccess' => '导入成功',
			'dataBackup.restartPrompt' => '数据导入成功，请重启应用以生效。',
			'webdavSync.title' => '云同步配置',
			'webdavSync.serviceTitle' => ({required Object service}) => '${service} 同步配置',
			'webdavSync.noneTip' => '请先在设置里选择同步服务，再回到这里填写配置。',
			'webdavSync.deleteConfig' => '删除配置',
			'webdavSync.testAndSave' => '测试连接并保存',
			'webdavSync.faq' => '常见问题',
			'webdavSync.webdavHost' => 'WebDAV 地址',
			'webdavSync.username' => '账号',
			'webdavSync.password' => '密码',
			'webdavSync.s3Endpoint' => '服务地址(Endpoint)',
			'webdavSync.s3EndpointHint' => '如: s3.amazonaws.com',
			'webdavSync.s3AccessKey' => 'Access Key',
			'webdavSync.s3SecretKey' => 'Secret Key',
			'webdavSync.s3Bucket' => '存储桶(Bucket)的名字',
			'webdavSync.s3Region' => '区域(Region)（可选）',
			'webdavSync.s3Port' => '端口（可选）',
			'webdavSync.useSsl' => '使用 HTTPS/SSL',
			'webdavSync.pathStyle' => '路径风格 (Path-Style)',
			'webdavSync.pathStyleSubtitle' => '自建 MinIO 通常需要开启此选项',
			'webdavSync.connectingWebdav' => '正在连接 WebDAV 服务器...',
			'webdavSync.webdavConnected' => 'WebDAV连接成功，已保存设置。',
			'webdavSync.webdavConnectFailed' => ({required Object error}) => '连接失败，请检查网络连接或WebDAV地址是否正确。\n${error}',
			'webdavSync.invalidPort' => '端口格式不正确，请输入 0-65535 的数字。',
			'webdavSync.connectingS3' => '正在连接 S3 服务...',
			'webdavSync.s3Connected' => 'S3 连接成功，已保存设置。',
			'webdavSync.s3ConnectFailed' => ({required Object error}) => '连接失败，请检查 S3 配置是否正确。\n${error}',
			'webdavSync.close' => '关闭',
			'webdavSync.success' => '成功',
			'webdavSync.error' => '错误',
			'webdavSync.faqMarkdown' => '### 可以同步哪些内容？\n- 目前同步哔咔历史记录、禁漫收藏和禁漫历史。\n\n### WebDAV 如何配置？\n- 填写 WebDAV 地址、账号、密码，点击测试连接并保存即可。\n\n### S3 如何配置？\n- Endpoint 示例：`s3.amazonaws.com`、`s3.filebase.com`、`play.min.io`。\n- 如果是自建 MinIO，可填写自定义端口，必要时关闭 SSL。\n\n### 自动同步间隔是多久？\n- 每 5 分钟自动同步一次。\n\n### 如何手动触发一次同步？\n- 在同步配置页测试连接并保存后会触发一次同步。\n- 或在设置里切换一次自动同步开关。',
			'realSr.title' => '图片超分（实验性）',
			'realSr.unlimited' => '不限制',
			'realSr.modelDownloadFailed' => '模型下载失败',
			'realSr.generalSection' => '通用',
			'realSr.autoUpscaleSection' => '自动超分',
			'realSr.autoUpscale' => '自动超分',
			'realSr.autoUpscaleSubtitleUnavailable' => '模型未下载，开启后无法自动超分',
			'realSr.autoUpscaleSubtitleAvailable' => '下载或加载图片时自动调用超分',
			'realSr.conditionSection' => '超分条件',
			'realSr.resolutionThreshold' => '分辨率阈值',
			'realSr.resolutionThresholdSubtitle' => '仅当图片宽度小于该值时才自动超分',
			'realSr.performanceSection' => '性能',
			'realSr.concurrency' => '并发数量',
			'realSr.concurrencySubtitle' => '高端显卡可适当提高，移动设备或性能较低时不建议设置高于1的并发量',
			'realSr.tileSize' => '分块大小',
			'realSr.tileSizeSubtitle' => '遇到崩溃可设置较小值，0为不分块，桌面端可尝试设置为0',
			'realSr.modelSection' => '模型',
			'realSr.model' => '模型',
			'realSr.modelSubtitle' => '切换模型族会重置对应的变体选项',
			'realSr.noiseLevel' => '降噪级别',
			'realSr.noiseLevelSubtitle' => '该选项随所选模型变化',
			'realSr.blockInfo' => '分块信息',
			'realSr.blockInfoTooltip' => 'blockSize 是模型输入尺寸，包含反射边距；\n内容块 = blockSize - 2×shrinkSize，才是真正拼接输出的区域。',
			'realSr.blockInfoFormat' => ({required Object contentSize, required Object blockSize, required Object shrinkSize}) => '内容块 ${contentSize}×${contentSize}，模型输入 ${blockSize}×${blockSize}（含 ${shrinkSize}px 反射边距）',
			'realSr.androidSuperResolution' => 'Android 超分',
			'realSr.androidSuperResolutionSubtitle' => '当前使用 waifu2x upconv 动漫模型，2 倍放大',
			'realSr.desktopStrategy' => '超分策略',
			'realSr.desktopStrategySubtitle' => '效率优先使用 waifu2x，质量优先使用 Real-CUGAN',
			'realSr.desktopNoiseLevel' => '降噪级别',
			'realSr.desktopNoiseLevelSubtitle' => '保守适合普通漫画，降噪级别越高涂抹感越强',
			'realSr.modelManagementSection' => '模型管理',
			'realSr.downloadingModel' => '正在下载模型',
			'realSr.modelReady' => '模型已就绪',
			'realSr.redownload' => '重新下载',
			'realSr.deleteModel' => '删除模型',
			'realSr.deleteModelConfirm' => '确定要删除已下载的超分模型吗？删除后需要重新下载才能使用。',
			'realSr.modelDeleted' => '模型已删除',
			'realSr.modelDeleteFailed' => '模型删除失败',
			'realSr.modelNotDownloaded' => '模型未下载',
			'realSr.modelNotDownloadedSubtitle' => '使用超分前需要先下载模型',
			'realSr.downloadModel' => '下载模型',
			'realSr.modeEfficiency' => '效率优先',
			'realSr.modeQuality' => '质量优先',
			'realSr.noiseConservative' => '保守',
			'realSr.noise0' => '无降噪',
			'realSr.noise1' => '降噪 1',
			'realSr.noise2' => '降噪 2',
			'realSr.noise3' => '降噪 3',
			'realSr.variantWaifu2xAnime' => 'waifu2x upconv 动漫',
			'realSr.variantRealCuganDenoise' => ({required Object noise}) => 'Real-CUGAN 降噪 ${noise}',
			'realSr.coremlSpeed' => '速度优先 (waifu2x)',
			'realSr.coremlQuality' => '质量优先 (Real-CUGAN)',
			'realSr.coremlNoise0' => '降噪 0',
			'realSr.coremlNoDenoise' => '无降噪',
			'realSr.coremlInputHint' => '输入图片绝对路径或 asset 路径',
			'realSr.coremlStartUpscale' => '开始超分',
			'realSr.coremlStatusFillInput' => '请填写输入图片路径',
			'realSr.coremlStatusNoModelFile' => '当前模型族没有可用的模型文件',
			'realSr.coremlStatusPreparing' => '正在准备资源...',
			'realSr.coremlStatusUpscaling' => '正在超分...',
			'realSr.coremlStatusDone' => ({required Object outputPath, required Object size}) => '完成\n${outputPath}\nsize: ${size} bytes',
			'realSr.coremlStatusFailed' => ({required Object error}) => '失败: ${error}',
			'realSr.coremlModelOption' => '模型选项（降噪级别）',
			'realSr.coremlGeneralOption' => '通用选项（放大倍率）',
			'realSr.coremlTileInfo' => '分块信息',
			'about.title' => '关于应用',
			'about.version' => ({required Object version}) => '版本号: ${version}',
			'about.loading' => '加载中...',
			'about.fetchFailed' => '获取失败',
			'about.networkError' => '网络错误',
			'about.projectAddress' => '项目地址',
			'about.projectAddressDesc' => '喜欢这个项目吗？点个star支持一下吧！',
			'about.projectLink' => '前往 GitHub 仓库 (deretame/Breeze) ⭐',
			'about.contact' => '联系方式',
			'about.contactDesc' => '有任何想法或问题，欢迎来找我聊聊~',
			'about.feedback' => '反馈与建议',
			'about.feedbackDesc' => '发现BUG或者有新的点子？',
			'about.feedbackLink' => '在 GitHub Issues 中提出',
			'about.contributors' => '贡献者',
			'about.contributorsCount' => ({required Object count}) => '${count}人',
			'about.contributionsTooltip' => ({required Object login, required Object count}) => '${login} (${count} 次提交)',
			'about.disclaimer' => '免责声明',
			'about.disclaimerTitle' => '开源项目免责声明',
			'about.disclaimerItem1Title' => '1. 项目性质与声明',
			'about.disclaimerItem1Content' => '本项目为开源软件，由本人独立开发并维护。项目以"原样"形式提供，开发者不对项目的功能完整性、稳定性、安全性或适用性作出任何明示或暗示的担保。',
			'about.disclaimerItem2Title' => '2. 责任限制',
			'about.disclaimerItem2Content' => '开发者对因使用、修改或分发本项目（包括但不限于直接使用、二次开发或集成至其他项目）而导致的任何直接、间接、特殊、附带或后果性损害不承担任何责任。这些损害可能包括但不限于数据丢失、设备损坏、业务中断、利润损失或其他经济损失。',
			'about.disclaimerItem3Title' => '3. 用户责任',
			'about.disclaimerItem3Content' => '用户在使用本项目时，应自行评估其适用性并承担所有风险。用户须确保其使用行为符合所在国家或地区的法律法规及道德规范。开发者不对用户因违反法律法规或不当使用本项目而导致的任何后果负责。',
			'about.disclaimerItem4Title' => '4. 第三方依赖与资源',
			'about.disclaimerItem4Content' => '本项目可能依赖或引用第三方库、工具、服务或其他资源。开发者不对这些第三方资源的内容、功能、安全性或合法性负责。用户应自行评估并承担使用第三方资源的风险。',
			'about.disclaimerItem5Title' => '5. 无担保声明',
			'about.disclaimerItem5Content' => '开发者明确声明不对本项目提供任何形式的担保，包括但不限于：适销性担保；特定用途适用性担保；不侵犯第三方权利担保；无错误或无中断运行担保。',
			'about.disclaimerItem6Title' => '6. 项目修改与终止',
			'about.disclaimerItem6Content' => '开发者保留随时修改、暂停或终止本项目的权利，且无需提前通知用户。开发者不对因项目修改、暂停或终止而导致的任何后果负责。',
			'about.disclaimerItem7Title' => '7. 贡献者责任',
			'about.disclaimerItem7Content' => '如果本项目接受外部贡献，贡献者的行为仅代表其个人立场，不代表开发者的观点或立场。开发者对贡献者的行为及其贡献内容不承担责任。',
			'about.disclaimerItem8Title' => '8. 法律合规性',
			'about.disclaimerItem8Content' => '用户在使用本项目时，应确保其行为符合所在国家或地区的法律法规。开发者不对用户因违反法律法规而导致的任何后果负责。',
			'about.disclaimerImportant' => '重要提示',
			'about.disclaimerImportantContent' => '在使用本项目之前，请仔细阅读并理解本免责声明。如果您不同意本声明的任何条款，请立即停止使用本项目。继续使用本项目即表示您已阅读、理解并同意本免责声明的全部内容。',
			'about.checkUpdate' => '检查更新',
			'about.alreadyLatest' => '已是最新版本',
			'about.updateAvailable' => '发现新版本',
			'about.license' => '开源许可',
			'about.privacy' => '隐私政策',
			'oldHome.title' => '首页',
			'oldHome.search' => '搜索',
			'oldHome.hotSearch' => '热搜',
			'oldHome.navigation' => '导航',
			'oldHome.recommend' => '推荐',
			'oldHome.latest' => '最新',
			'oldHome.cloudFavorite' => '云端收藏',
			'oldHome.list' => '列表',
			'oldHome.function' => '功能',
			'oldHome.close' => '关闭',
			'oldHome.loadFailedRetry' => '加载失败，请重试。',
			'oldHome.loadSectionFailed' => ({required Object title, required Object error}) => '加载 ${title} 失败\n${error}',
			'oldHome.empty' => '暂无内容',
			'oldHome.loadMoreFailed' => '加载更多失败，点击重试',
			'oldHome.loadMore' => '点击加载更多',
			'oldHome.noMore' => '没有更多了',
			'more.common' => '常用',
			'more.others' => '其他',
			'more.downloadTasks' => '下载任务',
			'more.comicFollow' => '追更',
			'more.changelog' => '更新日志',
			'search.title' => '搜索',
			'search.searchHint' => '搜索...',
			'search.selectSource' => '选择漫画源',
			'search.advancedSearchNotSupported' => '当前插件不支持高级搜索',
			'search.advancedSearchOptions' => '高级搜索选项',
			'search.notSelected' => '未选择',
			'search.selectedCount' => ({required Object count}) => '已选择 ${count} 项',
			'search.history' => '搜索历史',
			'search.clearHistory' => '清空历史',
			'search.newestFirst' => '当前：最近搜索在前',
			'search.oldestFirst' => '当前：最早搜索在前',
			'search.descending' => '时间倒序',
			'search.ascending' => '时间正序',
			'search.noHistory' => '暂无搜索记录',
			'search.tipsTitle' => '🔍 搜索技巧',
			'search.exactSearchTitle' => '精准搜索（同时满足）',
			'search.exactSearchExample' => '全彩(空格)+人妻',
			'search.exactSearchDesc' => '显示同时包含这两个标签的结果',
			'search.excludeSearchTitle' => '排除搜索（不要某类）',
			'search.excludeSearchExample' => '全彩(空格)-人妻',
			'search.excludeSearchDesc' => '显示"全彩"但排除含"人妻"的结果',
			'search.fuzzySearchTitle' => '模糊搜索（包含任一）',
			'search.fuzzySearchExample' => '全彩(空格)人妻',
			'search.fuzzySearchDesc' => '显示包含任意一个关键词的结果',
			'search.selectCategory' => '选择分类',
			'search.dataSource' => '数据来源',
			'search.sortBy' => '排序方式',
			'search.newestToOldest' => '从新到旧',
			'search.oldestToNewest' => '从旧到新',
			'search.mostLikes' => '最多点赞',
			'search.mostViews' => '最多观看',
			'search.selectSourceTooltip' => '选择漫画源',
			'search.hasResults' => '有结果',
			'search.showErrors' => '显示错误',
			'search.resultCount' => ({required Object count}) => '${count} 条',
			'search.noResults' => '无结果',
			'search.loadFailedForSource' => ({required Object source}) => '${source} 加载失败',
			'discover.title' => '发现',
			'discover.search' => '搜索',
			'discover.settings' => '设置',
			'discover.pluginManagement' => '插件管理',
			'discover.noPlugins' => '暂无可用插件，去插件商店安装一个吧~',
			'discover.pluginStore' => '插件商店',
			'discover.browseInstall' => '浏览安装',
			'discover.noPluginForSearch' => '暂无可用插件，无法搜索',
			'discover.pluginInfoLoadFailed' => ({required Object error}) => '插件信息加载失败: ${error}',
			'discover.pluginCapability' => '插件能力',
			'discover.disabled' => '已关闭',
			'discover.unnamed' => '未命名',
			'discover.pluginEnableFailed' => ({required Object error}) => '插件启用失败: ${error}',
			'discover.pluginCloseFailed' => ({required Object error}) => '插件关闭失败: ${error}',
			'discover.pluginDebugLoadFailed' => ({required Object error}) => '插件调试加载失败，已回退数据库: ${error}',
			'searchResult.enterPageNumber' => '输入页数',
			'searchResult.pleaseEnterNumber' => '请输入数字',
			'searchResult.returnToTop' => '返回顶部',
			'searchResult.jumpToPage' => '跳转页面',
			'searchResult.jump' => '跳转',
			'searchResult.retry' => '点击重试',
			'comicList.defaultTitle' => '漫画列表',
			'comicList.missingSource' => '缺少插件来源，无法加载列表',
			'comicList.reload' => '重新加载',
			'comicList.loadFailedRetry' => '加载失败，请重试。',
			'comicList.nothingHere' => '啥都没有',
			'comicList.filter' => '筛选',
			'comicList.subCategory' => '子分类',
			'comicList.levelCategory' => ({required Object level}) => '第${level}级分类',
			'comicList.missingListConfig' => '缺少列表请求配置',
			'comicList.missingFnPath' => '列表请求缺少 fnPath',
			'comicEntry.updatedAt' => ({required Object time}) => '更新: ${time}',
			'comicEntry.finished' => '完结',
			'comicEntry.ongoing' => '连载中',
			'comicEntry.likes' => ({required Object count}) => '喜欢 ${count}',
			'comicEntry.views' => ({required Object count}) => '浏览 ${count}',
			'comicEntry.deleteFavorite' => '删除收藏',
			'comicEntry.deleteFavoriteConfirm' => ({required Object title}) => '确定要删除（${title}）的收藏记录吗？',
			'comicEntry.deleteHistory' => '删除历史记录',
			'comicEntry.deleteHistoryConfirm' => ({required Object title}) => '确定要删除（${title}）的历史记录吗？',
			'comicEntry.deleteDownload' => '删除下载记录',
			'comicEntry.deleteDownloadConfirm' => ({required Object title}) => '确定要删除（${title}）的下载记录及文件吗？',
			'comicEntry.deleteFailed' => '删除失败',
			'comicFollow.title' => '追更',
			'comicFollow.loadFailed' => ({required Object result}) => '加载失败：${result}',
			'comicFollow.empty' => '暂无追更漫画',
			'comicFollow.emptyHint' => '在漫画详情页点击追更按钮即可加入',
			'comicFollow.unfollow' => '取消追更',
			'comicFollow.unfollowConfirm' => ({required Object title}) => '确定不再追更《${title}》吗？',
			'comicFollow.unfollowed' => '已取消追更',
			'comicFollow.latestChapterFailed' => '最新章节获取失败',
			'comicFollow.newChapters' => ({required Object diff, required Object total}) => '新增 ${diff} 话，共 ${total} 话',
			'comicFollow.latestCount' => ({required Object count}) => '最新 ${count} 话',
			'comicFollow.fetchFailed' => '获取失败',
			'comicFollow.newChaptersShort' => ({required Object diff}) => '新增 ${diff} 话',
			'comicFollow.update' => '更新',
			'comicFollow.retry' => '重试',
			'comicFollow.updateChannelName' => '漫画更新提醒',
			'comicFollow.updateChannelDesc' => '追更漫画检测到新章节时推送',
			'comicFollow.updateTitle' => '追更更新',
			'comicFollow.updateBodySingle' => '有 1 部追更漫画更新了',
			'comicFollow.updateBodyMultiple' => ({required Object count}) => '有 ${count} 部追更漫画更新了',
			'changelog.title' => '更新日志',
			'changelog.loadFailed' => '加载失败',
			'changelog.loadFailedWithError' => ({required Object error}) => '加载失败: ${error}',
			'changelog.cannotOpenLink' => ({required Object url}) => '无法打开链接: ${url}',
			'changelog.checkNetwork' => '加载失败，请检查网络',
			'changelog.retry' => '重试',
			'changelog.empty' => '暂无更新日志',
			'changelog.publishedAt' => ({required Object date}) => '发布于 ${date}',
			'changelog.viewInBrowser' => '在浏览器中查看',
			'changelog.attachments' => '附件下载',
			'webview.title' => '网页',
			'webview.cannotOpenLink' => ({required Object uri}) => '无法打开链接: ${uri}',
			'webview.invalidLink' => '链接无效，无法打开网页',
			'webview.emptyLink' => '(空链接)',
			'webview.loadFailed' => '网页加载失败',
			'webview.retry' => '重试',
			'webview.openInExternalBrowser' => '外部浏览器打开',
			'webview.windowClosed' => 'WebView 窗口已关闭',
			'webview.openedInExternalWindow' => '网页已在独立窗口中打开',
			'webview.back' => '返回',
			'webview.closeWindow' => '关闭 WebView 窗口',
			'webview.loadError' => ({required Object error}) => '加载失败（${error}）',
			'webview.httpErrorStatus' => ({required Object statusCode}) => '服务器返回异常状态码：${statusCode}',
			'oldRanking.bikaRanking' => '哔咔排行榜',
			'oldRanking.jmRanking' => '禁漫排行榜',
			'oldRanking.switchSource' => '切换',
			'login.title' => '登录',
			'login.missingPluginId' => '缺少插件标识，无法打开登录页',
			'login.loadConfigFailed' => ({required Object error}) => '登录配置加载失败: ${error}',
			'login.insufficientFields' => '插件返回的登录字段不足',
			'login.invalidCredentials' => '用户名或密码错误，请重新输入',
			'login.configNotReady' => '登录配置未就绪，请稍后重试',
			'login.loggingIn' => '正在登录，请耐心等待...',
			'login.loginSuccess' => '登录成功',
			'login.loginFailed' => '登录失败',
			'login.loginButton' => '登录',
			'login.retry' => '重试',
			'fontSetting.title' => '字体设置',
			'fontSetting.clear' => '清空',
			'fontSetting.hint' => '按字重分别选择字体文件。',
			'fontSetting.loadFailed' => '字体加载失败',
			'fontSetting.cleared' => '已清除',
			'fontSetting.saved' => '已保存',
			'fontSetting.allCleared' => '已清空',
			'fontSetting.noFileSelected' => '未选择文件',
			'fontSetting.clearFile' => '清除',
			'fontSetting.selectFile' => '选择文件',
			'fontSetting.sampleText' => 'Innovation in China 中国智造，慧及全球 0123456789',
			'download.title' => '下载任务',
			'download.startDownload' => '开始下载',
			'download.selectChaptersPrompt' => '请选择要下载的章节',
			'download.taskStarted' => '下载任务已启动',
			'download.taskStartFailed' => ({required Object error}) => '下载任务启动失败，${error}',
			'download.noTasks' => '暂无下载任务',
			'download.downloading' => '正在下载',
			'download.pending' => ({required Object count}) => '等待中 (${count})',
			_ => null,
		} ?? switch (path) {
			'download.taskDeleted' => '已删除任务',
			'download.cancelTask' => '取消任务',
			'download.cancelTaskConfirm' => ({required Object comicName}) => '确定要取消下载 ${comicName} 吗？',
			'download.paused' => '已暂停',
			'download.completed' => '已完成',
			'download.failed' => '失败',
			'download.startAll' => '全部开始',
			'download.pauseAll' => '全部暂停',
			'download.clearCompleted' => '清除已完成',
			'download.statusFetchingComicInfo' => '获取漫画信息中...',
			'download.statusDownloadingCover' => '下载封面中...',
			'download.statusFetchingChapterInfo' => '获取章节信息中...',
			'download.statusFetchingChapterInfoProgress' => ({required Object completed, required Object total, required Object percent}) => '获取章节信息中... (${completed}/${total}, ${percent}%)',
			'download.statusDownloadProgress' => ({required Object percent}) => '漫画下载进度: ${percent}%',
			'download.statusDownloadProgressComplete' => '漫画下载进度: 100%',
			'download.statusStartDownload' => '开始下载...',
			'download.statusWaiting' => '等待中',
			'download.statusCancelling' => '取消中...',
			'download.toastDownloadComplete' => ({required Object comicName}) => '${comicName} 下载完成',
			'download.toastDownloadFailed' => ({required Object comicName, required Object error}) => '${comicName} 下载失败 ${error}',
			'download.toastTaskAlreadyExists' => ({required Object comicName}) => '${comicName} 任务已存在',
			'download.notificationCompleteTitle' => '下载完成',
			'download.notificationFailedTitle' => '下载失败',
			'foregroundTask.channelName' => '前台任务',
			'foregroundTask.channelDescription' => '用于下载保活与后台保活，保持应用在后台继续运行',
			'foregroundTask.waitingForTask' => '等待下载任务中...',
			'foregroundTask.keepAliveRunning' => '正在保持后台运行',
			'foregroundTask.cancel' => '取消',
			'foregroundTask.notificationPermissionRequired' => '需要通知权限来启动前台任务，请在系统弹窗中允许通知权限',
			'foregroundTask.cannotStartWithoutPermission' => '无法启动前台任务：请先在系统设置中开启通知权限',
			'foregroundTask.startFailed' => ({required Object error}) => '前台服务启动失败: ${error}',
			'notification.permissionRequired' => '请开启通知权限',
			'notification.macPermissionRequired' => '请在系统设置中开启通知权限',
			'update.newVersion' => '发现新版本',
			'update.goToGitHub' => '前往GitHub',
			'update.downloadInstall' => '下载安装',
			'update.apkDownloadFailed' => '下载失败，请稍后再试！',
			'update.installPermissionRequired' => '请授予安装应用权限！',
			'update.unknownArch' => '未知',
			'dialog.hideOrClose' => '隐藏到托盘或关闭程序',
			'dialog.rememberChoice' => '记住我的选择',
			_ => null,
		};
	}
}
