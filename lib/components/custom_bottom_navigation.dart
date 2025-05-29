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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            offset: const Offset(0, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            backgroundColor: Colors.white,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF6CC2A8),
            unselectedItemColor: const Color(0xFF33354C),
            showSelectedLabels: false,
            showUnselectedLabels: false,
            iconSize: 28,
            items: const [
              BottomNavigationBarItem(
                icon: Center(child: Icon(Icons.home)),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Center(child: Icon(Icons.history)),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Center(child: Icon(Icons.calendar_today)),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Center(child: Icon(Icons.person)),
                label: '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
