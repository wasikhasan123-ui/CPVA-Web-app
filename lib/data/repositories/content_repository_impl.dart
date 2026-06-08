import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

import '../../domain/entities/contact_entity.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/gallery_entity.dart';
import '../../domain/entities/news_entity.dart';
import '../../domain/entities/notice_entity.dart';
import '../../domain/repositories/content_repository.dart';
import '../datasources/local_content_service.dart';
import '../datasources/remote/remote_content_datasource.dart';

class ContentRepositoryImpl implements ContentRepository {
  final LocalContentService _service;
  final RemoteContentDataSource _events;
  final RemoteContentDataSource _news;
  final RemoteContentDataSource _gallery;
  final RemoteContentDataSource _notices;
  final RemoteContentDataSource _contacts;

  ContentRepositoryImpl(
    this._service,
    this._events,
    this._news,
    this._gallery,
    this._notices,
    this._contacts,
  );

  Future<void> _ensureSeed() async {
    if (!kIsWeb) return;
    await _events.seedFromJson('events', 'events');
    await _news.seedFromJson('news', 'news');
    await _gallery.seedFromJson('gallery', 'gallery');
    await _notices.seedFromJson('notices', 'notices');
    await _contacts.seedFromJson('contacts', 'contacts');
  }

  @override
  Future<List<NoticeEntity>> getNotices() async {
    if (!kIsWeb) return _service.getNotices();
    try {
      await _ensureSeed();
      final data = await _notices.getAll();
      final list = data
          .map((d) => NoticeEntity.fromJson(Map<String, dynamic>.from(d)))
          .toList();
      list.sort(_sortNotices);
      return list;
    } catch (_) {
      return _service.getNotices();
    }
  }

  @override
  Stream<List<NoticeEntity>> streamNotices() {
    if (!kIsWeb) return Stream.fromFuture(_service.getNotices());
    return Stream.fromFuture(_ensureSeed()).asyncExpand((_) {
      return _notices.streamAll().map((data) {
        final list = data
            .map((d) => NoticeEntity.fromJson(Map<String, dynamic>.from(d)))
            .toList();
        list.sort(_sortNotices);
        return list;
      });
    });
  }

  int _sortNotices(NoticeEntity a, NoticeEntity b) {
    if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
    final ad = DateTime.tryParse(a.date);
    final bd = DateTime.tryParse(b.date);
    if (ad != null && bd != null) return bd.compareTo(ad);
    return b.date.compareTo(a.date);
  }

  @override
  Future<List<EventEntity>> getEvents() async {
    if (!kIsWeb) return _service.getEvents();
    await _ensureSeed();
    final data = await _events.getAll();
    return data.map((d) => EventEntity.fromJson(Map<String, dynamic>.from(d))).toList();
  }

  @override
  Future<List<NewsEntity>> getNews() async {
    if (!kIsWeb) return _service.getNews();
    await _ensureSeed();
    final data = await _news.getAll();
    return data.map((d) => NewsEntity.fromJson(Map<String, dynamic>.from(d))).toList();
  }

  @override
  Future<List<GalleryEntity>> getGallery() async {
    if (!kIsWeb) return _service.getGallery();
    await _ensureSeed();
    final data = await _gallery.getAll();
    return data.map((d) => GalleryEntity.fromJson(Map<String, dynamic>.from(d))).toList();
  }

  @override
  Future<List<ContactEntity>> getContacts() async {
    if (!kIsWeb) return _service.getContacts();
    try {
      await _ensureSeed();
      final data = await _contacts.getAll();
      return data
          .map((d) => ContactEntity.fromJson(Map<String, dynamic>.from(d)))
          .toList();
    } catch (_) {
      return _service.getContacts();
    }
  }

  @override
  Stream<List<ContactEntity>> streamContacts() {
    if (!kIsWeb) return Stream.fromFuture(_service.getContacts());
    return Stream.fromFuture(_ensureSeed()).asyncExpand((_) {
      return _contacts.streamAll().map((data) => data
          .map((d) => ContactEntity.fromJson(Map<String, dynamic>.from(d)))
          .toList());
    });
  }

