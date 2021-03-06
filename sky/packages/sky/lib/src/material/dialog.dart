// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'material_button.dart';
import 'material.dart';
import 'theme.dart';

typedef Widget DialogBuilder(NavigatorState navigator);

/// A material design dialog
///
/// <https://www.google.com/design/spec/components/dialogs.html>
class Dialog extends StatelessComponent {
  Dialog({
    Key key,
    this.title,
    this.titlePadding,
    this.content,
    this.contentPadding,
    this.actions,
    this.onDismiss
  }) : super(key: key);

  /// The (optional) title of the dialog is displayed in a large font at the top
  /// of the dialog.
  final Widget title;

  // Padding around the title; uses material design default if none is supplied
  // If there is no title, no padding will be provided
  final EdgeDims titlePadding;

  /// The (optional) content of the dialog is displayed in the center of the
  /// dialog in a lighter font.
  final Widget content;

  // Padding around the content; uses material design default if none is supplied
  final EdgeDims contentPadding;

  /// The (optional) set of actions that are displayed at the bottom of the
  /// dialog.
  final List<Widget> actions;

  /// An (optional) callback that is called when the dialog is dismissed.
  final GestureTapCallback onDismiss;

  Color _getColor(BuildContext context) {
    switch (Theme.of(context).brightness) {
      case ThemeBrightness.light:
        return Colors.white;
      case ThemeBrightness.dark:
        return Colors.grey[800];
    }
  }

  Widget build(BuildContext context) {

    List<Widget> dialogBody = new List<Widget>();

    if (title != null) {
      EdgeDims padding = titlePadding;
      if (padding == null)
        padding = new EdgeDims.TRBL(24.0, 24.0, content == null ? 20.0 : 0.0, 24.0);
      dialogBody.add(new Padding(
        padding: padding,
        child: new DefaultTextStyle(
          style: Theme.of(context).text.title,
          child: title
        )
      ));
    }

    if (content != null) {
      EdgeDims padding = contentPadding;
      if (padding == null)
        padding = const EdgeDims.TRBL(20.0, 24.0, 24.0, 24.0);
      dialogBody.add(new Padding(
        padding: padding,
        child: new DefaultTextStyle(
          style: Theme.of(context).text.subhead,
          child: content
        )
      ));
    }

    if (actions != null) {
      dialogBody.add(new ButtonTheme(
        color: ButtonColor.accent,
        child: new Container(
          child: new Row(actions,
            justifyContent: FlexJustifyContent.end
          )
        )
      ));
    }

    return new Stack([
      new GestureDetector(
        onTap: onDismiss,
        child: new Container(
          decoration: const BoxDecoration(
            backgroundColor: const Color(0x7F000000)
          )
        )
      ),
      new Center(
        child: new Container(
          margin: new EdgeDims.symmetric(horizontal: 40.0, vertical: 24.0),
          child: new ConstrainedBox(
            constraints: new BoxConstraints(minWidth: 280.0),
            child: new Material(
              level: 4,
              color: _getColor(context),
              child: new IntrinsicWidth(
                child: new Block(dialogBody)
              )
            )
          )
        )
      )
    ]);

  }
}

class _DialogRoute extends PerformanceRoute {
  _DialogRoute({ this.completer, this.builder });

  final Completer completer;
  final RouteBuilder builder;

  bool get opaque => false;
  Duration get transitionDuration => const Duration(milliseconds: 150);

  Widget build(NavigatorState navigator, PerformanceView nextRoutePerformance) {
    return new FadeTransition(
      performance: performance,
      opacity: new AnimatedValue<double>(0.0, end: 1.0, curve: easeOut),
      child: builder(new RouteArguments(navigator: navigator, previousPerformance: this.performance, nextPerformance: nextRoutePerformance))
    );
  }

  void didPop([dynamic result]) {
    completer.complete(result);
    super.didPop(result);
  }
}

Future showDialog(NavigatorState navigator, DialogBuilder builder) {
  Completer completer = new Completer();
  navigator.push(new _DialogRoute(
    completer: completer,
    builder: (RouteArguments args) {
      return new Focus(
        key: new GlobalObjectKey(completer),
        autofocus: true,
        child: builder(args.navigator)
      );
    }
  ));
  return completer.future;
}
