// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';

import 'basic.dart';
import 'focus.dart';
import 'framework.dart';
import 'transitions.dart';

class RouteArguments {
  const RouteArguments({ this.navigator, this.previousPerformance, this.nextPerformance });
  final NavigatorState navigator;
  final PerformanceView previousPerformance;
  final PerformanceView nextPerformance;
}

typedef Widget RouteBuilder(RouteArguments args);
typedef RouteBuilder RouteGenerator(String name);
typedef void StateRouteCallback(StateRoute route);

class Navigator extends StatefulComponent {
  Navigator({
    Key key,
    this.routes,
    this.onGenerateRoute, // you need to implement this if you pushNamed() to names that might not be in routes.
    this.onUnknownRoute // 404 generator. You only need to implement this if you have a way to navigate to arbitrary names.
  }) : super(key: key) {
    // To use a navigator, you must at a minimum define the route with the name '/'.
    assert(routes.containsKey('/'));
  }

  final Map<String, RouteBuilder> routes;
  final RouteGenerator onGenerateRoute;
  final RouteBuilder onUnknownRoute;

  NavigatorState createState() => new NavigatorState();
}

class NavigatorState extends State<Navigator> {

  List<Route> _history = new List<Route>();
  int _currentPosition = 0;

  Route get currentRoute => _history[_currentPosition];
  bool get hasPreviousRoute => _history.length > 1;

  void initState() {
    super.initState();
    PageRoute route = new PageRoute(config.routes['/']);
    assert(route != null);
    assert(!route.ephemeral);
    _insertRoute(route);
  }

  void pushState(State owner, Function callback) {
    push(new StateRoute(
      route: currentRoute,
      owner: owner,
      callback: callback
    ));
  }

  void pushNamed(String name) {
    RouteBuilder generateRoute() {
      assert(config.onGenerateRoute != null);
      return config.onGenerateRoute(name);
    }
    RouteBuilder builder = config.routes[name] ?? generateRoute() ?? config.onUnknownRoute;
    push(new PageRoute(builder));
  }

  void push(Route route) {
    assert(!_debugCurrentlyHaveRoute(route));
    setState(() {
      while (currentRoute.ephemeral) {
        currentRoute.didPop(null);
        _currentPosition -= 1;
      }
      _currentPosition += 1;
      _insertRoute(route);
    });
  }

  void popRoute(Route route, [dynamic result]) {
    assert(_debugCurrentlyHaveRoute(route));
    assert(_currentPosition > 0);
    setState(() {
      while (currentRoute != route) {
        assert(currentRoute.ephemeral);
        currentRoute.didPop(null);
        _currentPosition -= 1;
      }
      assert(_currentPosition > 0);
      currentRoute.didPop(result);
      _currentPosition -= 1;
    });
    assert(!_debugCurrentlyHaveRoute(route));
  }

  void pop([dynamic result]) {
    setState(() {
      assert(_currentPosition > 0);
      currentRoute.didPop(result);
      _currentPosition -= 1;
    });
  }

  bool _debugCurrentlyHaveRoute(Route route) {
    int index = _history.indexOf(route);
    return index >= 0 && index <= _currentPosition;
  }

  void _didCompleteRoute(Route route) {
    assert(_history.contains(route));
    if (route.isActuallyOpaque) {
      setState(() {
        // we need to rebuild because our build function depends on
        // whether the route is opaque or not.
      });
    }
  }

  void _didDismissRoute(Route route) {
    assert(_history.contains(route));
    if (_history.lastIndexOf(route) <= _currentPosition)
      popRoute(route);
  }

  void _insertRoute(Route route) {
    _history.insert(_currentPosition, route);
    route.didPush(this);
  }

  void _removeRoute(Route route) {
    assert(_history.contains(route));
    setState(() {
      _history.remove(route);
    });
  }

  Widget build(BuildContext context) {
    List<Widget> visibleRoutes = new List<Widget>();
    bool alreadyInsertModalBarrier = false;
    PerformanceView nextPerformance;
    for (int i = _history.length-1; i >= 0; i -= 1) {
      Route route = _history[i];
      if (!route.hasContent) {
        assert(!route.modal);
        continue;
      }
      visibleRoutes.add(
        new KeyedSubtree(
          key: new ObjectKey(route),
          child: route.build(this, nextPerformance)
        )
      );
      if (route.isActuallyOpaque)
        break;
      assert(route.modal || route.ephemeral);
      if (route.modal && i > 0 && !alreadyInsertModalBarrier) {
        visibleRoutes.add(new Listener(
          onPointerDown: (_) { pop(); },
          child: new Container()
        ));
        alreadyInsertModalBarrier = true;
      }
      nextPerformance = route.performance;
    }
    return new Focus(child: new Stack(visibleRoutes.reversed.toList()));
  }

}

