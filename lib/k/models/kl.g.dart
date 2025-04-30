// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kl.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetKlCollection on Isar {
  IsarCollection<Kl> get kls => this.collection();
}

const KlSchema = CollectionSchema(
  name: r'Kl',
  id: 9150872731331530422,
  properties: {
    r'description': PropertySchema(
      id: 0,
      name: r'description',
      type: IsarType.string,
    ),
    r'enabled': PropertySchema(
      id: 1,
      name: r'enabled',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 2,
      name: r'name',
      type: IsarType.string,
    )
  },
  estimateSize: _klEstimateSize,
  serialize: _klSerialize,
  deserialize: _klDeserialize,
  deserializeProp: _klDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'rules': LinkSchema(
      id: -1852616485128931084,
      name: r'rules',
      target: r'Rule',
      single: false,
      linkName: r'kl',
    )
  },
  embeddedSchemas: {},
  getId: _klGetId,
  getLinks: _klGetLinks,
  attach: _klAttach,
  version: '3.1.0+1',
);

int _klEstimateSize(
  Kl object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _klSerialize(
  Kl object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.description);
  writer.writeBool(offsets[1], object.enabled);
  writer.writeString(offsets[2], object.name);
}

Kl _klDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Kl(
    description: reader.readStringOrNull(offsets[0]),
    enabled: reader.readBoolOrNull(offsets[1]),
    id: id,
    name: reader.readStringOrNull(offsets[2]),
  );
  return object;
}

P _klDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readBoolOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _klGetId(Kl object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _klGetLinks(Kl object) {
  return [object.rules];
}

void _klAttach(IsarCollection<dynamic> col, Id id, Kl object) {
  object.id = id;
  object.rules.attach(col, col.isar.collection<Rule>(), r'rules', id);
}

extension KlQueryWhereSort on QueryBuilder<Kl, Kl, QWhere> {
  QueryBuilder<Kl, Kl, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension KlQueryWhere on QueryBuilder<Kl, Kl, QWhereClause> {
  QueryBuilder<Kl, Kl, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Kl, Kl, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Kl, Kl, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Kl, Kl, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Kl, Kl, QAfterWhereClause> idBetween(
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
}

extension KlQueryFilter on QueryBuilder<Kl, Kl, QFilterCondition> {
  QueryBuilder<Kl, Kl, QAfterFilterCondition> descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> descriptionEqualTo(
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

  QueryBuilder<Kl, Kl, QAfterFilterCondition> descriptionGreaterThan(
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

  QueryBuilder<Kl, Kl, QAfterFilterCondition> descriptionLessThan(
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

  QueryBuilder<Kl, Kl, QAfterFilterCondition> descriptionBetween(
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

  QueryBuilder<Kl, Kl, QAfterFilterCondition> descriptionStartsWith(
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

  QueryBuilder<Kl, Kl, QAfterFilterCondition> descriptionEndsWith(
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

  QueryBuilder<Kl, Kl, QAfterFilterCondition> descriptionContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> descriptionMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> enabledIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'enabled',
      ));
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> enabledIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'enabled',
      ));
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> enabledEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'enabled',
        value: value,
      ));
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Kl, Kl, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Kl, Kl, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Kl, Kl, QAfterFilterCondition> nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> nameEqualTo(
    String? value, {
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

  QueryBuilder<Kl, Kl, QAfterFilterCondition> nameGreaterThan(
    String? value, {
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

  QueryBuilder<Kl, Kl, QAfterFilterCondition> nameLessThan(
    String? value, {
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

  QueryBuilder<Kl, Kl, QAfterFilterCondition> nameBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<Kl, Kl, QAfterFilterCondition> nameStartsWith(
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

  QueryBuilder<Kl, Kl, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<Kl, Kl, QAfterFilterCondition> nameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> nameMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }
}

extension KlQueryObject on QueryBuilder<Kl, Kl, QFilterCondition> {}

extension KlQueryLinks on QueryBuilder<Kl, Kl, QFilterCondition> {
  QueryBuilder<Kl, Kl, QAfterFilterCondition> rules(FilterQuery<Rule> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'rules');
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> rulesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'rules', length, true, length, true);
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> rulesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'rules', 0, true, 0, true);
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> rulesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'rules', 0, false, 999999, true);
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> rulesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'rules', 0, true, length, include);
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> rulesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'rules', length, include, 999999, true);
    });
  }

  QueryBuilder<Kl, Kl, QAfterFilterCondition> rulesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'rules', lower, includeLower, upper, includeUpper);
    });
  }
}

