///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsEnUs extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEnUs({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.enUs,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en-US>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsEnUs _root = this; // ignore: unused_field

	@override 
	TranslationsEnUs $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEnUs(meta: meta ?? this.$meta);

	// Translations
	@override String get appName => 'Breeze';
	@override late final _Translations$common$en_US common = _Translations$common$en_US._(_root);
	@override late final _Translations$error$en_US error = _Translations$error$en_US._(_root);
	@override late final _Translations$navigation$en_US navigation = _Translations$navigation$en_US._(_root);
	@override late final _Translations$settings$en_US settings = _Translations$settings$en_US._(_root);
	@override late final _Translations$bookshelf$en_US bookshelf = _Translations$bookshelf$en_US._(_root);
	@override late final _Translations$comicInfo$en_US comicInfo = _Translations$comicInfo$en_US._(_root);
	@override late final _Translations$reader$en_US reader = _Translations$reader$en_US._(_root);
	@override late final _Translations$plugin$en_US plugin = _Translations$plugin$en_US._(_root);
	@override late final _Translations$gestureLock$en_US gestureLock = _Translations$gestureLock$en_US._(_root);
	@override late final _Translations$appBootstrap$en_US appBootstrap = _Translations$appBootstrap$en_US._(_root);
	@override late final _Translations$comments$en_US comments = _Translations$comments$en_US._(_root);
	@override late final _Translations$cache$en_US cache = _Translations$cache$en_US._(_root);
	@override late final _Translations$dataBackup$en_US dataBackup = _Translations$dataBackup$en_US._(_root);
	@override late final _Translations$webdavSync$en_US webdavSync = _Translations$webdavSync$en_US._(_root);
	@override late final _Translations$realSr$en_US realSr = _Translations$realSr$en_US._(_root);
	@override late final _Translations$about$en_US about = _Translations$about$en_US._(_root);
	@override late final _Translations$oldHome$en_US oldHome = _Translations$oldHome$en_US._(_root);
	@override late final _Translations$more$en_US more = _Translations$more$en_US._(_root);
	@override late final _Translations$search$en_US search = _Translations$search$en_US._(_root);
	@override late final _Translations$discover$en_US discover = _Translations$discover$en_US._(_root);
	@override late final _Translations$searchResult$en_US searchResult = _Translations$searchResult$en_US._(_root);
	@override late final _Translations$comicList$en_US comicList = _Translations$comicList$en_US._(_root);
	@override late final _Translations$comicEntry$en_US comicEntry = _Translations$comicEntry$en_US._(_root);
	@override late final _Translations$comicFollow$en_US comicFollow = _Translations$comicFollow$en_US._(_root);
	@override late final _Translations$changelog$en_US changelog = _Translations$changelog$en_US._(_root);
	@override late final _Translations$webview$en_US webview = _Translations$webview$en_US._(_root);
	@override late final _Translations$oldRanking$en_US oldRanking = _Translations$oldRanking$en_US._(_root);
	@override late final _Translations$login$en_US login = _Translations$login$en_US._(_root);
	@override late final _Translations$fontSetting$en_US fontSetting = _Translations$fontSetting$en_US._(_root);
	@override late final _Translations$download$en_US download = _Translations$download$en_US._(_root);
	@override late final _Translations$foregroundTask$en_US foregroundTask = _Translations$foregroundTask$en_US._(_root);
	@override late final _Translations$notification$en_US notification = _Translations$notification$en_US._(_root);
	@override late final _Translations$update$en_US update = _Translations$update$en_US._(_root);
	@override late final _Translations$dialog$en_US dialog = _Translations$dialog$en_US._(_root);
}

// Path: common
class _Translations$common$en_US extends Translations$common$zh_CN {
	_Translations$common$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get ok => 'OK';
	@override String get cancel => 'Cancel';
	@override String get save => 'Save';
	@override String get delete => 'Delete';
	@override String get edit => 'Edit';
	@override String get rename => 'Rename';
	@override String get add => 'Add';
	@override String get create => 'Create';
	@override String get refresh => 'Refresh';
	@override String get loading => 'Loading...';
	@override String get loadingFailed => 'Loading failed';
	@override String get retry => 'Retry';
	@override String get reload => 'Reload';
	@override String get confirm => 'Confirm';
	@override String get close => 'Close';
	@override String get back => 'Back';
	@override String get help => 'Help';
	@override String get gotIt => 'Got it';
	@override String get underConstruction => 'Under construction';
	@override String get comingSoon => 'Coming soon';
	@override String get root => 'Root';
	@override String get remove => 'Remove';
	@override String get overwrite => 'Overwrite';
	@override String get cancelled => 'Cancelled';
	@override String get search => 'Search';
	@override String get clear => 'Clear';
	@override String get copy => 'Copy';
	@override String get paste => 'Paste';
	@override String get share => 'Share';
	@override String get open => 'Open';
	@override String get download => 'Download';
	@override String get upload => 'Upload';
	@override String get import => 'Import';
	@override String get export => 'Export';
	@override String get success => 'Success';
	@override String get failed => 'Failed';
	@override String get error => 'Error';
	@override String get warning => 'Warning';
	@override String get info => 'Info';
	@override String get unknown => 'Unknown';
	@override String get empty => 'No data';
	@override String get all => 'All';
	@override String get none => 'None';
	@override String get default_ => 'Default';
	@override String get custom => 'Custom';
	@override String get enabled => 'Enabled';
	@override String get disabled => 'Disabled';
	@override String get followSystem => 'Follow system';
	@override String get lightMode => 'Light mode';
	@override String get darkMode => 'Dark mode';
	@override String get system => 'System';
	@override String get apply => 'Apply';
	@override String get reset => 'Reset';
	@override String get next => 'Next';
	@override String get previous => 'Previous';
	@override String get done => 'Done';
	@override String get select => 'Select';
	@override String get selected => 'Selected';
	@override String get deselect => 'Deselect';
	@override String get selectAll => 'Select all';
	@override String get yes => 'Yes';
	@override String get no => 'No';
	@override String get on => 'On';
	@override String get off => 'Off';
	@override String get more => 'More';
	@override String get detail => 'Details';
	@override String get settingSaved => 'Settings saved';
	@override String get restartToTakeEffect => 'Setting saved, restart to take effect';
}

// Path: error
class _Translations$error$en_US extends Translations$error$zh_CN {
	_Translations$error$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get generic => 'Something went wrong';
	@override String get network => 'Network error';
	@override String get downloadFailed => 'Download failed';
	@override String importFailed({required Object error}) => 'Import failed: ${error}';
	@override String get loadFailed => 'Loading failed';
	@override String get saveFailed => 'Save failed';
	@override String get permissionDenied => 'Permission denied';
	@override String get notFound => 'Not found';
	@override String get unsupportedPlatform => 'This feature is not supported on the current platform';
	@override String missingPluginSource({required Object action}) => 'Missing plugin source, cannot ${action}';
	@override String get operationFailed => 'Operation failed';
	@override String get executionFailed => 'Execution failed';
}

// Path: navigation
class _Translations$navigation$en_US extends Translations$navigation$zh_CN {
	_Translations$navigation$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get home => 'Home';
	@override String get rank => 'Rank';
	@override String get bookshelf => 'Bookshelf';
	@override String get discover => 'Discover';
	@override String get more => 'More';
	@override String get syncSuccess => 'Sync successful!';
	@override String get autoSyncSuccess => 'Auto sync successful!';
	@override String get syncFailed => 'Sync failed';
	@override String get autoSyncFailed => 'Auto sync failed';
	@override String syncFailedMessage({required Object error}) => 'Please check your network connection or try again later.\n${error}';
	@override String get loginExpired => 'Login expired, please log in again';
}

// Path: settings
class _Translations$settings$en_US extends Translations$settings$zh_CN {
	_Translations$settings$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Settings';
	@override String get globalTitle => 'Settings';
	@override String get appearance => 'Appearance';
	@override String get theme => 'Theme mode';
	@override String get themeSubtitle => 'Choose strategy to switch light/dark theme';
	@override String get themeColor => 'Theme color';
	@override String get themeColorSubtitle => 'Choose primary color for the app';
	@override String get language => 'Language';
	@override String get languageSubtitle => 'Change app display language';
	@override String get followSystemLanguage => 'Follow system';
	@override String get languageZhCn => '简体中文 (zh_CN)';
	@override String get languageEnUs => 'English (en_US)';
	@override String get languageChangedRestartHint => 'Language setting saved. Restart the app for changes to fully take effect.';
	@override String get dynamicColor => 'Dynamic color';
	@override String get dynamicColorSubtitle => 'Extract primary color from content automatically';
	@override String get fontSettings => 'Font settings';
	@override String get fontSettingsSubtitle => 'Customize display font';
	@override String get amoled => 'AMOLED black';
	@override String get amoledSubtitle => 'Use pure black background for AMOLED screens';
	@override String get notchAdaptation => 'Notch adaptation';
	@override String get notchAdaptationSubtitle => 'Reserve safe area to avoid content being obscured';
	@override String get contentAndNetwork => 'Content & Network';
	@override String get content => 'Content';
	@override String get network => 'Network';
	@override String get maskedKeywords => 'Masked keywords';
	@override String get maskedKeywordsSubtitle => 'Add keywords to filter unwanted content (search only)';
	@override String get maskedKeywordsEmpty => 'No masked keywords';
	@override String get maskedKeywordsInputHint => 'Enter new keyword...';
	@override String get chineseConvert => 'Chinese conversion';
	@override String get chineseConvertSubtitle => 'Convert comic titles, descriptions, chapters and comments';
	@override String get chineseConvertOff => 'Off';
	@override String get chineseConvertSimplified => 'Simplified Chinese';
	@override String get chineseConvertTraditional => 'Traditional Chinese';
	@override String get proxy => 'SOCKS5 Proxy';
	@override String get proxySubtitle => 'Configure SOCKS5 proxy';
	@override String get proxyEnabledSubtitle => 'Disable to stop using SOCKS5 proxy';
	@override String get proxyAddress => 'Proxy address';
	@override String get proxyHint => 'Enter SOCKS5 proxy address';
	@override String proxyCurrent({required Object currentProxy}) => 'Current proxy: ${currentProxy}';
	@override String get updateAccelerate => 'Update acceleration';
	@override String get updateAccelerateSubtitle => 'Use proxy to accelerate GitHub update links';
	@override String get sync => 'Sync';
	@override String get syncConfig => 'Sync config';
	@override String get syncConfigSubtitle => 'Enter page to configure address and auth';
	@override String get syncService => 'Sync service';
	@override String get syncServiceSubtitle => 'Choose service to manage sync strategy';
	@override String get syncServiceNone => 'Disabled';
	@override String get syncServiceWebdav => 'WebDAV';
	@override String get syncServiceS3 => 'S3';
	@override String get autoSync => 'Auto sync';
	@override String get autoSyncSubtitle => 'Sync configuration periodically in background';
	@override String get syncNotify => 'Sync notifications';
	@override String get syncNotifySubtitle => 'Notify when sync starts and completes';
	@override String get syncSettings => 'Sync settings';
	@override String get syncSettingsSubtitle => 'Use cloud settings to override local settings';
	@override String get syncPlugins => 'Sync plugins';
	@override String get syncPluginsSubtitle => 'Sync plugin configuration and installation status';
	@override String get appBehavior => 'App behavior';
	@override String get splashPage => 'Startup page';
	@override String get splashPageSubtitle => 'Choose startup page to open directly';
	@override String get desktopCloseBehavior => 'Close behavior';
	@override String get desktopCloseBehaviorSubtitle => 'Choose behavior when clicking close button';
	@override String get desktopCloseAsk => 'Ask';
	@override String get desktopCloseHide => 'Hide to tray';
	@override String get desktopCloseClose => 'Close directly';
	@override String get showMainWindow => 'Show main window';
	@override String get exitApp => 'Exit';
	@override String get appLock => 'App lock';
	@override String get appLockSubtitle => 'Require verification when entering the app';
	@override String get oldPageRollback => 'Old home page';
	@override String get oldPageRollbackSubtitle => 'Use old home page layout';
	@override String get customExportPath => 'Custom export path';
	@override String get storage => 'Storage';
	@override String get cache => 'Cache';
	@override String get clearCache => 'Clear cache';
	@override String get clearCacheConfirm => 'Are you sure you want to clear all cache files? This action cannot be undone.';
	@override String get calculatingCache => 'Calculating...';
	@override String get calculateCacheFailed => 'Calculate failed';
	@override String get dataBackup => 'Data Import/Export';
	@override String get dataBackupSubtitle => 'Backup or restore app data and downloaded comics';
	@override String get includeDownloaded => 'Include downloaded comics';
	@override String get includeDownloadedSubtitle => 'Pack downloaded comic files when exporting';
	@override String get exportData => 'Export data';
	@override String get importData => 'Import data';
	@override String get imageProcessing => 'Image processing';
	@override String get realSr => 'Image Super-Resolution (Experimental)';
	@override String get realSrSubtitle => 'Experimental feature, may be unstable';
	@override String get autoRealSr => 'Auto super-resolution';
	@override String get resolutionThreshold => 'Resolution threshold';
	@override String get debug => 'Debug';
	@override String get logAddress => 'Log forward address';
	@override String get logAddressSubtitle => 'Forward logs to specified address in real time';
	@override String get memoryDebug => 'Memory debug';
	@override String get memoryDebugSubtitle => 'Show memory usage on interface';
	@override String get forceEnableImpeller => 'Force enable Impeller';
	@override String get forceEnableImpellerSubtitle => 'Android experimental rendering backend';
	@override String get colorPreview => 'Color preview';
	@override String get colorPreviewSubtitle => 'Open color picker page for quick preview';
	@override String get qjsRuntimeDebug => 'QJS runtime debug';
	@override String get qjsRuntimeDebugSubtitle => 'Enter runtime ID to capture debug snapshot';
	@override String get qjsRuntimeSnapshot => 'Debug snapshot';
	@override String get qjsRuntimeIdLabel => 'Runtime ID';
	@override String get qjsRuntimeIdHint => 'e.g. 0a0e5858-a467-4702-994a-79e608a4589d';
	@override String get qjsRuntimeCapture => 'Capture snapshot';
	@override String get qjsRuntimeCapturing => 'Capturing...';
	@override String get qjsRuntimeCopyOutput => 'Copy output';
	@override String get qjsRuntimeNoOutput => 'No output yet';
	@override String get qjsRuntimeFillId => 'Please enter a runtime ID first';
	@override String qjsRuntimeCapturedAt({required Object dateTime}) => 'Captured at ${dateTime}';
	@override String qjsRuntimeCaptureFailed({required Object error}) => 'Capture failed: ${error}';
	@override String get qjsRuntimeNoCopyContent => 'No content to copy';
	@override String get qjsRuntimeCopied => 'Copied to clipboard';
	@override String get colorPreviewVariableFont => 'Variable Font test';
	@override String colorPreviewFontLoaded({required Object path}) => 'Loaded: ${path}';
	@override String get colorPreviewNoFont => 'No font loaded. Try the recommended sample or pick a TTF/OTF file.';
	@override String get colorPreviewLoadRecommended => 'Load recommended sample';
	@override String get colorPreviewSelectFont => 'Select font file';
	@override String get colorPreviewByWeight => 'Render by fontWeight';
	@override String get colorPreviewByVariableAxis => 'Render by variable axis';
	@override String get colorPreviewSystemDefault => 'System default font reference';
	@override String get colorPreviewLoadingFont => 'Loading font...';
	@override String get colorPreviewLoadSuccess => 'Font loaded. Compare different weights.';
	@override String colorPreviewLoadFailed({required Object error}) => 'Font load failed: ${error}';
	@override String get colorRed => 'Red';
	@override String get colorPink => 'Pink';
	@override String get colorPurple => 'Purple';
	@override String get colorDeepPurple => 'Deep purple';
	@override String get colorIndigo => 'Indigo';
	@override String get colorBlue => 'Blue';
	@override String get colorLightBlue => 'Light blue';
	@override String get colorCyan => 'Cyan';
	@override String get colorTeal => 'Teal';
	@override String get colorGreen => 'Green';
	@override String get colorLightGreen => 'Light green';
	@override String get colorLime => 'Lime';
	@override String get colorYellow => 'Yellow';
	@override String get colorAmber => 'Amber';
	@override String get colorOrange => 'Orange';
	@override String get colorDeepOrange => 'Deep orange';
	@override String get colorBrown => 'Brown';
	@override String get colorGrey => 'Grey';
	@override String get colorBlueGrey => 'Blue grey';
	@override String get coremlDebug => 'CoreML upscale debug';
	@override String get coremlDebugSubtitle => 'Test CoreML upscale with absolute path model';
	@override String get aboutAndMore => 'About & More';
	@override String get changelog => 'Changelog';
	@override String get changelogSubtitle => 'View update records for each version';
	@override String get aboutApp => 'About app';
	@override String get aboutAppSubtitle => 'Detailed information about Breeze';
	@override String get pluginManagement => 'Plugin management';
	@override String get debugMode => 'Debug mode';
	@override String get debugAddress => 'Debug address';
	@override String get notSet => 'Not set';
}

