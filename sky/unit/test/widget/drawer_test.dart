import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

void main() {

  test('Drawer control test', () {
    testWidgets((WidgetTester tester) {
      NavigatorState navigator;
      tester.pumpWidget(
        new MaterialApp(
          routes: {
            '/': (RouteArguments args) {
              navigator = args.navigator;
              new Container();
            }
          }
        )
      );
      tester.pump(); // no effect
      expect(tester.findText('drawer'), isNull);
      showDrawer(navigator: navigator, child: new Text('drawer'));
      tester.pump(); // drawer should be starting to animate in
      expect(tester.findText('drawer'), isNotNull);
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester.findText('drawer'), isNotNull);
      navigator.pop();
      tester.pump(); // drawer should be starting to animate away
      expect(tester.findText('drawer'), isNotNull);
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester.findText('drawer'), isNull);
    });
  });

  test('Drawer tap test', () {
    testWidgets((WidgetTester tester) {
      NavigatorState navigator;
      tester.pumpWidget(new Container()); // throw away the old App and its Navigator
      tester.pumpWidget(
        new MaterialApp(
          routes: {
            '/': (RouteArguments args) {
              navigator = args.navigator;
              new Container();
            }
          }
        )
      );
      tester.pump(); // no effect
      expect(tester.findText('drawer'), isNull);
      showDrawer(navigator: navigator, child: new Text('drawer'));
      tester.pump(); // drawer should be starting to animate in
      expect(tester.findText('drawer'), isNotNull);
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester.findText('drawer'), isNotNull);
      tester.tap(tester.findText('drawer'));
      tester.pump(); // nothing should have happened
      expect(tester.findText('drawer'), isNotNull);
      tester.pump(new Duration(seconds: 1)); // ditto
      expect(tester.findText('drawer'), isNotNull);
      tester.tapAt(const Point(750.0, 100.0)); // on the mask
      tester.pump(); // drawer should be starting to animate away
      expect(tester.findText('drawer'), isNotNull);
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester.findText('drawer'), isNull);
    });
  });

}
