// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wfp_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetWfpModelCollection on Isar {
  IsarCollection<WfpModel> get wfpModels => this.collection();
}

const WfpModelSchema = CollectionSchema(
  name: r'WfpModel',
  id: -4844026455713192288,
  properties: {
    r'action': PropertySchema(
      id: 0,
      name: r'action',
      type: IsarType.string,
    ),
    r'appPath': PropertySchema(
      id: 1,
      name: r'appPath',
      type: IsarType.string,
    ),
    r'description': PropertySchema(
      id: 2,
      name: r'description',
      type: IsarType.string,
    ),
    r'direction': PropertySchema(
      id: 3,
      name: r'direction',
      type: IsarType.string,
    ),
    r'local': PropertySchema(
      id: 4,
      name: r'local',
      type: IsarType.string,
    ),
    r'localPort': PropertySchema(
      id: 5,
      name: r'localPort',
      type: IsarType.long,
    ),
    r'localPortRange': PropertySchema(
      id: 6,
      name: r'localPortRange',
      type: IsarType.longList,
    ),
    r'name': PropertySchema(
      id: 7,
      name: r'name',
      type: IsarType.string,
    ),
    r'priority': PropertySchema(
      id: 8,
      name: r'priority',
      type: IsarType.long,
    ),
    r'protocol': PropertySchema(
      id: 9,
      name: r'protocol',
      type: IsarType.string,
    ),
    r'remote': PropertySchema(
      id: 10,
      name: r'remote',
      type: IsarType.string,
    ),
    r'remotePort': PropertySchema(
      id: 11,
      name: r'remotePort',
      type: IsarType.long,
    ),
    r'remotePortRange': PropertySchema(
      id: 12,
      name: r'remotePortRange',
      type: IsarType.longList,
    )
  },
  estimateSize: _wfpModelEstimateSize,
  serialize: _wfpModelSerialize,
  deserialize: _wfpModelDeserialize,
  deserializeProp: _wfpModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'name': IndexSchema(
      id: 879695947855722453,
      name: r'name',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'name',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _wfpModelGetId,
  getLinks: _wfpModelGetLinks,
  attach: _wfpModelAttach,
  version: '3.1.8',
);

int _wfpModelEstimateSize(
  WfpModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.action.length * 3;
  {
    final value = object.appPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.direction.length * 3;
  {
    final value = object.local;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.localPortRange;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.protocol;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.remote;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.remotePortRange;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  return bytesCount;
}

void _wfpModelSerialize(
  WfpModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.action);
  writer.writeString(offsets[1], object.appPath);
  writer.writeString(offsets[2], object.description);
  writer.writeString(offsets[3], object.direction);
  writer.writeString(offsets[4], object.local);
  writer.writeLong(offsets[5], object.localPort);
  writer.writeLongList(offsets[6], object.localPortRange);
  writer.writeString(offsets[7], object.name);
  writer.writeLong(offsets[8], object.priority);
  writer.writeString(offsets[9], object.protocol);
  writer.writeString(offsets[10], object.remote);
  writer.writeLong(offsets[11], object.remotePort);
  writer.writeLongList(offsets[12], object.remotePortRange);
}

WfpModel _wfpModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WfpModel();
  object.action = reader.readString(offsets[0]);
  object.appPath = reader.readStringOrNull(offsets[1]);
  object.description = reader.readStringOrNull(offsets[2]);
  object.direction = reader.readString(offsets[3]);
  object.id = id;
  object.local = reader.readStringOrNull(offsets[4]);
  object.localPort = reader.readLongOrNull(offsets[5]);
  object.localPortRange = reader.readLongList(offsets[6]);
  object.name = reader.readString(offsets[7]);
  object.priority = reader.readLongOrNull(offsets[8]);
  object.protocol = reader.readStringOrNull(offsets[9]);
  object.remote = reader.readStringOrNull(offsets[10]);
  object.remotePort = reader.readLongOrNull(offsets[11]);
  object.remotePortRange = reader.readLongList(offsets[12]);
  return object;
}

P _wfpModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readLongList(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset)) as P;
    case 12:
      return (reader.readLongList(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _wfpModelGetId(WfpModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _wfpModelGetLinks(WfpModel object) {
  return [];
}

void _wfpModelAttach(IsarCollection<dynamic> col, Id id, WfpModel object) {
  object.id = id;
}

extension WfpModelQueryWhereSort on QueryBuilder<WfpModel, WfpModel, QWhere> {
  QueryBuilder<WfpModel, WfpModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension WfpModelQueryWhere on QueryBuilder<WfpModel, WfpModel, QWhereClause> {
  QueryBuilder<WfpModel, WfpModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterWhereClause> nameEqualTo(String name) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'name',
        value: [name],
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterWhereClause> nameNotEqualTo(
      String name) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ));
      }
    });
  }
}

