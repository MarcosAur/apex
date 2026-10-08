import '../../../core/database/app_database.dart';

class ExerciseListItem {
  const ExerciseListItem({
    required this.exercise,
    required this.categoryName,
    required this.muscleGroupName,
  });

  final Exercise exercise;
  final String categoryName;
  final String muscleGroupName;
}
