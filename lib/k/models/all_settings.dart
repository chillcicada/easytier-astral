import 'package:isar/isar.dart';
part 'all_settings.g.dart';

@collection
class AllSettings {
  /// 主键ID，固定为1因为只需要一个实例
  Id id = 1;

  /// 当前启用的房间
  int? room;

  /// 玩家名称
  String? playerName;

  /// 监听列表
  List<String>? listenList;

  /// 自定义vpn网段
  List<String> customVpn = [];

  ///用户列表简约模式
  bool userListSimple = true;

  /// 关闭最小化到托盘
  bool closeMinimize = true;

  /// 开机自启
  bool startup = false;

  /// 启动后最小化
  bool startupMinimize = false;

  /// 启动后自动连接
  bool startupAutoConnect = false;

  /// 自动设置网卡跃点
  bool autoSetMTU = true;

  /// 参与测试版
  bool beta = false;

  /// 自动检查更新
  bool autoCheckUpdate = true;

  /// 下载加速
  String downloadAccelerate = 'https://gh.xmly.dev/';

  /// 服务器排序字段
  String serverSortField = 'id';

}