extension KlQuerySortBy on QueryBuilder<Kl, Kl, QSortBy> {
  QueryBuilder<Kl, Kl, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<Kl, Kl, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<Kl, Kl, QAfterSortBy> sortByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.asc);
    });
  }

  QueryBuilder<Kl, Kl, QAfterSortBy> sortByEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.desc);
    });
  }

  QueryBuilder<Kl, Kl, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Kl, Kl, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension KlQuerySortThenBy on QueryBuilder<Kl, Kl, QSortThenBy> {
  QueryBuilder<Kl, Kl, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<Kl, Kl, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<Kl, Kl, QAfterSortBy> thenByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.asc);
    });
  }

  QueryBuilder<Kl, Kl, QAfterSortBy> thenByEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.desc);
    });
  }

  QueryBuilder<Kl, Kl, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Kl, Kl, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Kl, Kl, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Kl, Kl, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension KlQueryWhereDistinct on QueryBuilder<Kl, Kl, QDistinct> {
  QueryBuilder<Kl, Kl, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Kl, Kl, QDistinct> distinctByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enabled');
    });
  }

  QueryBuilder<Kl, Kl, QDistinct> distinctByName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }
}

extension KlQueryProperty on QueryBuilder<Kl, Kl, QQueryProperty> {
  QueryBuilder<Kl, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Kl, String?, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<Kl, bool?, QQueryOperations> enabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enabled');
    });
  }

  QueryBuilder<Kl, String?, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRuleCollection on Isar {
  IsarCollection<Rule> get rules => this.collection();
}

const RuleSchema = CollectionSchema(
  name: r'Rule',
  id: -2659006343538057288,
  properties: {
    r'matchIp': PropertySchema(
      id: 0,
      name: r'matchIp',
      type: IsarType.string,
    ),
    r'matchPort': PropertySchema(
      id: 1,
      name: r'matchPort',
      type: IsarType.long,
    ),
    r'op': PropertySchema(
      id: 2,
      name: r'op',
      type: IsarType.byte,
      enumMap: _RuleopEnumValueMap,
    ),
    r'replaceIp': PropertySchema(
      id: 3,
      name: r'replaceIp',
      type: IsarType.string,
    ),
    r'replacePort': PropertySchema(
      id: 4,
      name: r'replacePort',
      type: IsarType.long,
    )
  },
  estimateSize: _ruleEstimateSize,
  serialize: _ruleSerialize,
  deserialize: _ruleDeserialize,
  deserializeProp: _ruleDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'kl': LinkSchema(
      id: -8483428176134566364,
      name: r'kl',
      target: r'Kl',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _ruleGetId,
  getLinks: _ruleGetLinks,
  attach: _ruleAttach,
  version: '3.1.0+1',
);

int _ruleEstimateSize(
  Rule object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.matchIp;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.replaceIp;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _ruleSerialize(
  Rule object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.matchIp);
  writer.writeLong(offsets[1], object.matchPort);
  writer.writeByte(offsets[2], object.op.index);
  writer.writeString(offsets[3], object.replaceIp);
  writer.writeLong(offsets[4], object.replacePort);
}

Rule _ruleDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Rule();
  object.id = id;
  object.matchIp = reader.readStringOrNull(offsets[0]);
  object.matchPort = reader.readLongOrNull(offsets[1]);
  object.op = _RuleopValueEnumMap[reader.readByteOrNull(offsets[2])] ??
      OperationType.connect;
  object.replaceIp = reader.readStringOrNull(offsets[3]);
  object.replacePort = reader.readLongOrNull(offsets[4]);
  return object;
}

P _ruleDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (_RuleopValueEnumMap[reader.readByteOrNull(offset)] ??
          OperationType.connect) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _RuleopEnumValueMap = {
  'connect': 0,
  'bind': 1,
  'sendto': 2,
  'recvfrom': 3,
  'all': 4,
};
const _RuleopValueEnumMap = {
  0: OperationType.connect,
  1: OperationType.bind,
  2: OperationType.sendto,
  3: OperationType.recvfrom,
  4: OperationType.all,
};

