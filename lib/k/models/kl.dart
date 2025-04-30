import 'package:astral/screens/tool_page.dart';
import 'package:isar/isar.dart';
part 'kl.g.dart';

@collection
class Kl {
  Id id = Isar.autoIncrement;

  String? name;
  String? description;
  // 是否启用
  bool? enabled;
  
  @Backlink(to: 'kl')
  final rules = IsarLinks<Rule>();

  //构造
  Kl({
    this.id = Isar.autoIncrement,
    this.name = "",
    this.description = "",
    this.enabled = true,
  });
}

@collection
class Rule {
  Id id = Isar.autoIncrement;

  @enumerated
  OperationType op = OperationType.all;
  String? matchIp;
  int? matchPort;
  String? replaceIp;
  int? replacePort;

  final kl = IsarLink<Kl>();
}

enum OperationType { connect, bind, sendto, recvfrom, all }
