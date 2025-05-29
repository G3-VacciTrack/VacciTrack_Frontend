import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontSize: 12);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: labelStyle,
      unselectedLabelStyle: labelStyle,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Appointment'),
        BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Education'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User Info'),
      ],
    );
  }
}
