import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/voice_service.dart';
import '../widgets/voice_wrapper.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/constants.dart';
import '../utils/app_translations.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  List<Map<String, String>> messages = [];
  bool isLoading = false;
  bool isListening = false;
  String selectedLanguage = "English";
  String selectedExpertMode = "Universal Farm AI";

  final Map<String, List<Map<String, String>>> domainPrompts = {
    "Universal Farm AI": [
      {
        "icon": "🌾",
        "title": "Best Fertilizers",
        "prompt": "What are the best organic fertilizers for wheat and rice crops?"
      },
      {
        "icon": "🐛",
        "title": "Pest Control",
        "prompt": "How can I prevent pest attacks on tomato and cotton plants?"
      },
      {
        "icon": "🌧️",
        "title": "Rain Safety",
        "prompt": "What precautions should farmers take during heavy monsoon rains?"
      },
      {
        "icon": "💰",
        "title": "Yield & Profit",
        "prompt": "How can I improve crop yield and maximize market profit?"
      },
    ],
    "🐄 Veterinary AI": [
      {
        "icon": "🐄",
        "title": "Lumpy Skin Care",
        "prompt": "How to treat Lumpy Skin Disease nodules and fever in dairy cows?"
      },
      {
        "icon": "🥛",
        "title": "Increase Milk Yield",
        "prompt": "What balanced ration and mineral mixture will boost buffalo milk fat and SNF?"
      },
      {
        "icon": "🩺",
        "title": "Mastitis First Aid",
        "prompt": "What immediate first-aid should I give for swollen, hot udder in lactating cattle?"
      },
      {
        "icon": "💉",
        "title": "Vaccination Chart",
        "prompt": "What is the complete annual vaccination schedule for FMD, HS, and BQ in livestock?"
      },
    ],
    "🐔 Poultry Advisor": [
      {
        "icon": "⚖️",
        "title": "Improve FCR",
        "prompt": "How can I reduce broiler Feed Conversion Ratio (FCR) below 1.55?"
      },
      {
        "icon": "🥚",
        "title": "Peak Laying Rates",
        "prompt": "What nutrition and lighting protocol will maintain 90%+ egg laying rate in layers?"
      },
      {
        "icon": "🌡️",
        "title": "Brooding Temp",
        "prompt": "What are the optimal brooding temperatures and humidity for Day 1 to Day 14 chicks?"
      },
      {
        "icon": "🛡️",
        "title": "Newcastle & IBD",
        "prompt": "What is the recommended drinking water vaccination schedule for broiler flock?"
      },
    ],
    "🐟 Aquaculture Specialist": [
      {
        "icon": "💨",
        "title": "Low DO Warning",
        "prompt": "What immediate measures should I take if pond Dissolved Oxygen falls below 4.0 mg/L?"
      },
      {
        "icon": "🦐",
        "title": "Vannamei Feed Chart",
        "prompt": "How to calculate check-tray feeding for 15-gram Vannamei shrimp to avoid overfeeding?"
      },
      {
        "icon": "🧪",
        "title": "Ammonia Spike Control",
        "prompt": "How to detoxify toxic ammonia and nitrite in fish and biofloc ponds rapidly?"
      },
      {
        "icon": "🦠",
        "title": "Gill Rot Treatment",
        "prompt": "What are the symptoms and bath treatment for bacterial gill rot in Indian carps?"
      },
    ],
    "🌿 Organic & Hydroponics": [
      {
        "icon": "🌿",
        "title": "Jeevamrutha Prep",
        "prompt": "What is the step-by-step recipe and fermentation time for preparing Jeevamrutha?"
      },
      {
        "icon": "🍃",
        "title": "Neemastra Spray",
        "prompt": "How to prepare Neemastra bio-pesticide and what is the dosage per acre?"
      },
      {
        "icon": "💧",
        "title": "Hydroponic EC/pH",
        "prompt": "What are the target EC and pH ranges for NFT hydroponic lettuce and spinach?"
      },
      {
        "icon": "📜",
        "title": "Organic Certification",
        "prompt": "What audit documentation is required for PGS-India and NPOP organic certification?"
      },
    ],
  };

  List<String> get languages {
    return [
      "English",
      "Hindi",
      "Telugu",
      "Marathi",
      "Tamil",
      "Bengali",
      "Gujarati",
      "Kannada",
      "Malayalam",
      "Punjabi",
      "Odia"
    ];
  }

  String _getLanguageFromCode(String code) {
    switch (code) {
      case 'te': return "Telugu";
      case 'hi': return "Hindi";
      case 'mr': return "Marathi";
      case 'ta': return "Tamil";
      case 'bn': return "Bengali";
      case 'gu': return "Gujarati";
      case 'kn': return "Kannada";
      case 'ml': return "Malayalam";
      case 'pa': return "Punjabi";
      case 'or': return "Odia";
      default: return "English";
    }
  }

  String _getCodeFromLanguage(String lang) {
    switch (lang) {
      case 'Telugu': return "te";
      case 'Hindi': return "hi";
      case 'Marathi': return "mr";
      case 'Tamil': return "ta";
      case 'Bengali': return "bn";
      case 'Gujarati': return "gu";
      case 'Kannada': return "kn";
      case 'Malayalam': return "ml";
      case 'Punjabi': return "pa";
      case 'Odia': return "or";
      default: return "en";
    }
  }

  @override
  void initState() {
    super.initState();
    VoiceService.init();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    await VoiceService.speak(text, localeProvider.locale.languageCode);
  }

  Future<void> _listen() async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    
    if (isListening || VoiceService.state == VoiceState.listening) {
      setState(() => isListening = false);
      await VoiceService.stopListening();
      return;
    }

    await VoiceService.stop();
    if (!mounted) return;

    setState(() => isListening = true);
    
    final result = await VoiceService.listenForCommand(
      localeProvider.locale.languageCode,
      onPartialResult: (val) {
        if (mounted) setState(() => _controller.text = val);
      },
    );

    if (mounted) {
      setState(() => isListening = false);
      if (result.isNotEmpty) {
        _controller.text = result;
      }
    }
  }

  Future<void> sendMessage([String? customPrompt]) async {
    String question = customPrompt ?? _controller.text.trim();
    if (question.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": question});
      isLoading = true;
    });

    _controller.clear();
    scrollToBottom();

    try {
      final answer = await AIService.getAIResponse(
        question,
        language: selectedLanguage,
      );

      if (mounted) {
        setState(() {
          messages.add({"role": "ai", "text": answer});
        });
        _speak(answer);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          messages.add({
            "role": "ai",
            "text": "AI Error: ${e.toString().replaceAll("Exception:", "")}",
          });
        });
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
      scrollToBottom();
    }
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Widget buildMessage(Map<String, String> message, int index) {
    bool isUser = message["role"] == "user";

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppConstants.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.smart_toy_rounded, size: 18, color: Colors.white),
              ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isUser ? AppConstants.primaryColor : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 20 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: isUser
                          ? null
                          : Border.all(color: Colors.green.withValues(alpha: 0.15)),
                    ),
                    child: message["role"] == "ai"
                        ? MarkdownBody(
                            data: message["text"] ?? "",
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(fontSize: 15, height: 1.45, color: Colors.black87),
                              listBullet: const TextStyle(fontSize: 15, color: Colors.green),
                              h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                              h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                              strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          )
                        : Text(
                            message["text"] ?? "",
                            style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                  ),
                  if (!isUser) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded, size: 18, color: Colors.green),
                          onPressed: () => _speak(message["text"] ?? ""),
                          tooltip: 'Listen to response',
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: message["text"] ?? ""));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied to clipboard!'), duration: Duration(seconds: 2)),
                            );
                          },
                          tooltip: 'Copy text',
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (isUser)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade800,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, size: 18, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              child: Icon(Icons.psychology_rounded, size: 18, color: Colors.green),
            ),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.askFarmerAI),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButton<String>(
              value: _getLanguageFromCode(Provider.of<LocaleProvider>(context).locale.languageCode),
              icon: const Icon(Icons.language, color: Colors.white, size: 18),
              underline: const SizedBox.shrink(),
              dropdownColor: Colors.green.shade800,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  Provider.of<LocaleProvider>(context, listen: false)
                      .setLocale(Locale(_getCodeFromLanguage(newValue)));
                  setState(() {
                    selectedLanguage = newValue;
                  });
                }
              },
              items: languages.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.askFarmerAI,
        textToRead: AppTranslations.get(
          'voice_assistant_intro',
          Provider.of<LocaleProvider>(context).locale.languageCode,
        ),
        child: Column(
          children: [
            // Status Header Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.green.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AgriNova AI Engine • Active in $selectedLanguage',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                  ),
                  const Spacer(),
                  const Icon(Icons.bolt_rounded, size: 14, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    'Ultra-Fast',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                  ),
                ],
              ),
            ),

            Expanded(
              child: messages.isEmpty
                  ? _buildWelcomeHero()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) => buildMessage(messages[index], index),
                    ),
            ),

            if (isLoading) _buildAnimatedTyping(),

            _buildEnhancedInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHero() {
    final activePrompts = domainPrompts[selectedExpertMode] ??
        domainPrompts["Universal Farm AI"]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Animated Pulse Bot Icon
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppConstants.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.eco_rounded, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.namasteAI,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Select an AI Specialist or ask any question in your native language across all farming domains.',
              style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),

          // Specialist Mode Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: domainPrompts.keys.map((mode) {
                final isSelected = selectedExpertMode == mode;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(mode),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => selectedExpertMode = mode);
                    },
                    selectedColor: AppConstants.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade800,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                    checkmarkColor: Colors.white,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected
                            ? AppConstants.primaryColor
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Suggested Prompts Title
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: Colors.amber),
              const SizedBox(width: 6),
              Text(
                '$selectedExpertMode Suggestions',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick Prompt Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: activePrompts.length,
            itemBuilder: (context, index) {
              final prompt = activePrompts[index];
              return InkWell(
                onTap: () => sendMessage(prompt["prompt"]),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(prompt["icon"]!, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prompt["title"]!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              prompt["prompt"]!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTyping() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: const Icon(Icons.smart_toy_rounded, color: Colors.green, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'AgriNova AI is generating response...',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green.shade800),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Voice Listening Button
            GestureDetector(
              onTap: _listen,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isListening ? Colors.red : Colors.green.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      boxShadow: isListening
                          ? [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: isListening ? Colors.white : Colors.green.shade800,
                      size: 22,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.askIn(selectedLanguage),
                    hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: AppConstants.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: () => sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
