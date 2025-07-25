import 'package:flutter/material.dart';
import 'package:stream_typewriter_text/src/animated_text_kit/animated_text.dart';
import 'package:stream_typewriter_text/src/animated_text_kit/typewriter.dart';

class StreamTypewriterAnimatedText extends StatefulWidget {
  final String text;
  final TextAlign textAlign;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;
  final Duration pause;
  final Duration speed;
  final Curve curve;
  final String cursor;
  final bool isRepeatingAnimation;
  final bool repeatForever;
  final int totalRepeatCount;
  final bool isHapticFeedbackEnabled;
  final int hapticInterval;
  final VoidCallback? onFinished;

  /// Whether tapping on the text should complete the animation immediately
  final bool tapToCompleteAnimation;

  /// Callback when the text is tapped (only called when tapToCompleteAnimation is true)
  final VoidCallback? onTap;

  const StreamTypewriterAnimatedText({
    super.key,
    required this.text,
    this.textAlign = TextAlign.start,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.speed = const Duration(milliseconds: 30),
    this.pause = const Duration(milliseconds: 1000),
    this.curve = Curves.linear,
    this.cursor = '_',
    this.isRepeatingAnimation = false,
    this.totalRepeatCount = 3,
    this.repeatForever = false,
    this.isHapticFeedbackEnabled = false,
    this.hapticInterval = 8,
    this.onFinished,
    this.tapToCompleteAnimation = false,
    this.onTap,
  });

  @override
  State<StreamTypewriterAnimatedText> createState() =>
      StreamTypewriterAnimatedTextState();
}

class StreamTypewriterAnimatedTextState
    extends State<StreamTypewriterAnimatedText> {
  Widget? _child;
  TypewriterAnimatedText? _typewriterAnimatedText;
  int _lengthAlreadyShown = 0;
  bool _didExceedMaxLines = false;
  bool _isCompleted = false; // Track if animation was completed by tap

  @override
  void didUpdateWidget(covariant StreamTypewriterAnimatedText oldWidget) {
    final typewriterAnimatedText = _typewriterAnimatedText;
    if (widget.text != oldWidget.text) {
      final startsWithOldText = widget.text.startsWith(oldWidget.text);
      if (_didExceedMaxLines && !startsWithOldText) {
        _didExceedMaxLines = false;
      }
      _lengthAlreadyShown = typewriterAnimatedText != null && startsWithOldText
          ? typewriterAnimatedText.visibleString.length
          : 0;
      // Reset completion state when text changes
      _isCompleted = false;
    }
    if (widget.style != oldWidget.style) {
      _didExceedMaxLines = false;
      _lengthAlreadyShown = 0;
      _isCompleted = false;
    }
    super.didUpdateWidget(oldWidget);
  }

  void _handleTap() {
    if (widget.tapToCompleteAnimation && !_isCompleted) {
      setState(() {
        _isCompleted = true;
      });
      widget.onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    // If animation was completed by tap, show complete text immediately
    if (_isCompleted && _typewriterAnimatedText != null) {
      final completeWidget = _typewriterAnimatedText!.completeText(context);
      return widget.tapToCompleteAnimation
          ? GestureDetector(
              onTap: _handleTap,
              child: completeWidget,
            )
          : completeWidget;
    }

    if (widget.maxLines != null) {
      if (_didExceedMaxLines && _child != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onFinished?.call();
          }
        });
        return _wrapWithTapHandler(_child!);
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          assert(constraints.hasBoundedWidth);
          final maxWidth = constraints.maxWidth;
          final textPainter = TextPainter(
            text: TextSpan(text: widget.text, style: widget.style),
            textAlign: widget.textAlign,
            textDirection: Directionality.of(context),
            maxLines: widget.maxLines,
            ellipsis: widget.overflow == TextOverflow.ellipsis ? '...' : null,
            locale: Localizations.maybeLocaleOf(context),
          );
          textPainter.layout(
            minWidth: constraints.minWidth,
            maxWidth: maxWidth,
          );
          _didExceedMaxLines = textPainter.didExceedMaxLines;
          if (_didExceedMaxLines) {
            final textSize = textPainter.size;
            final pos = textPainter.getPositionForOffset(
              textSize.bottomRight(Offset.zero),
            );
            _createNewWidget(widget.text.substring(0, pos.offset));
          } else {
            _createNewWidget(widget.text);
          }
          textPainter.dispose();
          return _wrapWithTapHandler(_child!);
        },
      );
    } else {
      _createNewWidget(widget.text);
      return _wrapWithTapHandler(_child!);
    }
  }

  Widget _wrapWithTapHandler(Widget child) {
    if (widget.tapToCompleteAnimation) {
      return GestureDetector(
        onTap: _handleTap,
        child: child,
      );
    }
    return child;
  }

  _createNewWidget(String text) {
    _typewriterAnimatedText = TypewriterAnimatedText(
      text,
      textAlign: widget.textAlign,
      textStyle: widget.style,
      lengthAlreadyShown: _lengthAlreadyShown,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      cursor: widget.cursor,
      curve: widget.curve,
      speed: widget.speed,
      isHapticFeedbackEnabled: widget.isHapticFeedbackEnabled,
      hapticInterval: widget.hapticInterval,
    );
    final valueKey = ValueKey(text.hashCode + widget.style.hashCode);
    if (_child != null && _child!.key == valueKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onFinished?.call();
        }
      });
    }
    _child = AnimatedTextKit(
      key: valueKey,
      pause: widget.pause,
      isRepeatingAnimation: widget.isRepeatingAnimation,
      animatedTexts: [_typewriterAnimatedText!],
      repeatForever: widget.repeatForever,
      totalRepeatCount: widget.totalRepeatCount,
      onFinished: widget.onFinished,
      // Don't use AnimatedTextKit's tap handling anymore, we handle it ourselves
      displayFullTextOnTap: false,
      onTap: null,
    );
  }
}
