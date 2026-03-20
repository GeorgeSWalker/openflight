part of 'user_clubs_cubit.dart';

class UserClubsState extends Equatable {
  const UserClubsState({required this.clubs});

  final List<String> clubs;

  @override
  List<Object?> get props => [clubs];
}
