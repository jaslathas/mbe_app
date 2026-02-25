import 'package:flutter/material.dart';

class CompanyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CompanyAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF2E2E2E), // Dark Grey
      elevation: 2,
      titleSpacing: 20,
      title: Row(
        children: [
          /// Company Logo
          Image.asset("assets/logo Background Removed.png", height: 35),
          const SizedBox(width: 12),

          /// Company Name + Page Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Malabar Bureau of Engineering",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(65);
}