// Path: bookshelf
class _Translations$bookshelf$en_US extends Translations$bookshelf$zh_CN {
	_Translations$bookshelf$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bookshelf';
	@override String get favorite => 'Favorites';
	@override String get history => 'History';
	@override String get download => 'Downloads';
	@override String get filter => 'Filter';
	@override String get searchList => 'Search list';
	@override String get newFolder => 'New folder';
	@override String get manage => 'Manage';
	@override String get importComic => 'Import comic';
	@override String get folderHint => 'Bookshelf hints';
	@override String get removeFromFolder => 'Remove from folder';
	@override String get deleteFavorite => 'Remove favorite';
	@override String get deleteHistory => 'Delete history';
	@override String get deleteDownload => 'Delete download record';
	@override String confirmDeleteSelected({required Object count}) => 'Are you sure you want to delete the selected ${count} records?';
	@override String deletedRecords({required Object count}) => 'Deleted ${count} records';
	@override String get noFilterSource => 'No filterable plugin sources';
	@override String get sort => 'Sort';
	@override String get sortDesc => 'Time (newest first)';
	@override String get sortAsc => 'Time (oldest first)';
	@override String get folderDeprecated => 'Folders (deprecated)';
	@override String get source => 'Comic source';
	@override String get deselectAll => 'Deselect all';
	@override String get deleteFolder => 'Delete folder';
	@override String get renameFolder => 'Rename folder';
	@override String confirmDeleteFolder({required Object name}) => 'Delete folder "${name}"?';
	@override String get folderAction => 'Please select an action';
	@override String get createFolder => 'Create folder';
	@override String get createFolderHint => 'Enter folder name';
	@override String get multiSelect => 'Multi-select';
	@override String get copyTo => 'Copy to';
	@override String get batchExport => 'Batch export';
	@override String get batchDeleteFailed => 'Batch delete failed';
	@override String get deleteSelected => 'Delete selected';
	@override String get cancel => 'Cancel selection';
	@override String get addToFavorite => 'Add to favorites';
	@override String get addToDownloadFolder => 'Add to download folder';
	@override String get createFavoriteFolderFirst => 'Please create a custom favorite folder first';
	@override String get addedToFavorite => 'Added to favorites';
	@override String get createDownloadFolderFirst => 'Please create a custom download folder first';
	@override String get addedToDownloadFolder => 'Added to download folder';
	@override String get selectFavoriteFolder => 'Select favorite folders (multiple)';
	@override String get selectDownloadFolder => 'Select download folders (multiple)';
	@override String selectedCount({required Object count}) => 'Selected ${count} items';
	@override String get selectTargetFolder => 'Select target folders (multiple)';
	@override String get confirmDeleteFolderTitle => 'Confirm delete';
	@override String get confirmDeleteFolderContent => 'Delete this folder? Contents will be deleted recursively.';
	@override String get confirmRemoveComicTitle => 'Remove from folder';
	@override String confirmRemoveComicContent({required Object title}) => 'Remove "${title}" from current folder?';
	@override String get importStarted => 'Importing comics (zip only)';
	@override String importCompleted({required Object title}) => 'Import completed: ${title}';
	@override String get comicExists => 'Comic already exists';
	@override String confirmOverwriteImport({required Object title}) => '${title} already exists in download list. Overwrite?';
	@override String get noExportableComics => 'No exportable comics in selection';
	@override String batchExportCompleted({required Object success, required Object total}) => 'Batch export completed: ${success}/${total}';
	@override String batchExportFailed({required Object error}) => 'Batch export failed: ${error}';
	@override String get confirmDeleteSelectedTitle => 'Confirm delete';
	@override String get confirmDeleteSelectedContent => 'Delete selected folders and comics? Folders will be deleted recursively.';
	@override String get cancelSelect => 'Cancel selection';
	@override String get selectAll => 'Select all';
	@override String get moveTo => 'Move to';
	@override String get addToFolder => 'Add to folder';
	@override String get folderName => 'Folder name';
	@override String get folderNameHint => 'Enter folder name';
	@override String get helpContent => '• Favorites and bookshelf are linked: favoriting a comic adds it to the bookshelf; only removing it from all favorite folders unfavorites it.\n• On comic detail page, unfavorite removes it from all favorite folders at once.\n• Same for downloads: only removing a comic from all download folders deletes its downloaded files.';
	@override String get folderCreated => 'Folder created';
	@override String get noComic => 'No comics yet';
	@override String get noHistory => 'No reading history yet';
	@override String get noDownload => 'No downloads yet';
	@override String get nothingHere => 'Nothing here';
	@override String get deleteAllDownloadRecordsAndFiles => 'Delete all download records and files';
	@override String get clearHistoryRecords => 'Clear history records';
	@override String get confirmDeleteAllDownloadsContent => 'Delete all download records and their files? This action cannot be undone!';
	@override String get confirmClearHistoryContent => 'Clear all history records? This action cannot be undone!';
	@override String get allDownloadRecordsAndFilesDeleted => 'All download records and files deleted';
	@override String get historyRecordsCleared => 'History records cleared';
	@override String get batchExportTitle => 'Choose export method';
	@override String get batchExportSubtitle => 'Please choose batch export as zip or folder';
	@override String get importCancelled => 'Import cancelled';
	@override String importEpisodeFallback({required Object index}) => 'Ep. ${index}';
	@override String get importMissingJson => 'Import directory is missing required JSON files';
	@override String get importVersionUnsupported => 'This version cannot be imported, please export with a newer app version';
	@override String get importMissingSource => 'Export file is missing source info, please re-export with a newer app version';
	@override String get importMissingComicId => 'Cannot get comic ID';
	@override String get importNoComicDir => 'No importable comic directory found in the archive';
	@override String get importMultipleComicDirs => 'Archive contains multiple comic directories, please import one at a time';
	@override String importComicExistsUncovered({required Object title}) => 'Comic "${title}" already exists, import skipped';
	@override String get folderNameEmpty => 'Folder name cannot be empty';
	@override String get folderNameSlash => 'Folder name cannot contain /';
	@override String get folderNameExists => 'A folder with the same name already exists in this path';
	@override String targetFolderNameExists({required Object name}) => 'A folder with the same name already exists at target: ${name}';
	@override String get cannotMoveFolderToSelf => 'Cannot move a folder into itself';
	@override String get cannotMoveParentToChild => 'Cannot move a parent folder into its subfolder';
	@override String get cannotCopyFolderToSelfOrChild => 'Cannot copy a folder into itself or its subfolders';
	@override String get moveFoldersOnlyOneTarget => 'Only one target folder can be selected when moving folders';
	@override String get favoriteFolderNameEmpty => 'Favorite folder name cannot be empty';
	@override String get favoriteFolderNameExists => 'A favorite folder with the same name already exists';
	@override String get downloadFolderNameEmpty => 'Download folder name cannot be empty';
	@override String get downloadFolderNameExists => 'A download folder with the same name already exists';
	@override String get removeFromFavoriteFolder => 'Remove from favorite folder';
	@override String get removeFromDownloadFolder => 'Remove from download folder';
	@override String get confirmRemoveFromCurrentFolder => 'Remove from current folder?';
	@override String confirmDeleteSelectedFavorites({required Object count}) => 'Delete selected ${count} favorite records?';
	@override String confirmDeleteSelectedHistory({required Object count}) => 'Delete selected ${count} history records?';
	@override String confirmDeleteSelectedDownloads({required Object count}) => 'Delete selected ${count} download records and files?';
}

// Path: comicInfo
class _Translations$comicInfo$en_US extends Translations$comicInfo$zh_CN {
	_Translations$comicInfo$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get follow => 'Follow updates';
	@override String get unfollow => 'Unfollow';
	@override String get exportComic => 'Export comic';
	@override String get collectToCloud => 'Collect to cloud';
	@override String get removeCloudCollection => 'Remove cloud collection';
	@override String get cloudCollectDisabled => 'Cloud collection disabled';
	@override String get collectingToCloud => 'Adding to cloud collection...';
	@override String get removingCloudCollection => 'Removing cloud collection...';
	@override String get cloudCollectSuccess => 'Added to cloud collection';
	@override String get cloudUncollectSuccess => 'Removed from cloud collection';
	@override String get discontinued => 'This comic is discontinued';
	@override String likes({required Object count}) => 'Likes ${count}';
	@override String comments({required Object count}) => 'Comments ${count}';
	@override String get collected => 'Collected';
	@override String get collect => 'Collect';
	@override String get download => 'Download';
	@override String get downloadForbidden => 'Download forbidden';
	@override String get addedToCollection => 'Added to collection';
	@override String get removedFromCollection => 'Removed from collection';
	@override String get confirmUncollectTitle => 'Remove collection';
	@override String get confirmUncollectContent => 'This will delete the comic from all folders. Continue?';
	@override String get commentForbidden => 'Comments are disabled for this comic';
	@override String get commentForbiddenTitle => 'Comments disabled';
	@override String get back => 'Back';
	@override String get exportTitle => 'Choose export format';
	@override String get exportSubtitle => 'Export as folder or zip archive:';
	@override String get folder => 'Folder';
	@override String get zip => 'Zip archive';
	@override String get exportSuccess => 'Export successful';
	@override String get detailsNotLoaded => 'Comic details not fully loaded';
	@override String get followed => 'Following updates';
	@override String get unfollowed => 'Unfollowed';
	@override String get confirmUnfollowTitle => 'Unfollow';
	@override String confirmUnfollowContent({required Object title}) => 'Stop following "${title}"?';
	@override String get noChapters => 'No chapter information';
	@override String get chapterList => 'Chapters';
	@override String episodeCount({required Object count}) => '${count} Episodes';
	@override String episodeFallback({required Object index}) => 'Ep. ${index}';
	@override String episodeLabel({required Object index}) => 'Ep. ${index}';
	@override String get author => 'Author';
	@override String get tags => 'Tags';
	@override String get works => 'Works';
	@override String views({required Object count}) => 'Views: ${count}';
	@override String updateTime({required Object time}) => 'Updated: ${time}';
	@override String get startRead => 'Start reading';
	@override String get continueRead => 'Continue reading';
	@override String get lastRead => 'Last read';
	@override String get chapters => 'Chapters';
	@override String get related => 'Related';
	@override String get description => 'Description';
	@override String get collapse => 'Collapse';
	@override String get expandFullText => 'Read more';
	@override String get readHistory => 'Reading history';
	@override String copied({required Object label}) => 'Copied: ${label}';
	@override String copiedToClipboard({required Object name}) => 'Copied ${name} to clipboard';
	@override String get liking => 'Liking...';
	@override String get unliking => 'Unliking...';
	@override String get likeSuccess => 'Liked';
	@override String get unlikeSuccess => 'Unliked';
	@override String localCollectFailed({required Object error}) => 'Local favorite failed: ${error}';
	@override String likeFailed({required Object error}) => 'Like failed: ${error}';
	@override String loadFailedWithError({required Object error}) => '${error}\nLoading failed, please retry.';
	@override String get exportPermissionDenied => 'All files access permission not granted, export cancelled';
	@override String exportFailedWithError({required Object error}) => 'Export failed, please retry.\n${error}';
	@override String exportDirectory({required Object displayPath}) => 'Export directory: ${displayPath}';
	@override String get exportPathTooLong => 'Export directory path is too long to create a valid structure';
	@override String get zipExportPathTooLong => 'Specified zip export path exceeds system path length limit';
	@override String get downloadPathTooLong => 'Download directory path is too long to create a valid zip file path';
	@override String get uniqueFileNameTooLong => 'Cannot create a unique file name for chapter: path length limit exceeded';
	@override String exportFolderComplete({required Object title}) => 'Exported "${title}" as folder';
	@override String exportZipComplete({required Object title}) => 'Exported "${title}" as zip';
	@override String exportComicNotFound({required Object comicId}) => 'No downloadable comic found for export: ${comicId}';
	@override String get pluginInvalidFavorited => 'Plugin did not return a valid favorited status';
	@override String get pluginInvalidLiked => 'Plugin did not return a valid liked status';
	@override String get addToCustomFolder => 'Add to custom folder';
	@override String addedToFolder({required Object name}) => 'Added to folder: ${name}';
	@override String get skipAdd => 'Skip / Don\'t add';
	@override String get confirmAdd => 'Confirm add';
	@override String resolveComicIdFailed({required Object type}) => 'Cannot resolve comic ID for reading: ${type}';
	@override String resolveEpsCountFailed({required Object type}) => 'Cannot resolve episode count for reading: ${type}';
}

// Path: reader
class _Translations$reader$en_US extends Translations$reader$zh_CN {
	_Translations$reader$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get pageMode => 'Page turn mode';
	@override String get fullscreen => 'Fullscreen';
	@override String get leftHandMode => 'Left-hand mode';
	@override String get rightHandMode => 'Right-hand mode';
	@override String get readingMode => 'Reading mode';
	@override String get infoDisplay => 'Info display';
	@override String get pageNumber => 'Page number';
	@override String get pageNumberSubtitle => 'Show current/total page count';
	@override String get networkStatus => 'Network status';
	@override String get networkStatusSubtitle => 'May be inaccurate on Linux';
	@override String get battery => 'Battery';
	@override String get time => 'Time';
	@override String get verticalPositionTop => 'Top';
	@override String get verticalPositionBottom => 'Bottom';
	@override String get horizontalPositionLeft => 'Left';
	@override String get horizontalPositionCenter => 'Center';
	@override String get horizontalPositionRight => 'Right';
	@override String get readingDirectionLtr => 'Left to right';
	@override String get readingDirectionRtl => 'Right to left';
	@override String get readingDirectionVertical => 'Top to bottom';
	@override String get webtoon => 'Webtoon';
	@override String get singlePageLtr => 'Single page (LTR)';
	@override String get singlePageRtl => 'Single page (RTL)';
	@override String get doublePage => 'Double page';
	@override String get doublePageSubtitle => 'Enable double-page spread in current reading mode';
	@override String get doublePageLeadingBlank => 'Leading blank';
	@override String get doublePageLeadingBlankSubtitle => 'Insert a blank page at the start of each chapter to shift page pairing';
	@override String get themeMode => 'Theme mode';
	@override String get autoRead => 'Auto read';
	@override String get autoReadSubtitle => 'Auto-scroll and show play/pause button';
	@override String get webtoonScrollDistance => 'Webtoon scroll distance';
	@override String get webtoonScrollInterval => 'Webtoon scroll interval';
	@override String get singlePageScrollInterval => 'Single page scroll interval';
	@override String get background => 'Background';
	@override String get auto => 'Auto';
	@override String get black => 'Black';
	@override String get white => 'White';
	@override String get grey => 'Grey';
	@override String get readingExperience => 'Reading experience';
	@override String get disableAnimation => 'Disable page animation';
	@override String get disableAnimationSubtitle => 'Disable full-page turn animation';
	@override String get readFilter => 'Read filter (dark mode only)';
	@override String get readFilterSubtitle => 'Only effective in reader, reduces brightness at night';
	@override String get filterIntensity => 'Filter intensity';
	@override String get einkOptimization => 'E-ink optimization (landscape)';
	@override String get einkOptimizationSubtitle => 'Show white screen before image after page turn';
	@override String get einkDelay => 'White screen duration';
	@override String get sidePadding => 'Side padding';
	@override String get sidePaddingSubtitle => 'Customize left/right padding ratio';
	@override String get sidePaddingPercent => 'Padding per side';
	@override String get batterySubtitle => 'Off by default, enable as needed';
	@override String get timeSubtitle => 'Show current time';
	@override String get infoBarPosition => 'Info bar position';
	@override String get showInStatusBar => 'Show in status bar';
	@override String get showInStatusBarSubtitle => 'Top info bar enters system status bar area';
	@override String get edgePadding => 'Edge padding';
	@override String get infoBarStyle => 'Info bar style';
	@override String get backgroundOpacity => 'Background opacity';
	@override String get fontSize => 'Font size';
	@override String get allHiddenNotice => 'All hidden, info bar will be completely hidden';
	@override String get edgePaddingDisabled => 'Edge padding has no effect when horizontally centered';
	@override String get settings => 'Reader settings';
	@override String get previousChapter => 'Previous chapter';
	@override String get nextChapter => 'Next chapter';
	@override String get backToHome => 'Back to home';
	@override String get jumpToChapterTitle => 'Jump';
	@override String jumpToChapterMessage({required Object chapter}) => 'Jump to ${chapter}?';
	@override String get selectChapter => 'Select chapter';
	@override String get enterFullscreen => 'Fullscreen (F11)';
	@override String get exitFullscreen => 'Exit fullscreen';
	@override String get chapterTransition => 'Chapter transition';
	@override String get transitionSwipeToLoad => 'Swipe to load';
	@override String get transitionLoaded => 'Load complete';
	@override String get transitionLoadFailedRetry => 'Load failed, tap to retry';
	@override String get pullDownToPrevChapter => 'Pull down to previous chapter';
	@override String get releaseToJumpPrevChapter => 'Release to jump to previous chapter';
	@override String get releaseToLoadPrevChapter => 'Release to load previous chapter';
	@override String get pullUpToNextChapter => 'Pull up to next chapter';
	@override String get releaseToJumpNextChapter => 'Release to jump to next chapter';
	@override String get releaseToLoadNextChapter => 'Release to load next chapter';
	@override String get chapterNotDownloaded => 'Chapter not downloaded';
	@override String loadFailedWithResult({required Object result}) => '${result}\nLoad failed';
	@override String chapterOrder({required Object order}) => 'Chapter ${order}';
	@override String get doubleTapAction => 'Double-tap action';
	@override String get doubleTapZoom => 'Double-tap zoom';
	@override String get doubleTapZoomSubtitle => 'Double-tap image to toggle zoom';
	@override String get doubleTapOpenMenu => 'Double-tap to open menu';
	@override String get doubleTapOpenMenuSubtitle => 'Double-tap page to open menu (exclusive with zoom)';
	@override String get volumeKeyPageTurn => 'Volume key page turn';
	@override String get enableVolumeKeyPageTurn => 'Enable volume key page turn';
	@override String get volumeKeyPageTurnSubtitle => 'Use volume keys to turn pages/scroll';
	@override String get screenHeightPercent => '% screen height';
	@override String get milliseconds => 'ms';
	@override String get percent => '%';
	@override String get pixels => 'px';
	@override String get gesture => 'Gesture';
	@override String get infoBar => 'Info bar';
	@override String get pauseAutoRead => 'Pause auto read';
	@override String get resumeAutoRead => 'Resume auto read';
	@override String imageLoadFailedRetry({required Object error}) => '${error}\nLoad failed, tap to retry';
	@override String imageSavedTo({required Object path}) => 'Image saved to: ${path}';
	@override String get imageSavedToAlbum => 'Image saved to album';
	@override String get imageSaveFailed => 'Image save failed';
	@override String get saveImagePermissionDenied => 'Save failed: please grant album access in settings';
	@override String imageSaveFailedWithError({required Object error}) => 'Save failed: ${error}';
}

