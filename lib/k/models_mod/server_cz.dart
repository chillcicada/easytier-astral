import 'package:astral/k/models/server_mod.dart';
import 'package:isar/isar.dart';

class ServerCz {
  final Isar _isar;

  ServerCz(this._isar) {
    init();
  }

  Future<void> init() async {
  }

  // 添加服务器
  Future<int> addServer(ServerMod server) async {
    return await _isar.writeTxn(() async {
      return await _isar.serverMods.put(server);
    });
  }

  // 设置是否启用
  Future<int> setServerEnable(ServerMod server, bool enable) async {
    server.enable = enable;
    return await _isar.writeTxn(() async {
      return await _isar.serverMods.put(server);
    });
  }

  // 根据ID获取服务器
  Future<ServerMod?> getServerById(int id) async {
    return await _isar.serverMods.get(id);
  }

  // 获取所有服务器
  Future<List<ServerMod>> getAllServers() async {
    return await _isar.serverMods.where().findAll();
  }

  // 更新服务器
  Future<int> updateServer(ServerMod server) async {
    return await _isar.writeTxn(() async {
      return await _isar.serverMods.put(server);
    });
  }

  // 删除服务器 by id
  Future<bool> deleteServerid(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.serverMods.delete(id);
    });
  }

  // 删除服务器 by object
  Future<bool> deleteServer(ServerMod server) async {
    return await _isar.writeTxn(() async {
      return await _isar.serverMods.delete(server.id);
    });
  }
}
