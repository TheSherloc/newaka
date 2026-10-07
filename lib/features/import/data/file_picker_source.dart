import 'package:file_picker/file_picker.dart';

import '../domain/file_source.dart';

class FilePickerSource implements FileSource {
  @override
  Future<PickedFile?> pick() async {
    final file = await FilePicker.pickFile(type: FileType.any);
    if (file == null) return null;
    return PickedFile(name: file.name, bytes: await file.readAsBytes());
  }
}
