import '../../domain/entities/contact_entity.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/gallery_entity.dart';
import '../../domain/entities/news_entity.dart';
import '../../domain/entities/notice_entity.dart';

abstract class ContentRepository {
  Future<List<NoticeEntity>> getNotices();
  Stream<List<NoticeEntity>> streamNotices();
  Future<List<EventEntity>> getEvents();
  Stream<List<EventEntity>> streamEvents();
  Future<List<NewsEntity>> getNews();
  Stream<List<NewsEntity>> streamNews();
  Future<List<GalleryEntity>> getGallery();
  Stream<List<GalleryEntity>> streamGallery();
  Future<List<ContactEntity>> getContacts();
  Stream<List<ContactEntity>> streamContacts();

  Future<void> saveNotice(NoticeEntity notice);
  Future<void> deleteNotice(String id);

  Future<void> saveEvent(EventEntity event);
  Future<void> deleteEvent(String id);

  Future<void> saveNews(NewsEntity news);
  Future<void> deleteNews(String id);

  Future<void> saveGallery(GalleryEntity item);
  Future<void> deleteGallery(String id);

  Future<void> saveContact(ContactEntity contact);
  Future<void> deleteContact(String id);
}
