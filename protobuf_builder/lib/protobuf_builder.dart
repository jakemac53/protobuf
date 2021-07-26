import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:path/path.dart' as p;

Builder protobufBuilder(_) => ProtobufBuilder();

class ProtobufBuilder extends Builder {
  Map<String, List<String>> get buildExtensions => const {
        '^protos/{{}}.proto': ['lib/{{}}.pb.dart']
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    var tmpDir = await Directory.systemTemp.createTemp('protobuf_builder');
    // Adds a dependency on the input proto
    await buildStep.canRead(buildStep.inputId);
    // TODO: Add dependencies on imported protos?
    try {
      var result = await Process.run(
          'protoc', ['--dart_out=${tmpDir.path}', buildStep.inputId.path]);
      if (result.exitCode != 0) {
        throw StateError('''
Error generating protos file, output from proto compiler was as follows:

exitCode: ${result.exitCode}
stdErr: ${result.stderr}
stdOut: ${result.stdout}
''');
      }
      var outputFile = File(p.join(
          tmpDir.path, buildStep.inputId.changeExtension('.pb.dart').path));
      var outputPath = buildStep.inputId.path
          .replaceFirst('protos/', 'lib/')
          .replaceFirst('.proto', '.pb.dart');
      buildStep.writeAsBytes(AssetId(buildStep.inputId.package, outputPath),
          await outputFile.readAsBytes());
    } finally {
      tmpDir.delete(recursive: true);
    }
  }
}
