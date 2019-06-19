import 'dart:async';
import 'dart:convert' as JSON;
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:breez/bloc/account/account_bloc.dart';
import 'package:breez/bloc/account/account_model.dart';
import 'package:breez/bloc/blocs_provider.dart';
import 'package:breez/bloc/invoice/invoice_bloc.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:breez/theme_data.dart' as theme;
import 'package:breez/widgets/back_button.dart' as backBtn;
import 'package:breez/widgets/loader.dart';
import 'package:flutter/services.dart' show rootBundle;

class VendorWebViewPage extends StatefulWidget {
  final AccountBloc accountBloc;
  final String _url;
  final String _title;

  VendorWebViewPage(this.accountBloc, this._url, this._title);

  @override
  State<StatefulWidget> createState() {
    return new VendorWebViewPageState();
  }
}

class VendorWebViewPageState extends State<VendorWebViewPage> {
  final _widgetWebview = new FlutterWebviewPlugin();

  AccountSettings _accountSettings;
  StreamSubscription<AccountSettings> _accountSettingsSubscription;
  StreamSubscription<CompletedPayment> _sentPaymentResultSubscription;

  InvoiceBloc invoiceBloc;
  StreamSubscription _postMessageListener;
  bool _isInit = false;

  Uint8List _screenshotData;

  var requestId;

  @override
  void initState() {
    super.initState();
    _listenPaymentsResults();
    _widgetWebview.onDestroy.listen((_) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<String> loadAsset(String path) async {
    return await rootBundle.loadString(path);
  }

  _listenPaymentsResults() {
    _accountSettingsSubscription = widget.accountBloc.accountSettingsStream.listen((settings) => _accountSettings = settings);

    _sentPaymentResultSubscription = widget.accountBloc.completedPaymentsStream.listen((payment) {
      // If user cancels or fulfills the payment show Webview again.
      _widgetWebview.show();
      setState(() {
        _screenshotData = null;
      });
      if (requestId != null) {
        !payment.cancelled ? _widgetWebview.evalJavascript("resolveRequest($requestId, true)") : _widgetWebview.evalJavascript("resolveRequest($requestId, false)");
      }
      requestId = null;
    }, onError: (_) {
      Navigator.popUntil(context, (route) {
        return route.settings.name == "/home" || route.settings.name == "/";
      });
    });
  }

  _initializeWebLN() async {
    String initWebLN = await loadAsset('src/scripts/initializeWebLN.js');
    _widgetWebview.evalJavascript(initWebLN);
  }

  @override
  void didChangeDependencies() {
    if (!_isInit) {
      invoiceBloc = AppBlocsProvider.of<InvoiceBloc>(context);
      _widgetWebview.onStateChanged.listen((state) async {
        if (state.type == WebViewState.finishLoad) {
          _initializeWebLN();
        }
      });
      _postMessageListener = _widgetWebview.onPostMessage.listen((postMessage) {
        if (postMessage != null) {
          final order = (widget._title == "ln.pizza") ? postMessage : JSON.jsonDecode(postMessage);
          if ((widget._title == "ln.pizza") || order.containsKey("pay_req")) {
            requestId = (widget._title == "ln.pizza") ? null :  order['req_id'];
            var _request = (widget._title == "ln.pizza") ? order : order['pay_req'];
            // Hide keyboard
            FocusScope.of(context).requestFocus(FocusNode());
            // Wait for keyboard and screen animations to settle
            Timer(Duration(milliseconds: 750), () {
              // Take screenshot and show payment request dialog
              _takeScreenshot().then((imageData) {
                setState(() {
                  _screenshotData = imageData;
                });
                // Wait for memory image to load
                Timer(Duration(milliseconds: 200), () {
                  // Hide Webview to interact with payment request dialog
                  _widgetWebview.hide();
                  invoiceBloc.newLightningLinkSink.add(_request);
                });
              });
            });
          }
        }
      });
      _isInit = true;
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _accountSettingsSubscription.cancel();
    _sentPaymentResultSubscription.cancel();
    _postMessageListener.cancel();
    _widgetWebview.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new WebviewScaffold(
      appBar: new AppBar(
        leading: backBtn.BackButton(),
        automaticallyImplyLeading: false,
        iconTheme: theme.appBarIconTheme,
        textTheme: theme.appBarTextTheme,
        backgroundColor: theme.BreezColors.blue[500],
        title: new Text(
          widget._title,
          style: theme.appBarTextStyle,
        ),
        elevation: 0.0,
      ),
      url: widget._url,
      withJavascript: true,
      withZoom: false,
      initialChild: _screenshotData != null ? Image.memory(_screenshotData) : null,
    );
  }

  Future _takeScreenshot() async {
    Uint8List _imageData = await _widgetWebview.takeScreenshot();
    return _imageData;
  }
}
