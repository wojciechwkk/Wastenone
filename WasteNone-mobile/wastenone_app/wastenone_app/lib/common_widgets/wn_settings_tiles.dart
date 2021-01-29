import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

/// [WNSwitchSettingsTile] is a widget that has a [Switch] with given title,
/// subtitle and default value/status of the switch
///
/// This widget supports an additional list of widgets to display
/// when the switch is enabled. These optional list of widgets is accessed
/// through `childrenIfEnabled` property of this widget.
///
/// This widget works similar to [CheckboxSettingsTile].
///
///  Example:
///
/// ```dart
///  SwitchSettingsTile(
///   leading: Icon(Icons.developer_mode),
///   settingKey: 'key-switch-dev-mode',
///   title: 'Developer Settings',
///   onChange: (value) {
///     debugPrint('key-switch-dev-mod: $value');
///   },
///   childrenIfEnabled: <Widget>[
///     CheckboxSettingsTile(
///       leading: Icon(Icons.adb),
///       settingKey: 'key-is-developer',
///       title: 'Developer Mode',
///       onChange: (value) {
///         debugPrint('key-is-developer: $value');
///       },
///     ),
///     SwitchSettingsTile(
///       leading: Icon(Icons.usb),
///       settingKey: 'key-is-usb-debugging',
///       title: 'USB Debugging',
///       onChange: (value) {
///         debugPrint('key-is-usb-debugging: $value');
///       },
///     ),
///     SimpleSettingsTile(
///       title: 'Root Settings',
///       subtitle: 'These settings is not accessible',
///       enabled: false,
///     )
///   ],
///  );
///  ```
class WNSwitchSettingsTile extends StatelessWidget {
  final String settingKey;
  final bool defaultValue;
  final String title;
  final String subtitle;
  final bool enabled;
  final OnChanged<bool> onChange;
  final Widget leading;
  final String enabledLabel;
  final String disabledLabel;
  final List<Widget> childrenIfEnabled;
  final bool presetValue;

  WNSwitchSettingsTile({
    @required this.title,
    @required this.settingKey,
    this.defaultValue = false,
    this.enabled = true,
    this.onChange,
    this.leading,
    this.enabledLabel = '',
    this.disabledLabel = '',
    this.childrenIfEnabled,
    this.subtitle = '',
    this.presetValue,
  });

  @override
  Widget build(BuildContext context) {
    return ValueChangeObserver<bool>(
      cacheKey: settingKey,
      defaultValue: defaultValue,
      builder: (BuildContext context, bool value, OnChanged<bool> onChanged) {
        if (presetValue != null) value = presetValue;
        Widget mainWidget = _SettingsTile(
          leading: leading,
          title: title,
          subtitle: getSubtitle(value),
          onTap: () => onChanged(!value),
          enabled: enabled,
          child: _SettingsSwitch(
            value: value,
            onChanged: (value) => _onSwitchChange(value, onChanged),
            enabled: enabled,
          ),
        );

        Widget finalWidget = getFinalWidget(
          context,
          mainWidget,
          value,
          childrenIfEnabled,
        );
        return finalWidget;
      },
    );
  }

  void _onSwitchChange(bool value, OnChanged<bool> onChanged) {
    onChanged(value);
    if (onChange != null) {
      onChange(value);
    }
  }

  String getSubtitle(bool currentStatus) {
    if (subtitle != null && subtitle.isNotEmpty) {
      return subtitle;
    }
    String label = '';
    if (currentStatus && enabledLabel.isNotEmpty) {
      label = enabledLabel;
    }
    if (!currentStatus && disabledLabel.isNotEmpty) {
      label = disabledLabel;
    }
    return label;
  }

  Widget getFinalWidget(BuildContext context, Widget mainWidget, bool currentValue, List<Widget> childrenIfEnabled) {
    if (childrenIfEnabled == null || !currentValue) {
      return SettingsContainer(
        children: <Widget>[
          mainWidget,
        ],
      );
    }
    List<Widget> children = <Widget>[mainWidget];
    children.addAll(childrenIfEnabled);
    return SettingsContainer(
      children: children,
    );
  }
}

/// [_SettingsTile] is a Basic Building block for Any Settings widget.
///
/// This widget is container for any widget which is to be used for setting.
class _SettingsTile extends StatefulWidget {
  /// title string for the tile
  final String title;

  /// widget to be placed at first in the tile
  final Widget leading;

  /// subtitle string for the tile
  final String subtitle;

  /// flag to represent if the tile is accessible or not, if false user input is ignored
  final bool enabled;

  /// widget which is placed as the main element of the tile as settings UI
  final Widget child;

  /// call back for handling the tap event on tile
  final GestureTapCallback onTap;

  /// flag to show the child below the main tile elements
  final bool showChildBelow;

  _SettingsTile({
    @required this.title,
    @required this.child,
    this.subtitle = '',
    this.onTap,
    this.enabled = true,
    this.showChildBelow = false,
    this.leading,
  });

  @override
  __SettingsTileState createState() => __SettingsTileState();
}

class __SettingsTileState extends State<_SettingsTile> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ListTile(
            leading: widget.leading,
            title: Text(
              widget.title,
              style: headerTextStyle(context),
            ),
            subtitle: widget.subtitle.isEmpty
                ? null
                : Text(
                    widget.subtitle,
                    style: subtitleTextStyle(context),
                  ),
            enabled: widget.enabled,
            onTap: widget.onTap,
            trailing: Visibility(
              visible: !widget.showChildBelow,
              child: widget.child,
            ),
            dense: true,
            isThreeLine: (widget.subtitle?.isNotEmpty ?? false) && widget.subtitle.length > 20,
          ),
          Visibility(
            visible: widget.showChildBelow,
            child: widget.child,
          ),
          _SettingsTileDivider(),
        ],
      ),
    );
  }
}

/// [_SettingsTileDivider] is widget which is used as a Divide various settings
/// tile in a list
class _SettingsTileDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.0,
    );
  }
}

/// [_SettingsSwitch] is a Settings UI version of the [Switch] widget
class _SettingsSwitch extends StatelessWidget {
  /// current state of the switch
  final bool value;

  /// on change callback to handle state change
  final OnChanged<bool> onChanged;

  /// flag which represents the state of the settings, if false the the tile will
  /// ignore all the user inputs
  final bool enabled;

  _SettingsSwitch({
    @required this.value,
    @required this.onChanged,
    @required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}
