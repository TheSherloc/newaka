import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../l10n/app_localizations.dart';
import 'section_header.dart';

class AboutSection extends StatefulWidget {
  const AboutSection({super.key});
  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    } catch (_) {
      // Ohne Plattform-Kanal (z. B. in Tests) bleibt die Version leer.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.sectionAbout),
        ListTile(
          leading: const LeadingIcon(Icons.recycling_outlined),
          title: Text(l10n.appTitle, style: theme.textTheme.titleMedium),
          subtitle: Text(l10n.appTagline),
        ),
        ListTile(leading: const LeadingIcon(Icons.info_outline), title: Text(l10n.version(_version))),
        ListTile(
          leading: const LeadingIcon(Icons.article_outlined),
          title: Text(l10n.licenses),
          onTap: () => showLicensePage(context: context, applicationName: l10n.appTitle),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.privacyNote, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}