Id _ruleGetId(Rule object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _ruleGetLinks(Rule object) {
  return [object.kl];
}

void _ruleAttach(IsarCollection<dynamic> col, Id id, Rule object) {
  object.id = id;
  object.kl.attach(col, col.isar.collection<Kl>(), r'kl', id);
}

extension RuleQueryWhereSort on QueryBuilder<Rule, Rule, QWhere> {
  QueryBuilder<Rule, Rule, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RuleQueryWhere on QueryBuilder<Rule, Rule, QWhereClause> {
  QueryBuilder<Rule, Rule, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Rule, Rule, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Rule, Rule, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Rule, Rule, QAfterWhereClause> idBetween(
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
}

extension RuleQueryFilter on QueryBuilder<Rule, Rule, QFilterCondition> {
  QueryBuilder<Rule, Rule, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Rule, Rule, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Rule, Rule, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchIpIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'matchIp',
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchIpIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'matchIp',
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchIpEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'matchIp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchIpGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'matchIp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchIpLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'matchIp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchIpBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'matchIp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchIpStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'matchIp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchIpEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'matchIp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchIpContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'matchIp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchIpMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'matchIp',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchIpIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'matchIp',
        value: '',
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchIpIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'matchIp',
        value: '',
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchPortIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'matchPort',
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchPortIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'matchPort',
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchPortEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'matchPort',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchPortGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'matchPort',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchPortLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'matchPort',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> matchPortBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'matchPort',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> opEqualTo(
      OperationType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'op',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> opGreaterThan(
    OperationType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'op',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> opLessThan(
    OperationType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'op',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> opBetween(
    OperationType lower,
    OperationType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'op',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> replaceIpIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'replaceIp',
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> replaceIpIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'replaceIp',
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> replaceIpEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'replaceIp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> replaceIpGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'replaceIp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> replaceIpLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'replaceIp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> replaceIpBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'replaceIp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> replaceIpStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'replaceIp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> replaceIpEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'replaceIp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> replaceIpContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'replaceIp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> replaceIpMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'replaceIp',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> replaceIpIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'replaceIp',
        value: '',
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> replaceIpIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'replaceIp',
        value: '',
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> replacePortIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'replacePort',
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> replacePortIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'replacePort',
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> replacePortEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'replacePort',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> replacePortGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'replacePort',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> replacePortLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'replacePort',
        value: value,
      ));
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> replacePortBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'replacePort',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension RuleQueryObject on QueryBuilder<Rule, Rule, QFilterCondition> {}

extension RuleQueryLinks on QueryBuilder<Rule, Rule, QFilterCondition> {
  QueryBuilder<Rule, Rule, QAfterFilterCondition> kl(FilterQuery<Kl> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'kl');
    });
  }

  QueryBuilder<Rule, Rule, QAfterFilterCondition> klIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'kl', 0, true, 0, true);
    });
  }
}

extension RuleQuerySortBy on QueryBuilder<Rule, Rule, QSortBy> {
  QueryBuilder<Rule, Rule, QAfterSortBy> sortByMatchIp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchIp', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByMatchIpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchIp', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByMatchPort() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchPort', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByMatchPortDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchPort', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByOp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'op', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByOpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'op', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByReplaceIp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replaceIp', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByReplaceIpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replaceIp', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByReplacePort() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replacePort', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> sortByReplacePortDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replacePort', Sort.desc);
    });
  }
}

extension RuleQuerySortThenBy on QueryBuilder<Rule, Rule, QSortThenBy> {
  QueryBuilder<Rule, Rule, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByMatchIp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchIp', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByMatchIpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchIp', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByMatchPort() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchPort', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByMatchPortDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchPort', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByOp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'op', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByOpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'op', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByReplaceIp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replaceIp', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByReplaceIpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replaceIp', Sort.desc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByReplacePort() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replacePort', Sort.asc);
    });
  }

  QueryBuilder<Rule, Rule, QAfterSortBy> thenByReplacePortDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replacePort', Sort.desc);
    });
  }
}

extension RuleQueryWhereDistinct on QueryBuilder<Rule, Rule, QDistinct> {
  QueryBuilder<Rule, Rule, QDistinct> distinctByMatchIp(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'matchIp', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Rule, Rule, QDistinct> distinctByMatchPort() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'matchPort');
    });
  }

  QueryBuilder<Rule, Rule, QDistinct> distinctByOp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'op');
    });
  }

  QueryBuilder<Rule, Rule, QDistinct> distinctByReplaceIp(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'replaceIp', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Rule, Rule, QDistinct> distinctByReplacePort() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'replacePort');
    });
  }
}

extension RuleQueryProperty on QueryBuilder<Rule, Rule, QQueryProperty> {
  QueryBuilder<Rule, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Rule, String?, QQueryOperations> matchIpProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'matchIp');
    });
  }

  QueryBuilder<Rule, int?, QQueryOperations> matchPortProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'matchPort');
    });
  }

  QueryBuilder<Rule, OperationType, QQueryOperations> opProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'op');
    });
  }

  QueryBuilder<Rule, String?, QQueryOperations> replaceIpProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'replaceIp');
    });
  }

  QueryBuilder<Rule, int?, QQueryOperations> replacePortProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'replacePort');
    });
  }
}
