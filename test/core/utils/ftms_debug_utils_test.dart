import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/utils/ftms_debug_utils.dart';
import 'package:ftms/core/models/ftms_parameter.dart';

class DummyParam {
  final dynamic flag;
  final dynamic size;
  final dynamic unit;
  final dynamic factor;
  final DummyName name;
  final dynamic value;
  DummyParam({this.flag, this.size, this.unit, this.factor, required this.name, this.value});
}

class DummyName {
  final String name;
  DummyName(this.name);
}

void main() {
  test('logFtmsParameterAttributes does not throw', () {
    final params = [
      DummyParam(flag: 1, size: 2, unit: 'm', factor: 3, name: DummyName('test'), value: 42),
      DummyParam(flag: null, size: null, unit: null, factor: null, name: DummyName('test2'), value: 99),
    ];
    expect(() => logFtmsParameterAttributes(params), returnsNormally);
  });

  test('logFtmsParameters does not throw', () {
    final params = <String, FtmsParameter>{
      'speed': FtmsParameter(
        name: 'speed',
        value: 25,
        factor: 1,
        unit: 'km/h',
        scaleFactor: 1,
        flag: null,
        size: 2,
        signed: false,
      ),
      'power': FtmsParameter(
        name: 'power',
        value: 250,
        factor: 1,
        unit: 'W',
        scaleFactor: 1,
        flag: null,
        size: 2,
        signed: false,
      ),
    };
    expect(() => logFtmsParameters(params), returnsNormally);
  });
}
