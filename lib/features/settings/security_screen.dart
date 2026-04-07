import 'package:flutter/material.dart';
import '../../app/app_strings.dart';
import '../../app/security_service.dart';
import '../../app/theme.dart';
import '../../app/ui_locale.dart';
import '../../widgets/circle_back_button.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStr.fromContext(UiLocaleScope.langOf(context));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleBackButton(),
                  Expanded(
                    child: Center(
                      child: Text(
                        s.privacySecurityOneLine,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(s.pinCode),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final ok = await _askOldPin(context);
                  if (ok != true) return;

                  if (!context.mounted) return;
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePinFlowScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _askOldPin(BuildContext context) async {
    final sec = SecurityService();
    final s = AppStr.fromContext(UiLocaleScope.langOf(context));
    final ctrl = TextEditingController();
    String? error;

    return showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(s.enterCurrentPin),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: InputDecoration(
              hintText: '••••',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.cancel)),
            ElevatedButton(
              onPressed: () async {
                final ok = await sec.verifyPin(ctrl.text);
                if (!ok) {
                  setState(() => error = s.wrongPin);
                  return;
                }
                if (!context.mounted) return;
                Navigator.pop(context, true);
              },
              child: Text(s.next),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePinFlowScreen extends StatefulWidget {
  const ChangePinFlowScreen({super.key});

  @override
  State<ChangePinFlowScreen> createState() => _ChangePinFlowScreenState();
}

class _ChangePinFlowScreenState extends State<ChangePinFlowScreen> {
  final sec = SecurityService();

  String first = '';
  String second = '';
  bool confirm = false;
  String? error;

  void tap(String d) {
    setState(() {
      error = null;
      if (!confirm) {
        if (first.length < 4) first += d;
        if (first.length == 4) confirm = true;
      } else {
        if (second.length < 4) second += d;
      }
    });
  }

  void back() {
    setState(() {
      error = null;
      if (!confirm) {
        if (first.isNotEmpty) first = first.substring(0, first.length - 1);
      } else {
        if (second.isNotEmpty) {
          second = second.substring(0, second.length - 1);
        } else {
          confirm = false;
        }
      }
    });
  }

  Future<void> save() async {
    if (first.length != 4 || second.length != 4) return;

    if (first != second) {
      if (!mounted) return;
      final s = AppStr.fromContext(UiLocaleScope.langOf(context));
      setState(() {
        error = s.pinMismatch;
        first = '';
        second = '';
        confirm = false;
      });
      return;
    }

    await sec.setPin(first);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStr.fromContext(UiLocaleScope.langOf(context));
    final title = confirm ? s.repeatNewPin : s.enterNewPin;
    final val = confirm ? second : first;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back)),
                  const Spacer(),
                ],
              ),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              _Dots(val.length),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
              const Spacer(),
              if (confirm)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: second.length == 4 ? save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    child: Text(s.saveButton),
                  ),
                ),
              const SizedBox(height: 12),
              _Keypad(onDigit: tap, onBackspace: back),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  const _Dots(this.count);

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
