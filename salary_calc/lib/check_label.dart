import 'package:flutter/material.dart';

class CheckLabel extends StatelessWidget {
  final bool checked;
  final String label;

  CheckLabel(this.label, this.checked);

  @override
  Widget build(BuildContext context) {
    List<Widget> children = List<Widget>();

    final style = checked ? TextStyle(fontWeight: FontWeight.bold) : null;
    if (checked) {
      children.add(Padding(
        padding: EdgeInsets.only(right: 3.0),
        child: Icon(Icons.check, size: 20.0),
      ));
    }
    children.add(Text(label, style: style));

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: children);
  }
}
