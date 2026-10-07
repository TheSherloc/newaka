import 'package:abfallkalender/features/import/domain/file_source.dart';

class FakeFileSource implements FileSource {
  PickedFile? next;
  @override
  Future<PickedFile?> pick() async => next;
}
