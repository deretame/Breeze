// import 'package:cherry_toast/cherry_toast.dart';
// import 'package:cherry_toast/resources/arrays.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:realm/realm.dart';
// import 'package:zephyr/config/global.dart';
// import 'package:zephyr/network/http/http_request.dart';
//
// import '../config/authorization.dart';
// import '../config/global_setting.dart';
// import '../realm/shield_categories.dart';
// import '../util/router.dart';
// import '../util/state_management.dart';
//
// class InitPage extends ConsumerStatefulWidget {
//   const InitPage({
//     super.key,
//   });
//
//   @override
//   ConsumerState<InitPage> createState() => _InitPageState();
// }
//
// class _InitPageState extends ConsumerState<InitPage> {
//   bool needLogin = true;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback(
//       (_) async {
//         await isFirstInit();
//         await initRealm();
//         await getAuthorizationStatus();
//         await getLoginStatus();
//       },
//     );
//   }
//
//   Future<void> isFirstInit() async {
//     if (getFirstInit() == true) {
//       await firstInit();
//     }
//   }
//
//   Future<void> firstInit() async {
//     setImageQuality("original");
//   }
//
//   Future<void> getAuthorizationStatus() async {
//     final colorNotifier = ref.read(defaultColorProvider);
//     needLogin = false;
//     if (getAuthorization() == null &&
//         (getAccount() == null || getPassword() == null)) {
//       CherryToast.warning(
//         description: Text("没有获取到登录状态哦，请先登录呢~",
//             style: TextStyle(color: colorNotifier.defaultTextColor)),
//         animationType: AnimationType.fromTop,
//         animationDuration: const Duration(milliseconds: 3000),
//         toastDuration: const Duration(milliseconds: 1500),
//         autoDismiss: true,
//         backgroundColor: colorNotifier.defaultBackgroundColor,
//       ).show(context);
//       needLogin = true;
//       Future.delayed(const Duration(seconds: 1), () {
//         // 检查State是否仍然挂载
//         if (!mounted) return;
//         navigateToNoReturn(context, "/login");
//       });
//     }
//   }
//
//   Future<void> getLoginStatus() async {
//     if (getAuthorization() == null &&
//         (getAccount() == null || getPassword() == null)) {
//       return;
//     }
//
//     final colorNotifier = ref.read(defaultColorProvider);
//     CherryToast.info(
//       description: Text(
//         "获取用户信息中，请稍候...",
//         style: TextStyle(color: colorNotifier.defaultTextColor),
//       ),
//       animationType: AnimationType.fromTop,
//       animationDuration: const Duration(milliseconds: 3000),
//       toastDuration: const Duration(milliseconds: 1500),
//       autoDismiss: true,
//       backgroundColor: colorNotifier.defaultBackgroundColor,
//     ).show(context);
//
//     while (true) {
//       try {
//         var response = await getPersonalInfo();
//         if (response['error'] != null) {
//           if (response['data']['code'] == 401 &&
//               response['data']['message'] == 'unauthorized') {
//             if (!mounted) return;
//             CherryToast.warning(
//               description: Text(
//                 "登录状态失效，尝试重新登陆...",
//                 style: TextStyle(color: colorNotifier.defaultTextColor),
//               ),
//               animationType: AnimationType.fromTop,
//               animationDuration: const Duration(milliseconds: 3000),
//               toastDuration: const Duration(milliseconds: 1500),
//               autoDismiss: true,
//               backgroundColor: colorNotifier.defaultBackgroundColor,
//             ).show(context);
//             if (getAccount() == null || getPassword() == null) {
//               CherryToast.warning(
//                 description: Text(
//                   "未发现有效的登录信息，请重新登录...",
//                   style: TextStyle(color: colorNotifier.defaultTextColor),
//                 ),
//                 animationType: AnimationType.fromTop,
//                 animationDuration: const Duration(milliseconds: 3000),
//                 toastDuration: const Duration(milliseconds: 1500),
//                 autoDismiss: true,
//                 backgroundColor: colorNotifier.defaultBackgroundColor,
//               ).show(context);
//               navigateToNoReturn(context, "/login");
//             } else {
//               final result = await login(getAccount()!, getPassword()!);
//
//               if (!mounted) return;
//
//               if (result == "true") {
//                 CherryToast.success(
//                   description: Text(
//                     "登录成功！",
//                     style: TextStyle(color: colorNotifier.defaultTextColor),
//                   ),
//                   animationType: AnimationType.fromTop,
//                   animationDuration: const Duration(milliseconds: 3000),
//                   toastDuration: const Duration(milliseconds: 1500),
//                   autoDismiss: true,
//                   backgroundColor: colorNotifier.defaultBackgroundColor,
//                 ).show(context);
//                 continue;
//               } else {
//                 CherryToast.warning(
//                   description: Text(
//                     "登录失败，正在重试...",
//                     style: TextStyle(color: colorNotifier.defaultTextColor),
//                   ),
//                   animationType: AnimationType.fromTop,
//                   animationDuration: const Duration(milliseconds: 3000),
//                   toastDuration: const Duration(milliseconds: 1500),
//                   autoDismiss: true,
//                   backgroundColor: colorNotifier.defaultBackgroundColor,
//                 ).show(context);
//                 continue;
//               }
//             }
//           } else {
//             continue; // Retry on other errors
//           }
//         } else {
//           if (!mounted) return;
//           CherryToast.success(
//             description: Text(
//               "获取用户信息成功！",
//               style: TextStyle(color: colorNotifier.defaultTextColor),
//             ),
//             animationType: AnimationType.fromTop,
//             animationDuration: const Duration(milliseconds: 3000),
//             toastDuration: const Duration(milliseconds: 1500),
//             autoDismiss: true,
//             backgroundColor: colorNotifier.defaultBackgroundColor,
//           ).show(context);
//           // 检查State是否仍然挂载
//           if (!mounted) return;
//           navigateToNoReturn(context, "/main");
//         }
//       } catch (e) {
//         CherryToast.error(
//           description: Text(
//             "获取用户信息失败，正在重试...",
//             style: TextStyle(color: colorNotifier.defaultTextColor),
//           ),
//           animationType: AnimationType.fromTop,
//           animationDuration: const Duration(milliseconds: 3000),
//           toastDuration: const Duration(milliseconds: 1500),
//           autoDismiss: true,
//           backgroundColor: colorNotifier.defaultBackgroundColor,
//         ).show(context);
//         Future.delayed(const Duration(seconds: 1), () {});
//         continue;
//       }
//     }
//   }
//
//   Future<void> initRealm() async {
//     final shieldedCategories = Configuration.local([ShieldedCategories.schema]);
//     final realm = Realm(shieldedCategories);
//     debugPrint("schemaVersion: ${shieldedCategories.schemaVersion}");
//
//     final shieldedCategoriesList = realm.all<ShieldedCategories>();
//
//     if (shieldedCategoriesList.isEmpty) {
//       debugPrint("Realm is empty");
//       final temp =
//           ShieldedCategories("ShieldedCategories", map: shieldCategoryMapRealm);
//       realm.write(() => realm.add(temp));
//       final shieldedCategoriesListAfterAdd = realm.all<ShieldedCategories>();
//       debugPrint(
//           "Init Realm: ${shieldedCategoriesListAfterAdd.map((e) => e.toString()).toList()}");
//
//       final getPrimitiveMap = temp.dynamic.getMap('map');
//       debugPrint("Get Map: $getPrimitiveMap");
//     } else {
//       debugPrint("Realm is not empty");
//       for (var category in shieldedCategoriesList) {
//         debugPrint("ShieldedCategory: ${category.toString()}");
//
//         final map = category.dynamic.getMap('map');
//         debugPrint("Map: $map");
//       }
//       // 重新查询以确保获取最新的对象
//       var temp = realm.find<ShieldedCategories>("ShieldedCategories");
//
//       // 将RealmMap转换为Dart Map
//       Map<String, bool> dartMap = {
//         for (var key in temp!.map.keys) key: temp.map[key] as bool
//       };
//
//       // 打印Dart Map
//       debugPrint("Dart Map: $dartMap");
//
//       // 更新全局变量
//       shieldCategoryMapRealm = dartMap;
//     }
//
//     realm.close();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final colorNotifier = ref.watch(defaultColorProvider);
//     colorNotifier.initialize(context); // 显式初始化
//
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
//           children: <Widget>[
//             LoadingAnimationWidget.threeRotatingDots(
//               color: Color(Colors.blue.value),
//               size: 100,
//             ),
//             SizedBox(height: 20), // 在加载动画和文字之间添加一些间距
//             Text(
//               '初始化中，请稍候...',
//               style: TextStyle(fontSize: 24), // 设置文字大小
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
