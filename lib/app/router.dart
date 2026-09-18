import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_view.dart';
import '../features/lab/lab_view.dart';
import '../features/projects/project_detail_view.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _fade(state, const HomeView()),
    ),
    GoRoute(
      path: '/p/:id',
      pageBuilder: (context, state) => _fade(
        state,
        ProjectDetailView(projectId: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/lab',
      pageBuilder: (context, state) => _fade(state, const LabView()),
    ),
  ],
);

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 380),
    transitionsBuilder: (context, animation, secondary, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeOut).animate(animation),
        child: child,
      );
    },
  );
}
