import 'dart:ui' as ui;

import 'package:test/test.dart';

void main() {
  test('should be settable using "style" attribute', () {
    ui.LayoutRoot layoutRoot = new ui.LayoutRoot();
    var document = new ui.Document();
    var foo = document.createElement('foo');
    layoutRoot.rootElement = foo;

    foo.setAttribute('style', 'color: red');

    expect(foo.getAttribute('style'), equals('color: red'));
    expect(foo.style["color"], equals('rgb(255, 0, 0)'));
  });

  test('should not crash when setting style to null', () {
    ui.LayoutRoot layoutRoot = new ui.LayoutRoot();
    var document = new ui.Document();
    var foo = document.createElement('foo');
    layoutRoot.rootElement = foo;

    expect(foo.style['color'], isNull);
    foo.style["color"] = null; // This used to crash.
    expect(foo.style['color'], isNull);
    foo.style["color"] = "blue";
    expect(foo.style['color'], equals("rgb(0, 0, 255)"));
    foo.style["color"] = null;
    expect(foo.style['color'], isNull);
    foo.style["color"] = "blue";
    expect(foo.style['color'], equals("rgb(0, 0, 255)"));
    foo.style.removeProperty("color");
    expect(foo.style['color'], isNull);

    layoutRoot.layout();
  });
}