// Path: plugin
class _Translations$plugin$en_US extends Translations$plugin$zh_CN {
	_Translations$plugin$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get store => 'Plugin Store';
	@override String get searchHint => 'Search plugin name or author...';
	@override String get localInstall => 'Local install';
	@override String get networkInstall => 'Network install';
	@override String get cloudComponents => 'Cloud components';
	@override String get loginSuccess => 'Please complete login in the browser, the host will sync cookies automatically';
	@override String get chromiumFallbackUnsupported => 'External Chromium auto-login fallback is not supported on this platform';
	@override String get switchingToExternalBrowser => 'Built-in WebView login is limited, switching to external browser...';
	@override String get chromiumNotFound => 'No Chromium browser detected, please install Chrome first';
	@override String browserSwitched({required Object browser}) => 'Switched to ${browser}, cookies will be synced automatically after login';
	@override String invalidLink({required Object url}) => 'Invalid link: ${url}';
	@override String cannotOpenLink({required Object url}) => 'Cannot open link: ${url}';
	@override String readLocalPluginFailed({required Object error}) => 'Failed to read local plugin: ${error}';
	@override String get addFromNetwork => 'Add plugin from network';
	@override String get urlCannotBeEmpty => 'URL cannot be empty';
	@override String get startInstall => 'Start install';
	@override String pluginSettingsTitle({required Object name}) => '${name} settings';
	@override String get debugConfigUpdated => 'Plugin debug config updated';
	@override String get deletePlugin => 'Delete plugin';
	@override String get confirmDeletePlugin => 'Delete this plugin? This will delete plugin and related data.';
	@override String deleteFailed({required Object error}) => 'Delete failed: ${error}';
	@override String get pluginDeleted => 'Plugin deleted';
	@override String executeFailed({required Object error}) => 'Execute failed: ${error}';
	@override String get debugMode => 'Debug mode';
	@override String get debugAddress => 'Debug address';
	@override String get deletePluginSubtitle => 'Delete plugin and related data permanently';
	@override String get pluginSettings => 'Plugin settings';
	@override String get noUserInfo => 'No user info';
	@override String get operations => 'Operations';
	@override String get management => 'Plugin management';
	@override String get installed => 'Installed';
	@override String get notInstalled => 'Not installed';
	@override String get update => 'Update';
	@override String get install => 'Install';
	@override String get uninstall => 'Uninstall';
	@override String get author => 'Author';
	@override String get version => 'Version';
	@override String get description => 'Description';
	@override String get repo => 'Repository';
	@override String get homepage => 'Homepage';
	@override String get download => 'Download';
	@override String get downloadUpdate => 'Download update';
	@override String get noCloudPlugins => 'No cloud components';
	@override String get noMatchingPlugins => 'No matching plugins';
	@override String get networkInstallHint => 'Enter plugin script URL';
	@override String cloudPluginsLoadFailed({required Object error}) => 'Failed to load cloud components: ${error}';
	@override String installingFromCloud({required Object name}) => 'Downloading and installing ${name}...';
	@override String get installingFromLocal => 'Installing local plugin...';
	@override String get installingFromNetwork => 'Downloading network plugin...';
	@override String cloudDownloadFailed({required Object error}) => 'Cloud download failed: ${error}';
	@override String networkDownloadFailed({required Object error}) => 'Network plugin download failed: ${error}';
	@override String cloudVersion({required Object version}) => 'Cloud ${version}';
	@override String localVersion({required Object version}) => 'Local ${version}';
	@override String loginTitle({required Object name}) => '${name} Login';
	@override String get cookieSynced => 'Login cookie synced';
	@override String get executeSuccess => 'Executed successfully';
	@override String get userInfoTitle => 'User info';
	@override String get userInfoLoadFailed => 'Failed to load user info';
	@override String get unnamedAction => 'Unnamed action';
	@override String get pluginSettingsLoading => 'Loading plugin settings...';
	@override String get pluginSettingsLoadFailed => 'Failed to load plugin settings';
	@override String get actionNotExecutable => 'Action not executable: missing fnPath';
	@override String get saved => 'Saved';
	@override String get close => 'Close';
	@override String get sync => 'Sync';
	@override String get syncSubtitle => 'Check and update via npm / updateUrl';
	@override String get syncing => 'Syncing plugin...';
	@override String get syncSuccess => 'Sync successful';
	@override String syncFailed({required Object error}) => 'Sync failed: ${error}';
	@override String get updateSubtitle => 'Manually reinstall this plugin from a network URL or local file';
	@override String get updateFromNetwork => 'Install from network';
	@override String get updateFromLocal => 'Install from local';
	@override String get updateChooseSource => 'Choose install method';
	@override String get updating => 'Updating plugin...';
	@override String get updateSuccess => 'Update successful';
	@override String updateFailed({required Object error}) => 'Update failed: ${error}';
	@override String get uuidMismatch => 'Plugin id mismatch, install rejected';
	@override String currentVersion({required Object version}) => 'Current version ${version}';
	@override String get alreadyLatest => 'Already up to date';
}

// Path: gestureLock
class _Translations$gestureLock$en_US extends Translations$gestureLock$zh_CN {
	_Translations$gestureLock$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get gestureTitle => 'Gesture unlock';
	@override String get gestureHint => 'Draw gesture password';
	@override String get pinTitle => 'Enter PIN';
	@override String get pinHint => 'Enter reset PIN';
	@override String get atLeast4Points => 'Connect at least 4 points';
	@override String get confirmGesture => 'Please draw again to confirm';
	@override String get gestureNotMatch => 'The two drawings do not match';
	@override String get setSuccess => 'Set successfully';
	@override String get forgotPassword => 'Forgot password';
	@override String get incorrectPassword => 'Incorrect gesture password, please try again';
	@override String get resetPin => 'Reset PIN';
	@override String get pin => 'PIN';
	@override String get pinDescription => 'PIN can reset gesture password. If both are forgotten, you cannot enter the app. Please keep it safe.';
	@override String get pinMinLength => 'PIN must be at least 4 digits';
	@override String get pinNotMatch => 'The two PINs do not match';
	@override String get pinIncorrect => 'Incorrect PIN, please try again';
	@override String get appLocked => 'App is locked';
	@override String get verifyToUnlock => 'Please complete gesture verification';
	@override String get resetGesturePassword => 'Reset gesture password';
	@override String get resetPinHint => 'Enter the reset PIN you saved';
	@override String get passwordCleared => 'Password cleared, please set again';
	@override String get setupHintFirst => 'Please connect at least 4 points';
	@override String get setupHintConfirm => 'Please draw the same gesture again';
	@override String get setupErrorMinPoints => 'Connect at least 4 points';
	@override String get setupErrorMismatch => 'Gestures do not match, please set again';
	@override String get pinHintMinDigits => 'At least 4 digits';
}

// Path: appBootstrap
class _Translations$appBootstrap$en_US extends Translations$appBootstrap$zh_CN {
	_Translations$appBootstrap$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get initializing => 'Initializing....';
	@override String get verifyGesture => 'Please verify gesture password';
	@override String get pinVerifyFailed => 'PIN verification failed';
	@override String get unlockCancelled => 'Unlock cancelled';
	@override String get enteringApp => 'Verification successful, entering app';
}

// Path: comments
class _Translations$comments$en_US extends Translations$comments$zh_CN {
	_Translations$comments$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get retry => 'Retry';
	@override String get noComments => 'No comments yet';
	@override String get loadMore => 'Load more';
	@override String get collapseReplies => 'Collapse replies';
	@override String replyCount({required Object count}) => '${count} replies';
	@override String get noReplies => 'No replies yet';
	@override String get loadMoreReplies => 'Load more replies';
	@override String get postComment => 'Post comment';
	@override String get postCommentHint => 'Enter comment content';
	@override String get postReply => 'Reply';
	@override String get postReplyHint => 'Enter reply content';
	@override String get cancel => 'Cancel';
	@override String get confirm => 'Confirm';
	@override String get postSuccess => 'Posted successfully';
	@override String postFailed({required Object error}) => 'Failed to post: ${error}';
	@override String get anonymous => 'Anonymous';
}

// Path: cache
class _Translations$cache$en_US extends Translations$cache$zh_CN {
	_Translations$cache$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Cache settings';
	@override String get currentCache => 'Current cache';
	@override String get clearCache => 'Clear cache';
	@override String get clearCacheConfirm => 'Are you sure you want to clear all cache files? This action cannot be undone.';
	@override String get cleared => 'Cache cleared';
	@override String get clearFailed => 'Clear failed';
	@override String get cacheSize => 'Cache size';
	@override String get recalculate => 'Recalculate';
	@override String get manualClear => 'Manual clear cache';
	@override String get manualClearSubtitle => 'Delete all cache files immediately';
	@override String get clear => 'Clear';
	@override String get cacheLimit => 'Cache limit';
	@override String get sizeLimit => 'Cache size limit';
	@override String get sizeLimitSubtitle => 'Old cache will be automatically cleared when the limit is reached';
	@override String get autoClean => 'Auto clean cache';
	@override String get autoCleanSubtitle => 'Automatically clean old cache when exceeding limit';
	@override String get calculating => 'Calculating...';
	@override String get calculateFailed => 'Calculate failed';
}

// Path: dataBackup
class _Translations$dataBackup$en_US extends Translations$dataBackup$zh_CN {
	_Translations$dataBackup$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Data Import/Export';
	@override String get exportSection => 'Export';
	@override String get importSection => 'Import';
	@override String get includeDownloads => 'Include downloaded comics';
	@override String get includeDownloadsSubtitle => 'Pack downloaded comic files when exporting';
	@override String get exportData => 'Export data';
	@override String get exportDataSubtitle => 'Pack settings and data into zip';
	@override String get importData => 'Import data';
	@override String get importDataSubtitle => 'Restore data from zip file';
	@override String get selectExportDirFailed => 'Failed to select export directory';
	@override String get exporting => 'Exporting, please wait…';
	@override String get exportSuccess => 'Export successful';
	@override String savedTo({required Object path}) => 'Saved to: ${path}';
	@override String get exportFailed => 'Export failed';
	@override String get processingBackup => 'Processing backup file…';
	@override String get selectBackupFailed => 'Failed to select backup file';
	@override String get readingBackup => 'Reading backup info…';
	@override String get readBackupFailed => 'Failed to read backup';
	@override String get importing => 'Importing, please wait…';
	@override String get importFailed => 'Import failed';
	@override String get importTitle => 'Import data';
	@override String get importConfirm => 'Import will overwrite all current app data. Continue?';
	@override String get includesDownloadsWarning => 'This backup contains downloaded comic files. Existing downloads will be deleted before import.';
	@override String get versionMismatch => 'Version mismatch. Data import may have issues. Continue?';
	@override String exportedVersion({required Object version}) => 'Exported version: ${version}';
	@override String currentVersion({required Object version}) => 'Current app version: ${version}';
	@override String get kContinue => 'Continue';
	@override String get importSuccess => 'Import successful';
	@override String get restartPrompt => 'Data imported successfully. Please restart the app to apply.';
}

// Path: webdavSync
class _Translations$webdavSync$en_US extends Translations$webdavSync$zh_CN {
	_Translations$webdavSync$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Cloud Sync Config';
	@override String serviceTitle({required Object service}) => '${service} Sync Config';
	@override String get noneTip => 'Please select a sync service in Settings first, then return here to fill in the configuration.';
	@override String get deleteConfig => 'Delete Config';
	@override String get testAndSave => 'Test & Save';
	@override String get faq => 'FAQ';
	@override String get webdavHost => 'WebDAV URL';
	@override String get username => 'Username';
	@override String get password => 'Password';
	@override String get s3Endpoint => 'Endpoint';
	@override String get s3EndpointHint => 'e.g. s3.amazonaws.com';
	@override String get s3AccessKey => 'Access Key';
	@override String get s3SecretKey => 'Secret Key';
	@override String get s3Bucket => 'Bucket Name';
	@override String get s3Region => 'Region (optional)';
	@override String get s3Port => 'Port (optional)';
	@override String get useSsl => 'Use HTTPS/SSL';
	@override String get pathStyle => 'Path-Style';
	@override String get pathStyleSubtitle => 'Self-hosted MinIO usually requires this option';
	@override String get connectingWebdav => 'Connecting to WebDAV server...';
	@override String get webdavConnected => 'WebDAV connected and settings saved.';
	@override String webdavConnectFailed({required Object error}) => 'Connection failed. Please check network or WebDAV address.\n${error}';
	@override String get invalidPort => 'Invalid port. Please enter a number between 0 and 65535.';
	@override String get connectingS3 => 'Connecting to S3 service...';
	@override String get s3Connected => 'S3 connected and settings saved.';
	@override String s3ConnectFailed({required Object error}) => 'Connection failed. Please check S3 configuration.\n${error}';
	@override String get close => 'Close';
	@override String get success => 'Success';
	@override String get error => 'Error';
	@override String get faqMarkdown => '### What can be synced?\n- Currently syncs Bika history, JM favorites, and JM history.\n\n### How to configure WebDAV?\n- Fill in WebDAV URL, username, password, then tap Test & Save.\n\n### How to configure S3?\n- Endpoint examples: `s3.amazonaws.com`, `s3.filebase.com`, `play.min.io`.\n- For self-hosted MinIO, fill in a custom port and disable SSL if necessary.\n\n### How often does auto-sync run?\n- Every 5 minutes.\n\n### How to trigger a manual sync?\n- Tap Test & Save on the sync config page.\n- Or toggle the auto-sync switch in Settings.';
}

// Path: realSr
class _Translations$realSr$en_US extends Translations$realSr$zh_CN {
	_Translations$realSr$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Image Super-Resolution (Experimental)';
	@override String get unlimited => 'Unlimited';
	@override String get modelDownloadFailed => 'Model download failed';
	@override String get generalSection => 'General';
	@override String get autoUpscaleSection => 'Auto Upscale';
	@override String get autoUpscale => 'Auto Upscale';
	@override String get autoUpscaleSubtitleUnavailable => 'Model not downloaded; auto upscale will not work';
	@override String get autoUpscaleSubtitleAvailable => 'Automatically upscale when downloading or loading images';
	@override String get conditionSection => 'Condition';
	@override String get resolutionThreshold => 'Resolution Threshold';
	@override String get resolutionThresholdSubtitle => 'Only auto-upscale when image width is below this value';
	@override String get performanceSection => 'Performance';
	@override String get concurrency => 'Concurrency';
	@override String get concurrencySubtitle => 'Higher values suit high-end GPUs; mobile/low-end devices should keep it at 1';
	@override String get tileSize => 'Tile Size';
	@override String get tileSizeSubtitle => 'Set smaller if crashes occur; 0 means no tiling; desktop can try 0';
	@override String get modelSection => 'Model';
	@override String get model => 'Model';
	@override String get modelSubtitle => 'Switching model family resets variant options';
	@override String get noiseLevel => 'Denoise Level';
	@override String get noiseLevelSubtitle => 'This option varies with the selected model';
	@override String get blockInfo => 'Tile Info';
	@override String get blockInfoTooltip => 'blockSize is the model input size including reflection padding;\ncontent block = blockSize - 2×shrinkSize, which is the actual拼接 output region.';
	@override String blockInfoFormat({required Object contentSize, required Object blockSize, required Object shrinkSize}) => 'Content block ${contentSize}×${contentSize}, model input ${blockSize}×${blockSize} (with ${shrinkSize}px reflection padding)';
	@override String get androidSuperResolution => 'Android Super-Resolution';
	@override String get androidSuperResolutionSubtitle => 'Currently uses waifu2x upconv anime model, 2x upscale';
	@override String get desktopStrategy => 'Upscale Strategy';
	@override String get desktopStrategySubtitle => 'Efficiency priority uses waifu2x; quality priority uses Real-CUGAN';
	@override String get desktopNoiseLevel => 'Denoise Level';
	@override String get desktopNoiseLevelSubtitle => 'Conservative suits normal comics; higher levels produce stronger smearing';
	@override String get modelManagementSection => 'Model Management';
	@override String get downloadingModel => 'Downloading model';
	@override String get modelReady => 'Model ready';
	@override String get redownload => 'Redownload';
	@override String get deleteModel => 'Delete Model';
	@override String get deleteModelConfirm => 'Delete the downloaded super-resolution model? You will need to download it again before use.';
	@override String get modelDeleted => 'Model deleted';
	@override String get modelDeleteFailed => 'Failed to delete model';
	@override String get modelNotDownloaded => 'Model not downloaded';
	@override String get modelNotDownloadedSubtitle => 'Download model before using super-resolution';
	@override String get downloadModel => 'Download Model';
	@override String get modeEfficiency => 'Efficiency priority';
	@override String get modeQuality => 'Quality priority';
	@override String get noiseConservative => 'Conservative';
	@override String get noise0 => 'No denoise';
	@override String get noise1 => 'Denoise 1';
	@override String get noise2 => 'Denoise 2';
	@override String get noise3 => 'Denoise 3';
	@override String get variantWaifu2xAnime => 'waifu2x upconv anime';
	@override String variantRealCuganDenoise({required Object noise}) => 'Real-CUGAN denoise ${noise}';
	@override String get coremlSpeed => 'Speed priority (waifu2x)';
	@override String get coremlQuality => 'Quality priority (Real-CUGAN)';
	@override String get coremlNoise0 => 'Denoise 0';
	@override String get coremlNoDenoise => 'No denoise';
	@override String get coremlInputHint => 'Enter input image absolute path or asset path';
	@override String get coremlStartUpscale => 'Start upscale';
	@override String get coremlStatusFillInput => 'Please fill in the input image path';
	@override String get coremlStatusNoModelFile => 'No model files available for current family';
	@override String get coremlStatusPreparing => 'Preparing resources...';
	@override String get coremlStatusUpscaling => 'Upscaling...';
	@override String coremlStatusDone({required Object outputPath, required Object size}) => 'Done\n${outputPath}\nsize: ${size} bytes';
	@override String coremlStatusFailed({required Object error}) => 'Failed: ${error}';
	@override String get coremlModelOption => 'Model option (denoise level)';
	@override String get coremlGeneralOption => 'General option (scale)';
	@override String get coremlTileInfo => 'Tile info';
}

