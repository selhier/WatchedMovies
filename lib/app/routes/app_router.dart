import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/my_lists/presentation/my_lists_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/movie_detail/presentation/movie_detail_screen.dart';
import '../../features/shared_list/presentation/public_shared_list_screen.dart';
import '../../features/shared_list/presentation/create_shared_list_screen.dart';
import '../../features/shared_list/data/shared_list_repository.dart';
import '../shell/app_shell.dart';

/// App router configuration with GoRouter
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/';

      return null;
    },
    routes: [
      // Login
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchScreen(),
            ),
          ),
          GoRoute(
            path: '/lists',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MyListsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // Movie detail (outside shell to go full screen)
      GoRoute(
        path: '/movie/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return MovieDetailScreen(movieId: id);
        },
      ),

      // Public Shared List view
      GoRoute(
        path: '/shared/:listId',
        builder: (context, state) {
          final listId = state.pathParameters['listId']!;
          return PublicSharedListScreen(listId: listId);
        },
      ),
      // Create Shared List view
      GoRoute(
        path: '/create-list',
        builder: (context, state) {
          final existingList = state.extra as SharedList?;
          return CreateSharedListScreen(existingList: existingList);
        },
      ),
    ],
  );
});
