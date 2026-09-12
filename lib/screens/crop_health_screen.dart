import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/constants.dart';
import 'disease_screen.dart';
import 'disease_gallery_screen.dart';
import '../widgets/voice_wrapper.dart';
import '../providers/locale_provider.dart';
import '../utils/app_translations.dart';

class CropHealthScreen extends StatelessWidget {
  const CropHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final langCode = Provider.of<LocaleProvider>(context).locale.languageCode;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          title: Text(AppTranslations.get('telemetry_crop_health', langCode), style: const TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                icon: const Icon(Icons.document_scanner_rounded),
                text: l10n.diseaseDetection,
              ),
              Tab(
                icon: const Icon(Icons.menu_book_rounded),
                text: l10n.diseaseGuide,
              ),
            ],
          ),
        ),
        body: VoiceWrapper(
          screenTitle: l10n.diseaseDetection,
          textToRead: AppTranslations.get('voice_crop_health_intro', langCode),
          child: const TabBarView(
            children: [
              DiseaseScreen(isEmbedded: true),
              DiseaseGalleryScreen(isEmbedded: true),
            ],
          ),
        ),
      ),
    );
  }
}
