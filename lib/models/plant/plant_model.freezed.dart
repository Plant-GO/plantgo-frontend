// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plant_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PlantModel _$PlantModelFromJson(Map<String, dynamic> json) {
  return _PlantModel.fromJson(json);
}

/// @nodoc
mixin _$PlantModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  List<String>? get imageChunks => throw _privateConstructorUsedError;
  bool get isChunkedImage => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get species => throw _privateConstructorUsedError;
  String? get family => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  String? get userId => throw _privateConstructorUsedError;

  /// Serializes this PlantModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlantModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlantModelCopyWith<PlantModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlantModelCopyWith<$Res> {
  factory $PlantModelCopyWith(
          PlantModel value, $Res Function(PlantModel) then) =
      _$PlantModelCopyWithImpl<$Res, PlantModel>;
  @useResult
  $Res call(
      {String id,
      String name,
      double latitude,
      double longitude,
      String imageUrl,
      List<String>? imageChunks,
      bool isChunkedImage,
      DateTime createdAt,
      DateTime? updatedAt,
      String? description,
      String? species,
      String? family,
      List<String> tags,
      String? userId});
}

/// @nodoc
class _$PlantModelCopyWithImpl<$Res, $Val extends PlantModel>
    implements $PlantModelCopyWith<$Res> {
  _$PlantModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlantModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? imageUrl = null,
    Object? imageChunks = freezed,
    Object? isChunkedImage = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? description = freezed,
    Object? species = freezed,
    Object? family = freezed,
    Object? tags = null,
    Object? userId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      imageChunks: freezed == imageChunks
          ? _value.imageChunks
          : imageChunks // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      isChunkedImage: null == isChunkedImage
          ? _value.isChunkedImage
          : isChunkedImage // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      species: freezed == species
          ? _value.species
          : species // ignore: cast_nullable_to_non_nullable
              as String?,
      family: freezed == family
          ? _value.family
          : family // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlantModelImplCopyWith<$Res>
    implements $PlantModelCopyWith<$Res> {
  factory _$$PlantModelImplCopyWith(
          _$PlantModelImpl value, $Res Function(_$PlantModelImpl) then) =
      __$$PlantModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      double latitude,
      double longitude,
      String imageUrl,
      List<String>? imageChunks,
      bool isChunkedImage,
      DateTime createdAt,
      DateTime? updatedAt,
      String? description,
      String? species,
      String? family,
      List<String> tags,
      String? userId});
}

/// @nodoc
class __$$PlantModelImplCopyWithImpl<$Res>
    extends _$PlantModelCopyWithImpl<$Res, _$PlantModelImpl>
    implements _$$PlantModelImplCopyWith<$Res> {
  __$$PlantModelImplCopyWithImpl(
      _$PlantModelImpl _value, $Res Function(_$PlantModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlantModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? imageUrl = null,
    Object? imageChunks = freezed,
    Object? isChunkedImage = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? description = freezed,
    Object? species = freezed,
    Object? family = freezed,
    Object? tags = null,
    Object? userId = freezed,
  }) {
    return _then(_$PlantModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      imageChunks: freezed == imageChunks
          ? _value._imageChunks
          : imageChunks // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      isChunkedImage: null == isChunkedImage
          ? _value.isChunkedImage
          : isChunkedImage // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      species: freezed == species
          ? _value.species
          : species // ignore: cast_nullable_to_non_nullable
              as String?,
      family: freezed == family
          ? _value.family
          : family // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlantModelImpl implements _PlantModel {
  const _$PlantModelImpl(
      {required this.id,
      required this.name,
      required this.latitude,
      required this.longitude,
      required this.imageUrl,
      final List<String>? imageChunks = const [],
      this.isChunkedImage = false,
      required this.createdAt,
      this.updatedAt,
      this.description,
      this.species,
      this.family,
      final List<String> tags = const [],
      this.userId})
      : _imageChunks = imageChunks,
        _tags = tags;

  factory _$PlantModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlantModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String imageUrl;
  final List<String>? _imageChunks;
  @override
  @JsonKey()
  List<String>? get imageChunks {
    final value = _imageChunks;
    if (value == null) return null;
    if (_imageChunks is EqualUnmodifiableListView) return _imageChunks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey()
  final bool isChunkedImage;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final String? description;
  @override
  final String? species;
  @override
  final String? family;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  final String? userId;

  @override
  String toString() {
    return 'PlantModel(id: $id, name: $name, latitude: $latitude, longitude: $longitude, imageUrl: $imageUrl, imageChunks: $imageChunks, isChunkedImage: $isChunkedImage, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, species: $species, family: $family, tags: $tags, userId: $userId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlantModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            const DeepCollectionEquality()
                .equals(other._imageChunks, _imageChunks) &&
            (identical(other.isChunkedImage, isChunkedImage) ||
                other.isChunkedImage == isChunkedImage) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.species, species) || other.species == species) &&
            (identical(other.family, family) || other.family == family) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.userId, userId) || other.userId == userId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      latitude,
      longitude,
      imageUrl,
      const DeepCollectionEquality().hash(_imageChunks),
      isChunkedImage,
      createdAt,
      updatedAt,
      description,
      species,
      family,
      const DeepCollectionEquality().hash(_tags),
      userId);

  /// Create a copy of PlantModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlantModelImplCopyWith<_$PlantModelImpl> get copyWith =>
      __$$PlantModelImplCopyWithImpl<_$PlantModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlantModelImplToJson(
      this,
    );
  }
}

abstract class _PlantModel implements PlantModel {
  const factory _PlantModel(
      {required final String id,
      required final String name,
      required final double latitude,
      required final double longitude,
      required final String imageUrl,
      final List<String>? imageChunks,
      final bool isChunkedImage,
      required final DateTime createdAt,
      final DateTime? updatedAt,
      final String? description,
      final String? species,
      final String? family,
      final List<String> tags,
      final String? userId}) = _$PlantModelImpl;

  factory _PlantModel.fromJson(Map<String, dynamic> json) =
      _$PlantModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  String get imageUrl;
  @override
  List<String>? get imageChunks;
  @override
  bool get isChunkedImage;
  @override
  DateTime get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  String? get description;
  @override
  String? get species;
  @override
  String? get family;
  @override
  List<String> get tags;
  @override
  String? get userId;

  /// Create a copy of PlantModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlantModelImplCopyWith<_$PlantModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