abstract class Route {
  /// If hasContent is true, then the route represents some on-screen state.
  ///
  /// If hasContent is false, then no performance will be created, and the values of
  /// ephemeral, modal, and opaque are ignored. This is useful if the route
  /// represents some state handled by another widget. See
  /// NavigatorState.pushState().
  ///
  /// Set hasContent to false if you have nothing useful to return from build().
  ///
  /// modal must be false if hasContent is false, since otherwise any
  /// interaction with the system at all would imply that the current route is
  /// popped, which would be pointless.
  bool get hasContent => true;

  /// If ephemeral is true, then to explicitly pop the route you have to use
  /// navigator.popRoute() with a reference to this route. navigator.pop()
  /// automatically pops all ephemeral routes before popping the current
  /// top-most non-ephemeral route.
  ///
  /// If ephemeral is false, then the route can be popped with navigator.pop().
  ///
  /// Set ephemeral to true if you want to be automatically popped when another
  /// route is pushed or popped.
  ///
  /// modal must be true if ephemeral is false.
  bool get ephemeral => false;

  /// If modal is true, a hidden layer is inserted in the widget tree that
  /// catches all touches to widgets created by routes below this one, even if
  /// this one is transparent.
  ///
  /// If modal is false, then earlier routes can be interacted with, including
  /// causing new routes to be pushed and/or this route (and maybe others) to be
  /// popped.
  ///
  /// ephemeral must be true if modal is false.
  /// hasContent must be true if modal is true.
  bool get modal => true;

  /// If opaque is true, then routes below this one will not be built or painted
  /// when the transition to this route is complete.
  ///
  /// If opaque is false, then the previous route will always be painted even if
  /// this route's transition is complete.
  ///
  /// Set this to true if there's no reason to build and paint the route behind
  /// you when your transition is finished, and set it to false if you do not
  /// cover the entire application surface or are in any way semi-transparent.
  bool get opaque => false;

  PerformanceView get performance => null;
  bool get isActuallyOpaque => (performance == null || performance.isCompleted) && opaque;

  Widget build(NavigatorState navigator, PerformanceView nextRoutePerformance);

  NavigatorState _navigator;

  void setState(void fn()) {
    assert(_navigator != null);
    _navigator.setState(fn);
  }

  void didPush(NavigatorState navigator) {
    assert(_navigator == null);
    _navigator = navigator;
    assert(_navigator != null);
    performance?.addStatusListener(_handlePerformanceStatusChanged);
  }

  void didPop([dynamic result]) {
    assert(_navigator != null);
    if (performance == null)
      _navigator._removeRoute(this);
  }

  void _handlePerformanceStatusChanged(PerformanceStatus status) {
    if (status == PerformanceStatus.completed) {
      _navigator._didCompleteRoute(this);
    } else if (status == PerformanceStatus.dismissed) {
      _navigator._didDismissRoute(this);
      _navigator._removeRoute(this);
      _navigator = null;
    }
  }

  String toString() => '$runtimeType()';
}

abstract class PerformanceRoute extends Route {
  PerformanceRoute() {
    _performance = createPerformance();
  }

  PerformanceView get performance => _performance?.view;
  Performance _performance;

  Performance createPerformance() {
    Duration duration = transitionDuration;
    assert(duration >= Duration.ZERO);
    return new Performance(duration: duration);
  }

  Duration get transitionDuration;

  Widget build(NavigatorState navigator, PerformanceView nextRoutePerformance);

  void didPush(NavigatorState navigator) {
    super.didPush(navigator);
    _performance?.forward();
  }

  void didPop([dynamic result]) {
    _performance?.reverse();
    super.didPop(result);
  }
}

const Duration _kTransitionDuration = const Duration(milliseconds: 150);
const Point _kTransitionStartPoint = const Point(0.0, 75.0);

class PageRoute extends PerformanceRoute {
  PageRoute(this.builder);

  final RouteBuilder builder;

  bool get opaque => true;
  Duration get transitionDuration => _kTransitionDuration;

  Widget build(NavigatorState navigator, PerformanceView nextRoutePerformance) {
    // TODO(jackson): Hit testing should ignore transform
    // TODO(jackson): Block input unless content is interactive
    return new SlideTransition(
      performance: performance,
      position: new AnimatedValue<Point>(_kTransitionStartPoint, end: Point.origin, curve: easeOut),
      child: new FadeTransition(
        performance: performance,
        opacity: new AnimatedValue<double>(0.0, end: 1.0, curve: easeOut),
        child: builder(new RouteArguments(navigator: navigator, previousPerformance: this.performance, nextPerformance: nextRoutePerformance))
      )
    );
  }
}

class StateRoute extends Route {
  StateRoute({ this.route, this.owner, this.callback });

  Route route;
  State owner;
  StateRouteCallback callback;

  bool get hasContent => false;
  bool get modal => false;
  bool get opaque => false;

  void didPop([dynamic result]) {
    assert(result == null);
    if (callback != null)
      callback(this);
    super.didPop(result);
  }

  Widget build(NavigatorState navigator, PerformanceView nextRoutePerformance) => null;
}
