import 'package:isar/isar.dart';
part 'all_settings.g.dart';

@collection
class AllSettings {
  /// 主键ID，固定为1因为只需要一个实例
  Id id = 1;

  double windowWidth = 1280;
  double windowHeight = 720;
}