// Path: about
class _Translations$about$en_US extends Translations$about$zh_CN {
	_Translations$about$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'About app';
	@override String version({required Object version}) => 'Version: ${version}';
	@override String get loading => 'Loading...';
	@override String get fetchFailed => 'Failed to load';
	@override String get networkError => 'Network error';
	@override String get projectAddress => 'Project';
	@override String get projectAddressDesc => 'Like this project? Give it a star on GitHub!';
	@override String get projectLink => 'Go to GitHub repo (deretame/Breeze) ⭐';
	@override String get contact => 'Contact';
	@override String get contactDesc => 'Have ideas or questions? Feel free to reach out~';
	@override String get feedback => 'Feedback';
	@override String get feedbackDesc => 'Found a bug or have a new idea?';
	@override String get feedbackLink => 'Open a GitHub Issue';
	@override String get contributors => 'Contributors';
	@override String contributorsCount({required Object count}) => '${count}';
	@override String contributionsTooltip({required Object login, required Object count}) => '${login} (${count} commits)';
	@override String get disclaimer => 'Disclaimer';
	@override String get disclaimerTitle => 'Open Source Disclaimer';
	@override String get disclaimerItem1Title => '1. Nature and Statement';
	@override String get disclaimerItem1Content => 'This project is open-source software, independently developed and maintained by the author. It is provided "as-is". The developer makes no express or implied warranties regarding functionality, stability, security, or fitness for purpose.';
	@override String get disclaimerItem2Title => '2. Limitation of Liability';
	@override String get disclaimerItem2Content => 'The developer shall not be liable for any direct, indirect, special, incidental, or consequential damages arising from use, modification, or distribution of this project (including but not limited to direct use, secondary development, or integration into other projects). These damages may include but are not limited to data loss, device damage, business interruption, lost profits, or other economic losses.';
	@override String get disclaimerItem3Title => '3. User Responsibility';
	@override String get disclaimerItem3Content => 'Users should evaluate suitability and assume all risks when using this project. Users must ensure their use complies with applicable laws, regulations, and ethical standards. The developer is not responsible for consequences resulting from violations of laws or misuse.';
	@override String get disclaimerItem4Title => '4. Third-Party Dependencies and Resources';
	@override String get disclaimerItem4Content => 'This project may depend on or reference third-party libraries, tools, services, or other resources. The developer is not responsible for the content, functionality, security, or legality of these third-party resources. Users should evaluate and assume risks themselves.';
	@override String get disclaimerItem5Title => '5. No Warranty';
	@override String get disclaimerItem5Content => 'The developer expressly disclaims all warranties, including but not limited to: merchantability; fitness for a particular purpose; non-infringement; and error-free or uninterrupted operation.';
	@override String get disclaimerItem6Title => '6. Modification and Termination';
	@override String get disclaimerItem6Content => 'The developer reserves the right to modify, suspend, or terminate this project at any time without prior notice. The developer is not responsible for any consequences arising from such changes.';
	@override String get disclaimerItem7Title => '7. Contributor Responsibility';
	@override String get disclaimerItem7Content => 'If external contributions are accepted, contributors act in their personal capacity and do not represent the developer\'s views or positions. The developer is not responsible for contributor actions or content.';
	@override String get disclaimerItem8Title => '8. Legal Compliance';
	@override String get disclaimerItem8Content => 'Users must ensure their use complies with applicable laws and regulations. The developer is not responsible for consequences resulting from legal violations.';
	@override String get disclaimerImportant => 'Important Notice';
	@override String get disclaimerImportantContent => 'Please read and understand this disclaimer before using this project. If you do not agree with any term, stop using it immediately. Continued use constitutes acceptance of the entire disclaimer.';
	@override String get checkUpdate => 'Check update';
	@override String get alreadyLatest => 'Already latest version';
	@override String get updateAvailable => 'New version available';
	@override String get license => 'Open source licenses';
	@override String get privacy => 'Privacy policy';
}

// Path: oldHome
class _Translations$oldHome$en_US extends Translations$oldHome$zh_CN {
	_Translations$oldHome$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Home';
	@override String get search => 'Search';
	@override String get hotSearch => 'Hot Search';
	@override String get navigation => 'Navigation';
	@override String get recommend => 'Recommend';
	@override String get latest => 'Latest';
	@override String get cloudFavorite => 'Cloud Favorites';
	@override String get list => 'List';
	@override String get function => 'Function';
	@override String get close => 'Close';
	@override String get loadFailedRetry => 'Load failed, please retry.';
	@override String loadSectionFailed({required Object title, required Object error}) => 'Failed to load ${title}\n${error}';
	@override String get empty => 'No content';
	@override String get loadMoreFailed => 'Failed to load more, tap to retry';
	@override String get loadMore => 'Load more';
	@override String get noMore => 'No more';
}

// Path: more
class _Translations$more$en_US extends Translations$more$zh_CN {
	_Translations$more$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get common => 'Common';
	@override String get others => 'Others';
	@override String get downloadTasks => 'Download Tasks';
	@override String get comicFollow => 'Updates';
	@override String get changelog => 'Changelog';
}

// Path: search
class _Translations$search$en_US extends Translations$search$zh_CN {
	_Translations$search$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Search';
	@override String get searchHint => 'Search...';
	@override String get selectSource => 'Select Source';
	@override String get advancedSearchNotSupported => 'Current plugin does not support advanced search';
	@override String get advancedSearchOptions => 'Advanced Search Options';
	@override String get notSelected => 'Not selected';
	@override String selectedCount({required Object count}) => '${count} selected';
	@override String get history => 'Search History';
	@override String get clearHistory => 'Clear History';
	@override String get newestFirst => 'Current: newest first';
	@override String get oldestFirst => 'Current: oldest first';
	@override String get descending => 'Newest first';
	@override String get ascending => 'Oldest first';
	@override String get noHistory => 'No search history';
	@override String get tipsTitle => '🔍 Search Tips';
	@override String get exactSearchTitle => 'Exact search (AND)';
	@override String get exactSearchExample => 'colorful + married';
	@override String get exactSearchDesc => 'Show results containing both keywords';
	@override String get excludeSearchTitle => 'Exclude search';
	@override String get excludeSearchExample => 'colorful - married';
	@override String get excludeSearchDesc => 'Show \'colorful\' results excluding \'married\'';
	@override String get fuzzySearchTitle => 'Fuzzy search (OR)';
	@override String get fuzzySearchExample => 'colorful married';
	@override String get fuzzySearchDesc => 'Show results containing any keyword';
	@override String get selectCategory => 'Select Category';
	@override String get dataSource => 'Data Source';
	@override String get sortBy => 'Sort By';
	@override String get newestToOldest => 'Newest to oldest';
	@override String get oldestToNewest => 'Oldest to newest';
	@override String get mostLikes => 'Most likes';
	@override String get mostViews => 'Most views';
	@override String get selectSourceTooltip => 'Select source';
	@override String get hasResults => 'With results';
	@override String get showErrors => 'Show errors';
	@override String resultCount({required Object count}) => '${count} results';
	@override String get noResults => 'No results';
	@override String loadFailedForSource({required Object source}) => 'Failed to load ${source}';
}

// Path: discover
class _Translations$discover$en_US extends Translations$discover$zh_CN {
	_Translations$discover$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Discover';
	@override String get search => 'Search';
	@override String get settings => 'Settings';
	@override String get pluginManagement => 'Plugin Management';
	@override String get noPlugins => 'No plugins available. Go to the plugin store to install one~';
	@override String get pluginStore => 'Plugin Store';
	@override String get browseInstall => 'Browse & Install';
	@override String get noPluginForSearch => 'No plugins available, cannot search';
	@override String pluginInfoLoadFailed({required Object error}) => 'Failed to load plugin info: ${error}';
	@override String get pluginCapability => 'Plugin Capability';
	@override String get disabled => 'Disabled';
	@override String get unnamed => 'Unnamed';
	@override String pluginEnableFailed({required Object error}) => 'Failed to enable plugin: ${error}';
	@override String pluginCloseFailed({required Object error}) => 'Failed to disable plugin: ${error}';
	@override String pluginDebugLoadFailed({required Object error}) => 'Plugin debug load failed, reverted to database: ${error}';
}

// Path: searchResult
class _Translations$searchResult$en_US extends Translations$searchResult$zh_CN {
	_Translations$searchResult$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get enterPageNumber => 'Enter page number';
	@override String get pleaseEnterNumber => 'Please enter a number';
	@override String get returnToTop => 'Return to top';
	@override String get jumpToPage => 'Jump to page';
	@override String get jump => 'Jump';
	@override String get retry => 'Tap to retry';
}

// Path: comicList
class _Translations$comicList$en_US extends Translations$comicList$zh_CN {
	_Translations$comicList$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get defaultTitle => 'Comic List';
	@override String get missingSource => 'Missing plugin source, cannot load list';
	@override String get reload => 'Reload';
	@override String get loadFailedRetry => 'Load failed, please retry.';
	@override String get nothingHere => 'Nothing here';
	@override String get filter => 'Filter';
	@override String get subCategory => 'Subcategory';
	@override String levelCategory({required Object level}) => 'Level ${level}';
	@override String get missingListConfig => 'Missing list request configuration';
	@override String get missingFnPath => 'List request missing fnPath';
}

// Path: comicEntry
class _Translations$comicEntry$en_US extends Translations$comicEntry$zh_CN {
	_Translations$comicEntry$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String updatedAt({required Object time}) => 'Updated: ${time}';
	@override String get finished => 'Finished';
	@override String get ongoing => 'Ongoing';
	@override String likes({required Object count}) => 'Likes ${count}';
	@override String views({required Object count}) => 'Views ${count}';
	@override String get deleteFavorite => 'Delete Favorite';
	@override String deleteFavoriteConfirm({required Object title}) => 'Delete favorite record for "${title}"?';
	@override String get deleteHistory => 'Delete History';
	@override String deleteHistoryConfirm({required Object title}) => 'Delete history record for "${title}"?';
	@override String get deleteDownload => 'Delete Download';
	@override String deleteDownloadConfirm({required Object title}) => 'Delete download record and files for "${title}"?';
	@override String get deleteFailed => 'Delete failed';
}

// Path: comicFollow
class _Translations$comicFollow$en_US extends Translations$comicFollow$zh_CN {
	_Translations$comicFollow$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Updates';
	@override String loadFailed({required Object result}) => 'Load failed: ${result}';
	@override String get empty => 'No followed comics';
	@override String get emptyHint => 'Tap the follow button on a comic detail page to add it here';
	@override String get unfollow => 'Unfollow';
	@override String unfollowConfirm({required Object title}) => 'Stop following "${title}"?';
	@override String get unfollowed => 'Unfollowed';
	@override String get latestChapterFailed => 'Failed to get latest chapter';
	@override String newChapters({required Object diff, required Object total}) => '${diff} new chapters, ${total} total';
	@override String latestCount({required Object count}) => 'Latest ${count} chapters';
	@override String get fetchFailed => 'Fetch failed';
	@override String newChaptersShort({required Object diff}) => '${diff} new';
	@override String get update => 'Update';
	@override String get retry => 'Retry';
	@override String get updateChannelName => 'Comic update reminder';
	@override String get updateChannelDesc => 'Pushed when followed comics have new chapters';
	@override String get updateTitle => 'Follow update';
	@override String get updateBodySingle => '1 followed comic has updates';
	@override String updateBodyMultiple({required Object count}) => '${count} followed comics have updates';
}

// Path: changelog
class _Translations$changelog$en_US extends Translations$changelog$zh_CN {
	_Translations$changelog$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Changelog';
	@override String get loadFailed => 'Load failed';
	@override String loadFailedWithError({required Object error}) => 'Load failed: ${error}';
	@override String cannotOpenLink({required Object url}) => 'Cannot open link: ${url}';
	@override String get checkNetwork => 'Load failed, please check network';
	@override String get retry => 'Retry';
	@override String get empty => 'No changelog';
	@override String publishedAt({required Object date}) => 'Published at ${date}';
	@override String get viewInBrowser => 'View in browser';
	@override String get attachments => 'Attachments';
}

// Path: webview
class _Translations$webview$en_US extends Translations$webview$zh_CN {
	_Translations$webview$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Webpage';
	@override String cannotOpenLink({required Object uri}) => 'Cannot open link: ${uri}';
	@override String get invalidLink => 'Invalid link, cannot open webpage';
	@override String get emptyLink => '(empty link)';
	@override String get loadFailed => 'Webpage load failed';
	@override String get retry => 'Retry';
	@override String get openInExternalBrowser => 'Open in external browser';
	@override String get windowClosed => 'WebView window closed';
	@override String get openedInExternalWindow => 'Webpage opened in external window';
	@override String get back => 'Back';
	@override String get closeWindow => 'Close WebView window';
	@override String loadError({required Object error}) => 'Load failed (${error})';
	@override String httpErrorStatus({required Object statusCode}) => 'Server returned abnormal status code: ${statusCode}';
}

// Path: oldRanking
class _Translations$oldRanking$en_US extends Translations$oldRanking$zh_CN {
	_Translations$oldRanking$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get bikaRanking => 'Bika Ranking';
	@override String get jmRanking => 'JM Ranking';
	@override String get switchSource => 'Switch';
}

// Path: login
class _Translations$login$en_US extends Translations$login$zh_CN {
	_Translations$login$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Login';
	@override String get missingPluginId => 'Missing plugin identifier, cannot open login page';
	@override String loadConfigFailed({required Object error}) => 'Failed to load login config: ${error}';
	@override String get insufficientFields => 'Plugin returned insufficient login fields';
	@override String get invalidCredentials => 'Invalid username or password, please try again';
	@override String get configNotReady => 'Login config not ready, please retry later';
	@override String get loggingIn => 'Logging in, please wait...';
	@override String get loginSuccess => 'Login successful';
	@override String get loginFailed => 'Login failed';
	@override String get loginButton => 'Login';
	@override String get retry => 'Retry';
}

// Path: fontSetting
class _Translations$fontSetting$en_US extends Translations$fontSetting$zh_CN {
	_Translations$fontSetting$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Font Settings';
	@override String get clear => 'Clear';
	@override String get hint => 'Select font files for each weight.';
	@override String get loadFailed => 'Font load failed';
	@override String get cleared => 'Cleared';
	@override String get saved => 'Saved';
	@override String get allCleared => 'All cleared';
	@override String get noFileSelected => 'No file selected';
	@override String get clearFile => 'Clear';
	@override String get selectFile => 'Select File';
	@override String get sampleText => 'Innovation in China 中国智造，慧及全球 0123456789';
}

// Path: download
class _Translations$download$en_US extends Translations$download$zh_CN {
	_Translations$download$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Download tasks';
	@override String get startDownload => 'Start Download';
	@override String get selectChaptersPrompt => 'Please select chapters to download';
	@override String get taskStarted => 'Download task started';
	@override String taskStartFailed({required Object error}) => 'Failed to start download task: ${error}';
	@override String get noTasks => 'No download tasks';
	@override String get downloading => 'Downloading';
	@override String pending({required Object count}) => 'Pending (${count})';
	@override String get taskDeleted => 'Task deleted';
	@override String get cancelTask => 'Cancel Task';
	@override String cancelTaskConfirm({required Object comicName}) => 'Cancel download of ${comicName}?';
	@override String get paused => 'Paused';
	@override String get completed => 'Completed';
	@override String get failed => 'Failed';
	@override String get startAll => 'Start all';
	@override String get pauseAll => 'Pause all';
	@override String get clearCompleted => 'Clear completed';
	@override String get statusFetchingComicInfo => 'Fetching comic info...';
	@override String get statusDownloadingCover => 'Downloading cover...';
	@override String get statusFetchingChapterInfo => 'Fetching chapter info...';
	@override String statusFetchingChapterInfoProgress({required Object completed, required Object total, required Object percent}) => 'Fetching chapter info... (${completed}/${total}, ${percent}%)';
	@override String statusDownloadProgress({required Object percent}) => 'Comic download progress: ${percent}%';
	@override String get statusDownloadProgressComplete => 'Comic download progress: 100%';
	@override String get statusStartDownload => 'Start downloading...';
	@override String get statusWaiting => 'Waiting';
	@override String get statusCancelling => 'Cancelling...';
	@override String toastDownloadComplete({required Object comicName}) => '${comicName} download complete';
	@override String toastDownloadFailed({required Object comicName, required Object error}) => '${comicName} download failed ${error}';
	@override String toastTaskAlreadyExists({required Object comicName}) => '${comicName} task already exists';
	@override String get notificationCompleteTitle => 'Download complete';
	@override String get notificationFailedTitle => 'Download failed';
}

// Path: foregroundTask
class _Translations$foregroundTask$en_US extends Translations$foregroundTask$zh_CN {
	_Translations$foregroundTask$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get channelName => 'Foreground download task';
	@override String get channelDescription => 'Keeps download tasks running in the background';
	@override String get waitingForTask => 'Waiting for download tasks...';
	@override String get cancel => 'Cancel';
	@override String get notificationPermissionRequired => 'Downloads need notification permission to start foreground task, please allow in the system dialog';
	@override String get cannotStartWithoutPermission => 'Cannot start download: please enable notification permission in system settings';
	@override String startFailed({required Object error}) => 'Foreground service start failed: ${error}';
}

// Path: notification
class _Translations$notification$en_US extends Translations$notification$zh_CN {
	_Translations$notification$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get permissionRequired => 'Please enable notification permission';
	@override String get macPermissionRequired => 'Please enable notification permission in system settings';
}

