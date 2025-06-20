import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'spb_model.g.dart';

@JsonSerializable()
class SpbModel extends Equatable {
  final String noSpb;
  final String tglAntarBuah;
  final String millTujuan;
  final String status;
  final String? keterangan;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isSynced;

  const SpbModel({
    required this.noSpb,
    required this.tglAntarBuah,
    required this.millTujuan,
    required this.status,
    this.keterangan,
    this.createdAt,
    this.updatedAt,
    this.isSynced = true,
  });

  factory SpbModel.fromJson(Map<String, dynamic> json) => _$SpbModelFromJson(json);

  Map<String, dynamic> toJson() => _$SpbModelToJson(this);

  // For database operations
  factory SpbModel.fromDatabase(Map<String, dynamic> map) {
    return SpbModel(
      noSpb: map['no_spb'] as String,
      tglAntarBuah: map['tgl_antar_buah'] as String,
      millTujuan: map['mill_tujuan'] as String,
      status: map['status'] as String,
      keterangan: map['keterangan'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
      isSynced: (map['is_synced'] as int) == 1,
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'no_spb': noSpb,
      'tgl_antar_buah': tglAntarBuah,
      'mill_tujuan': millTujuan,
      'status': status,
      'keterangan': keterangan,
      'created_at': createdAt?.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  SpbModel copyWith({
    String? noSpb,
    String? tglAntarBuah,
    String? millTujuan,
    String? status,
    String? keterangan,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return SpbModel(
      noSpb: noSpb ?? this.noSpb,
      tglAntarBuah: tglAntarBuah ?? this.tglAntarBuah,
      millTujuan: millTujuan ?? this.millTujuan,
      status: status ?? this.status,
      keterangan: keterangan ?? this.keterangan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [
        noSpb,
        tglAntarBuah,
        millTujuan,
        status,
        keterangan,
        createdAt,
        updatedAt,
        isSynced,
      ];
}