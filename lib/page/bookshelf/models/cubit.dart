import 'package:zephyr/page/bookshelf/cubit/search_status.dart';

// --- 用来区分不同用途的 SearchStatusCubit ---
class FavoriteCubit extends SearchStatusCubit {}

class HistoryCubit extends SearchStatusCubit {}

class DownloadCubit extends SearchStatusCubit {}

class JmFavoriteCubit extends SearchStatusCubit {}
