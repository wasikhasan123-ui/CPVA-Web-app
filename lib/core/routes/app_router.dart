import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/contact_entity.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/executive_member_entity.dart';
import '../../domain/entities/gallery_entity.dart';
import '../../domain/entities/member_entity.dart';
import '../../domain/entities/news_entity.dart';
import '../../domain/entities/notice_entity.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/pages/admin/edit_contact_page.dart';
import '../../presentation/pages/admin/edit_event_page.dart';
import '../../presentation/pages/admin/edit_executive_page.dart';
import '../../presentation/pages/admin/edit_gallery_page.dart';
import '../../presentation/pages/admin/edit_member_page.dart';
import '../../presentation/pages/admin/edit_news_page.dart';
import '../../presentation/pages/admin/edit_notice_page.dart';
import '../../presentation/pages/admin/admin_panel_page.dart';
import '../../presentation/pages/admin/email_settings_page.dart';
import '../../presentation/pages/auth/change_password_page.dart';
import '../../presentation/pages/auth/forgot_password_page.dart';
import '../../presentation/pages/contact/contact_page.dart';
import '../../presentation/pages/events/event_details_page.dart';
import '../../presentation/pages/events/events_tab_page.dart';
import '../../presentation/pages/executive/executive_members_page.dart';
import '../../presentation/pages/gallery/gallery_page.dart';
import '../../presentation/pages/id_card/id_card_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/member/member_details_page.dart';
import '../../presentation/pages/member/member_directory_page.dart';
import '../../presentation/pages/news/news_page.dart';
import '../../presentation/pages/notices/notice_details_page.dart';
import '../../presentation/pages/notices/notices_tab_page.dart';
import '../../presentation/pages/payment/payments_page.dart';
import '../../presentation/pages/profile/my_profile_page.dart';
import '../../presentation/pages/registration/registration_page.dart';
import '../../presentation/pages/shell/main_shell.dart';
import '../../presentation/pages/splash/splash_page.dart';
import 'app_routes.dart';

GoRouter buildRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthListenable(authBloc),
    redirect: (context, state) {
      final authState = authBloc.state;
      final loggedIn = authState is AuthAuthenticated;
      final loc = state.matchedLocation;
      final atSplash = loc == AppRoutes.splash;
      final atLogin = loc == AppRoutes.login;
      final atRegistration = loc == AppRoutes.registration;
      final atForgot = loc == AppRoutes.forgotPassword;

      if (atSplash) return null;
      if (!loggedIn && !atLogin && !atRegistration && !atForgot) {
        return AppRoutes.login;
      }
      if (loggedIn && (atLogin || atRegistration || atForgot)) {
        return AppRoutes.shell;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.shell,
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: AppRoutes.idCard,
        builder: (context, state) => const IdCardPage(),
      ),
      GoRoute(
        path: AppRoutes.myProfile,
        builder: (context, state) => const MyProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.members,
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text('Member Directory'),
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
          ),
          body: const MemberDirectoryPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.memberDetails,
        builder: (context, state) {
          final member = state.extra as MemberEntity;
          return MemberDetailsPage(member: member);
        },
      ),
      GoRoute(
        path: AppRoutes.executives,
        builder: (context, state) => const ExecutiveMembersPage(),
      ),
      GoRoute(
        path: AppRoutes.editExecutive,
        builder: (context, state) {
          final e = state.extra as ExecutiveMemberEntity?;
          return EditExecutivePage(executive: e);
        },
      ),
      GoRoute(
        path: AppRoutes.noticesList,
        builder: (context, state) => const NoticesTabPage(),
      ),
      GoRoute(
        path: AppRoutes.eventsList,
        builder: (context, state) => const EventsTabPage(),
      ),
      GoRoute(
        path: AppRoutes.noticeDetails,
        builder: (context, state) {
          final n = state.extra as NoticeEntity;
          return NoticeDetailsPage(notice: n);
        },
      ),
      GoRoute(
        path: AppRoutes.eventDetails,
        builder: (context, state) {
          final e = state.extra as EventEntity;
          return EventDetailsPage(event: e);
        },
      ),
      GoRoute(
        path: AppRoutes.newsList,
        builder: (context, state) => const NewsPage(),
      ),
      GoRoute(
        path: AppRoutes.newsDetails,
        builder: (context, state) {
          final n = state.extra as NewsEntity;
          return NewsArticleView(news: n);
        },
      ),
      GoRoute(
        path: AppRoutes.galleryList,
        builder: (context, state) => const GalleryPage(),
      ),
      GoRoute(
        path: AppRoutes.contactList,
        builder: (context, state) => const ContactPage(),
      ),
      GoRoute(
        path: AppRoutes.payments,
        builder: (context, state) => const PaymentsPage(),
      ),
      GoRoute(
        path: AppRoutes.editMember,
        builder: (context, state) {
          final m = state.extra as MemberEntity?;
          return EditMemberPage(member: m);
        },
      ),
      GoRoute(
        path: AppRoutes.editNotice,
        builder: (context, state) {
          final n = state.extra as NoticeEntity?;
          return EditNoticePage(notice: n);
        },
      ),
      GoRoute(
        path: AppRoutes.editEvent,
        builder: (context, state) {
          final e = state.extra as EventEntity?;
          return EditEventPage(event: e);
        },
      ),
      GoRoute(
        path: AppRoutes.editNews,
        builder: (context, state) {
          final n = state.extra as NewsEntity?;
          return EditNewsPage(news: n);
        },
      ),
      GoRoute(
        path: AppRoutes.editGallery,
        builder: (context, state) {
          final g = state.extra as GalleryEntity?;
          return EditGalleryPage(item: g);
        },
      ),
      GoRoute(
        path: AppRoutes.editContact,
        builder: (context, state) {
          final c = state.extra as ContactEntity?;
          return EditContactPage(contact: c);
        },
      ),
      GoRoute(
        path: AppRoutes.registration,
        builder: (context, state) => const RegistrationPage(),
      ),
      GoRoute(
        path: AppRoutes.adminPanel,
        builder: (context, state) => const AdminPanelPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.emailSettings,
        builder: (context, state) => const EmailSettingsPage(),
      ),
    ],
  );
}

class _AuthListenable extends ChangeNotifier {
  final AuthBloc _authBloc;

  _AuthListenable(this._authBloc) {
    _authBloc.stream.listen((_) => notifyListeners());
  }
}
