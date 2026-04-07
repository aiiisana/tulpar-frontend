import 'package:flutter/material.dart';
import '../../app/security_service.dart';
import '../../app/theme.dart';
import '../../app/app_storage.dart';
import '../setup/home_shell.dart';

class EnterPinScreen extends StatefulWidget {
  const EnterPinScreen({super.key});

  @override
  State<EnterPinScreen> createState() => _EnterPinScreenState();
}

class _EnterPinScreenState extends State<EnterPinScreen> {
  final _sec = SecurityService();

  String pin = '';
  String? error;

  bool bioSupported = false;
  bool bioEnabled = false;
  bool askedBioOnce = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final supported = await _sec.canBiometric();
    final enabled = await AppStorage.isBioEnabled();

    if (!mounted) return;
    setState(() {
      bioSupported = supported;
      bioEnabled = enabled;
    });

    if (supported && enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runBiometric());
    } else if (supported && !enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _askEnableBiometricOnce());
    }
  }

  Future<void> _askEnableBiometricOnce() async {
    if (askedBioOnce) return;
    askedBioOnce = true;

    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Включить вход по биометрии?'),
        content: const Text('Можно входить по отпечатку пальца или Face ID вместо PIN.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Нет')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Да')),
        ],
      ),
    );

    if (res == true) {
      await AppStorage.setBioEnabled(true);
      if (!mounted) return;
      setState(() => bioEnabled = true);
      await _runBiometric();
    }
  }

  void _tapDigit(String d) {
    if (pin.length >= 4) return;

    setState(() {
      error = null;
      pin += d;
    });

    if (pin.length == 4) {
      _checkPin();
    }
  }

  void _backspace() {
    if (pin.isEmpty) return;
    setState(() {
      error = null;
      pin = pin.substring(0, pin.length - 1);
    });
  }

  Future<void> _checkPin() async {
    final ok = await _sec.verifyPin(pin);
    if (!ok) {
      if (!mounted) return;
      setState(() {
        error = 'Неверный PIN-код';
        pin = '';
      });
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  Future<void> _runBiometric() async {
    if (!bioSupported) {
      setState(() => error = 'Биометрия недоступна на устройстве');
      return;
    }

    final ok = await _sec.authenticateBiometric();

    if (!ok) return;

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            children: [
              const SizedBox(height: 110),

              const Text(
                'Введите PIN-код',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),

              _PinDots(count: pin.length),

              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],

              const SizedBox(height: 26),

              if (bioSupported)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      if (!bioEnabled) {
                        await _askEnableBiometricOnce();
                        return;
                      }
                      await _runBiometric();
                    },
                    icon: const Icon(Icons.fingerprint, color: AppTheme.primary),
                    label: Text(
                      bioEnabled ? 'Войти по биометрии' : 'Включить биометрию',
                      style: const TextStyle(color: AppTheme.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

              const Spacer(),

              _RoundKeypad(
                onDigit: _tapDigit,
                onBackspace: _backspace,
              ),
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
          margin: const EdgeInsets.symmetric(horizontal: 10),
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

class _RoundKeypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  const _RoundKeypad({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    Widget roundBtn(String t, {VoidCallback? onTap}) {
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap ?? () => onDigit(t),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.border),
          ),
          alignment: Alignment.center,
          child: Text(
            t,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    const gapV = SizedBox(height: 14);

    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [roundBtn('1'), roundBtn('2'), roundBtn('3')]),
        gapV,
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [roundBtn('4'), roundBtn('5'), roundBtn('6')]),
        gapV,
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [roundBtn('7'), roundBtn('8'), roundBtn('9')]),
        gapV,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72, height: 72),
            roundBtn('0'),
            roundBtn('⌫', onTap: onBackspace),
          ],
        ),
      ],
    );
  }
}
