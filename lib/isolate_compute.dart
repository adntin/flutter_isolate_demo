import 'package:flutter/foundation.dart';
import 'package:flutter_isolate_demo/my_print.dart';
import 'package:flutter_isolate_demo/my_sum.dart';

void isolateCompute() async {
  // https://dart.cn/guides/language/concurrency#implementing-a-simple-worker-isolate
  final result = await compute(mySum, 10);
  myPrint("isolateCompute 计算结果: $result");
}
