import 'dart:isolate';

import 'package:flutter_isolate_demo/my_print.dart';
import 'package:flutter_isolate_demo/my_sum.dart';

void isolateRun() async {
  // https://api.dart.cn/dev/3.1.0-174.0.dev/dart-isolate/Isolate/run.html
  // https://github.com/dart-lang/samples/blob/main/isolates/bin/send_and_receive.dart
  final result2 = await Isolate.run(() => mySum(20));
  myPrint('isolateRun 计算结果: $result2');
}
