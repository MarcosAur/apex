import 'package:drift/drift.dart';

import '../../features/exercises/domain/measurement_unit.dart';
import '../../features/workouts/domain/effort_level.dart';
import '../../features/wellness/domain/meal_type.dart';
import '../../features/wellness/domain/quantity_unit.dart';

import 'tables/categories.dart';
import 'tables/exercise_logs.dart';
import 'tables/exercises.dart';
import 'tables/gyms.dart';
import 'tables/muscle_groups.dart';
import 'tables/workout_exercises.dart';
import 'tables/workouts.dart';
import 'tables/meal_items.dart';
import 'tables/meals.dart';
import 'tables/set_drafts.dart';
import 'tables/sleep_logs.dart';
import 'tables/water_intakes.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Gyms,
    Categories,
    MuscleGroups,
    Exercises,
    Workouts,
    WorkoutExercises,
    ExerciseLogs,
    SetDrafts,
    SleepLogs,
    Meals,
    MealItems,
    WaterIntakes,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  static const initialCategories = ['Push', 'Pull', 'Legs'];
  static const initialMuscleGroups = [
    'Peitoral',
    'Costas',
    'Ombros',
    'Bíceps',
    'Tríceps',
    'Quadríceps',
    'Posteriores de coxa',
    'Glúteos',
    'Panturrilhas',
    'Core',
  ];

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createActiveIndex();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 1 || from >= to || to != 5) {
        throw UnsupportedError(
          'Migração de banco não implementada da versão $from para $to.',
        );
      }
      if (from < 4) {
        if (from == 1) {
          await migrator.addColumn(exerciseLogs, exerciseLogs.effortLevel);
        }
        if (from < 3) {
          await migrator.addColumn(workouts, workouts.status);
          await migrator.addColumn(workouts, workouts.completedAt);
          await migrator.createTable(setDrafts);
          await _createActiveIndex();
        }
        await migrator.addColumn(exercises, exercises.measurementUnit);
        await migrator.addColumn(
          workoutExercises,
          workoutExercises.measurementUnit,
        );
        await customStatement(
          'ALTER TABLE exercise_logs '
          'RENAME COLUMN weight TO measurement_value',
        );
        if (from == 3) {
          await customStatement(
            'ALTER TABLE set_drafts '
            'RENAME COLUMN weight_text TO measurement_text',
          );
        }
      }
      if (from < 5) {
        await migrator.createTable(sleepLogs);
        await migrator.createIndex(sleepLogsSleepDate);
        await migrator.createTable(meals);
        await migrator.createIndex(mealsEatenAt);
        await migrator.createTable(mealItems);
        await migrator.createTable(waterIntakes);
        await migrator.createIndex(waterIntakesConsumedAt);
      }
      if (from < 6) {
        await migrator.addColumn(exerciseLogs, exerciseLogs.pace);
        await migrator.addColumn(setDrafts, setDrafts.paceText);
        await migrator.addColumn(workouts, workouts.title);
        await migrator.addColumn(workouts, workouts.evaluation);
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await ensureSeedData();
    },
  );

  Future<void> _createActiveIndex() => customStatement(
    "CREATE UNIQUE INDEX one_active_workout ON workouts(status) WHERE status = 'active'",
  );

  Future<void> initialize() async {
    await customSelect('SELECT 1').getSingle();
  }

  Future<void> ensureSeedData() async {
    await batch((batch) {
      for (final name in initialCategories) {
        batch.insert(
          categories,
          CategoriesCompanion.insert(name: name),
          mode: InsertMode.insertOrIgnore,
        );
      }
      for (final name in initialMuscleGroups) {
        batch.insert(
          muscleGroups,
          MuscleGroupsCompanion.insert(name: name),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }
}
