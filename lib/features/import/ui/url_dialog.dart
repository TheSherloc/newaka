import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

Future<String?> showUrlDialog(BuildContext context, {String? initial}) {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: initial ?? '');
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.urlDialogTitle),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(hintText: l10n.urlDialogHint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(l10n.ok),
        ),
      ],
    ),
  );
}
