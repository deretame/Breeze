# 汇总一些常用的flutter命令

# 构建安装包
flutter build apk --split-per-abi --no-shrink

# 生成json_serializable freezed 代码
flutter pub run build_runner build --delete-conflicting-outputs

# 生成realm的dart代码
dart run realm generate