import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/auth_model.dart';
import 'home_model.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(UserRole role) : super(HomeState(tabs: HomeTabInfo.forRole(role)));
  void select(HomeTab tab) => emit(state.copyWith(tab: tab));
}
