part of skysprites;

/// Labels are used to display a string of text in a the node tree. To align
/// the label, the textAlign property of teh [TextStyle] can be set.
class Label extends Node {
  /// Creates a new Label with the provided [_text] and [_textStyle].
  Label(this._text, [this._textStyle]) {
    if (_textStyle == null) {
      _textStyle = new TextStyle();
    }
  }

  String _text;

  /// The text being drawn by the label.
  String get text => _text;

  set text(String text) {
    _text = text;
    _painter = null;
  }

  TextStyle _textStyle;

  /// The style to draw the text in.
  TextStyle get textStyle => _textStyle;

  set textStyle(TextStyle textStyle) {
    _textStyle = textStyle;
    _painter = null;
  }

  TextPainter _painter;
  double _width;

  void paint(PaintingCanvas canvas) {
    if (_painter == null) {
      PlainTextSpan textSpan = new PlainTextSpan(_text);
      StyledTextSpan styledTextSpan = new StyledTextSpan(_textStyle, [textSpan]);
      _painter = new TextPainter(styledTextSpan);

      _painter.maxWidth = double.INFINITY;
      _painter.minWidth = 0.0;
      _painter.layout();

      _width = _painter.maxContentWidth.ceil().toDouble();

      _painter.maxWidth = _width;
      _painter.minWidth = _width;
      _painter.layout();
    }

    Offset offset = Offset.zero;
    if (_textStyle.textAlign == TextAlign.center) {
      offset = new Offset(-_width / 2.0, 0.0);
    } else if (_textStyle.textAlign == TextAlign.right) {
      offset = new Offset(-_width, 0.0);
    }

    _painter.paint(canvas, offset);
  }
}
