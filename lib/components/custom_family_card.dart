import 'package:flutter/material.dart';

class FamilyCard extends StatelessWidget {
  final Map<String, dynamic> familyMember;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;

  const FamilyCard({
    super.key,
    required this.familyMember,
    this.onTap,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final String firstName = familyMember['firstName'] ?? '';
    final String lastName = familyMember['lastName'] ?? '';
    final String name = '$firstName $lastName'.trim();
    final String age = familyMember['age']?.toString() ?? 'N/A';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF33354C).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Name',
                  style: TextStyle(color: Color(0xFF6F6F6F), fontSize: 12),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Age',
                            style: TextStyle(
                              color: Color(0xFF6F6F6F),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            age,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      if (onEditTap != null)
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Color(0xFF6F6F6F),
                          ),
                          onPressed: onEditTap,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
