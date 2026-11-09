class Profile {
  const Profile({
    required this.fullName,
    required this.heightCm,
    this.birthDate,
    this.targetWeightKg,
  });
  final String fullName;
  final double heightCm;
  final String? birthDate;
  final double? targetWeightKg;

  factory Profile.fromMap(Map<String, Object?> row) => Profile(
    fullName: row['full_name'] as String,
    heightCm: (row['height_cm'] as num).toDouble(),
    birthDate: row['birth_date'] as String?,
    targetWeightKg: (row['target_weight_kg'] as num?)?.toDouble(),
  );
}
