import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark.dart';

class BookmarkService {
  static const String _bookmarksKey = 'notilus_bookmarks';

  Future<void> addBookmark(Bookmark bookmark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = await getBookmarks();
      
      // Remove existing bookmark if it exists (same URL)
      bookmarks.removeWhere((b) => b.url == bookmark.url);
      
      // Add new bookmark
      bookmarks.add(bookmark);
      
      // Save
      final bookmarksJson = bookmarks.map((b) => b.toJson()).toList();
      await prefs.setString(_bookmarksKey, jsonEncode(bookmarksJson));
    } catch (e) {
      // Ignore errors
    }
  }

  Future<List<Bookmark>> getBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJsonString = prefs.getString(_bookmarksKey);
      if (bookmarksJsonString != null) {
        final List<dynamic> bookmarksJson = jsonDecode(bookmarksJsonString);
        return bookmarksJson.map((json) => Bookmark.fromJson(json)).toList();
      }
    } catch (e) {
      // Return empty list on error
    }
    return [];
  }

  Future<List<Bookmark>> searchBookmarks(String query) async {
    final bookmarks = await getBookmarks();
    final lowerQuery = query.toLowerCase();
    return bookmarks.where((bookmark) {
      return bookmark.url.toLowerCase().contains(lowerQuery) ||
          bookmark.title.toLowerCase().contains(lowerQuery) ||
          (bookmark.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          bookmark.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  Future<void> removeBookmark(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = await getBookmarks();
      bookmarks.removeWhere((b) => b.id == id);
      
      final bookmarksJson = bookmarks.map((b) => b.toJson()).toList();
      await prefs.setString(_bookmarksKey, jsonEncode(bookmarksJson));
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> updateBookmark(Bookmark bookmark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = await getBookmarks();
      final index = bookmarks.indexWhere((b) => b.id == bookmark.id);
      
      if (index != -1) {
        bookmarks[index] = bookmark;
        final bookmarksJson = bookmarks.map((b) => b.toJson()).toList();
        await prefs.setString(_bookmarksKey, jsonEncode(bookmarksJson));
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<bool> isBookmarked(String url) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((b) => b.url == url);
  }
}

