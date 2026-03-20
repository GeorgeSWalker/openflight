import 'package:equatable/equatable.dart';

import 'package:openflight_mobile/core/models/shot_data_model.dart';

/// State for [ShotCubit].
class ShotState extends Equatable {
  const ShotState({
    this.latestShot,
    this.history = const [],
  });

  /// The most recently received shot, or null before the first shot.
  final ShotDataModel? latestShot;

  /// Ring-buffer of up to [ShotCubit.kMaxHistory] shots, newest first.
  final List<ShotDataModel> history;

  bool get hasShot => latestShot != null;

  ShotState copyWith({
    ShotDataModel? latestShot,
    List<ShotDataModel>? history,
  }) =>
      ShotState(
        latestShot: latestShot ?? this.latestShot,
        history: history ?? this.history,
      );

  static const initial = ShotState();

  @override
  List<Object?> get props => [latestShot, history];
}
