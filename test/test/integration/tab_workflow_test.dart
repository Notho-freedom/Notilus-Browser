import 'package:flutter_test/flutter_test.dart';
import 'package:notilus/services/tab_manager.dart';
import 'package:notilus/models/tab_model.dart';

void main() {
  group('Tab Workflow Integration Tests', () {
    late TabManager tabManager;
    
    setUp(() {
      tabManager = TabManager();
    });
    
    group('Tab Creation Workflow', () {
      test('should create initial tab on initialization', () async {
        // Attendre l'initialisation
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(tabManager.tabs.isNotEmpty, isTrue);
        expect(tabManager.activeTab, isNotNull);
      });
      
      test('should create new tab with URL', () {
        final tab = tabManager.createNewTab(url: 'https://example.com');
        
        expect(tab.url, equals('https://example.com'));
        expect(tabManager.activeTabId, equals(tab.id));
      });
      
      test('should create new tab without URL (about:newtab)', () {
        final tab = tabManager.createNewTab();
        
        expect(tab.url, equals('about:newtab'));
      });
      
      test('should create private tab', () {
        final tab = tabManager.createNewTab(isPrivate: true);
        
        expect(tab.isPrivate, isTrue);
        expect(tab.groupId, isNull); // Private tabs can't be in groups
      });
    });
    
    group('Tab Selection Workflow', () {
      test('should select tab by ID', () {
        final tab1 = tabManager.createNewTab(url: 'https://site1.com');
        final tab2 = tabManager.createNewTab(url: 'https://site2.com');
        
        // Tab2 should be active after creation
        expect(tabManager.activeTabId, equals(tab2.id));
        
        // Select tab1
        tabManager.selectTab(tab1.id);
        
        expect(tabManager.activeTabId, equals(tab1.id));
        expect(tabManager.activeTab?.url, equals('https://site1.com'));
      });
      
      test('should update isSelected flag correctly', () {
        final tab1 = tabManager.createNewTab(url: 'https://site1.com');
        final tab2 = tabManager.createNewTab(url: 'https://site2.com');
        
        // Check tab2 is selected
        final tab2State = tabManager.tabs.firstWhere((t) => t.id == tab2.id);
        expect(tab2State.isSelected, isTrue);
        
        // Select tab1
        tabManager.selectTab(tab1.id);
        
        final tab1AfterSelect = tabManager.tabs.firstWhere((t) => t.id == tab1.id);
        final tab2AfterSelect = tabManager.tabs.firstWhere((t) => t.id == tab2.id);
        
        expect(tab1AfterSelect.isSelected, isTrue);
        expect(tab2AfterSelect.isSelected, isFalse);
      });
    });
    
    group('Tab Close Workflow', () {
      test('should close tab and select next', () async {
        final tab1 = tabManager.createNewTab(url: 'https://site1.com');
        final tab2 = tabManager.createNewTab(url: 'https://site2.com');
        
        final initialCount = tabManager.tabs.length;
        
        // Close tab2 (active)
        tabManager.closeTab(tab2.id);
        
        await Future.delayed(const Duration(milliseconds: 50));
        
        expect(tabManager.tabs.length, equals(initialCount - 1));
        // Should have selected tab1 or previous tab
      });
      
      test('should create new tab when closing last tab', () async {
        // Close all tabs except one
        while (tabManager.tabs.length > 1) {
          tabManager.closeTab(tabManager.tabs.first.id);
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        final lastTabId = tabManager.tabs.first.id;
        tabManager.closeTab(lastTabId);
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Should have created a new tab
        expect(tabManager.tabs.isNotEmpty, isTrue);
        expect(tabManager.activeTab, isNotNull);
      });
    });
    
    group('Tab Update Workflow', () {
      test('should update tab URL', () {
        final tab = tabManager.createNewTab(url: 'https://old-url.com');
        
        tabManager.updateTab(tab.id, url: 'https://new-url.com');
        
        final updatedTab = tabManager.tabs.firstWhere((t) => t.id == tab.id);
        expect(updatedTab.url, equals('https://new-url.com'));
      });
      
      test('should update tab title', () {
        final tab = tabManager.createNewTab(url: 'https://example.com');
        
        tabManager.updateTab(tab.id, title: 'Example Site');
        
        final updatedTab = tabManager.tabs.firstWhere((t) => t.id == tab.id);
        expect(updatedTab.title, equals('Example Site'));
      });
      
      test('should update tab state', () {
        final tab = tabManager.createNewTab(url: 'https://example.com');
        
        tabManager.updateTab(tab.id, state: TabState.loaded);
        
        final updatedTab = tabManager.tabs.firstWhere((t) => t.id == tab.id);
        expect(updatedTab.state, equals(TabState.loaded));
      });
    });
    
    group('Tab Pin Workflow', () {
      test('should pin and unpin tab', () {
        final tab = tabManager.createNewTab(url: 'https://example.com');
        
        // Initially not pinned
        expect(tabManager.tabs.firstWhere((t) => t.id == tab.id).isPinned, isFalse);
        
        // Pin the tab
        tabManager.pinTab(tab.id);
        expect(tabManager.tabs.firstWhere((t) => t.id == tab.id).isPinned, isTrue);
        
        // Unpin the tab
        tabManager.pinTab(tab.id);
        expect(tabManager.tabs.firstWhere((t) => t.id == tab.id).isPinned, isFalse);
      });
    });
    
    group('Tab Duplicate Workflow', () {
      test('should duplicate tab with same URL', () {
        final original = tabManager.createNewTab(url: 'https://example.com');
        tabManager.updateTab(original.id, title: 'Example');
        
        final duplicate = tabManager.duplicateTab(original.id);
        
        expect(duplicate, isNotNull);
        expect(duplicate!.url, equals(original.url));
        expect(duplicate.id, isNot(equals(original.id)));
      });
      
      test('should select duplicated tab', () {
        final original = tabManager.createNewTab(url: 'https://example.com');
        final duplicate = tabManager.duplicateTab(original.id);
        
        expect(tabManager.activeTabId, equals(duplicate!.id));
      });
    });
    
    group('Tab Reorder Workflow', () {
      test('should reorder tabs', () {
        tabManager.createNewTab(url: 'https://site1.com');
        tabManager.createNewTab(url: 'https://site2.com');
        tabManager.createNewTab(url: 'https://site3.com');
        
        final initialOrder = tabManager.tabs.map((t) => t.url).toList();
        
        // Move first tab to last position
        tabManager.reorderTab(0, tabManager.tabs.length);
        
        final newOrder = tabManager.tabs.map((t) => t.url).toList();
        
        expect(newOrder, isNot(equals(initialOrder)));
      });
    });
    
    group('Tab Group Workflow', () {
      test('should create group', () {
        final group = tabManager.createGroup('Test Group', '#FF0000');
        
        expect(group.name, equals('Test Group'));
        expect(group.color, equals('#FF0000'));
        expect(tabManager.groups, contains(group));
      });
      
      test('should add tab to group', () {
        final tab = tabManager.createNewTab(url: 'https://example.com');
        final group = tabManager.createGroup('Test Group', '#FF0000');
        
        tabManager.addTabToGroup(tab.id, group.id);
        
        final updatedTab = tabManager.tabs.firstWhere((t) => t.id == tab.id);
        expect(updatedTab.groupId, equals(group.id));
      });
      
      test('should remove tab from group', () {
        final tab = tabManager.createNewTab(url: 'https://example.com');
        final group = tabManager.createGroup('Test Group', '#FF0000');
        
        tabManager.addTabToGroup(tab.id, group.id);
        tabManager.removeTabFromGroup(tab.id);
        
        final updatedTab = tabManager.tabs.firstWhere((t) => t.id == tab.id);
        expect(updatedTab.groupId, isNull);
      });
      
      test('should delete group and remove tabs from it', () {
        final tab = tabManager.createNewTab(url: 'https://example.com');
        final group = tabManager.createGroup('Test Group', '#FF0000');
        
        tabManager.addTabToGroup(tab.id, group.id);
        tabManager.deleteGroup(group.id);
        
        expect(tabManager.groups, isNot(contains(group)));
        
        final updatedTab = tabManager.tabs.firstWhere((t) => t.id == tab.id);
        expect(updatedTab.groupId, isNull);
      });
    });
  });
}

