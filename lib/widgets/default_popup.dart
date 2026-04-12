import 'package:flutter/material.dart';

class DefaultPopup extends StatelessWidget {
  final String message;
  final String buttonText;
  final VoidCallback? onClose;

  const DefaultPopup({
    super.key,
    this.message = 'Вы успешно записаны в разговорный клуб!',
    this.buttonText = 'Закрыть',
    this.onClose,
  });

  static Future<void> show(
      BuildContext context, {
        required String message,
        String buttonText = 'Закрыть',
      }) {
    return showDialog(
      context: context,
      builder: (BuildContext context) => DefaultPopup(
        message: message,
        buttonText: buttonText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Dialog(
        insetPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        elevation: 10,
        backgroundColor: const Color(0xFFE6E6E1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
            ),

            const Divider(height: 1, color: Colors.black12),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed: onClose ?? () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D523E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}