import 'package:flutter/material.dart';
import '../theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  String _getSaudacao() {
    final hora = DateTime.now().hour;
    if (hora < 12) {
      return 'Bom dia';
    } else if (hora < 18) {
      return 'Boa tarde';
    } else {
      return 'Boa noite';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              'assets/images/remedi.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _getSaudacao(),
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
