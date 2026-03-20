import 'package:flutter_bloc/flutter_bloc.dart';

/// Tracks the user-defined target distance (yards) for the dispersion canvas.
class TargetDistanceCubit extends Cubit<double> {
  TargetDistanceCubit() : super(150.0);

  void setDistance(double yards) => emit(yards);
}
