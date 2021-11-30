import 'package:flutter/material.dart';


class CustomButton extends StatefulWidget {
  CustomButton(this.visible, this.icon, this.iconSize, this.onClick, this.insideColor, {Key? key}) : super(key: key);

  bool visible;
  final IconData icon;
  final double iconSize;
  final Function onClick;
  final Color insideColor;
  @override
  _CustomButtonState createState() => _CustomButtonState();
}


class _CustomButtonState extends State<CustomButton> {

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: widget.visible,
        child: Ink(
        decoration: const ShapeDecoration(
            color: Colors.black54,
            shape: CircleBorder()
        ),
        child:Center(
            child:IconButton(
              onPressed: () => {
                widget.onClick.call()
              },
              icon: Icon(widget.icon,
                size: widget.iconSize,
                color: widget.insideColor,
              )
            )
        )
      )
    );
  }

  void changeVisibility()
  {
    setState(() {
      widget.visible = !widget.visible;
    });
  }
}
