import 'package:flutter/material.dart';
import 'package:breez/theme_data.dart' as theme;
import 'package:breez/widgets/breez_avatar.dart';
import 'package:breez/bloc/bloc_widget_connector.dart';
import 'package:breez/bloc/app_blocs.dart';
import 'package:breez/bloc/user_profile/breez_user_model.dart';
import 'package:breez/bloc/user_profile/user_profile_bloc.dart';
import 'package:breez/widgets/breez_avatar_dialog.dart';
import 'package:breez/widgets/breez_drawer_header.dart';

class DrawerItemConfig {
  final String _name;
  final String _title;
  final String _icon;
  final void Function(String name) onItemSelected;

  DrawerItemConfig(this._name, this._title, this._icon, {this.onItemSelected});

  String get name {
    return _name;
  }

  String get title {
    return _title;
  }

  String get icon {
    return _title;
  }
}

class NavigationDrawer extends StatelessWidget {
  NavigationDrawer(this._avatar, this._screensConfig, this._majorActionsFundsConfig, this._majorActionsPayConfig,
      this._minorActionsCardConfig, this._minorActionsInvoiceConfig, this._minorActionsDevConfig, this._onItemSelected);
  final bool _avatar;
  final List<DrawerItemConfig> _screensConfig;
  final List<DrawerItemConfig> _majorActionsFundsConfig;
  final List<DrawerItemConfig> _majorActionsPayConfig;
  final List<DrawerItemConfig> _minorActionsCardConfig;
  final List<DrawerItemConfig> _minorActionsInvoiceConfig;
  final List<DrawerItemConfig> _minorActionsDevConfig;
  final void Function(String screenName) _onItemSelected;

  @override
  Widget build(BuildContext context) {
    return new BlocConnector<AppBlocs>((context, blocs) => new _NavigationDrawer(
        _avatar,
        _screensConfig,
        _majorActionsFundsConfig,
        _majorActionsPayConfig,
        _minorActionsCardConfig,
        _minorActionsInvoiceConfig,
        _minorActionsDevConfig,
        _onItemSelected,
        blocs.userProfileBloc));
  }
}

class _NavigationDrawer extends StatelessWidget {
  final bool _avatar;
  final List<DrawerItemConfig> _screensConfig;
  final List<DrawerItemConfig> _majorActionsFundsConfig;
  final List<DrawerItemConfig> _majorActionsPayConfig;
  final List<DrawerItemConfig> _minorActionsCardConfig;
  final List<DrawerItemConfig> _minorActionsInvoiceConfig;
  final List<DrawerItemConfig> _minorActionsDevConfig;
  final void Function(String screenName) _onItemSelected;
  final UserProfileBloc _userProfileBloc;

  _NavigationDrawer(
      this._avatar,
      this._screensConfig,
      this._majorActionsFundsConfig,
      this._majorActionsPayConfig,
      this._minorActionsCardConfig,
      this._minorActionsInvoiceConfig,
      this._minorActionsDevConfig,
      this._onItemSelected,
      this._userProfileBloc);

  @override
  Widget build(BuildContext context) {
    if (_majorActionsPayConfig != null && _minorActionsCardConfig != null) {
      return new Drawer(
        child: new ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.only(bottom: 20.0),
            children: <Widget>[
              _breezDrawerHeader(_userProfileBloc, _avatar),
            ]
              ..addAll(_majorActionsFundsConfig
                  .map(
                    (action) => _actionTile(action, context, _onItemSelected, false),
                  )
                  .toList())
              ..add(new Padding(padding: EdgeInsets.only(left: 8.0, right: 8.0), child: Divider()))
              ..addAll(_majorActionsPayConfig
                  .map(
                    (action) => _actionTile(action, context, _onItemSelected, false),
                  )
                  .toList())
              ..add(new Padding(padding: EdgeInsets.only(left: 8.0, right: 8.0), child: Divider()))
              ..add(_expansionTile(context, "Card", AssetImage("src/icon/card.png"), _minorActionsCardConfig, _onItemSelected))
              ..add(new Padding(padding: EdgeInsets.only(left: 8.0, right: 8.0), child: Divider()))
              ..addAll(_minorActionsInvoiceConfig
                  .map(
                    (action) => _actionTile(action, context, _onItemSelected, false),
              )
                  .toList())
              ..add(new Padding(padding: EdgeInsets.only(left: 8.0, right: 8.0), child: Divider()))
              ..addAll(_minorActionsDevConfig
                  .map(
                    (action) => _actionTile(action, context, _onItemSelected, false),
                  )
                  .toList())),
      );
    } else {
      return new Drawer(
        child: new ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: <Widget>[_breezDrawerHeader(_userProfileBloc, _avatar)]
              ..addAll(_majorActionsFundsConfig
                  .map(
                    (action) => _actionTile(action, context, _onItemSelected, false),
                  )
                  .toList())
              ..add(new Padding(padding: EdgeInsets.only(left: 8.0, right: 8.0), child: Divider()))
              ..addAll(_minorActionsDevConfig
                  .map(
                    (action) => _actionTile(action, context, _onItemSelected, false),
                  )
                  .toList())),
      );
    }
  }
}

Widget _breezDrawerHeader(UserProfileBloc user, bool drawAvatar) {
  return new BreezDrawerHeader(
    padding: EdgeInsets.only(top: 54.0, left: 16.0),
    child: !drawAvatar
        ? new Container()
        : new StreamBuilder<BreezUserModel>(
            stream: user.userStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return new Container();
              } else {
                return new GestureDetector(
                  onTap: () {
                    showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => breezAvatarDialog(context, user),
                    );
                  },
                  child: new Column(children: <Widget>[
                    new Row(
                      children: <Widget>[
                        BreezAvatar(snapshot.data.avatarURL, radius: 24.0),
                      ],
                    ),
                    new Padding(
                      padding: EdgeInsets.only(top: 22.0),
                      child: new Row(
                        children: <Widget>[
                          new Opacity(
                              opacity: 0.6,
                              child: new Text(
                                snapshot.data.name ?? "No Name",
                                style: theme.navigationDrawerHandleStyle,
                              )),
                        ],
                      ),
                    ),
                  ]),
                );
              }
            }),
    decoration: new BoxDecoration(
      image: DecorationImage(image: AssetImage("src/images/waves-drawer.png")),
    ),
  );
}

Widget _actionTile(DrawerItemConfig action, BuildContext context, Function onItemSelected, bool subTile) {
  return new Padding(
    padding: EdgeInsets.only(left: subTile ? 36.0 : 8.0, right: 8.0),
    child: new ListTile(
      leading: ImageIcon(
        AssetImage(action._icon),
        size: 24.0,
        color: Colors.white,
      ),
      title: new Text(action.title, style: theme.drawerItemTextStyle),
      onTap: () {
        Navigator.pop(context);
        onItemSelected(action.name);
      },
    ),
  );
}

Widget _expansionTile(BuildContext context, String title, AssetImage icon, List<DrawerItemConfig> config, Function onItemSelected){
  final _expansionTileTheme = Theme.of(context).copyWith(dividerColor: Theme.of(context).canvasColor);
  return Theme(data: _expansionTileTheme, child:ExpansionTile(
    title: Padding(
      padding: EdgeInsets.only(left:8.0, right: 8.0), child:Text(title,style: theme.drawerItemTextStyle,),),
    leading: Padding(padding: EdgeInsets.only(left:8.0),child:ImageIcon(icon, size: 24.0,
      color: Colors.white,),),
    children:
    config.map((action) => _actionTile(action, context, onItemSelected, true)).toList(),
  ));
}