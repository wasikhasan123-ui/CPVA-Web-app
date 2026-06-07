import 'package:get_it/get_it.dart';

import '../../data/datasources/email_service.dart';
import '../../data/datasources/imgbb_service.dart';
import '../../data/datasources/executive_local_datasource.dart';
import '../../data/datasources/local_content_service.dart';
import '../../data/datasources/member_remote_datasource.dart';
import '../../data/datasources/member_photo_cache.dart';
import '../../data/datasources/photo_service.dart';
import '../../data/datasources/registration_remote_datasource.dart';
import '../../data/datasources/remote/firestore_service.dart';
import '../../data/datasources/remote/password_service.dart';
import '../../data/datasources/remote/remote_content_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/content_repository_impl.dart';
import '../../data/repositories/member_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/repositories/member_repository.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  await resetDependencies();
}

Future<void> resetDependencies() async {
  await sl.reset();

  sl.registerLazySingleton<FirestoreService>(
    () => FirestoreService(),
  );
  sl.registerLazySingleton<MemberRemoteDataSource>(
    () => MemberRemoteDataSource(sl<FirestoreService>()),
  );
  final contentService = LocalContentService();
  await contentService.init();
  sl.registerSingleton<LocalContentService>(contentService);

  sl.registerLazySingleton<RegistrationRemoteDataSource>(
    () => RegistrationRemoteDataSource(sl<FirestoreService>()),
  );
  sl.registerLazySingleton<PasswordService>(
    () => PasswordService(),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      sl<MemberRemoteDataSource>(),
      sl<RegistrationRemoteDataSource>(),
      sl<PasswordService>(),
    ),
  );
  sl.registerLazySingleton<RemoteContentDataSource>(
    () => RemoteContentDataSource(sl<FirestoreService>(), 'events', 'cpva_events_seeded_v1'),
    instanceName: 'events',
  );
  sl.registerLazySingleton<RemoteContentDataSource>(
    () => RemoteContentDataSource(sl<FirestoreService>(), 'news', 'cpva_news_seeded_v1'),
    instanceName: 'news',
  );
  sl.registerLazySingleton<RemoteContentDataSource>(
    () => RemoteContentDataSource(
      sl<FirestoreService>(),
      'gallery',
      'cpva_gallery_seeded_v1',
      permanentFlagKey: 'gallery_seeded_permanently',
    ),
    instanceName: 'gallery',
  );
  sl.registerLazySingleton<RemoteContentDataSource>(
    () => RemoteContentDataSource(sl<FirestoreService>(), 'notices', 'cpva_notices_seeded_v1'),
    instanceName: 'notices',
  );
  sl.registerLazySingleton<RemoteContentDataSource>(
    () => RemoteContentDataSource(sl<FirestoreService>(), 'contacts', 'cpva_contacts_seeded_v1'),
    instanceName: 'contacts',
  );
  sl.registerLazySingleton<MemberRepository>(
    () => MemberRepositoryImpl(sl<MemberRemoteDataSource>()),
  );
  sl.registerLazySingleton<ContentRepository>(
    () => ContentRepositoryImpl(
      sl<LocalContentService>(),
      sl<RemoteContentDataSource>(instanceName: 'events'),
      sl<RemoteContentDataSource>(instanceName: 'news'),
      sl<RemoteContentDataSource>(instanceName: 'gallery'),
      sl<RemoteContentDataSource>(instanceName: 'notices'),
      sl<RemoteContentDataSource>(instanceName: 'contacts'),
    ),
  );
  sl.registerLazySingleton<PhotoService>(
    () => PhotoService('member'),
    instanceName: 'member',
  );
  sl.registerLazySingleton<PhotoService>(
    () => PhotoService('executive'),
    instanceName: 'executive',
  );
  sl.registerLazySingleton<MemberPhotoCache>(
    () => MemberPhotoCache(),
  );
  sl.registerLazySingleton<ExecutiveLocalDataSource>(
    () => ExecutiveLocalDataSource(),
  );
  sl.registerLazySingleton<EmailService>(
    () => EmailService(),
  );
  sl.registerLazySingleton<ImgbbService>(
    () => ImgbbService(),
  );
}