  @override
  Future<void> saveNotice(NoticeEntity notice) async {
    if (kIsWeb) {
      await _ensureSeed();
      await _notices.set(notice.id, notice.toJson());
      return;
    }
    final list = await _service.getNotices();
    final idx = list.indexWhere((e) => e.id == notice.id);
    if (idx >= 0) {
      list[idx] = notice;
    } else {
      list.insert(0, notice);
    }
    await _service.saveNotices(list);
  }

  @override
  Future<void> deleteNotice(String id) async {
    if (kIsWeb) {
      await _notices.deleteWhere(id);
      return;
    }
    final list = await _service.getNotices();
    list.removeWhere((e) => e.id == id);
    await _service.saveNotices(list);
  }

  @override
  Future<void> saveEvent(EventEntity event) async {
    if (kIsWeb) {
      await _ensureSeed();
      await _events.set(event.id, event.toJson());
      return;
    }
    final list = await _service.getEvents();
    final idx = list.indexWhere((e) => e.id == event.id);
    if (idx >= 0) {
      list[idx] = event;
    } else {
      list.insert(0, event);
    }
    await _service.saveEvents(list);
  }

  @override
  Future<void> deleteEvent(String id) async {
    if (kIsWeb) {
      await _events.deleteWhere(id);
      return;
    }

    final list = await _service.getEvents();
    list.removeWhere((e) => e.id == id);
    await _service.saveEvents(list);
  }

  @override
  Future<void> saveNews(NewsEntity news) async {
    if (kIsWeb) {
      await _ensureSeed();
      await _news.set(news.id, news.toJson());
      return;
    }
    final list = await _service.getNews();
    final idx = list.indexWhere((e) => e.id == news.id);
    if (idx >= 0) {
      list[idx] = news;
    } else {
      list.insert(0, news);
    }
    await _service.saveNews(list);
  }

  @override
  Future<void> deleteNews(String id) async {
    if (kIsWeb) {
      try {
        await _news.delete(id);
        return;
      } catch (_) {}
    }
    final list = await _service.getNews();
    list.removeWhere((e) => e.id == id);
    await _service.saveNews(list);
  }

  @override
  Future<void> saveGallery(GalleryEntity item) async {
    if (kIsWeb) {
      await _ensureSeed();
      await _gallery.set(item.id, item.toJson());
      return;
    }
    final list = await _service.getGallery();
    final idx = list.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      list[idx] = item;
    } else {
      list.insert(0, item);
    }
    await _service.saveGallery(list);
  }

  @override
  Future<void> deleteGallery(String id) async {
    if (kIsWeb) {
      try {
        await _gallery.deleteWhere(id);
        if (kDebugMode) {
          // ignore: avoid_print
          print('Gallery deleted from Firestore: $id');
        }
        return;
      } catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('Gallery deleteWhere failed: $e');
        }
        rethrow;
      }
    }
    final list = await _service.getGallery();
    list.removeWhere((e) => e.id == id);
    await _service.saveGallery(list);
  }

  @override
  Future<void> saveContact(ContactEntity contact) async {
    if (kIsWeb) {
      await _ensureSeed();
      await _contacts.set(contact.id, contact.toJson());
      return;
    }
    final list = await _service.getContacts();
    final idx = list.indexWhere((e) => e.id == contact.id);
    if (idx >= 0) {
      list[idx] = contact;
    } else {
      list.insert(0, contact);
    }
    await _service.saveContacts(list);
  }

  @override
  Future<void> deleteContact(String id) async {
    if (kIsWeb) {
      await _contacts.deleteWhere(id);
      return;
    }
    final list = await _service.getContacts();
    list.removeWhere((e) => e.id == id);
    await _service.saveContacts(list);
  }
}
