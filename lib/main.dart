import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_strings.dart';
import 'core/di/injection.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/member_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/member/member_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCUsmoosXpL7MZbP_RGMCjRodX2bSSaiSY',
        authDomain: 'cpva-26cb3.firebaseapp.com',
        projectId: 'cpva-26cb3',
        storageBucket: 'cpva-26cb3.firebasestorage.app',
        messagingSenderId: '339347372151',
        appId: '1:339347372151:web:d7dcd060780dfa84562e72',
      ),
    );
  }
  runApp(const CpvaApp());
}

class CpvaApp extends StatefulWidget {
  const CpvaApp({super.key});

  @override
  State<CpvaApp> createState() => _CpvaAppState();
}

class _CpvaAppState extends State<CpvaApp> {
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(sl<AuthRepository>())..add(const AuthCheckRequested());
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<MemberBloc>(
          create: (_) => MemberBloc(sl<MemberRepository>()),
        ),
      ],
      child: MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        routerConfig: buildRouter(_authBloc),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('bn'),
        ],
        locale: const Locale('en'),
      ),
    );
  }
}
