import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:after_layout/after_layout.dart';


class NewView extends StatefulWidget {
  const NewView({super.key});

  @override
  State<NewView> createState() => _NewViewState();
}

class _NewViewState extends State<NewView> with AfterLayoutMixin {

  InAppWebViewController? webViewController;

  InAppWebViewSettings settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true);

  late ContextMenu contextMenu;

  PullToRefreshController? pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();

  TextEditingController? _searchController = TextEditingController();

  OutlineInputBorder outlineBorder = const OutlineInputBorder(
    borderSide: BorderSide(color: Colors.transparent, width: 0.0),
    borderRadius: BorderRadius.all(
      Radius.circular(50.0),
    ),
  );

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {
    _searchController?.text = "https://docs.flutter.dev";
  }

  @override
  void initState() {
    super.initState();
    contextMenu = ContextMenu(
        menuItems: [
          ContextMenuItem(
              id: 1,
              title: "Special",
              action: () async {
                print("Menu item Special clicked!");
                print(await webViewController?.getSelectedText());
                await webViewController?.clearFocus();
              })
        ],
        settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: false),
        onCreateContextMenu: (hitTestResult) async {
          print("onCreateContextMenu");
          print(hitTestResult.extra);
          print(await webViewController?.getSelectedText());
        },
        onHideContextMenu: () {
          print("onHideContextMenu");
        },
        onContextMenuActionItemClicked: (contextMenuItemClicked) async {
          var id = contextMenuItemClicked.id;
          print(
              "onContextMenuActionItemClicked: $id ${contextMenuItemClicked.title}");
        });

    pullToRefreshController = kIsWeb ||
        ![TargetPlatform.iOS, TargetPlatform.android]
            .contains(defaultTargetPlatform)
        ? null
        : PullToRefreshController(
      settings: PullToRefreshSettings(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (defaultTargetPlatform == TargetPlatform.android) {
          webViewController?.reload();
        } else if (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS) {
          webViewController?.loadUrl(
              urlRequest:
              URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        // leading: IconButton(
        //   icon: const Icon(Icons.home),
        //   color: Colors.white,
        //   onPressed: () {},
        // ),
        titleSpacing: 0.0,
        title: SizedBox(
          height: 40.0,
          child: Stack(
            children: <Widget>[
              TextField(
                onSubmitted: (value) {},
                keyboardType: TextInputType.url,
                // focusNode: _focusNode,
                autofocus: false,
                controller: _searchController,
                textInputAction: TextInputAction.go,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(
                      left: 45.0, top: 10.0, right: 10.0, bottom: 10.0),
                  filled: true,
                  fillColor: Colors.white,
                  border: outlineBorder,
                  focusedBorder: outlineBorder,
                  enabledBorder: outlineBorder,
                  hintText: "Search for or type a web address",
                  hintStyle:
                  const TextStyle(color: Colors.black54, fontSize: 16.0),
                ),
                style: const TextStyle(color: Colors.black, fontSize: 16.0),
              ),
              IconButton(
                icon: Icon(
                  Icons.lock,
                  color: Colors.green,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ).padding(left: 12,right: 10),
        actions: <Widget>[
          InkWell(
            // key: tabInkWellKey,
            child: Container(
              margin: const EdgeInsets.only(
                  left: 10.0, top: 15.0, right: 10.0, bottom: 15.0),
              decoration: BoxDecoration(
                  border: Border.all(width: 2.0, color: Colors.white),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(5.0)),
              constraints: const BoxConstraints(minWidth: 25.0),
              child: Center(
                  child: Text(
                    "3",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0),
                  )),
            ),
          ),
          PopupMenuButton<String>(
            // onSelected: _popupMenuChoiceAction,
            itemBuilder: (popupMenuContext) {
              return [];
            },
            iconColor: Colors.white,
          )
        ],
      ),
      body: Column(
        children: [
          InAppWebView(
            // key: webViewKey,
            // webViewEnvironment: webViewEnvironment,
            initialUrlRequest:
            URLRequest(url: WebUri('https://docs.flutter.dev')),
            // initialUrlRequest:
            // URLRequest(url: WebUri(Uri.base.toString().replaceFirst("/#/", "/") + 'page.html')),
            // initialFile: "assets/index.html",
            initialUserScripts: UnmodifiableListView<UserScript>([]),
            initialSettings: settings,
            contextMenu: contextMenu,
            pullToRefreshController: pullToRefreshController,
            onWebViewCreated: (controller) async {
              webViewController = controller;
            },
            onLoadStart: (controller, url) async {
              setState(() {
                this.url = url.toString();
                urlController.text = this.url;
              });
            },
            onPermissionRequest: (controller, request) async {
              return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.GRANT);
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              var uri = navigationAction.request.url!;

              if (![
                "http",
                "https",
                "file",
                "chrome",
                "data",
                "javascript",
                "about"
              ].contains(uri.scheme)) {
                // if (await canLaunchUrl(uri)) {
                //   // Launch the App
                //   await launchUrl(
                //     uri,
                //   );
                //   // and cancel the request
                //   return NavigationActionPolicy.CANCEL;
                // }
              }

              return NavigationActionPolicy.ALLOW;
            },
            onLoadStop: (controller, url) async {
              pullToRefreshController?.endRefreshing();
              setState(() {
                this.url = url.toString();
                urlController.text = this.url;
              });
            },
            onReceivedError: (controller, request, error) {
              pullToRefreshController?.endRefreshing();
            },
            onProgressChanged: (controller, progress) {
              if (progress == 100) {
                pullToRefreshController?.endRefreshing();
              }
              setState(() {
                this.progress = progress / 100;
                urlController.text = this.url;
              });
            },
            onUpdateVisitedHistory: (controller, url, isReload) {
              setState(() {
                this.url = url.toString();
                urlController.text = this.url;
              });
            },
            onConsoleMessage: (controller, consoleMessage) {
              print(consoleMessage);
            },
          ).expanded(),
        ],
      ),
    );
  }
}

main() async {
  return runApp(MaterialApp(
    home: Scaffold(
        body: NewView()),
  ));
}
