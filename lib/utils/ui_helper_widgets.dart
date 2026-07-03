import 'package:flutter/material.dart';
import 'package:simpson/utils/sizes.dart';

///UI helper widgets for custom space

class P1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(Sizes.s1));
  }
}

class P2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(Sizes.s2));
  }
}

class P5 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(Sizes.s5));
  }
}

class P8 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(Sizes.s8));
  }
}

class P10 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(Sizes.s10));
  }
}

class PH10 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.symmetric(horizontal: Sizes.s10));
  }
}

class P20 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(Sizes.s20));
  }
}

class P30 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(Sizes.s30));
  }
}

class P40 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(Sizes.s40));
  }
}

class C0 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }
}

class CXX extends StatelessWidget {
  //final Color color;
  final double? height;
  final double? width;
  final Color? color;
  const CXX({this.height, this.width, this.color}); //: super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      color:color ?? Colors.transparent, 
    );
  }
}

class C1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: Sizes.s1,
      width: Sizes.s1,
    );
  }
}

class C2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: Sizes.s2,
      width: Sizes.s2,
    );
  }
}

class C5 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: Sizes.s5,
      width: Sizes.s5,
    );
  }
}

class C10 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: Sizes.s10,
      width: Sizes.s10,
    );
  }
}

class C15 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: Sizes.s15,
      width: Sizes.s15,
    );
  }
}

class C20 extends StatelessWidget {
  final Color? color;

  const C20({Key? key, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      height: Sizes.s20,
      width: Sizes.s20,
    );
  }
}

class C25 extends StatelessWidget {
  final Color? color;

  const C25({Key? key, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color ?? Colors.transparent,
      height: Sizes.s25,
      width: Sizes.s25,
    );
  }
}

class C30 extends StatelessWidget {
  final Color? color;

  const C30({Key? key, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color ?? Colors.transparent,
      height: Sizes.s30,
      width: Sizes.s30,
    );
  }
}

class C50 extends StatelessWidget {
  final Color? color;

  const C50({Key? key, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color ?? Colors.transparent,
      height: Sizes.s50,
      width: Sizes.s50,
    );
  }
}

class C100 extends StatelessWidget {
  final Color? color;

  const C100({Key? key, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color ?? Colors.transparent,
      height: Sizes.s100,
      width: Sizes.s100,
    );
  }
}

class C150 extends StatelessWidget {
  final Color? color;

  const C150({Key? key, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color ?? Colors.transparent,
      height: Sizes.s150,
      width: Sizes.s150,
    );
  }
}
