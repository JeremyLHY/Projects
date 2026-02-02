import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFf0f1fc),
      child: Center(
        child: SpinKitDoubleBounce(
          color: Colors.black,
          size: 50.0,
        ),
      ),
    );
  }
}