// Path: update
class _Translations$update$en_US extends Translations$update$zh_CN {
	_Translations$update$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get newVersion => 'New version available';
	@override String get goToGitHub => 'Go to GitHub';
	@override String get downloadInstall => 'Download & install';
	@override String get apkDownloadFailed => 'Download failed, please try again later';
	@override String get installPermissionRequired => 'Please grant install app permission';
	@override String get unknownArch => 'Unknown';
}

// Path: dialog
class _Translations$dialog$en_US extends Translations$dialog$zh_CN {
	_Translations$dialog$en_US._(TranslationsEnUs root) : this._root = root, super.internal(root);

	final TranslationsEnUs _root; // ignore: unused_field

	// Translations
	@override String get hideOrClose => 'Hide to tray or close app';
	@override String get rememberChoice => 'Remember my choice';
}

/// The flat map containing all translations for locale <en-US>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEnUs {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'Breeze',
			'common.ok' => 'OK',
			'common.cancel' => 'Cancel',
			'common.save' => 'Save',
			'common.delete' => 'Delete',
			'common.edit' => 'Edit',
			'common.rename' => 'Rename',
			'common.add' => 'Add',
			'common.create' => 'Create',
			'common.refresh' => 'Refresh',
			'common.loading' => 'Loading...',
			'common.loadingFailed' => 'Loading failed',
			'common.retry' => 'Retry',
			'common.reload' => 'Reload',
			'common.confirm' => 'Confirm',
			'common.close' => 'Close',
			'common.back' => 'Back',
			'common.help' => 'Help',
			'common.gotIt' => 'Got it',
			'common.underConstruction' => 'Under construction',
			'common.comingSoon' => 'Coming soon',
			'common.root' => 'Root',
			'common.remove' => 'Remove',
			'common.overwrite' => 'Overwrite',
			'common.cancelled' => 'Cancelled',
			'common.search' => 'Search',
			'common.clear' => 'Clear',
			'common.copy' => 'Copy',
			'common.paste' => 'Paste',
			'common.share' => 'Share',
			'common.open' => 'Open',
			'common.download' => 'Download',
			'common.upload' => 'Upload',
			'common.import' => 'Import',
			'common.export' => 'Export',
			'common.success' => 'Success',
			'common.failed' => 'Failed',
			'common.error' => 'Error',
			'common.warning' => 'Warning',
			'common.info' => 'Info',
			'common.unknown' => 'Unknown',
			'common.empty' => 'No data',
			'common.all' => 'All',
			'common.none' => 'None',
			'common.default_' => 'Default',
			'common.custom' => 'Custom',
			'common.enabled' => 'Enabled',
			'common.disabled' => 'Disabled',
			'common.followSystem' => 'Follow system',
			'common.lightMode' => 'Light mode',
			'common.darkMode' => 'Dark mode',
			'common.system' => 'System',
			'common.apply' => 'Apply',
			'common.reset' => 'Reset',
			'common.next' => 'Next',
			'common.previous' => 'Previous',
			'common.done' => 'Done',
			'common.select' => 'Select',
			'common.selected' => 'Selected',
			'common.deselect' => 'Deselect',
			'common.selectAll' => 'Select all',
			'common.yes' => 'Yes',
			'common.no' => 'No',
			'common.on' => 'On',
			'common.off' => 'Off',
			'common.more' => 'More',
			'common.detail' => 'Details',
			'common.settingSaved' => 'Settings saved',
			'common.restartToTakeEffect' => 'Setting saved, restart to take effect',
			'error.generic' => 'Something went wrong',
			'error.network' => 'Network error',
			'error.downloadFailed' => 'Download failed',
			'error.importFailed' => ({required Object error}) => 'Import failed: ${error}',
			'error.loadFailed' => 'Loading failed',
			'error.saveFailed' => 'Save failed',
			'error.permissionDenied' => 'Permission denied',
			'error.notFound' => 'Not found',
			'error.unsupportedPlatform' => 'This feature is not supported on the current platform',
			'error.missingPluginSource' => ({required Object action}) => 'Missing plugin source, cannot ${action}',
			'error.operationFailed' => 'Operation failed',
			'error.executionFailed' => 'Execution failed',
			'navigation.home' => 'Home',
			'navigation.rank' => 'Rank',
			'navigation.bookshelf' => 'Bookshelf',
			'navigation.discover' => 'Discover',
			'navigation.more' => 'More',
			'navigation.syncSuccess' => 'Sync successful!',
			'navigation.autoSyncSuccess' => 'Auto sync successful!',
			'navigation.syncFailed' => 'Sync failed',
			'navigation.autoSyncFailed' => 'Auto sync failed',
			'navigation.syncFailedMessage' => ({required Object error}) => 'Please check your network connection or try again later.\n${error}',
			'navigation.loginExpired' => 'Login expired, please log in again',
			'settings.title' => 'Settings',
			'settings.globalTitle' => 'Settings',
			'settings.appearance' => 'Appearance',
			'settings.theme' => 'Theme mode',
			'settings.themeSubtitle' => 'Choose strategy to switch light/dark theme',
			'settings.themeColor' => 'Theme color',
			'settings.themeColorSubtitle' => 'Choose primary color for the app',
			'settings.language' => 'Language',
			'settings.languageSubtitle' => 'Change app display language',
			'settings.followSystemLanguage' => 'Follow system',
			'settings.languageZhCn' => '简体中文 (zh_CN)',
			'settings.languageEnUs' => 'English (en_US)',
			'settings.languageChangedRestartHint' => 'Language setting saved. Restart the app for changes to fully take effect.',
			'settings.dynamicColor' => 'Dynamic color',
			'settings.dynamicColorSubtitle' => 'Extract primary color from content automatically',
			'settings.fontSettings' => 'Font settings',
			'settings.fontSettingsSubtitle' => 'Customize display font',
			'settings.amoled' => 'AMOLED black',
			'settings.amoledSubtitle' => 'Use pure black background for AMOLED screens',
			'settings.notchAdaptation' => 'Notch adaptation',
			'settings.notchAdaptationSubtitle' => 'Reserve safe area to avoid content being obscured',
			'settings.contentAndNetwork' => 'Content & Network',
			'settings.content' => 'Content',
			'settings.network' => 'Network',
			'settings.maskedKeywords' => 'Masked keywords',
			'settings.maskedKeywordsSubtitle' => 'Add keywords to filter unwanted content (search only)',
			'settings.maskedKeywordsEmpty' => 'No masked keywords',
			'settings.maskedKeywordsInputHint' => 'Enter new keyword...',
			'settings.chineseConvert' => 'Chinese conversion',
			'settings.chineseConvertSubtitle' => 'Convert comic titles, descriptions, chapters and comments',
			'settings.chineseConvertOff' => 'Off',
			'settings.chineseConvertSimplified' => 'Simplified Chinese',
			'settings.chineseConvertTraditional' => 'Traditional Chinese',
			'settings.proxy' => 'SOCKS5 Proxy',
			'settings.proxySubtitle' => 'Configure SOCKS5 proxy',
			'settings.proxyEnabledSubtitle' => 'Disable to stop using SOCKS5 proxy',
			'settings.proxyAddress' => 'Proxy address',
			'settings.proxyHint' => 'Enter SOCKS5 proxy address',
			'settings.proxyCurrent' => ({required Object currentProxy}) => 'Current proxy: ${currentProxy}',
			'settings.updateAccelerate' => 'Update acceleration',
			'settings.updateAccelerateSubtitle' => 'Use proxy to accelerate GitHub update links',
			'settings.sync' => 'Sync',
			'settings.syncConfig' => 'Sync config',
			'settings.syncConfigSubtitle' => 'Enter page to configure address and auth',
			'settings.syncService' => 'Sync service',
			'settings.syncServiceSubtitle' => 'Choose service to manage sync strategy',
			'settings.syncServiceNone' => 'Disabled',
			'settings.syncServiceWebdav' => 'WebDAV',
			'settings.syncServiceS3' => 'S3',
			'settings.autoSync' => 'Auto sync',
			'settings.autoSyncSubtitle' => 'Sync configuration periodically in background',
			'settings.syncNotify' => 'Sync notifications',
			'settings.syncNotifySubtitle' => 'Notify when sync starts and completes',
			'settings.syncSettings' => 'Sync settings',
			'settings.syncSettingsSubtitle' => 'Use cloud settings to override local settings',
			'settings.syncPlugins' => 'Sync plugins',
			'settings.syncPluginsSubtitle' => 'Sync plugin configuration and installation status',
			'settings.appBehavior' => 'App behavior',
			'settings.splashPage' => 'Startup page',
			'settings.splashPageSubtitle' => 'Choose startup page to open directly',
			'settings.desktopCloseBehavior' => 'Close behavior',
			'settings.desktopCloseBehaviorSubtitle' => 'Choose behavior when clicking close button',
			'settings.desktopCloseAsk' => 'Ask',
			'settings.desktopCloseHide' => 'Hide to tray',
			'settings.desktopCloseClose' => 'Close directly',
			'settings.showMainWindow' => 'Show main window',
			'settings.exitApp' => 'Exit',
			'settings.appLock' => 'App lock',
			'settings.appLockSubtitle' => 'Require verification when entering the app',
			'settings.oldPageRollback' => 'Old home page',
			'settings.oldPageRollbackSubtitle' => 'Use old home page layout',
			'settings.customExportPath' => 'Custom export path',
			'settings.storage' => 'Storage',
			'settings.cache' => 'Cache',
			'settings.clearCache' => 'Clear cache',
			'settings.clearCacheConfirm' => 'Are you sure you want to clear all cache files? This action cannot be undone.',
			'settings.calculatingCache' => 'Calculating...',
			'settings.calculateCacheFailed' => 'Calculate failed',
			'settings.dataBackup' => 'Data Import/Export',
			'settings.dataBackupSubtitle' => 'Backup or restore app data and downloaded comics',
			'settings.includeDownloaded' => 'Include downloaded comics',
			'settings.includeDownloadedSubtitle' => 'Pack downloaded comic files when exporting',
			'settings.exportData' => 'Export data',
			'settings.importData' => 'Import data',
			'settings.imageProcessing' => 'Image processing',
			'settings.realSr' => 'Image Super-Resolution (Experimental)',
			'settings.realSrSubtitle' => 'Experimental feature, may be unstable',
			'settings.autoRealSr' => 'Auto super-resolution',
			'settings.resolutionThreshold' => 'Resolution threshold',
			'settings.debug' => 'Debug',
			'settings.logAddress' => 'Log forward address',
			'settings.logAddressSubtitle' => 'Forward logs to specified address in real time',
			'settings.memoryDebug' => 'Memory debug',
			'settings.memoryDebugSubtitle' => 'Show memory usage on interface',
			'settings.forceEnableImpeller' => 'Force enable Impeller',
			'settings.forceEnableImpellerSubtitle' => 'Android experimental rendering backend',
			'settings.colorPreview' => 'Color preview',
			'settings.colorPreviewSubtitle' => 'Open color picker page for quick preview',
			'settings.qjsRuntimeDebug' => 'QJS runtime debug',
			'settings.qjsRuntimeDebugSubtitle' => 'Enter runtime ID to capture debug snapshot',
			'settings.qjsRuntimeSnapshot' => 'Debug snapshot',
			'settings.qjsRuntimeIdLabel' => 'Runtime ID',
			'settings.qjsRuntimeIdHint' => 'e.g. 0a0e5858-a467-4702-994a-79e608a4589d',
			'settings.qjsRuntimeCapture' => 'Capture snapshot',
			'settings.qjsRuntimeCapturing' => 'Capturing...',
			'settings.qjsRuntimeCopyOutput' => 'Copy output',
			'settings.qjsRuntimeNoOutput' => 'No output yet',
			'settings.qjsRuntimeFillId' => 'Please enter a runtime ID first',
			'settings.qjsRuntimeCapturedAt' => ({required Object dateTime}) => 'Captured at ${dateTime}',
			'settings.qjsRuntimeCaptureFailed' => ({required Object error}) => 'Capture failed: ${error}',
			'settings.qjsRuntimeNoCopyContent' => 'No content to copy',
			'settings.qjsRuntimeCopied' => 'Copied to clipboard',
			'settings.colorPreviewVariableFont' => 'Variable Font test',
			'settings.colorPreviewFontLoaded' => ({required Object path}) => 'Loaded: ${path}',
			'settings.colorPreviewNoFont' => 'No font loaded. Try the recommended sample or pick a TTF/OTF file.',
			'settings.colorPreviewLoadRecommended' => 'Load recommended sample',
			'settings.colorPreviewSelectFont' => 'Select font file',
			'settings.colorPreviewByWeight' => 'Render by fontWeight',
			'settings.colorPreviewByVariableAxis' => 'Render by variable axis',
			'settings.colorPreviewSystemDefault' => 'System default font reference',
			'settings.colorPreviewLoadingFont' => 'Loading font...',
			'settings.colorPreviewLoadSuccess' => 'Font loaded. Compare different weights.',
			'settings.colorPreviewLoadFailed' => ({required Object error}) => 'Font load failed: ${error}',
			'settings.colorRed' => 'Red',
			'settings.colorPink' => 'Pink',
			'settings.colorPurple' => 'Purple',
			'settings.colorDeepPurple' => 'Deep purple',
			'settings.colorIndigo' => 'Indigo',
			'settings.colorBlue' => 'Blue',
			'settings.colorLightBlue' => 'Light blue',
			'settings.colorCyan' => 'Cyan',
			'settings.colorTeal' => 'Teal',
			'settings.colorGreen' => 'Green',
			'settings.colorLightGreen' => 'Light green',
			'settings.colorLime' => 'Lime',
			'settings.colorYellow' => 'Yellow',
			'settings.colorAmber' => 'Amber',
			'settings.colorOrange' => 'Orange',
			'settings.colorDeepOrange' => 'Deep orange',
			'settings.colorBrown' => 'Brown',
			'settings.colorGrey' => 'Grey',
			'settings.colorBlueGrey' => 'Blue grey',
			'settings.coremlDebug' => 'CoreML upscale debug',
			'settings.coremlDebugSubtitle' => 'Test CoreML upscale with absolute path model',
			'settings.aboutAndMore' => 'About & More',
			'settings.changelog' => 'Changelog',
			'settings.changelogSubtitle' => 'View update records for each version',
			'settings.aboutApp' => 'About app',
			'settings.aboutAppSubtitle' => 'Detailed information about Breeze',
			'settings.pluginManagement' => 'Plugin management',
			'settings.debugMode' => 'Debug mode',
			'settings.debugAddress' => 'Debug address',
			'settings.notSet' => 'Not set',
			'bookshelf.title' => 'Bookshelf',
			'bookshelf.favorite' => 'Favorites',
			'bookshelf.history' => 'History',
			'bookshelf.download' => 'Downloads',
			'bookshelf.filter' => 'Filter',
			'bookshelf.searchList' => 'Search list',
			'bookshelf.newFolder' => 'New folder',
			'bookshelf.manage' => 'Manage',
			'bookshelf.importComic' => 'Import comic',
			'bookshelf.folderHint' => 'Bookshelf hints',
			'bookshelf.removeFromFolder' => 'Remove from folder',
			'bookshelf.deleteFavorite' => 'Remove favorite',
			'bookshelf.deleteHistory' => 'Delete history',
			'bookshelf.deleteDownload' => 'Delete download record',
			'bookshelf.confirmDeleteSelected' => ({required Object count}) => 'Are you sure you want to delete the selected ${count} records?',
			'bookshelf.deletedRecords' => ({required Object count}) => 'Deleted ${count} records',
			'bookshelf.noFilterSource' => 'No filterable plugin sources',
			'bookshelf.sort' => 'Sort',
			'bookshelf.sortDesc' => 'Time (newest first)',
			'bookshelf.sortAsc' => 'Time (oldest first)',
			'bookshelf.folderDeprecated' => 'Folders (deprecated)',
			'bookshelf.source' => 'Comic source',
			'bookshelf.deselectAll' => 'Deselect all',
			'bookshelf.deleteFolder' => 'Delete folder',
			'bookshelf.renameFolder' => 'Rename folder',
			'bookshelf.confirmDeleteFolder' => ({required Object name}) => 'Delete folder "${name}"?',
			'bookshelf.folderAction' => 'Please select an action',
			'bookshelf.createFolder' => 'Create folder',
			'bookshelf.createFolderHint' => 'Enter folder name',
			'bookshelf.multiSelect' => 'Multi-select',
			'bookshelf.copyTo' => 'Copy to',
			'bookshelf.batchExport' => 'Batch export',
			'bookshelf.batchDeleteFailed' => 'Batch delete failed',
			'bookshelf.deleteSelected' => 'Delete selected',
			'bookshelf.cancel' => 'Cancel selection',
			'bookshelf.addToFavorite' => 'Add to favorites',
			'bookshelf.addToDownloadFolder' => 'Add to download folder',
			'bookshelf.createFavoriteFolderFirst' => 'Please create a custom favorite folder first',
			'bookshelf.addedToFavorite' => 'Added to favorites',
			'bookshelf.createDownloadFolderFirst' => 'Please create a custom download folder first',
			'bookshelf.addedToDownloadFolder' => 'Added to download folder',
			'bookshelf.selectFavoriteFolder' => 'Select favorite folders (multiple)',
			'bookshelf.selectDownloadFolder' => 'Select download folders (multiple)',
			'bookshelf.selectedCount' => ({required Object count}) => 'Selected ${count} items',
			'bookshelf.selectTargetFolder' => 'Select target folders (multiple)',
			'bookshelf.confirmDeleteFolderTitle' => 'Confirm delete',
			'bookshelf.confirmDeleteFolderContent' => 'Delete this folder? Contents will be deleted recursively.',
			'bookshelf.confirmRemoveComicTitle' => 'Remove from folder',
			'bookshelf.confirmRemoveComicContent' => ({required Object title}) => 'Remove "${title}" from current folder?',
			'bookshelf.importStarted' => 'Importing comics (zip only)',
			'bookshelf.importCompleted' => ({required Object title}) => 'Import completed: ${title}',
			'bookshelf.comicExists' => 'Comic already exists',
			'bookshelf.confirmOverwriteImport' => ({required Object title}) => '${title} already exists in download list. Overwrite?',
			'bookshelf.noExportableComics' => 'No exportable comics in selection',
			'bookshelf.batchExportCompleted' => ({required Object success, required Object total}) => 'Batch export completed: ${success}/${total}',
			'bookshelf.batchExportFailed' => ({required Object error}) => 'Batch export failed: ${error}',
			'bookshelf.confirmDeleteSelectedTitle' => 'Confirm delete',
			'bookshelf.confirmDeleteSelectedContent' => 'Delete selected folders and comics? Folders will be deleted recursively.',
			'bookshelf.cancelSelect' => 'Cancel selection',
			'bookshelf.selectAll' => 'Select all',
			'bookshelf.moveTo' => 'Move to',
			'bookshelf.addToFolder' => 'Add to folder',
			'bookshelf.folderName' => 'Folder name',
			'bookshelf.folderNameHint' => 'Enter folder name',
			'bookshelf.helpContent' => '• Favorites and bookshelf are linked: favoriting a comic adds it to the bookshelf; only removing it from all favorite folders unfavorites it.\n• On comic detail page, unfavorite removes it from all favorite folders at once.\n• Same for downloads: only removing a comic from all download folders deletes its downloaded files.',
			'bookshelf.folderCreated' => 'Folder created',
			'bookshelf.noComic' => 'No comics yet',
			'bookshelf.noHistory' => 'No reading history yet',
			'bookshelf.noDownload' => 'No downloads yet',
			'bookshelf.nothingHere' => 'Nothing here',
			'bookshelf.deleteAllDownloadRecordsAndFiles' => 'Delete all download records and files',
			'bookshelf.clearHistoryRecords' => 'Clear history records',
			'bookshelf.confirmDeleteAllDownloadsContent' => 'Delete all download records and their files? This action cannot be undone!',
			'bookshelf.confirmClearHistoryContent' => 'Clear all history records? This action cannot be undone!',
			'bookshelf.allDownloadRecordsAndFilesDeleted' => 'All download records and files deleted',
			'bookshelf.historyRecordsCleared' => 'History records cleared',
			'bookshelf.batchExportTitle' => 'Choose export method',
			'bookshelf.batchExportSubtitle' => 'Please choose batch export as zip or folder',
			'bookshelf.importCancelled' => 'Import cancelled',
			'bookshelf.importEpisodeFallback' => ({required Object index}) => 'Ep. ${index}',
			'bookshelf.importMissingJson' => 'Import directory is missing required JSON files',
			'bookshelf.importVersionUnsupported' => 'This version cannot be imported, please export with a newer app version',
			'bookshelf.importMissingSource' => 'Export file is missing source info, please re-export with a newer app version',
			'bookshelf.importMissingComicId' => 'Cannot get comic ID',
			'bookshelf.importNoComicDir' => 'No importable comic directory found in the archive',
			'bookshelf.importMultipleComicDirs' => 'Archive contains multiple comic directories, please import one at a time',
			'bookshelf.importComicExistsUncovered' => ({required Object title}) => 'Comic "${title}" already exists, import skipped',
			'bookshelf.folderNameEmpty' => 'Folder name cannot be empty',
			'bookshelf.folderNameSlash' => 'Folder name cannot contain /',
			'bookshelf.folderNameExists' => 'A folder with the same name already exists in this path',
			'bookshelf.targetFolderNameExists' => ({required Object name}) => 'A folder with the same name already exists at target: ${name}',
			'bookshelf.cannotMoveFolderToSelf' => 'Cannot move a folder into itself',
			'bookshelf.cannotMoveParentToChild' => 'Cannot move a parent folder into its subfolder',
			'bookshelf.cannotCopyFolderToSelfOrChild' => 'Cannot copy a folder into itself or its subfolders',
			'bookshelf.moveFoldersOnlyOneTarget' => 'Only one target folder can be selected when moving folders',
			'bookshelf.favoriteFolderNameEmpty' => 'Favorite folder name cannot be empty',
			'bookshelf.favoriteFolderNameExists' => 'A favorite folder with the same name already exists',
			'bookshelf.downloadFolderNameEmpty' => 'Download folder name cannot be empty',
			'bookshelf.downloadFolderNameExists' => 'A download folder with the same name already exists',
			'bookshelf.removeFromFavoriteFolder' => 'Remove from favorite folder',
			'bookshelf.removeFromDownloadFolder' => 'Remove from download folder',
			'bookshelf.confirmRemoveFromCurrentFolder' => 'Remove from current folder?',
			'bookshelf.confirmDeleteSelectedFavorites' => ({required Object count}) => 'Delete selected ${count} favorite records?',
			'bookshelf.confirmDeleteSelectedHistory' => ({required Object count}) => 'Delete selected ${count} history records?',
			'bookshelf.confirmDeleteSelectedDownloads' => ({required Object count}) => 'Delete selected ${count} download records and files?',
			'comicInfo.follow' => 'Follow updates',
			'comicInfo.unfollow' => 'Unfollow',
			'comicInfo.exportComic' => 'Export comic',
			'comicInfo.collectToCloud' => 'Collect to cloud',
			'comicInfo.removeCloudCollection' => 'Remove cloud collection',
			'comicInfo.cloudCollectDisabled' => 'Cloud collection disabled',
			'comicInfo.collectingToCloud' => 'Adding to cloud collection...',
			'comicInfo.removingCloudCollection' => 'Removing cloud collection...',
			'comicInfo.cloudCollectSuccess' => 'Added to cloud collection',
			'comicInfo.cloudUncollectSuccess' => 'Removed from cloud collection',
			'comicInfo.discontinued' => 'This comic is discontinued',
			'comicInfo.likes' => ({required Object count}) => 'Likes ${count}',
			'comicInfo.comments' => ({required Object count}) => 'Comments ${count}',
			'comicInfo.collected' => 'Collected',
			'comicInfo.collect' => 'Collect',
			'comicInfo.download' => 'Download',
			'comicInfo.downloadForbidden' => 'Download forbidden',
			'comicInfo.addedToCollection' => 'Added to collection',
			'comicInfo.removedFromCollection' => 'Removed from collection',
			'comicInfo.confirmUncollectTitle' => 'Remove collection',
			'comicInfo.confirmUncollectContent' => 'This will delete the comic from all folders. Continue?',
			'comicInfo.commentForbidden' => 'Comments are disabled for this comic',
			'comicInfo.commentForbiddenTitle' => 'Comments disabled',
			'comicInfo.back' => 'Back',
			'comicInfo.exportTitle' => 'Choose export format',
			'comicInfo.exportSubtitle' => 'Export as folder or zip archive:',
			'comicInfo.folder' => 'Folder',
			'comicInfo.zip' => 'Zip archive',
			'comicInfo.exportSuccess' => 'Export successful',
			'comicInfo.detailsNotLoaded' => 'Comic details not fully loaded',
			'comicInfo.followed' => 'Following updates',
			'comicInfo.unfollowed' => 'Unfollowed',
			'comicInfo.confirmUnfollowTitle' => 'Unfollow',
			'comicInfo.confirmUnfollowContent' => ({required Object title}) => 'Stop following "${title}"?',
			'comicInfo.noChapters' => 'No chapter information',
			'comicInfo.chapterList' => 'Chapters',
			'comicInfo.episodeCount' => ({required Object count}) => '${count} Episodes',
			'comicInfo.episodeFallback' => ({required Object index}) => 'Ep. ${index}',
			'comicInfo.episodeLabel' => ({required Object index}) => 'Ep. ${index}',
			'comicInfo.author' => 'Author',
			'comicInfo.tags' => 'Tags',
			'comicInfo.works' => 'Works',
			'comicInfo.views' => ({required Object count}) => 'Views: ${count}',
			'comicInfo.updateTime' => ({required Object time}) => 'Updated: ${time}',
			'comicInfo.startRead' => 'Start reading',
			'comicInfo.continueRead' => 'Continue reading',
			'comicInfo.lastRead' => 'Last read',
			'comicInfo.chapters' => 'Chapters',
			'comicInfo.related' => 'Related',
			'comicInfo.description' => 'Description',
			'comicInfo.collapse' => 'Collapse',
			'comicInfo.expandFullText' => 'Read more',
			'comicInfo.readHistory' => 'Reading history',
			'comicInfo.copied' => ({required Object label}) => 'Copied: ${label}',
			'comicInfo.copiedToClipboard' => ({required Object name}) => 'Copied ${name} to clipboard',
			'comicInfo.liking' => 'Liking...',
			'comicInfo.unliking' => 'Unliking...',
			'comicInfo.likeSuccess' => 'Liked',
			'comicInfo.unlikeSuccess' => 'Unliked',
			'comicInfo.localCollectFailed' => ({required Object error}) => 'Local favorite failed: ${error}',
			'comicInfo.likeFailed' => ({required Object error}) => 'Like failed: ${error}',
			'comicInfo.loadFailedWithError' => ({required Object error}) => '${error}\nLoading failed, please retry.',
			'comicInfo.exportPermissionDenied' => 'All files access permission not granted, export cancelled',
			'comicInfo.exportFailedWithError' => ({required Object error}) => 'Export failed, please retry.\n${error}',
			'comicInfo.exportDirectory' => ({required Object displayPath}) => 'Export directory: ${displayPath}',
			'comicInfo.exportPathTooLong' => 'Export directory path is too long to create a valid structure',
			'comicInfo.zipExportPathTooLong' => 'Specified zip export path exceeds system path length limit',
			'comicInfo.downloadPathTooLong' => 'Download directory path is too long to create a valid zip file path',
			'comicInfo.uniqueFileNameTooLong' => 'Cannot create a unique file name for chapter: path length limit exceeded',
			'comicInfo.exportFolderComplete' => ({required Object title}) => 'Exported "${title}" as folder',
			'comicInfo.exportZipComplete' => ({required Object title}) => 'Exported "${title}" as zip',
			'comicInfo.exportComicNotFound' => ({required Object comicId}) => 'No downloadable comic found for export: ${comicId}',
			'comicInfo.pluginInvalidFavorited' => 'Plugin did not return a valid favorited status',
			'comicInfo.pluginInvalidLiked' => 'Plugin did not return a valid liked status',
			'comicInfo.addToCustomFolder' => 'Add to custom folder',
			'comicInfo.addedToFolder' => ({required Object name}) => 'Added to folder: ${name}',
			'comicInfo.skipAdd' => 'Skip / Don\'t add',
			'comicInfo.confirmAdd' => 'Confirm add',
			'comicInfo.resolveComicIdFailed' => ({required Object type}) => 'Cannot resolve comic ID for reading: ${type}',
			'comicInfo.resolveEpsCountFailed' => ({required Object type}) => 'Cannot resolve episode count for reading: ${type}',
			'reader.pageMode' => 'Page turn mode',
			'reader.fullscreen' => 'Fullscreen',
			'reader.leftHandMode' => 'Left-hand mode',
			'reader.rightHandMode' => 'Right-hand mode',
			'reader.readingMode' => 'Reading mode',
			'reader.infoDisplay' => 'Info display',
			'reader.pageNumber' => 'Page number',
			'reader.pageNumberSubtitle' => 'Show current/total page count',
			'reader.networkStatus' => 'Network status',
			'reader.networkStatusSubtitle' => 'May be inaccurate on Linux',
			'reader.battery' => 'Battery',
			'reader.time' => 'Time',
			'reader.verticalPositionTop' => 'Top',
			'reader.verticalPositionBottom' => 'Bottom',
			'reader.horizontalPositionLeft' => 'Left',
			'reader.horizontalPositionCenter' => 'Center',
			'reader.horizontalPositionRight' => 'Right',
			'reader.readingDirectionLtr' => 'Left to right',
			'reader.readingDirectionRtl' => 'Right to left',
			'reader.readingDirectionVertical' => 'Top to bottom',
			'reader.webtoon' => 'Webtoon',
			'reader.singlePageLtr' => 'Single page (LTR)',
			'reader.singlePageRtl' => 'Single page (RTL)',
			'reader.doublePage' => 'Double page',
			'reader.doublePageSubtitle' => 'Enable double-page spread in current reading mode',
			'reader.doublePageLeadingBlank' => 'Leading blank',
			'reader.doublePageLeadingBlankSubtitle' => 'Insert a blank page at the start of each chapter to shift page pairing',
			'reader.themeMode' => 'Theme mode',
			'reader.autoRead' => 'Auto read',
			'reader.autoReadSubtitle' => 'Auto-scroll and show play/pause button',
			'reader.webtoonScrollDistance' => 'Webtoon scroll distance',
			'reader.webtoonScrollInterval' => 'Webtoon scroll interval',
			'reader.singlePageScrollInterval' => 'Single page scroll interval',
			'reader.background' => 'Background',
			'reader.auto' => 'Auto',
			'reader.black' => 'Black',
			'reader.white' => 'White',
			'reader.grey' => 'Grey',
			'reader.readingExperience' => 'Reading experience',
			'reader.disableAnimation' => 'Disable page animation',
			'reader.disableAnimationSubtitle' => 'Disable full-page turn animation',
			'reader.readFilter' => 'Read filter (dark mode only)',
			'reader.readFilterSubtitle' => 'Only effective in reader, reduces brightness at night',
			'reader.filterIntensity' => 'Filter intensity',
			'reader.einkOptimization' => 'E-ink optimization (landscape)',
			'reader.einkOptimizationSubtitle' => 'Show white screen before image after page turn',
			'reader.einkDelay' => 'White screen duration',
			'reader.sidePadding' => 'Side padding',
			'reader.sidePaddingSubtitle' => 'Customize left/right padding ratio',
			'reader.sidePaddingPercent' => 'Padding per side',
			'reader.batterySubtitle' => 'Off by default, enable as needed',
			'reader.timeSubtitle' => 'Show current time',
			'reader.infoBarPosition' => 'Info bar position',
			'reader.showInStatusBar' => 'Show in status bar',
			'reader.showInStatusBarSubtitle' => 'Top info bar enters system status bar area',
			'reader.edgePadding' => 'Edge padding',
			'reader.infoBarStyle' => 'Info bar style',
			'reader.backgroundOpacity' => 'Background opacity',
			'reader.fontSize' => 'Font size',
			'reader.allHiddenNotice' => 'All hidden, info bar will be completely hidden',
			'reader.edgePaddingDisabled' => 'Edge padding has no effect when horizontally centered',
			'reader.settings' => 'Reader settings',
			'reader.previousChapter' => 'Previous chapter',
			'reader.nextChapter' => 'Next chapter',
			'reader.backToHome' => 'Back to home',
			'reader.jumpToChapterTitle' => 'Jump',
			'reader.jumpToChapterMessage' => ({required Object chapter}) => 'Jump to ${chapter}?',
			'reader.selectChapter' => 'Select chapter',
			'reader.enterFullscreen' => 'Fullscreen (F11)',
			'reader.exitFullscreen' => 'Exit fullscreen',
			'reader.chapterTransition' => 'Chapter transition',
			'reader.transitionSwipeToLoad' => 'Swipe to load',
			'reader.transitionLoaded' => 'Load complete',
			'reader.transitionLoadFailedRetry' => 'Load failed, tap to retry',
			'reader.pullDownToPrevChapter' => 'Pull down to previous chapter',
			'reader.releaseToJumpPrevChapter' => 'Release to jump to previous chapter',
			'reader.releaseToLoadPrevChapter' => 'Release to load previous chapter',
			'reader.pullUpToNextChapter' => 'Pull up to next chapter',
			'reader.releaseToJumpNextChapter' => 'Release to jump to next chapter',
			'reader.releaseToLoadNextChapter' => 'Release to load next chapter',
			'reader.chapterNotDownloaded' => 'Chapter not downloaded',
			'reader.loadFailedWithResult' => ({required Object result}) => '${result}\nLoad failed',
			_ => null,
		} ?? switch (path) {
			'reader.chapterOrder' => ({required Object order}) => 'Chapter ${order}',
			'reader.doubleTapAction' => 'Double-tap action',
			'reader.doubleTapZoom' => 'Double-tap zoom',
			'reader.doubleTapZoomSubtitle' => 'Double-tap image to toggle zoom',
			'reader.doubleTapOpenMenu' => 'Double-tap to open menu',
			'reader.doubleTapOpenMenuSubtitle' => 'Double-tap page to open menu (exclusive with zoom)',
			'reader.volumeKeyPageTurn' => 'Volume key page turn',
			'reader.enableVolumeKeyPageTurn' => 'Enable volume key page turn',
			'reader.volumeKeyPageTurnSubtitle' => 'Use volume keys to turn pages/scroll',
			'reader.screenHeightPercent' => '% screen height',
			'reader.milliseconds' => 'ms',
			'reader.percent' => '%',
			'reader.pixels' => 'px',
			'reader.gesture' => 'Gesture',
			'reader.infoBar' => 'Info bar',
			'reader.pauseAutoRead' => 'Pause auto read',
			'reader.resumeAutoRead' => 'Resume auto read',
			'reader.imageLoadFailedRetry' => ({required Object error}) => '${error}\nLoad failed, tap to retry',
			'reader.imageSavedTo' => ({required Object path}) => 'Image saved to: ${path}',
			'reader.imageSavedToAlbum' => 'Image saved to album',
			'reader.imageSaveFailed' => 'Image save failed',
			'reader.saveImagePermissionDenied' => 'Save failed: please grant album access in settings',
			'reader.imageSaveFailedWithError' => ({required Object error}) => 'Save failed: ${error}',
			'plugin.store' => 'Plugin Store',
			'plugin.searchHint' => 'Search plugin name or author...',
			'plugin.localInstall' => 'Local install',
			'plugin.networkInstall' => 'Network install',
			'plugin.cloudComponents' => 'Cloud components',
			'plugin.loginSuccess' => 'Please complete login in the browser, the host will sync cookies automatically',
			'plugin.chromiumFallbackUnsupported' => 'External Chromium auto-login fallback is not supported on this platform',
			'plugin.switchingToExternalBrowser' => 'Built-in WebView login is limited, switching to external browser...',
			'plugin.chromiumNotFound' => 'No Chromium browser detected, please install Chrome first',
			'plugin.browserSwitched' => ({required Object browser}) => 'Switched to ${browser}, cookies will be synced automatically after login',
			'plugin.invalidLink' => ({required Object url}) => 'Invalid link: ${url}',
			'plugin.cannotOpenLink' => ({required Object url}) => 'Cannot open link: ${url}',
			'plugin.readLocalPluginFailed' => ({required Object error}) => 'Failed to read local plugin: ${error}',
			'plugin.addFromNetwork' => 'Add plugin from network',
			'plugin.urlCannotBeEmpty' => 'URL cannot be empty',
			'plugin.startInstall' => 'Start install',
			'plugin.pluginSettingsTitle' => ({required Object name}) => '${name} settings',
			'plugin.debugConfigUpdated' => 'Plugin debug config updated',
			'plugin.deletePlugin' => 'Delete plugin',
			'plugin.confirmDeletePlugin' => 'Delete this plugin? This will delete plugin and related data.',
			'plugin.deleteFailed' => ({required Object error}) => 'Delete failed: ${error}',
			'plugin.pluginDeleted' => 'Plugin deleted',
			'plugin.executeFailed' => ({required Object error}) => 'Execute failed: ${error}',
			'plugin.debugMode' => 'Debug mode',
			'plugin.debugAddress' => 'Debug address',
			'plugin.deletePluginSubtitle' => 'Delete plugin and related data permanently',
			'plugin.pluginSettings' => 'Plugin settings',
			'plugin.noUserInfo' => 'No user info',
			'plugin.operations' => 'Operations',
			'plugin.management' => 'Plugin management',
			'plugin.installed' => 'Installed',
			'plugin.notInstalled' => 'Not installed',
			'plugin.update' => 'Update',
			'plugin.install' => 'Install',
			'plugin.uninstall' => 'Uninstall',
			'plugin.author' => 'Author',
			'plugin.version' => 'Version',
			'plugin.description' => 'Description',
			'plugin.repo' => 'Repository',
			'plugin.homepage' => 'Homepage',
			'plugin.download' => 'Download',
			'plugin.downloadUpdate' => 'Download update',
			'plugin.noCloudPlugins' => 'No cloud components',
			'plugin.noMatchingPlugins' => 'No matching plugins',
			'plugin.networkInstallHint' => 'Enter plugin script URL',
			'plugin.cloudPluginsLoadFailed' => ({required Object error}) => 'Failed to load cloud components: ${error}',
			'plugin.installingFromCloud' => ({required Object name}) => 'Downloading and installing ${name}...',
			'plugin.installingFromLocal' => 'Installing local plugin...',
			'plugin.installingFromNetwork' => 'Downloading network plugin...',
			'plugin.cloudDownloadFailed' => ({required Object error}) => 'Cloud download failed: ${error}',
			'plugin.networkDownloadFailed' => ({required Object error}) => 'Network plugin download failed: ${error}',
			'plugin.cloudVersion' => ({required Object version}) => 'Cloud ${version}',
			'plugin.localVersion' => ({required Object version}) => 'Local ${version}',
			'plugin.loginTitle' => ({required Object name}) => '${name} Login',
			'plugin.cookieSynced' => 'Login cookie synced',
			'plugin.executeSuccess' => 'Executed successfully',
			'plugin.userInfoTitle' => 'User info',
			'plugin.userInfoLoadFailed' => 'Failed to load user info',
			'plugin.unnamedAction' => 'Unnamed action',
			'plugin.pluginSettingsLoading' => 'Loading plugin settings...',
			'plugin.pluginSettingsLoadFailed' => 'Failed to load plugin settings',
			'plugin.actionNotExecutable' => 'Action not executable: missing fnPath',
			'plugin.saved' => 'Saved',
			'plugin.close' => 'Close',
			'plugin.sync' => 'Sync',
			'plugin.syncSubtitle' => 'Check and update via npm / updateUrl',
			'plugin.syncing' => 'Syncing plugin...',
			'plugin.syncSuccess' => 'Sync successful',
			'plugin.syncFailed' => ({required Object error}) => 'Sync failed: ${error}',
			'plugin.updateSubtitle' => 'Manually reinstall this plugin from a network URL or local file',
			'plugin.updateFromNetwork' => 'Install from network',
			'plugin.updateFromLocal' => 'Install from local',
			'plugin.updateChooseSource' => 'Choose install method',
			'plugin.updating' => 'Updating plugin...',
			'plugin.updateSuccess' => 'Update successful',
			'plugin.updateFailed' => ({required Object error}) => 'Update failed: ${error}',
			'plugin.uuidMismatch' => 'Plugin id mismatch, install rejected',
			'plugin.currentVersion' => ({required Object version}) => 'Current version ${version}',
			'plugin.alreadyLatest' => 'Already up to date',
			'gestureLock.gestureTitle' => 'Gesture unlock',
			'gestureLock.gestureHint' => 'Draw gesture password',
			'gestureLock.pinTitle' => 'Enter PIN',
			'gestureLock.pinHint' => 'Enter reset PIN',
			'gestureLock.atLeast4Points' => 'Connect at least 4 points',
			'gestureLock.confirmGesture' => 'Please draw again to confirm',
			'gestureLock.gestureNotMatch' => 'The two drawings do not match',
			'gestureLock.setSuccess' => 'Set successfully',
			'gestureLock.forgotPassword' => 'Forgot password',
			'gestureLock.incorrectPassword' => 'Incorrect gesture password, please try again',
			'gestureLock.resetPin' => 'Reset PIN',
			'gestureLock.pin' => 'PIN',
			'gestureLock.pinDescription' => 'PIN can reset gesture password. If both are forgotten, you cannot enter the app. Please keep it safe.',
			'gestureLock.pinMinLength' => 'PIN must be at least 4 digits',
			'gestureLock.pinNotMatch' => 'The two PINs do not match',
			'gestureLock.pinIncorrect' => 'Incorrect PIN, please try again',
			'gestureLock.appLocked' => 'App is locked',
			'gestureLock.verifyToUnlock' => 'Please complete gesture verification',
			'gestureLock.resetGesturePassword' => 'Reset gesture password',
			'gestureLock.resetPinHint' => 'Enter the reset PIN you saved',
			'gestureLock.passwordCleared' => 'Password cleared, please set again',
			'gestureLock.setupHintFirst' => 'Please connect at least 4 points',
			'gestureLock.setupHintConfirm' => 'Please draw the same gesture again',
			'gestureLock.setupErrorMinPoints' => 'Connect at least 4 points',
			'gestureLock.setupErrorMismatch' => 'Gestures do not match, please set again',
			'gestureLock.pinHintMinDigits' => 'At least 4 digits',
			'appBootstrap.initializing' => 'Initializing....',
			'appBootstrap.verifyGesture' => 'Please verify gesture password',
			'appBootstrap.pinVerifyFailed' => 'PIN verification failed',
			'appBootstrap.unlockCancelled' => 'Unlock cancelled',
			'appBootstrap.enteringApp' => 'Verification successful, entering app',
			'comments.retry' => 'Retry',
			'comments.noComments' => 'No comments yet',
			'comments.loadMore' => 'Load more',
			'comments.collapseReplies' => 'Collapse replies',
			'comments.replyCount' => ({required Object count}) => '${count} replies',
			'comments.noReplies' => 'No replies yet',
			'comments.loadMoreReplies' => 'Load more replies',
			'comments.postComment' => 'Post comment',
			'comments.postCommentHint' => 'Enter comment content',
			'comments.postReply' => 'Reply',
			'comments.postReplyHint' => 'Enter reply content',
			'comments.cancel' => 'Cancel',
			'comments.confirm' => 'Confirm',
			'comments.postSuccess' => 'Posted successfully',
			'comments.postFailed' => ({required Object error}) => 'Failed to post: ${error}',
			'comments.anonymous' => 'Anonymous',
			'cache.title' => 'Cache settings',
			'cache.currentCache' => 'Current cache',
			'cache.clearCache' => 'Clear cache',
			'cache.clearCacheConfirm' => 'Are you sure you want to clear all cache files? This action cannot be undone.',
			'cache.cleared' => 'Cache cleared',
			'cache.clearFailed' => 'Clear failed',
			'cache.cacheSize' => 'Cache size',
			'cache.recalculate' => 'Recalculate',
			'cache.manualClear' => 'Manual clear cache',
			'cache.manualClearSubtitle' => 'Delete all cache files immediately',
			'cache.clear' => 'Clear',
			'cache.cacheLimit' => 'Cache limit',
			'cache.sizeLimit' => 'Cache size limit',
			'cache.sizeLimitSubtitle' => 'Old cache will be automatically cleared when the limit is reached',
			'cache.autoClean' => 'Auto clean cache',
			'cache.autoCleanSubtitle' => 'Automatically clean old cache when exceeding limit',
			'cache.calculating' => 'Calculating...',
			'cache.calculateFailed' => 'Calculate failed',
			'dataBackup.title' => 'Data Import/Export',
			'dataBackup.exportSection' => 'Export',
			'dataBackup.importSection' => 'Import',
			'dataBackup.includeDownloads' => 'Include downloaded comics',
			'dataBackup.includeDownloadsSubtitle' => 'Pack downloaded comic files when exporting',
			'dataBackup.exportData' => 'Export data',
			'dataBackup.exportDataSubtitle' => 'Pack settings and data into zip',
			'dataBackup.importData' => 'Import data',
			'dataBackup.importDataSubtitle' => 'Restore data from zip file',
			'dataBackup.selectExportDirFailed' => 'Failed to select export directory',
			'dataBackup.exporting' => 'Exporting, please wait…',
			'dataBackup.exportSuccess' => 'Export successful',
			'dataBackup.savedTo' => ({required Object path}) => 'Saved to: ${path}',
			'dataBackup.exportFailed' => 'Export failed',
			'dataBackup.processingBackup' => 'Processing backup file…',
			'dataBackup.selectBackupFailed' => 'Failed to select backup file',
			'dataBackup.readingBackup' => 'Reading backup info…',
			'dataBackup.readBackupFailed' => 'Failed to read backup',
			'dataBackup.importing' => 'Importing, please wait…',
			'dataBackup.importFailed' => 'Import failed',
			'dataBackup.importTitle' => 'Import data',
			'dataBackup.importConfirm' => 'Import will overwrite all current app data. Continue?',
			'dataBackup.includesDownloadsWarning' => 'This backup contains downloaded comic files. Existing downloads will be deleted before import.',
			'dataBackup.versionMismatch' => 'Version mismatch. Data import may have issues. Continue?',
			'dataBackup.exportedVersion' => ({required Object version}) => 'Exported version: ${version}',
			'dataBackup.currentVersion' => ({required Object version}) => 'Current app version: ${version}',
			'dataBackup.kContinue' => 'Continue',
			'dataBackup.importSuccess' => 'Import successful',
			'dataBackup.restartPrompt' => 'Data imported successfully. Please restart the app to apply.',
			'webdavSync.title' => 'Cloud Sync Config',
			'webdavSync.serviceTitle' => ({required Object service}) => '${service} Sync Config',
			'webdavSync.noneTip' => 'Please select a sync service in Settings first, then return here to fill in the configuration.',
			'webdavSync.deleteConfig' => 'Delete Config',
			'webdavSync.testAndSave' => 'Test & Save',
			'webdavSync.faq' => 'FAQ',
			'webdavSync.webdavHost' => 'WebDAV URL',
			'webdavSync.username' => 'Username',
			'webdavSync.password' => 'Password',
			'webdavSync.s3Endpoint' => 'Endpoint',
			'webdavSync.s3EndpointHint' => 'e.g. s3.amazonaws.com',
			'webdavSync.s3AccessKey' => 'Access Key',
			'webdavSync.s3SecretKey' => 'Secret Key',
			'webdavSync.s3Bucket' => 'Bucket Name',
			'webdavSync.s3Region' => 'Region (optional)',
			'webdavSync.s3Port' => 'Port (optional)',
			'webdavSync.useSsl' => 'Use HTTPS/SSL',
			'webdavSync.pathStyle' => 'Path-Style',
			'webdavSync.pathStyleSubtitle' => 'Self-hosted MinIO usually requires this option',
			'webdavSync.connectingWebdav' => 'Connecting to WebDAV server...',
			'webdavSync.webdavConnected' => 'WebDAV connected and settings saved.',
			'webdavSync.webdavConnectFailed' => ({required Object error}) => 'Connection failed. Please check network or WebDAV address.\n${error}',
			'webdavSync.invalidPort' => 'Invalid port. Please enter a number between 0 and 65535.',
			'webdavSync.connectingS3' => 'Connecting to S3 service...',
			'webdavSync.s3Connected' => 'S3 connected and settings saved.',
			'webdavSync.s3ConnectFailed' => ({required Object error}) => 'Connection failed. Please check S3 configuration.\n${error}',
			'webdavSync.close' => 'Close',
			'webdavSync.success' => 'Success',
			'webdavSync.error' => 'Error',
			'webdavSync.faqMarkdown' => '### What can be synced?\n- Currently syncs Bika history, JM favorites, and JM history.\n\n### How to configure WebDAV?\n- Fill in WebDAV URL, username, password, then tap Test & Save.\n\n### How to configure S3?\n- Endpoint examples: `s3.amazonaws.com`, `s3.filebase.com`, `play.min.io`.\n- For self-hosted MinIO, fill in a custom port and disable SSL if necessary.\n\n### How often does auto-sync run?\n- Every 5 minutes.\n\n### How to trigger a manual sync?\n- Tap Test & Save on the sync config page.\n- Or toggle the auto-sync switch in Settings.',
			'realSr.title' => 'Image Super-Resolution (Experimental)',
			'realSr.unlimited' => 'Unlimited',
			'realSr.modelDownloadFailed' => 'Model download failed',
			'realSr.generalSection' => 'General',
			'realSr.autoUpscaleSection' => 'Auto Upscale',
			'realSr.autoUpscale' => 'Auto Upscale',
			'realSr.autoUpscaleSubtitleUnavailable' => 'Model not downloaded; auto upscale will not work',
			'realSr.autoUpscaleSubtitleAvailable' => 'Automatically upscale when downloading or loading images',
			'realSr.conditionSection' => 'Condition',
			'realSr.resolutionThreshold' => 'Resolution Threshold',
			'realSr.resolutionThresholdSubtitle' => 'Only auto-upscale when image width is below this value',
			'realSr.performanceSection' => 'Performance',
			'realSr.concurrency' => 'Concurrency',
			'realSr.concurrencySubtitle' => 'Higher values suit high-end GPUs; mobile/low-end devices should keep it at 1',
			'realSr.tileSize' => 'Tile Size',
			'realSr.tileSizeSubtitle' => 'Set smaller if crashes occur; 0 means no tiling; desktop can try 0',
			'realSr.modelSection' => 'Model',
			'realSr.model' => 'Model',
			'realSr.modelSubtitle' => 'Switching model family resets variant options',
			'realSr.noiseLevel' => 'Denoise Level',
			'realSr.noiseLevelSubtitle' => 'This option varies with the selected model',
			'realSr.blockInfo' => 'Tile Info',
			'realSr.blockInfoTooltip' => 'blockSize is the model input size including reflection padding;\ncontent block = blockSize - 2×shrinkSize, which is the actual拼接 output region.',
			'realSr.blockInfoFormat' => ({required Object contentSize, required Object blockSize, required Object shrinkSize}) => 'Content block ${contentSize}×${contentSize}, model input ${blockSize}×${blockSize} (with ${shrinkSize}px reflection padding)',
			'realSr.androidSuperResolution' => 'Android Super-Resolution',
			'realSr.androidSuperResolutionSubtitle' => 'Currently uses waifu2x upconv anime model, 2x upscale',
			'realSr.desktopStrategy' => 'Upscale Strategy',
			'realSr.desktopStrategySubtitle' => 'Efficiency priority uses waifu2x; quality priority uses Real-CUGAN',
			'realSr.desktopNoiseLevel' => 'Denoise Level',
			'realSr.desktopNoiseLevelSubtitle' => 'Conservative suits normal comics; higher levels produce stronger smearing',
			'realSr.modelManagementSection' => 'Model Management',
			'realSr.downloadingModel' => 'Downloading model',
			'realSr.modelReady' => 'Model ready',
			'realSr.redownload' => 'Redownload',
			'realSr.deleteModel' => 'Delete Model',
			'realSr.deleteModelConfirm' => 'Delete the downloaded super-resolution model? You will need to download it again before use.',
			'realSr.modelDeleted' => 'Model deleted',
			'realSr.modelDeleteFailed' => 'Failed to delete model',
			'realSr.modelNotDownloaded' => 'Model not downloaded',
			'realSr.modelNotDownloadedSubtitle' => 'Download model before using super-resolution',
			'realSr.downloadModel' => 'Download Model',
			'realSr.modeEfficiency' => 'Efficiency priority',
			'realSr.modeQuality' => 'Quality priority',
			'realSr.noiseConservative' => 'Conservative',
			'realSr.noise0' => 'No denoise',
			'realSr.noise1' => 'Denoise 1',
			'realSr.noise2' => 'Denoise 2',
			'realSr.noise3' => 'Denoise 3',
			'realSr.variantWaifu2xAnime' => 'waifu2x upconv anime',
			'realSr.variantRealCuganDenoise' => ({required Object noise}) => 'Real-CUGAN denoise ${noise}',
			'realSr.coremlSpeed' => 'Speed priority (waifu2x)',
			'realSr.coremlQuality' => 'Quality priority (Real-CUGAN)',
			'realSr.coremlNoise0' => 'Denoise 0',
			'realSr.coremlNoDenoise' => 'No denoise',
			'realSr.coremlInputHint' => 'Enter input image absolute path or asset path',
			'realSr.coremlStartUpscale' => 'Start upscale',
			'realSr.coremlStatusFillInput' => 'Please fill in the input image path',
			'realSr.coremlStatusNoModelFile' => 'No model files available for current family',
			'realSr.coremlStatusPreparing' => 'Preparing resources...',
			'realSr.coremlStatusUpscaling' => 'Upscaling...',
			'realSr.coremlStatusDone' => ({required Object outputPath, required Object size}) => 'Done\n${outputPath}\nsize: ${size} bytes',
			'realSr.coremlStatusFailed' => ({required Object error}) => 'Failed: ${error}',
			'realSr.coremlModelOption' => 'Model option (denoise level)',
			'realSr.coremlGeneralOption' => 'General option (scale)',
			'realSr.coremlTileInfo' => 'Tile info',
			'about.title' => 'About app',
			'about.version' => ({required Object version}) => 'Version: ${version}',
			'about.loading' => 'Loading...',
			'about.fetchFailed' => 'Failed to load',
			'about.networkError' => 'Network error',
			'about.projectAddress' => 'Project',
			'about.projectAddressDesc' => 'Like this project? Give it a star on GitHub!',
			'about.projectLink' => 'Go to GitHub repo (deretame/Breeze) ⭐',
			'about.contact' => 'Contact',
			'about.contactDesc' => 'Have ideas or questions? Feel free to reach out~',
			'about.feedback' => 'Feedback',
			'about.feedbackDesc' => 'Found a bug or have a new idea?',
			'about.feedbackLink' => 'Open a GitHub Issue',
			'about.contributors' => 'Contributors',
			'about.contributorsCount' => ({required Object count}) => '${count}',
			'about.contributionsTooltip' => ({required Object login, required Object count}) => '${login} (${count} commits)',
			'about.disclaimer' => 'Disclaimer',
			'about.disclaimerTitle' => 'Open Source Disclaimer',
			'about.disclaimerItem1Title' => '1. Nature and Statement',
			'about.disclaimerItem1Content' => 'This project is open-source software, independently developed and maintained by the author. It is provided "as-is". The developer makes no express or implied warranties regarding functionality, stability, security, or fitness for purpose.',
			'about.disclaimerItem2Title' => '2. Limitation of Liability',
			'about.disclaimerItem2Content' => 'The developer shall not be liable for any direct, indirect, special, incidental, or consequential damages arising from use, modification, or distribution of this project (including but not limited to direct use, secondary development, or integration into other projects). These damages may include but are not limited to data loss, device damage, business interruption, lost profits, or other economic losses.',
			'about.disclaimerItem3Title' => '3. User Responsibility',
			'about.disclaimerItem3Content' => 'Users should evaluate suitability and assume all risks when using this project. Users must ensure their use complies with applicable laws, regulations, and ethical standards. The developer is not responsible for consequences resulting from violations of laws or misuse.',
			'about.disclaimerItem4Title' => '4. Third-Party Dependencies and Resources',
			'about.disclaimerItem4Content' => 'This project may depend on or reference third-party libraries, tools, services, or other resources. The developer is not responsible for the content, functionality, security, or legality of these third-party resources. Users should evaluate and assume risks themselves.',
			'about.disclaimerItem5Title' => '5. No Warranty',
			'about.disclaimerItem5Content' => 'The developer expressly disclaims all warranties, including but not limited to: merchantability; fitness for a particular purpose; non-infringement; and error-free or uninterrupted operation.',
			'about.disclaimerItem6Title' => '6. Modification and Termination',
			'about.disclaimerItem6Content' => 'The developer reserves the right to modify, suspend, or terminate this project at any time without prior notice. The developer is not responsible for any consequences arising from such changes.',
			'about.disclaimerItem7Title' => '7. Contributor Responsibility',
			'about.disclaimerItem7Content' => 'If external contributions are accepted, contributors act in their personal capacity and do not represent the developer\'s views or positions. The developer is not responsible for contributor actions or content.',
			'about.disclaimerItem8Title' => '8. Legal Compliance',
			'about.disclaimerItem8Content' => 'Users must ensure their use complies with applicable laws and regulations. The developer is not responsible for consequences resulting from legal violations.',
			'about.disclaimerImportant' => 'Important Notice',
			'about.disclaimerImportantContent' => 'Please read and understand this disclaimer before using this project. If you do not agree with any term, stop using it immediately. Continued use constitutes acceptance of the entire disclaimer.',
			'about.checkUpdate' => 'Check update',
			'about.alreadyLatest' => 'Already latest version',
			'about.updateAvailable' => 'New version available',
			'about.license' => 'Open source licenses',
			'about.privacy' => 'Privacy policy',
			'oldHome.title' => 'Home',
			'oldHome.search' => 'Search',
			'oldHome.hotSearch' => 'Hot Search',
			'oldHome.navigation' => 'Navigation',
			'oldHome.recommend' => 'Recommend',
			'oldHome.latest' => 'Latest',
			'oldHome.cloudFavorite' => 'Cloud Favorites',
			'oldHome.list' => 'List',
			'oldHome.function' => 'Function',
			'oldHome.close' => 'Close',
			'oldHome.loadFailedRetry' => 'Load failed, please retry.',
			'oldHome.loadSectionFailed' => ({required Object title, required Object error}) => 'Failed to load ${title}\n${error}',
			'oldHome.empty' => 'No content',
			'oldHome.loadMoreFailed' => 'Failed to load more, tap to retry',
			'oldHome.loadMore' => 'Load more',
			'oldHome.noMore' => 'No more',
			'more.common' => 'Common',
			'more.others' => 'Others',
			'more.downloadTasks' => 'Download Tasks',
			'more.comicFollow' => 'Updates',
			'more.changelog' => 'Changelog',
			'search.title' => 'Search',
			'search.searchHint' => 'Search...',
			'search.selectSource' => 'Select Source',
			'search.advancedSearchNotSupported' => 'Current plugin does not support advanced search',
			'search.advancedSearchOptions' => 'Advanced Search Options',
			'search.notSelected' => 'Not selected',
			'search.selectedCount' => ({required Object count}) => '${count} selected',
			'search.history' => 'Search History',
			'search.clearHistory' => 'Clear History',
			'search.newestFirst' => 'Current: newest first',
			'search.oldestFirst' => 'Current: oldest first',
			'search.descending' => 'Newest first',
			'search.ascending' => 'Oldest first',
			'search.noHistory' => 'No search history',
			'search.tipsTitle' => '🔍 Search Tips',
			'search.exactSearchTitle' => 'Exact search (AND)',
			'search.exactSearchExample' => 'colorful + married',
			'search.exactSearchDesc' => 'Show results containing both keywords',
			'search.excludeSearchTitle' => 'Exclude search',
			'search.excludeSearchExample' => 'colorful - married',
			'search.excludeSearchDesc' => 'Show \'colorful\' results excluding \'married\'',
			'search.fuzzySearchTitle' => 'Fuzzy search (OR)',
			'search.fuzzySearchExample' => 'colorful married',
			'search.fuzzySearchDesc' => 'Show results containing any keyword',
			'search.selectCategory' => 'Select Category',
			'search.dataSource' => 'Data Source',
			'search.sortBy' => 'Sort By',
			'search.newestToOldest' => 'Newest to oldest',
			'search.oldestToNewest' => 'Oldest to newest',
			'search.mostLikes' => 'Most likes',
			'search.mostViews' => 'Most views',
			'search.selectSourceTooltip' => 'Select source',
			'search.hasResults' => 'With results',
			'search.showErrors' => 'Show errors',
			'search.resultCount' => ({required Object count}) => '${count} results',
			'search.noResults' => 'No results',
			'search.loadFailedForSource' => ({required Object source}) => 'Failed to load ${source}',
			'discover.title' => 'Discover',
			'discover.search' => 'Search',
			'discover.settings' => 'Settings',
			'discover.pluginManagement' => 'Plugin Management',
			'discover.noPlugins' => 'No plugins available. Go to the plugin store to install one~',
			'discover.pluginStore' => 'Plugin Store',
			'discover.browseInstall' => 'Browse & Install',
			'discover.noPluginForSearch' => 'No plugins available, cannot search',
			'discover.pluginInfoLoadFailed' => ({required Object error}) => 'Failed to load plugin info: ${error}',
			'discover.pluginCapability' => 'Plugin Capability',
			'discover.disabled' => 'Disabled',
			'discover.unnamed' => 'Unnamed',
			'discover.pluginEnableFailed' => ({required Object error}) => 'Failed to enable plugin: ${error}',
			'discover.pluginCloseFailed' => ({required Object error}) => 'Failed to disable plugin: ${error}',
			'discover.pluginDebugLoadFailed' => ({required Object error}) => 'Plugin debug load failed, reverted to database: ${error}',
			'searchResult.enterPageNumber' => 'Enter page number',
			'searchResult.pleaseEnterNumber' => 'Please enter a number',
			'searchResult.returnToTop' => 'Return to top',
			'searchResult.jumpToPage' => 'Jump to page',
			'searchResult.jump' => 'Jump',
			'searchResult.retry' => 'Tap to retry',
			'comicList.defaultTitle' => 'Comic List',
			'comicList.missingSource' => 'Missing plugin source, cannot load list',
			'comicList.reload' => 'Reload',
			'comicList.loadFailedRetry' => 'Load failed, please retry.',
			'comicList.nothingHere' => 'Nothing here',
			'comicList.filter' => 'Filter',
			'comicList.subCategory' => 'Subcategory',
			'comicList.levelCategory' => ({required Object level}) => 'Level ${level}',
			'comicList.missingListConfig' => 'Missing list request configuration',
			'comicList.missingFnPath' => 'List request missing fnPath',
			'comicEntry.updatedAt' => ({required Object time}) => 'Updated: ${time}',
			'comicEntry.finished' => 'Finished',
			'comicEntry.ongoing' => 'Ongoing',
			'comicEntry.likes' => ({required Object count}) => 'Likes ${count}',
			'comicEntry.views' => ({required Object count}) => 'Views ${count}',
			'comicEntry.deleteFavorite' => 'Delete Favorite',
			'comicEntry.deleteFavoriteConfirm' => ({required Object title}) => 'Delete favorite record for "${title}"?',
			'comicEntry.deleteHistory' => 'Delete History',
			'comicEntry.deleteHistoryConfirm' => ({required Object title}) => 'Delete history record for "${title}"?',
			'comicEntry.deleteDownload' => 'Delete Download',
			'comicEntry.deleteDownloadConfirm' => ({required Object title}) => 'Delete download record and files for "${title}"?',
			'comicEntry.deleteFailed' => 'Delete failed',
			'comicFollow.title' => 'Updates',
			'comicFollow.loadFailed' => ({required Object result}) => 'Load failed: ${result}',
			'comicFollow.empty' => 'No followed comics',
			'comicFollow.emptyHint' => 'Tap the follow button on a comic detail page to add it here',
			'comicFollow.unfollow' => 'Unfollow',
			'comicFollow.unfollowConfirm' => ({required Object title}) => 'Stop following "${title}"?',
			'comicFollow.unfollowed' => 'Unfollowed',
			'comicFollow.latestChapterFailed' => 'Failed to get latest chapter',
			'comicFollow.newChapters' => ({required Object diff, required Object total}) => '${diff} new chapters, ${total} total',
			'comicFollow.latestCount' => ({required Object count}) => 'Latest ${count} chapters',
			'comicFollow.fetchFailed' => 'Fetch failed',
			'comicFollow.newChaptersShort' => ({required Object diff}) => '${diff} new',
			'comicFollow.update' => 'Update',
			'comicFollow.retry' => 'Retry',
			'comicFollow.updateChannelName' => 'Comic update reminder',
			'comicFollow.updateChannelDesc' => 'Pushed when followed comics have new chapters',
			'comicFollow.updateTitle' => 'Follow update',
			'comicFollow.updateBodySingle' => '1 followed comic has updates',
			'comicFollow.updateBodyMultiple' => ({required Object count}) => '${count} followed comics have updates',
			'changelog.title' => 'Changelog',
			'changelog.loadFailed' => 'Load failed',
			'changelog.loadFailedWithError' => ({required Object error}) => 'Load failed: ${error}',
			'changelog.cannotOpenLink' => ({required Object url}) => 'Cannot open link: ${url}',
			'changelog.checkNetwork' => 'Load failed, please check network',
			'changelog.retry' => 'Retry',
			'changelog.empty' => 'No changelog',
			'changelog.publishedAt' => ({required Object date}) => 'Published at ${date}',
			'changelog.viewInBrowser' => 'View in browser',
			'changelog.attachments' => 'Attachments',
			'webview.title' => 'Webpage',
			'webview.cannotOpenLink' => ({required Object uri}) => 'Cannot open link: ${uri}',
			'webview.invalidLink' => 'Invalid link, cannot open webpage',
			'webview.emptyLink' => '(empty link)',
			'webview.loadFailed' => 'Webpage load failed',
			'webview.retry' => 'Retry',
			'webview.openInExternalBrowser' => 'Open in external browser',
			'webview.windowClosed' => 'WebView window closed',
			'webview.openedInExternalWindow' => 'Webpage opened in external window',
			'webview.back' => 'Back',
			'webview.closeWindow' => 'Close WebView window',
			'webview.loadError' => ({required Object error}) => 'Load failed (${error})',
			'webview.httpErrorStatus' => ({required Object statusCode}) => 'Server returned abnormal status code: ${statusCode}',
			'oldRanking.bikaRanking' => 'Bika Ranking',
			'oldRanking.jmRanking' => 'JM Ranking',
			'oldRanking.switchSource' => 'Switch',
			'login.title' => 'Login',
			'login.missingPluginId' => 'Missing plugin identifier, cannot open login page',
			'login.loadConfigFailed' => ({required Object error}) => 'Failed to load login config: ${error}',
			'login.insufficientFields' => 'Plugin returned insufficient login fields',
			'login.invalidCredentials' => 'Invalid username or password, please try again',
			'login.configNotReady' => 'Login config not ready, please retry later',
			'login.loggingIn' => 'Logging in, please wait...',
			'login.loginSuccess' => 'Login successful',
			'login.loginFailed' => 'Login failed',
			'login.loginButton' => 'Login',
			'login.retry' => 'Retry',
			'fontSetting.title' => 'Font Settings',
			'fontSetting.clear' => 'Clear',
			'fontSetting.hint' => 'Select font files for each weight.',
			'fontSetting.loadFailed' => 'Font load failed',
			'fontSetting.cleared' => 'Cleared',
			'fontSetting.saved' => 'Saved',
			'fontSetting.allCleared' => 'All cleared',
			'fontSetting.noFileSelected' => 'No file selected',
			'fontSetting.clearFile' => 'Clear',
			'fontSetting.selectFile' => 'Select File',
			'fontSetting.sampleText' => 'Innovation in China 中国智造，慧及全球 0123456789',
			'download.title' => 'Download tasks',
			'download.startDownload' => 'Start Download',
			'download.selectChaptersPrompt' => 'Please select chapters to download',
			'download.taskStarted' => 'Download task started',
			'download.taskStartFailed' => ({required Object error}) => 'Failed to start download task: ${error}',
			'download.noTasks' => 'No download tasks',
			'download.downloading' => 'Downloading',
			'download.pending' => ({required Object count}) => 'Pending (${count})',
			'download.taskDeleted' => 'Task deleted',
			'download.cancelTask' => 'Cancel Task',
			'download.cancelTaskConfirm' => ({required Object comicName}) => 'Cancel download of ${comicName}?',
			'download.paused' => 'Paused',
			_ => null,
		} ?? switch (path) {
			'download.completed' => 'Completed',
			'download.failed' => 'Failed',
			'download.startAll' => 'Start all',
			'download.pauseAll' => 'Pause all',
			'download.clearCompleted' => 'Clear completed',
			'download.statusFetchingComicInfo' => 'Fetching comic info...',
			'download.statusDownloadingCover' => 'Downloading cover...',
			'download.statusFetchingChapterInfo' => 'Fetching chapter info...',
			'download.statusFetchingChapterInfoProgress' => ({required Object completed, required Object total, required Object percent}) => 'Fetching chapter info... (${completed}/${total}, ${percent}%)',
			'download.statusDownloadProgress' => ({required Object percent}) => 'Comic download progress: ${percent}%',
			'download.statusDownloadProgressComplete' => 'Comic download progress: 100%',
			'download.statusStartDownload' => 'Start downloading...',
			'download.statusWaiting' => 'Waiting',
			'download.statusCancelling' => 'Cancelling...',
			'download.toastDownloadComplete' => ({required Object comicName}) => '${comicName} download complete',
			'download.toastDownloadFailed' => ({required Object comicName, required Object error}) => '${comicName} download failed ${error}',
			'download.toastTaskAlreadyExists' => ({required Object comicName}) => '${comicName} task already exists',
			'download.notificationCompleteTitle' => 'Download complete',
			'download.notificationFailedTitle' => 'Download failed',
			'foregroundTask.channelName' => 'Foreground download task',
			'foregroundTask.channelDescription' => 'Keeps download tasks running in the background',
			'foregroundTask.waitingForTask' => 'Waiting for download tasks...',
			'foregroundTask.cancel' => 'Cancel',
			'foregroundTask.notificationPermissionRequired' => 'Downloads need notification permission to start foreground task, please allow in the system dialog',
			'foregroundTask.cannotStartWithoutPermission' => 'Cannot start download: please enable notification permission in system settings',
			'foregroundTask.startFailed' => ({required Object error}) => 'Foreground service start failed: ${error}',
			'notification.permissionRequired' => 'Please enable notification permission',
			'notification.macPermissionRequired' => 'Please enable notification permission in system settings',
			'update.newVersion' => 'New version available',
			'update.goToGitHub' => 'Go to GitHub',
			'update.downloadInstall' => 'Download & install',
			'update.apkDownloadFailed' => 'Download failed, please try again later',
			'update.installPermissionRequired' => 'Please grant install app permission',
			'update.unknownArch' => 'Unknown',
			'dialog.hideOrClose' => 'Hide to tray or close app',
			'dialog.rememberChoice' => 'Remember my choice',
			_ => null,
		};
	}
}
