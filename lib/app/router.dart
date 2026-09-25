import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/city/city_view.dart';
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
    // La home de antes y el laboratorio de efectos ya no existen: la calle
    // tiene todo. Los enlaces viejos caen en la calle y no en una página en
    // blanco.
    GoRoute(path: '/clasica', redirect: (context, state) => '/'),
    GoRoute(path: '/calle', redirect: (context, state) => '/'),
    GoRoute(path: '/lab', redirect: (context, state) => '/'),
    GoRoute(
      path: '/p/:id',
      pageBuilder: (context, state) => _fade(
        state,
        ProjectDetailView(projectId: state.pathParameters['id'] ?? ''),
      ),
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
