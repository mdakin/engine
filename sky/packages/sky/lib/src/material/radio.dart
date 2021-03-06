// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'theme.dart';

const ui.Color _kLightOffColor = const ui.Color(0x8A000000);
const ui.Color _kDarkOffColor = const ui.Color(0xB2FFFFFF);

typedef void RadioValueChanged(Object value);

class Radio extends StatelessComponent {
  Radio({
    Key key,
    this.value,
    this.groupValue,
    this.onChanged
  }) : super(key: key) {
    assert(onChanged != null);
  }

  final Object value;
  final Object groupValue;
  final RadioValueChanged onChanged;

  Color _getColor(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    if (value == groupValue)
      return themeData.accentColor;
    return themeData.brightness == ThemeBrightness.light ? _kLightOffColor : _kDarkOffColor;
  }

  Widget build(BuildContext context) {
    const double kDiameter = 16.0;
    const double kOuterRadius = kDiameter / 2;
    const double kInnerRadius = 5.0;
    return new GestureDetector(
      onTap: () => onChanged(value),
      child: new Container(
        margin: const EdgeDims.symmetric(horizontal: 5.0),
        width: kDiameter,
        height: kDiameter,
        child: new CustomPaint(
          callback: (ui.Canvas canvas, Size size) {

            Paint paint = new Paint()..color = _getColor(context);

            // Draw the outer circle
            paint.setStyle(ui.PaintingStyle.stroke);
            paint.strokeWidth = 2.0;
            canvas.drawCircle(const Point(kOuterRadius, kOuterRadius), kOuterRadius, paint);

            // Draw the inner circle
            if (value == groupValue) {
              paint.setStyle(ui.PaintingStyle.fill);
              canvas.drawCircle(const Point(kOuterRadius, kOuterRadius), kInnerRadius, paint);
            }
          }
        )
      )
    );
  }
}
