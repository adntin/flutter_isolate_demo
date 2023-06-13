import 'dart:io';
import 'dart:isolate';

import 'package:flutter_isolate_demo/my_print.dart';

// https://www.jianshu.com/p/a9a54b101870
// https://github.com/dart-lang/samples/blob/main/isolates/bin/long_running_isolate.dart

// flutter: s1--main isolate 发送消息
// flutter: r1 收到消息: [1, 这条信息是 s1 在main isolate中 发送的]
// flutter: s1--new isolate 发送消息
// flutter: new isolate 模拟耗时开始
// flutter: r1 收到消息: [0, SendPort]
// flutter: 计算结果: 55
// flutter: new isolate 模拟耗时结束
// flutter: s1--new isolate 发送消息
// flutter: s2--new isolate 发送消息
// flutter: r1 收到消息: [1, 这条信息是 s1 在new isolate中 发送的]
// flutter: r2 收到消息: [1, 这条信息是 s2 在new isolate中 发送的]
// flutter: s2--main isolate 发送消息
// flutter: r2 收到消息: [1, 这条信息是 s2 在main isolate中 发送的]

isolatePort() async {
  ReceivePort r1 = ReceivePort();
  SendPort s1 = r1.sendPort;
  // 通过spawn新建一个isolate，并绑定静态方法
  Isolate? newIsolate = await Isolate.spawn(doWork, s1);
  SendPort? s2;
  r1.listen((message) {
    myPrint("r1 收到消息: $message"); // 2.4.7 r1 收到消息
    if (message[0] == 0) {
      s2 = message[1]; //得到r2的发送器s2
    } else {
      if (s2 != null) {
        myPrint("s2--main isolate 发送消息");
        s2!.send([1, "这条信息是 s2 在main isolate中 发送的"]); // 8.s2发送消息
      }
    }
  });
  myPrint("s1--main isolate 发送消息");
  s1.send([1, "这条信息是 s1 在main isolate中 发送的"]); // 1. s1发送消息

  // newIsolate.kill(priority: Isolate.immediate);
  // // 赋值为空 便于内存及时回收
  // newIsolate = null;
}

// 新的isolate中可以处理耗时任务
void doWork(SendPort s1) {
  ReceivePort r2 = ReceivePort();
  SendPort s2 = r2.sendPort;
  r2.listen((message) {
    //9.10 r2 收到消息
    myPrint("r2 收到消息: $message");
  });
  // 将新isolate中创建的SendPort发送到main isolate中用于通信
  myPrint("s1--new isolate 发送消息");
  s1.send([0, s2]); // 3. s1发送消息, 传递[0,r2的发送器]
  myPrint("new isolate 模拟耗时开始");
  sleep(const Duration(seconds: 10));
  myPrint("new isolate 模拟耗时结束");
  myPrint("s1--new isolate 发送消息");
  s1.send([1, "这条信息是 s1 在new isolate中 发送的"]); // 5. s1发送消息
  myPrint("s2--new isolate 发送消息");
  s2.send([1, "这条信息是 s2 在new isolate中 发送的"]); // 6. s2发送消息
}
