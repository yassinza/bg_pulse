import 'package:flutter/cupertino.dart';

import '../models/glucose_reading.dart';

class GlucoseWidget extends StatelessWidget {
  final GlucoseReading? reading;

  const GlucoseWidget({Key? key, this.reading}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (reading == null) {
      return Center(child: Text('No reading available'));
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${reading!.value} mg/dL ${reading!.emoji}',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          reading!.trendArrow,
          style: TextStyle(fontSize: 40),
        ),
        Text(
          '${reading!.timestamp.toLocal()}',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
