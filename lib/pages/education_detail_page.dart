// import 'package:flutter/material.dart';
// import '../components/custom_vaccine_accordion.dart';

// class EducationDetailPage extends StatelessWidget {
//   final Map<String, dynamic> data;

//   const EducationDetailPage({super.key, required this.data});

//   @override
//   Widget build(BuildContext context) {
//     final List sections = data['sections'] ?? [];
//     final String? reference = data['Reference'];

//     return Scaffold(
//       appBar: AppBar(title: Text("Vaccines for " + data['title'] ?? 'Detail')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 30),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (data['cover'] != null)
//               Image.asset(
//                 'assets/images/${data['cover']}.png',
//                 width: double.infinity,
//                 height: 250,
//                 fit: BoxFit.cover,
//               ),
//             SizedBox(height: 16),
//             Text(data['description'] ?? '', style: TextStyle(fontSize: 16)),
//             SizedBox(height: 24),

//             ...sections
//                 .map((section) => CustomVaccineAccordion(section: section))
//                 .toList(),

//             SizedBox(height: 32),
//             if (reference != null && reference.isNotEmpty)
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Divider(),
//                   SizedBox(height: 10),
//                   Text(
//                     'Reference',
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                   Text(reference, style: TextStyle(color: Colors.black)),
//                 ],
//               ),
//             SizedBox(height: 30),
//           ],
//         ),
//       ),
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import '../components/custom_vaccine_accordion.dart';

// class EducationDetailPage extends StatelessWidget {
//   final Map<String, dynamic> data;

//   const EducationDetailPage({super.key, required this.data});

//   @override
//   Widget build(BuildContext context) {
//     final List sections = data['sections'] ?? [];
//     final String? reference = data['Reference'];

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 51, vertical: 40),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 🔙 Back button + title
//             Row(
//               children: [
//                 IconButton(
//                   icon: Icon(Icons.chevron_left_rounded, color: Color(0xFF33354C), size: 40),
//                   onPressed: () => Navigator.of(context).pop(),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     data['title'] ?? 'Details',
//                     style: const TextStyle(
//                       color: Color(0xFF33354C),
//                       fontSize: 24,
//                       fontFamily: 'Noto Sans Bengali',
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 20),

//             // 🖼 Cover image
//             Center(
//               child: Image.asset(
//                 'assets/images/${data['cover'] ?? 'placeholder'}.png',
//                 width: 290,
//                 height: 222,
//                 fit: BoxFit.fill,
//               ),
//             ),

//             const SizedBox(height: 20),

//             // 📝 Description
//             Text(
//               data['description'] ?? '',
//               style: const TextStyle(
//                 color: Colors.black,
//                 fontSize: 12,
//                 fontFamily: 'Noto Sans Bengali',
//                 fontWeight: FontWeight.w500,
//               ),
//             ),

//             const SizedBox(height: 24),

//             // 📦 Sections
//             ...sections.map((section) => CustomVaccineAccordion(section: section)).toList(),

//             const SizedBox(height: 20),

//             // 🔗 Reference (optional)
//             if (reference != null && reference.isNotEmpty)
//   Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       const Divider(),
//       const SizedBox(height: 8),
//       Text(
//         'Reference',
//         style: TextStyle(
//           color: Colors.black,
//           fontSize: 12,
//           fontFamily: 'Noto Sans Bengali',
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       const SizedBox(height: 4),
//       Text(
//         reference,
//         style: TextStyle(
//           color: Colors.black,
//           fontSize: 12,
//           fontFamily: 'Noto Sans Bengali',
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     ],
//   ),


//             const SizedBox(height: 40),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../components/custom_vaccine_accordion.dart';

class EducationDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const EducationDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final List sections = data['sections'] ?? [];
    final String? reference = data['Reference'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40), // ❌ เอา horizontal ออก
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔙 Back button + title with separate padding
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 24), // ✅ ปรับระยะใหม่ตรงนี้
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, color: Color(0xFF33354C), size: 40),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data['title'] ?? 'Details',
                      style: const TextStyle(
                        color: Color(0xFF33354C),
                        fontSize: 24,
                        fontFamily: 'Noto Sans Bengali',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🖼 Cover image
            Center(
              child: Image.asset(
                'assets/images/${data['cover'] ?? 'placeholder'}.png',
                width: 290,
                height: 222,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 20),

            // 📝 Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 51),
              child: Text(
                data['description'] ?? '',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontFamily: 'Noto Sans Bengali',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 📦 Sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 51),
              child: Column(
                children: sections.map((section) => CustomVaccineAccordion(section: section)).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // 🔗 Reference (optional)
            if (reference != null && reference.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 51),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Reference',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontFamily: 'Noto Sans Bengali',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reference,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontFamily: 'Noto Sans Bengali',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
