import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/main/presentation/pages/main_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/data/presentation/pages/data_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;
      final isLoggedIn = authState is AuthAuthenticated;

      // If user is not logged in and trying to access protected routes
<<<<<<< HEAD
      if (!isLoggedIn &&
          state.matchedLocation != '/login' &&
          state.matchedLocation != '/splash' &&
          !state.matchedLocation.startsWith('/password-reset')) {
=======
      if (!isLoggedIn && 
          state.matchedLocation != '/login' && 
          state.matchedLocation != '/splash') {
>>>>>>> 51ee234352a17f5d388bc3b671fd5e5a8578b12a
        return '/login';
      }

      // If user is logged in and trying to access auth routes
<<<<<<< HEAD
      if (isLoggedIn &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/splash' ||
              state.matchedLocation.startsWith('/password-reset'))) {
=======
      if (isLoggedIn && 
          (state.matchedLocation == '/login' || 
           state.matchedLocation == '/splash')) {
>>>>>>> 51ee234352a17f5d388bc3b671fd5e5a8578b12a
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
<<<<<<< HEAD
      // GoRoute(
      //   path: '/password-reset',
      //   name: 'password-reset',
      //   builder: (context, state) {
      //     final token = state.uri.queryParameters['token'];
      //     return PasswordResetPage(token: token);
      //   },
      // ),
=======
>>>>>>> 51ee234352a17f5d388bc3b671fd5e5a8578b12a
      ShellRoute(
        builder: (context, state, child) => MainPage(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/data',
            name: 'data',
            builder: (context, state) => const DataPage(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );
}
