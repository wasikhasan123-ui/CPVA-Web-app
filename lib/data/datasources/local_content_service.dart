import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/contact_entity.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/gallery_entity.dart';
import '../../domain/entities/news_entity.dart';
import '../../domain/entities/notice_entity.dart';

class LocalContentService {
  static const _kNotices = 'cpva_notices_v1';
  static const _kEvents = 'cpva_events_v1';
  static const _kNews = 'cpva_news_v1';
  static const _kGallery = 'cpva_gallery_v1';
  static const _kContacts = 'cpva_contacts_v1';

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    await _seedIfMissing(_kNotices, 'notices');
    await _seedIfMissing(_kEvents, 'events');
    await _seedIfMissing(_kNews, 'news');
    await _seedIfMissing(_kGallery, 'gallery');
    await _seedIfMissing(_kContacts, 'contacts');
    _initialized = true;
  }

  Future<void> _seedIfMissing(String key, String assetName) async {
    if (_prefs.containsKey(key)) return;
    final raw = await rootBundle.loadString('assets/data/$assetName.json');
    await _prefs.setString(key, raw);
  }

  Future<List<NoticeEntity>> getNotices() async {
    await init();
    final raw = _prefs.getString(_kNotices) ?? '{}';
    final list = (jsonDecode(raw)['notices'] as List).cast<Map<String, dynamic>>();
    return list.map(NoticeEntity.fromJson).toList();
  }

  Future<List<EventEntity>> getEvents() async {
    await init();
    final raw = _prefs.getString(_kEvents) ?? '{}';
    final list = (jsonDecode(raw)['events'] as List).cast<Map<String, dynamic>>();
    return list.map(EventEntity.fromJson).toList();
  }

  Future<List<NewsEntity>> getNews() async {
    await init();
    final raw = _prefs.getString(_kNews) ?? '{}';
    final list = (jsonDecode(raw)['news'] as List).cast<Map<String, dynamic>>();
    return list.map(NewsEntity.fromJson).toList();
  }

  Future<List<GalleryEntity>> getGallery() async {
    await init();
    final raw = _prefs.getString(_kGallery) ?? '{}';
    final list = (jsonDecode(raw)['gallery'] as List).cast<Map<String, dynamic>>();
    return list.map(GalleryEntity.fromJson).toList();
  }

  Future<List<ContactEntity>> getContacts() async {
    await init();
    final raw = _prefs.getString(_kContacts) ?? '{}';
    final list = (jsonDecode(raw)['contacts'] as List).cast<Map<String, dynamic>>();
    return list.map(ContactEntity.fromJson).toList();
  }

  Future<void> saveNotices(List<NoticeEntity> items) async {
    await init();
    final list = {'notices': items.map((e) => e.toJson()).toList()};
    await _prefs.setString(_kNotices, jsonEncode(list));
  }

  Future<void> saveEvents(List<EventEntity> items) async {
    await init();
    final list = {'events': items.map((e) => e.toJson()).toList()};
    await _prefs.setString(_kEvents, jsonEncode(list));
  }

  Future<void> saveNews(List<NewsEntity> items) async {
    await init();
    final list = {'news': items.map((e) => e.toJson()).toList()};
    await _prefs.setString(_kNews, jsonEncode(list));
  }

  Future<void> saveGallery(List<GalleryEntity> items) async {
    await init();
    final list = {'gallery': items.map((e) => e.toJson()).toList()};
    await _prefs.setString(_kGallery, jsonEncode(list));
  }

  Future<void> saveContacts(List<ContactEntity> items) async {
    await init();
    final list = {'contacts': items.map((e) => e.toJson()).toList()};
    await _prefs.setString(_kContacts, jsonEncode(list));
  }

  Future<void> resetAll() async {
    await _prefs.remove(_kNotices);
    await _prefs.remove(_kEvents);
    await _prefs.remove(_kNews);
    await _prefs.remove(_kGallery);
    await _prefs.remove(_kContacts);
    _initialized = false;
    await init();
  }
}
