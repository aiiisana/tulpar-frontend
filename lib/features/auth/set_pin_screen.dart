import 'package:flutter/material.dart';
import 'package:tulpar_front/features/setup/choose_level_screen.dart';
import '../../app/security_service.dart';
import '../../app/theme.dart';
import '../../widgets/primary_button.dart';
import '../setup/daily_goal_screen.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final _sec = SecurityService();

  String first = '';
  String second = '';
  bool confirmStep = false;
  String? error;

  void _tapDigit(String d) {
    setState(() {
      error = null;
      if (!confirmStep) {
        if (first.length < 4) first += d;
        if (first.length == 4) confirmStep = true;
      } else {
        if (second.length < 4) second += d;
      }
    });
  }

  void _backspace() {
    setState(() {
      error = null;
      if (!confirmStep) {
        if (first.isNotEmpty) first = first.substring(0, first.length - 1);
      } else {
        if (second.isNotEmpty) {
          second = second.substring(0, second.length - 1);
        } else {
          confirmStep = false;
        }
      }
    });
  }

  Future<void> _save() async {
    if (first.length != 4 || second.length != 4) return;

    if (first != second) {
      setState(() {
        error = 'PIN-коды не совпадают';
        first = '';
        second = '';
        confirmStep = false;
      });
      return;
    }

    await _sec.setPin(first);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ChooseLevelScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = confirmStep ? 'Повторите PIN-код' : 'Создайте PIN-код';
    final value = confirmStep ? second : first;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('4 цифры', style: TextStyle(color: AppTheme.textSecondary)),

              const SizedBox(height: 22),
              _PinDots(count: value.length),

              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],

              const Spacer(),

              if (confirmStep)
                PrimaryButton(
                  text: 'Сохранить',
                  onPressed: (second.length == 4) ? _save : null,
                ),

              const SizedBox(height: 12),
              _Keypad(onDigit: _tapDigit, onBackspace: _backspace),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  final int count;
  const _PinDots({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final filled = i < count;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppTheme.primary : AppTheme.border,
          ),
        );
      }),
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  const _Keypad({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    Widget btn(String t, {VoidCallback? onTap}) {
      return InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onTap ?? () => onDigit(t),
        child: Container(
          width: 70,
          height: 56,
          alignment: Alignment.center,
          child: Text(t, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        ),
      );
    }

    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [btn('1'), btn('2'), btn('3')]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [btn('4'), btn('5'), btn('6')]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [btn('7'), btn('8'), btn('9')]),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 70, height: 56),
            btn('0'),
            btn('⌫', onTap: onBackspace),
          ],
        ),
      ],
    );
  }
}
