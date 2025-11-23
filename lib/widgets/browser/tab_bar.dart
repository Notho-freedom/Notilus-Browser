import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/theme_extensions.dart';
import 'tab_item.dart';
import 'tab_draggable.dart';
import '../../widgets/common/neon_button.dart';

class BrowserTabBar extends StatelessWidget {
  const BrowserTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<TabManager>(
      builder: (context, tabManager, _) {
        return Container(
          height: AppConstants.tabBarHeight,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: context.borderColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // New tab button
              NeonButton(
                text: '+',
                variant: NeonButtonVariant.primary,
                onPressed: () {
                  tabManager.createNewTab();
                },
                width: 32,
                height: 32,
                padding: EdgeInsets.zero,
              ),
              
              const SizedBox(width: 4),
              
              // Tabs scrollable area
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: tabManager.tabs.length,
                  itemBuilder: (context, index) {
                    final tab = tabManager.tabs[index];
                    return TabDraggable(
                      tab: tab,
                      onTap: () => tabManager.selectTab(tab.id),
                      onClose: () => tabManager.closeTab(tab.id),
                      onDuplicate: () => tabManager.duplicateTab(tab.id),
                      onPin: () => tabManager.pinTab(tab.id),
                      onCloseOthers: () {
                        final tabsToClose = tabManager.tabs
                            .where((t) => t.id != tab.id)
                            .map((t) => t.id)
                            .toList();
                        for (final tabId in tabsToClose) {
                          tabManager.closeTab(tabId);
                        }
                      },
                      onCloseToRight: () {
                        final currentIndex = tabManager.tabs.indexWhere((t) => t.id == tab.id);
                        if (currentIndex != -1) {
                          final tabsToClose = tabManager.tabs
                              .skip(currentIndex + 1)
                              .map((t) => t.id)
                              .toList();
                          for (final tabId in tabsToClose) {
                            tabManager.closeTab(tabId);
                          }
                        }
                      },
                      child: TabItem(
                        tab: tab,
                        onTap: () => tabManager.selectTab(tab.id),
                        onClose: () => tabManager.closeTab(tab.id),
                        onDuplicate: () => tabManager.duplicateTab(tab.id),
                        onPin: () => tabManager.pinTab(tab.id),
                        onCloseOthers: () {
                          final tabsToClose = tabManager.tabs
                              .where((t) => t.id != tab.id)
                              .map((t) => t.id)
                              .toList();
                          for (final tabId in tabsToClose) {
                            tabManager.closeTab(tabId);
                          }
                        },
                        onCloseToRight: () {
                          final currentIndex = tabManager.tabs.indexWhere((t) => t.id == tab.id);
                          if (currentIndex != -1) {
                            final tabsToClose = tabManager.tabs
                                .skip(currentIndex + 1)
                                .map((t) => t.id)
                                .toList();
                            for (final tabId in tabsToClose) {
                              tabManager.closeTab(tabId);
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

