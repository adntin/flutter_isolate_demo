// https://github.com/dart-lang/samples/blob/main/isolates/bin/long_running_isolate.dart
// Spawn an isolate, read multiple files, send their contents to the spawned isolate, and wait for the parsed JSON.
// 生成一个隔离，读取多个文件，将其内容发送到生成的隔离，并等待解析的JSON。

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:flutter_isolate_demo/my_print.dart';

const filenames = [
  'assets/json_01.json',
  'assets/json_02.json',
  'assets/json_03.json',
];

void isolateFiles() async {
  myPrint('[fileIsolate] start.');
  await for (final jsonData in _sendAndReceive(filenames)) {
    myPrint('[fileIsolate] Received JSON with ${jsonData.length} keys');
  }
  myPrint('[fileIsolate] end.');
}

// Spawns an isolate and asynchronously sends a list of filenames for it to
// read and decode. Waits for the response containing the decoded JSON
// before sending the next.
// Returns a stream that emits the JSON-decoded contents of each file.
// 生成一个隔离并异步发送一个文件名列表供其读取和解码。在发送下一个之前等待包含解码JSON的响应。
// 返回一个流，该流发出每个文件的json解码内容。
Stream<Map<String, dynamic>> _sendAndReceive(List<String> filenames) async* {
  final p = ReceivePort(); // 主隔离的 ReceivePort
  myPrint('主隔离 create 新隔离, 开始.');
  await Isolate.spawn(_readAndParseJsonService, p.sendPort);
  myPrint('主隔离 create 新隔离, 完成.');
  // Convert the ReceivePort into a StreamQueue to receive messages from the
  // spawned isolate using a pull-based interface. Events are stored in this
  // queue until they are accessed by `events.next`.
  // 将ReceivePort转换为StreamQueue，以使用"pull-based"接口接收来自派生隔离的消息。事件被存储在这个队列中，直到它们被`events.next`访问。
  final events = StreamQueue<dynamic>(p); // StreamQueue 来自 async 插件
  // The first message from the spawned isolate is a SendPort. This port is
  // used to communicate with the spawned isolate.
  myPrint('主隔离 listen 新隔离, 等待第一个消息.');
  SendPort sendPort = await events.next; // sendPort: 新隔离的 ReceivePort#sendPort
  myPrint('主隔离 <-- 新隔离, 收到第一个消息 SendPort.');
  for (var filename in filenames) {
    // Send the next filename to be read and parsed
    myPrint('主隔离 --> 新隔离, 发送文件路径. $filename');
    sendPort.send(filename);
    // Receive the parsed JSON
    myPrint('主隔离 listen 新隔离, 等待 Map JSON.');
    Map<String, dynamic> message = await events.next;
    myPrint('主隔离 <-- 新隔离, 收到 Map JSON. $message');
    // Add the result to the stream returned by this async* function.
    // 将结果添加到这个async*函数返回的流中。
    yield message;
  }
  // Send a signal to the spawned isolate indicating that it should exit.
  myPrint('主隔离 --> 新隔离, 发送退出信号. null');
  sendPort.send(null);
  // Dispose the StreamQueue.
  myPrint('释放 StreamQueue.');
  await events.cancel();
}

// The entrypoint that runs on the spawned isolate. Receives messages from
// the main isolate, reads the contents of the file, decodes the JSON, and
// sends the result back to the main isolate.
// 在生成的隔离上运行此入口函数。接收来自主隔离的消息，读取文件的内容，解码JSON，并将结果发送回主隔离。
// 参数 SendPort 是主隔离的 ReceivePort#sendPort
Future<void> _readAndParseJsonService(SendPort p) async {
  myPrint('Spawned isolate started.');
  // Send a SendPort to the main isolate so that it can send JSON strings to
  // this isolate.
  // 向主隔离发送一个SendPort，这样它就可以向这个隔离发送JSON字符串。
  final commandPort = ReceivePort(); // 衍生隔离的 ReceivePort
  myPrint('新隔离 --> 主隔离, 发送第一个消息 SendPort.');
  p.send(commandPort.sendPort);
  // Wait for messages from the main isolate.
  myPrint('新隔离 listen 主隔离, 等待文件路径.');
  await for (final message in commandPort) {
    if (message is String) {
      myPrint('新隔离 <-- 主隔离, 收到文件路径: $message');
      myPrint("模拟耗时5秒开始.");
      sleep(const Duration(seconds: 5));
      myPrint("模拟耗时5秒结束.");
      // Read and decode the file.
      // 读取并解码文件。
      // final contents = await File(message).readAsString();
      // String yamlString = await DefaultAssetBundle.of(context).loadString(path);
      // final contents = await rootBundle.loadString(message);
      // Send the result to the main isolate.
      // 将结果发送到主隔离。
      String contents = '{"a": 1}';
      Map<String, dynamic> mapJson = jsonDecode(contents);
      myPrint('新隔离 --> 主隔离, 发送 Map JSON. $mapJson');
      p.send(mapJson);
    } else if (message == null) {
      // Exit if the main isolate sends a null message, indicating there are no
      // more files to read and parse.
      myPrint("新隔离 <-- 主隔离, 收到退出信号. null");
      break;
    }
  }
  myPrint('Spawned isolate finished.');
  Isolate.exit();
}