extension WfpModelQueryFilter
    on QueryBuilder<WfpModel, WfpModel, QFilterCondition> {
  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> actionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> actionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> actionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> actionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'action',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> actionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> actionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> actionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> actionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'action',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> actionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'action',
        value: '',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> actionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'action',
        value: '',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> appPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'appPath',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> appPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'appPath',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> appPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'appPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> appPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'appPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> appPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'appPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> appPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'appPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> appPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'appPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> appPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'appPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> appPathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'appPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> appPathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'appPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> appPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'appPath',
        value: '',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> appPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'appPath',
        value: '',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> descriptionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> descriptionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> directionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'direction',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> directionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'direction',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> directionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'direction',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> directionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'direction',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> directionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'direction',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> directionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'direction',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> directionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'direction',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> directionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'direction',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> directionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'direction',
        value: '',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      directionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'direction',
        value: '',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> localIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'local',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> localIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'local',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> localEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'local',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> localGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'local',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> localLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'local',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> localBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'local',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> localStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'local',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> localEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'local',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> localContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'local',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> localMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'local',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> localIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'local',
        value: '',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> localIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'local',
        value: '',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> localPortIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'localPort',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> localPortIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'localPort',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> localPortEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localPort',
        value: value,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> localPortGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localPort',
        value: value,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> localPortLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localPort',
        value: value,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> localPortBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localPort',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      localPortRangeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'localPortRange',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      localPortRangeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'localPortRange',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      localPortRangeElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localPortRange',
        value: value,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      localPortRangeElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localPortRange',
        value: value,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      localPortRangeElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localPortRange',
        value: value,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      localPortRangeElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localPortRange',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      localPortRangeLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'localPortRange',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      localPortRangeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'localPortRange',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      localPortRangeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'localPortRange',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      localPortRangeLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'localPortRange',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      localPortRangeLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'localPortRange',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      localPortRangeLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'localPortRange',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> priorityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'priority',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> priorityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'priority',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> priorityEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priority',
        value: value,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> priorityGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'priority',
        value: value,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> priorityLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'priority',
        value: value,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> priorityBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'priority',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> protocolIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'protocol',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> protocolIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'protocol',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> protocolEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'protocol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> protocolGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'protocol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> protocolLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'protocol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> protocolBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'protocol',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> protocolStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'protocol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> protocolEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'protocol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> protocolContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'protocol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> protocolMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'protocol',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> protocolIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'protocol',
        value: '',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> protocolIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'protocol',
        value: '',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> remoteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remote',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> remoteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remote',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> remoteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> remoteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> remoteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> remoteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remote',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> remoteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'remote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> remoteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'remote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> remoteContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> remoteMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remote',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> remoteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remote',
        value: '',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> remoteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remote',
        value: '',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> remotePortIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remotePort',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      remotePortIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remotePort',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> remotePortEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remotePort',
        value: value,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> remotePortGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remotePort',
        value: value,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> remotePortLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remotePort',
        value: value,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition> remotePortBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remotePort',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      remotePortRangeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remotePortRange',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      remotePortRangeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remotePortRange',
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      remotePortRangeElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remotePortRange',
        value: value,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      remotePortRangeElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remotePortRange',
        value: value,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      remotePortRangeElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remotePortRange',
        value: value,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      remotePortRangeElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remotePortRange',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      remotePortRangeLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'remotePortRange',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      remotePortRangeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'remotePortRange',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      remotePortRangeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'remotePortRange',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      remotePortRangeLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'remotePortRange',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      remotePortRangeLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'remotePortRange',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterFilterCondition>
      remotePortRangeLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'remotePortRange',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension WfpModelQueryObject
    on QueryBuilder<WfpModel, WfpModel, QFilterCondition> {}

extension WfpModelQueryLinks
    on QueryBuilder<WfpModel, WfpModel, QFilterCondition> {}

extension WfpModelQuerySortBy on QueryBuilder<WfpModel, WfpModel, QSortBy> {
  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByAction() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'action', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByActionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'action', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByAppPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appPath', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByAppPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appPath', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByDirectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByLocal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'local', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByLocalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'local', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByLocalPort() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPort', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByLocalPortDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPort', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByPriorityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByProtocol() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protocol', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByProtocolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protocol', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByRemote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remote', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByRemoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remote', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByRemotePort() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remotePort', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> sortByRemotePortDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remotePort', Sort.desc);
    });
  }
}

