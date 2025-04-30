import 'package:isar/isar.dart';
import 'package:astral/k/models/kl.dart';

class KlCz {
  final Isar _isar;

  KlCz(this._isar) {
    init();
  }

  Future<void> init() async {}

  // 添加Kl配置
  Future<int> addKl(Kl kl) async {
    return await _isar.writeTxn(() async {
      return await _isar.kls.put(kl);
    });
  }

  // 根据ID获取Kl配置
  Future<Kl?> getKlById(int id) async {
    return await _isar.kls.get(id);
  }

  // 获取所有Kl配置
  Future<List<Kl>> getAllKls() async {
    return await _isar.kls.where().findAll();
  }

  // 更新Kl配置
  Future<int> updateKl(Kl kl) async {
    return await _isar.writeTxn(() async {
      return await _isar.kls.put(kl);
    });
  }

  // 删除Kl配置
  Future<bool> deleteKl(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.kls.delete(id);
    });
  }

  // 根据名称查询Kl配置
  Future<List<Kl>> getKlsByName(String name) async {
    return await _isar.kls.filter().nameEqualTo(name).findAll();
  }

  // 根据启用状态查询Kl配置
  Future<List<Kl>> getKlsByEnabled(bool enabled) async {
    return await _isar.kls.filter().enabledEqualTo(enabled).findAll();
  }

  // 添加规则
  Future<int> addRule(Rule rule, int klId) async {
    return await _isar.writeTxn(() async {
      // 获取关联的Kl对象
      final kl = await _isar.kls.get(klId);
      if (kl != null) {
        // 设置关联关系
        rule.kl.value = kl;
        // 保存规则
        final id = await _isar.rules.put(rule);
        // 更新Kl的规则链接
        kl.rules.add(rule);
        await kl.rules.save();
        return id;
      }
      return -1; // 返回-1表示操作失败
    });
  }

  // 获取规则
  Future<Rule?> getRuleById(int id) async {
    return await _isar.rules.get(id);
  }

  // 获取Kl下的所有规则
  Future<List<Rule>> getRulesByKlId(int klId) async {
    final kl = await _isar.kls.get(klId);
    if (kl != null) {
      await kl.rules.load();
      return kl.rules.toList();
    }
    return [];
  }

  // 更新规则
  Future<int> updateRule(Rule rule) async {
    return await _isar.writeTxn(() async {
      return await _isar.rules.put(rule);
    });
  }

  // 删除规则
  Future<bool> deleteRule(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.rules.delete(id);
    });
  }

  // 根据操作类型查询规则
  Future<List<Rule>> getRulesByOperationType(OperationType opType) async {
    return await _isar.rules.filter().opEqualTo(opType).findAll();
  }
}
