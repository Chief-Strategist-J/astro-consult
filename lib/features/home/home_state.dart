import 'package:equatable/equatable.dart';

import 'home_model.dart';

class HomeState extends Equatable {
  const HomeState({required this.tabs, this.selected});
  final List<HomeTab> tabs;
  final HomeTab? selected;

  HomeTab get tab => selected ?? tabs.first;
  int get index => tabs.indexOf(tab);

  HomeState copyWith({HomeTab? tab}) => HomeState(tabs: tabs, selected: tab ?? selected);

  @override
  List<Object?> get props => [tabs, tab];
}