extension WfpModelQuerySortThenBy
    on QueryBuilder<WfpModel, WfpModel, QSortThenBy> {
  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByAction() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'action', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByActionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'action', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByAppPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appPath', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByAppPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appPath', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByDirectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByLocal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'local', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByLocalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'local', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByLocalPort() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPort', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByLocalPortDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPort', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByPriorityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByProtocol() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protocol', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByProtocolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protocol', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByRemote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remote', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByRemoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remote', Sort.desc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByRemotePort() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remotePort', Sort.asc);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QAfterSortBy> thenByRemotePortDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remotePort', Sort.desc);
    });
  }
}

extension WfpModelQueryWhereDistinct
    on QueryBuilder<WfpModel, WfpModel, QDistinct> {
  QueryBuilder<WfpModel, WfpModel, QDistinct> distinctByAction(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'action', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QDistinct> distinctByAppPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'appPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QDistinct> distinctByDirection(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'direction', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QDistinct> distinctByLocal(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'local', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QDistinct> distinctByLocalPort() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localPort');
    });
  }

  QueryBuilder<WfpModel, WfpModel, QDistinct> distinctByLocalPortRange() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localPortRange');
    });
  }

  QueryBuilder<WfpModel, WfpModel, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QDistinct> distinctByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'priority');
    });
  }

  QueryBuilder<WfpModel, WfpModel, QDistinct> distinctByProtocol(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'protocol', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QDistinct> distinctByRemote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remote', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WfpModel, WfpModel, QDistinct> distinctByRemotePort() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remotePort');
    });
  }

  QueryBuilder<WfpModel, WfpModel, QDistinct> distinctByRemotePortRange() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remotePortRange');
    });
  }
}

extension WfpModelQueryProperty
    on QueryBuilder<WfpModel, WfpModel, QQueryProperty> {
  QueryBuilder<WfpModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<WfpModel, String, QQueryOperations> actionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'action');
    });
  }

  QueryBuilder<WfpModel, String?, QQueryOperations> appPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'appPath');
    });
  }

  QueryBuilder<WfpModel, String?, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<WfpModel, String, QQueryOperations> directionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'direction');
    });
  }

  QueryBuilder<WfpModel, String?, QQueryOperations> localProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'local');
    });
  }

  QueryBuilder<WfpModel, int?, QQueryOperations> localPortProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localPort');
    });
  }

  QueryBuilder<WfpModel, List<int>?, QQueryOperations>
      localPortRangeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localPortRange');
    });
  }

  QueryBuilder<WfpModel, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<WfpModel, int?, QQueryOperations> priorityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'priority');
    });
  }

  QueryBuilder<WfpModel, String?, QQueryOperations> protocolProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'protocol');
    });
  }

  QueryBuilder<WfpModel, String?, QQueryOperations> remoteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remote');
    });
  }

  QueryBuilder<WfpModel, int?, QQueryOperations> remotePortProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remotePort');
    });
  }

  QueryBuilder<WfpModel, List<int>?, QQueryOperations>
      remotePortRangeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remotePortRange');
    });
  }
}
