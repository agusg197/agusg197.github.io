import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/city/city_view.dart';
import '../features/lab/lab_view.dart';
import '../features/projects/project_detail_view.dart';

final router = GoRouter(
  routes: [
    // La calle es el sitio. `?ver=` abre un panel y `?at=` arranca frente a
    // un edificio: los dos sirven para compartir un enlace directo.
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _fade(
        state,
        CityView(
          open: state.uri.queryParameters['ver'],
          at: state.uri.queryParameters['at'],
        ),
      ),
    ),
    // La home de antes ya no existe: la calle tiene todo. Los enlaces viejos
    // caen en la calle en vez de en una página en blanco.
    GoRoute(path: '/clasica', redirect: (context, state) => '/'),
    GoRoute(path: '/calle', redirect: (context, state) => '/'),
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
