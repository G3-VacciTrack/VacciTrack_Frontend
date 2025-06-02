// import 'package:flutter/material.dart';

// class CustomVaccineAccordion extends StatelessWidget {
//   final Map<String, dynamic> section;

//   const CustomVaccineAccordion({super.key, required this.section});

//   @override
//   Widget build(BuildContext context) {
//     final vaccines = section['vaccines'] ?? [];

//     return ExpansionTile(
//       title: Text(
//         section['title'] ?? '',
//         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//       ),
//       shape: Border.all(color: Colors.transparent),
//       tilePadding: EdgeInsets.zero,
//       collapsedIconColor: Colors.black,
//       expandedAlignment: Alignment.centerLeft,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: List.generate(vaccines.length, (vIndex) {
//               final vaccine = vaccines[vIndex];
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 12.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "• ${vaccine['name']}",
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     if (vaccine['doses'] != null)
//                       Text(
//                         vaccine['doses'],
//                       ),
//                     if (vaccine['importance'] != null)
//                       Text(
//                         "Why important: ${vaccine['importance']}",
//                         style: TextStyle(fontStyle: FontStyle.italic),
//                       ),
//                   ],
//                 ),
//               );
//             }),
//           ),
//         ),
//         SizedBox(height: 10),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';

class CustomVaccineAccordion extends StatefulWidget {
  final Map<String, dynamic> section;

  const CustomVaccineAccordion({super.key, required this.section});

  @override
  State<CustomVaccineAccordion> createState() => _CustomVaccineAccordionState();
}

class _CustomVaccineAccordionState extends State<CustomVaccineAccordion> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _sizeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggleExpansion() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.section['title'] ?? '';
    final List vaccines = widget.section['vaccines'] ?? [];

    return Column(
      children: [
        GestureDetector(
          onTap: toggleExpansion,
          child: Container(
            height: 40.9,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isExpanded ? const Color(0xFFE5F5F0) : Colors.white,
              border: Border.all(color: const Color(0xFFBBBBBB)),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(10),
                bottom: isExpanded ? Radius.zero : const Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF3A3A3A),
                    fontSize: 14,
                    fontFamily: 'Noto Sans Bengali',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _sizeAnimation,
          axisAlignment: 1.0,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFBBBBBB)),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3F80809C),
                  blurRadius: 11.3,
                  offset: Offset(2, 2),
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(vaccines.length, (vIndex) {
                final vaccine = vaccines[vIndex];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "• ${vaccine['name'] ?? 'Unnamed'}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF33354C),
                        ),
                      ),
                      if (vaccine['doses'] != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 10, top: 2),
                          child: Text(
                            vaccine['doses'],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      if (vaccine['importance'] != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 10, top: 2),
                          child: Text(
                            "Why important: ${vaccine['importance']}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
