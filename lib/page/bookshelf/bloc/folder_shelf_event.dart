import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/page/bookshelf/cubit/search_status.dart';

part 'folder_shelf_event.freezed.dart';

@freezed
sealed class FolderShelfEvent with _$FolderShelfEvent {
  const factory FolderShelfEvent.loadRequested({SearchStatusState? search}) =
      FolderShelfLoadRequested;
  const factory FolderShelfEvent.enterFolder(String path) =
      FolderShelfEnterFolder;
  const factory FolderShelfEvent.goBack() = FolderShelfGoBack;
  const factory FolderShelfEvent.goHome() = FolderShelfGoHome;
  const factory FolderShelfEvent.toggleSort() = FolderShelfToggleSort;
  const factory FolderShelfEvent.createFolder(String name) =
      FolderShelfCreateFolder;
  const factory FolderShelfEvent.deleteFolder(String path) =
      FolderShelfDeleteFolder;
  const factory FolderShelfEvent.renameFolder(String path, String newName) =
      FolderShelfRenameFolder;
  const factory FolderShelfEvent.enterSelectionMode() =
      FolderShelfEnterSelectionMode;
  const factory FolderShelfEvent.exitSelectionMode() =
      FolderShelfExitSelectionMode;
  const factory FolderShelfEvent.toggleFolderSelection(String path) =
      FolderShelfToggleFolderSelection;
  const factory FolderShelfEvent.toggleComicSelection(String comicUniqueKey) =
      FolderShelfToggleComicSelection;
  const factory FolderShelfEvent.selectAll() = FolderShelfSelectAll;
  const factory FolderShelfEvent.moveSelected(
    Set<String> targetPaths, {
    Set<String>? sourceFolderPaths,
  }) = FolderShelfMoveSelected;
  const factory FolderShelfEvent.copySelected(Set<String> targetPaths) =
      FolderShelfCopySelected;
  const factory FolderShelfEvent.deleteSelected() = FolderShelfDeleteSelected;
}
