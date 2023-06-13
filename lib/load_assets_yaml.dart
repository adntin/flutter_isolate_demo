import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

void loadAssetsYaml() async {
  String path = 'assets/my_config.yaml';
  // String yamlString = await DefaultAssetBundle.of(context).loadString(path);
  String yamlString = await rootBundle.loadString(path);
  final dynamic yamlMap = loadYaml(yamlString);
  print(yamlMap['country']);
  print(yamlMap['animal']);
}
