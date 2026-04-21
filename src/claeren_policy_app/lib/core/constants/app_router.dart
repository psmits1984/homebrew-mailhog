import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/two_factor_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/entity/screens/entity_selection_screen.dart';
import '../../features/entity/screens/entity_detail_screen.dart';
import '../../features/policies/screens/policy_list_screen.dart';
import '../../features/policies/screens/policy_detail_screen.dart';
import '../../features/claims/screens/new_claim_screen.dart';
import '../../features/naverrrekening/screens/naverrrekening_screen.dart';
import '../../features/payments/screens/payments_screen.dart';
import '../../features/payments/screens/sepa_mandate_screen.dart';
import '../../features/offertes/screens/offerte_list_screen.dart';
import '../../features/offertes/screens/offerte_detail_screen.dart';
import '../../features/compliance/screens/compliance_check_screen.dart';
import '../../features/compliance/screens/ubo_formulier_screen.dart';
import '../../features/slotverklaring/screens/slotverklaring_screen.dart';
import '../storage/secure_storage.dart';

final appRouter = GoRouter(
  initialLocation: '/auth/login',
  redirect: (context, state) async {
    if (state.matchedLocation == '/auth/login') {
      final token = await SecureStorage().getToken();
      if (token != null) return '/entiteiten';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/auth/login',
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/auth/2fa',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return TwoFactorScreen(
          sessionToken: extra['sessionToken'] as String,
          requiresOnboarding: extra['requiresOnboarding'] as bool,
        );
      },
    ),
    GoRoute(
      path: '/auth/onboarding',
      builder: (_, state) => OnboardingScreen(
        sessionToken: state.extra as String,
      ),
    ),
    GoRoute(
      path: '/entiteiten',
      builder: (_, __) => const EntitySelectionScreen(),
    ),
    GoRoute(
      path: '/entiteiten/:entityId/profiel',
      builder: (_, state) => EntityDetailScreen(
        entityId: state.pathParameters['entityId']!,
      ),
    ),
    GoRoute(
      path: '/entiteiten/:entityId/betalingen',
      builder: (_, state) => PaymentsScreen(
        entityId: state.pathParameters['entityId']!,
      ),
    ),
    GoRoute(
      path: '/entiteiten/:entityId/sepa',
      builder: (_, state) => SepaMandateScreen(
        entityId: state.pathParameters['entityId']!,
        polisNummer: state.uri.queryParameters['polis'],
        polisOmschrijving: state.uri.queryParameters['omschrijving'],
      ),
    ),
    GoRoute(
      path: '/polissen/:entityId',
      builder: (_, state) => PolicyListScreen(
        entityId: state.pathParameters['entityId']!,
      ),
      routes: [
        GoRoute(
          path: ':polisNummer',
          builder: (_, state) => PolicyDetailScreen(
            entityId: state.pathParameters['entityId']!,
            polisNummer: state.pathParameters['polisNummer']!,
          ),
          routes: [
            GoRoute(
              path: 'claim',
              builder: (_, state) => NewClaimScreen(
                entityId: state.pathParameters['entityId']!,
                polisNummer: state.pathParameters['polisNummer']!,
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/naverrrekening/:entityId',
      builder: (_, state) => NaverrekenScreen(
        entityId: state.pathParameters['entityId']!,
      ),
    ),

    // ─── Offertes ─────────────────────────────────────────────────────────────
    GoRoute(
      path: '/entiteiten/:entityId/offertes',
      builder: (_, state) => OfferteListScreen(
        entityId: state.pathParameters['entityId']!,
      ),
    ),
    GoRoute(
      path: '/offertes/:offerteId',
      builder: (_, state) => OfferteDetailScreen(
        offerteId: state.pathParameters['offerteId']!,
      ),
    ),

    // ─── Compliance / VNAB ────────────────────────────────────────────────────
    GoRoute(
      path: '/offertes/:offerteId/compliance',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ComplianceCheckScreen(
          offerteId: state.pathParameters['offerteId']!,
          entityId: extra['entityId'] as String? ?? '',
          relatieSoort: extra['relatieSoort'] as String? ?? 'Zakelijk',
          kvkNummer: extra['kvkNummer'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/offertes/:offerteId/ubo',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return UboFormulierScreen(
          offerteId: state.pathParameters['offerteId']!,
          entityId: extra['entityId'] as String? ?? '',
        );
      },
    ),

    // ─── Slotverklaring ───────────────────────────────────────────────────────
    GoRoute(
      path: '/offertes/:offerteId/slotverklaring',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return SlotverklaringScreen(
          offerteId: state.pathParameters['offerteId']!,
          entityId: extra['entityId'] as String? ?? '',
        );
      },
    ),
  ],
  errorBuilder: (_, state) => Scaffold(
    body: Center(child: Text('Pagina niet gevonden: ${state.error}')),
  ),
);
