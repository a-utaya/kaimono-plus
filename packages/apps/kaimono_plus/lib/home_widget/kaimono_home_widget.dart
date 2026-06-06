import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

class KaimonoHomeWidget {
  const KaimonoHomeWidget._();

  static const appGroupId = 'group.com.example.kaimonoPlus.widgets';
  static const widgetKind = 'KaimonoWidget';

  static const listIdKey = 'kaimono_widget_list_id';
  static const _titleKey = 'kaimono_widget_title';
  static const _itemsKey = 'kaimono_widget_items';
  static const _updatedAtKey = 'kaimono_widget_updated_at';
  static const _emptyMessageKey = 'kaimono_widget_empty_message';

  static Future<String?> displayedListId() async {
    if (!_supportsHomeWidget) return null;

    final id = await _runOrNull(
      () async {
        await HomeWidget.setAppGroupId(appGroupId);
        return HomeWidget.getWidgetData<String>(
          listIdKey,
          appGroupId: appGroupId,
        );
      },
    );
    if (id == null || id.trim().isEmpty) return null;
    return id;
  }

  static Future<void> syncLatestList({
    required String id,
    required String title,
    required List<String> pendingItems,
    required DateTime updatedAt,
  }) async {
    if (!_supportsHomeWidget) return;

    await _runOrNull(
      () async {
        await HomeWidget.setAppGroupId(appGroupId);
        await HomeWidget.saveWidgetData<String>(listIdKey, id);
        await HomeWidget.saveWidgetData<String>(
          _titleKey,
          title.trim().isEmpty ? '買うものリスト' : title.trim(),
        );
        await HomeWidget.saveWidgetData<String>(
          _itemsKey,
          jsonEncode(pendingItems.take(10).toList()),
        );
        await HomeWidget.saveWidgetData<String>(
          _updatedAtKey,
          '${updatedAt.month}/${updatedAt.day} 更新',
        );
        await HomeWidget.saveWidgetData<String>(
          _emptyMessageKey,
          pendingItems.isEmpty ? 'すべて買いました' : '',
        );
        await HomeWidget.updateWidget(
          name: widgetKind,
          iOSName: widgetKind,
        );
      },
    );
  }

  static Future<void> clear() async {
    if (!_supportsHomeWidget) return;

    await _runOrNull(
      () async {
        await HomeWidget.setAppGroupId(appGroupId);
        await HomeWidget.saveWidgetData<String>(listIdKey, '');
        await HomeWidget.saveWidgetData<String>(_titleKey, '買うものリスト');
        await HomeWidget.saveWidgetData<String>(
          _itemsKey,
          jsonEncode(<String>[]),
        );
        await HomeWidget.saveWidgetData<String>(_updatedAtKey, '');
        await HomeWidget.saveWidgetData<String>(
          _emptyMessageKey,
          '保存したリストがありません',
        );
        await HomeWidget.updateWidget(
          name: widgetKind,
          iOSName: widgetKind,
        );
      },
    );
  }

  static Future<T?> _runOrNull<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static bool get _supportsHomeWidget {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }
}
