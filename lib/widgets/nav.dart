import 'package:flutter/material.dart';
import 'package:paynote/history.dart';

class Nav extends StatelessWidget {
  final Function(int) onTap;
  final int selectedIndex;

  const Nav({super.key, required this.onTap, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            // First IconButton (Analytics)
            IconButton(
              icon: Icon(
                Icons.analytics_outlined,
                color: selectedIndex == 0 ? Colors.blue : Colors.grey,
              ),
              onPressed: () => onTap(0),
            ),
            const SizedBox(width: 30), // Space for FAB
            // Second IconButton (History)
            IconButton(
              icon: Icon(
                Icons.history,
                color: selectedIndex == 1 ? Colors.blue : Colors.grey,
              ),
              onPressed: (){
                MaterialPageRoute route = MaterialPageRoute(
                  builder: (context) => const History(),
                );
                Navigator.pushReplacement(context, route);
              },
            ),
          ],
        ),
      ),
    );
  }
}
