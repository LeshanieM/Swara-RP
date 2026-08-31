class ActivityModel {
  final String id;
  final String nameEn;
  final String nameSi;
  final String purposeEn;
  final String instructionEn;
  final String instructionSi;
  final bool isSlpGuided;

  ActivityModel({
    required this.id,
    required this.nameEn,
    required this.nameSi,
    required this.purposeEn,
    required this.instructionEn,
    required this.instructionSi,
    this.isSlpGuided = false,
  });
}
