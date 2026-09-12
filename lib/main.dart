import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const HybridCalculatorApp());
}

class HistoryEntry {
  final String expression;
  final String result;

  HistoryEntry({required this.expression, required this.result});
}

class HybridCalculatorApp extends StatelessWidget {
  const HybridCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'iOS Calc Pro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String input = '';
  String previewResult = '';
  List<HistoryEntry> history = [];
  bool isScientificExpanded = false;
  bool isRad = true;
  bool isEvaluated = false;

  final Uri _ytUrl = Uri.parse('https://www.youtube.com/channel/UCKhGVoXX01SXBxVp90-hGdg');

  Future<void> _openYouTubeChannel() async {
    try {
      if (!await launchUrl(_ytUrl, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $_ytUrl');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  void handleTap(String val) {
    setState(() {
      if (val == 'AC') {
        input = '';
        previewResult = '';
        isEvaluated = false;
      } else if (val == '⌫') {
        if (isEvaluated) {
          input = '';
          previewResult = '';
          isEvaluated = false;
        } else if (input.isNotEmpty) {
          input = input.substring(0, input.length - 1);
          _updateLivePreview();
        }
      } else if (val == '=') {
        if (input.isNotEmpty && previewResult.isNotEmpty && previewResult != 'Error') {
          history.insert(0, HistoryEntry(expression: input, result: previewResult));
          input = previewResult;
          previewResult = '';
          isEvaluated = true;
        }
      } else if (val == '+/-') {
        if (input.startsWith('-')) {
          input = input.substring(1);
        } else if (input.isNotEmpty) {
          input = '-$input';
        }
        _updateLivePreview();
      } else if (val == 'Rad' || val == 'Deg') {
        isRad = !isRad;
        _updateLivePreview();
      } else if (val == '( )') {
        if (isEvaluated) {
          input = '';
          isEvaluated = false;
        }
        int openCount = '('.allMatches(input).length;
        int closeCount = ')'.allMatches(input).length;
        if (openCount > closeCount && input.isNotEmpty && !_isOperator(input[input.length - 1])) {
          input += ')';
        } else {
          input += '(';
        }
        _updateLivePreview();
      } else {
        if (isEvaluated) {
          if (_isOperator(val)) {
            isEvaluated = false;
          } else {
            input = '';
            isEvaluated = false;
          }
        }
        input += val;
        _updateLivePreview();
      }
    });
  }

  void _updateLivePreview() {
    if (input.isEmpty) {
      previewResult = '';
      return;
    }
    try {
      double evaluated = _evaluateExpression(input);
      if (!evaluated.isNaN && !evaluated.isInfinite) {
        String formatted = _formatNumber(evaluated);
        previewResult = (formatted == input) ? '' : formatted;
      } else {
        previewResult = '';
      }
    } catch (_) {
      previewResult = '';
    }
  }

  bool _isOperator(String char) {
    return ['+', '-', '×', '÷', '%', '^'].contains(char);
  }

  double _evaluateExpression(String expr) {
    String clean = expr
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('π', '${math.pi}')
        .replaceAll('e', '${math.e}');

    clean = clean.replaceAllMapped(RegExp(r'(\d+)!'), (match) {
      int num = int.parse(match.group(1)!);
      return _factorial(num).toString();
    });

    clean = clean.replaceAllMapped(RegExp(r'√(\d+(\.\d+)?)'), (match) {
      double num = double.parse(match.group(1)!);
      return math.sqrt(num).toString();
    });

    clean = _replaceFunc(clean, 'sin', (x) => math.sin(isRad ? x : x * math.pi / 180));
    clean = _replaceFunc(clean, 'cos', (x) => math.cos(isRad ? x : x * math.pi / 180));
    clean = _replaceFunc(clean, 'tan', (x) => math.tan(isRad ? x : x * math.pi / 180));
    clean = _replaceFunc(clean, 'ln', (x) => math.log(x));
    clean = _replaceFunc(clean, 'log', (x) => math.log(x) / math.ln10);

    return _basicEval(clean);
  }

  String _replaceFunc(String expr, String fn, double Function(double) calc) {
    RegExp exp = RegExp('$fn\\((\\d+(\\.\\d+)?)\\)');
    while (exp.hasMatch(expr)) {
      expr = expr.replaceAllMapped(exp, (match) {
        double val = double.parse(match.group(1)!);
        return calc(val).toString();
      });
    }
    return expr;
  }

  int _factorial(int n) {
    if (n <= 1) return 1;
    return n * _factorial(n - 1);
  }

  double _basicEval(String expr) {
    try {
      if (expr.contains('+')) {
        var parts = expr.split('+');
        return _basicEval(parts[0]) + _basicEval(parts.sublist(1).join('+'));
      }
      if (expr.contains('-') && !expr.startsWith('-')) {
        var parts = expr.split('-');
        return _basicEval(parts[0]) - _basicEval(parts.sublist(1).join('-'));
      }
      if (expr.contains('*')) {
        var parts = expr.split('*');
        return _basicEval(parts[0]) * _basicEval(parts.sublist(1).join('*'));
      }
      if (expr.contains('/')) {
        var parts = expr.split('/');
        return _basicEval(parts[0]) / _basicEval(parts.sublist(1).join('/'));
      }
      if (expr.contains('^')) {
        var parts = expr.split('^');
        return math.pow(_basicEval(parts[0]), _basicEval(parts[1])).toDouble();
      }
      if (expr.contains('%')) {
        var parts = expr.split('%');
        return _basicEval(parts[0]) % _basicEval(parts[1]);
      }
      return double.parse(expr.replaceAll('(', '').replaceAll(')', ''));
    } catch (e) {
      return 0;
    }
  }

  String _formatNumber(double num) {
    if (num % 1 == 0) {
      return num.toInt().toString();
    }
    return num.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.white70, size: 28),
                    onPressed: _showHistorySheet,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white70, size: 28),
                    color: const Color(0xFF1C1C1E),
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (value) {
                      if (value == 'clear') {
                        setState(() => history.clear());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('History cleared! 🗑️'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      } else if (value == 'youtube') {
                        _openYouTubeChannel();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'clear',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Clear history', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 10),
                      const PopupMenuItem(
                        enabled: false,
                        child: Center(
                          child: Text(
                            'Made by Raihan ⚡',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'youtube',
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF0000).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFF0000), width: 1.2),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_circle_fill, color: Color(0xFFFF0000), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Support on YT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.launch, color: Colors.white70, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Display Screen
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        input.isEmpty ? '0' : input,
                        style: TextStyle(
                          fontSize: isEvaluated ? 68 : 52,
                          fontWeight: isEvaluated ? FontWeight.bold : FontWeight.w400,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: previewResult.isNotEmpty ? 1.0 : 0.0,
                      child: Text(
                        previewResult,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF34C759),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scientific Arrow Toggle Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isScientificExpanded = !isScientificExpanded;
                      });
                    },
                    child: AnimatedRotation(
                      turns: isScientificExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white10,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white70,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Animated Scientific Panel
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              height: isScientificExpanded ? 190 : 0,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: ClipRect(
                child: OverflowBox(
                  maxHeight: 190,
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      Expanded(child: _buildRow(['√', 'π', '^', '!'], isScientific: true)),
                      const SizedBox(height: 8),
                      Expanded(child: _buildRow([isRad ? 'Rad' : 'Deg', 'sin(', 'cos(', 'tan('], isScientific: true)),
                      const SizedBox(height: 8),
                      Expanded(child: _buildRow(['Inv', 'e', 'ln(', 'log('], isScientific: true)),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),

            // Standard Keypad Grid
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Expanded(
                      child: _buildRow(['AC', '( )', '%', '÷'],
                          types: [ButtonType.top, ButtonType.top, ButtonType.top, ButtonType.operator]),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _buildRow(['7', '8', '9', '×'],
                          types: [ButtonType.num, ButtonType.num, ButtonType.num, ButtonType.operator]),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _buildRow(['4', '5', '6', '-'],
                          types: [ButtonType.num, ButtonType.num, ButtonType.num, ButtonType.operator]),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _buildRow(['1', '2', '3', '+'],
                          types: [ButtonType.num, ButtonType.num, ButtonType.num, ButtonType.operator]),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _buildRow(['0', '.', '⌫', '='],
                          types: [ButtonType.num, ButtonType.num, ButtonType.num, ButtonType.equals]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> labels, {List<ButtonType>? types, bool isScientific = false}) {
    return Row(
      children: List.generate(labels.length, (i) {
        ButtonType type = isScientific
            ? ButtonType.scientific
            : (types != null ? types[i] : ButtonType.num);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: LiquidGlassButton(
              label: labels[i],
              type: type,
              onTap: () => handleTap(labels[i]),
            ),
          ),
        );
      }),
    );
  }

  // Tidy History Sheet
  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'History 📜',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, thickness: 1),
              const SizedBox(height: 8),
              Expanded(
                child: history.isEmpty
                    ? const Center(
                        child: Text(
                          'No history recorded yet.',
                          style: TextStyle(color: Colors.white38, fontSize: 16),
                        ),
                      )
                    : ListView.separated(
                        itemCount: history.length,
                        separatorBuilder: (context, index) => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(color: Colors.white12, thickness: 1),
                        ),
                        itemBuilder: (context, i) {
                          final entry = history[i];
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Typed Expression (Small & Gray)
                                Text(
                                  entry.expression,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Answer (Bigger & Bold Green)
                                Text(
                                  '= ${entry.result}',
                                  style: const TextStyle(
                                    color: Color(0xFF34C759),
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum ButtonType { num, top, operator, equals, scientific }

class LiquidGlassButton extends StatefulWidget {
  final String label;
  final ButtonType type;
  final VoidCallback onTap;

  const LiquidGlassButton({
    super.key,
    required this.label,
    required this.type,
    required this.onTap,
  });

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton> {
  bool _isPressed = false;

  Color get _baseColor {
    switch (widget.type) {
      case ButtonType.top:
        return const Color(0xFF005DFF);
      case ButtonType.operator:
        return const Color(0xFFFF9F0A);
      case ButtonType.equals:
        return const Color(0xFF34C759);
      case ButtonType.scientific:
        return const Color(0xFF1F2937);
      case ButtonType.num:
        return const Color(0xFF2C2C2E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _baseColor.withValues(alpha: _isPressed ? 0.6 : 0.95),
                _baseColor,
                _baseColor.withValues(alpha: 0.8),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: _isPressed ? 0.4 : 0.18),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _baseColor.withValues(alpha: _isPressed ? 0.2 : 0.45),
                blurRadius: _isPressed ? 4 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.type == ButtonType.scientific ? 17 : 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}