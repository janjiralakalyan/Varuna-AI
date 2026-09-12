/// Multilingual localization system for Jala-Mitra (Water AI)
/// Supporting English, Telugu (తెలుగు), and Hindi (हिंदी).
/// Simplified for rural farmers — no technical jargon.
class JalaMitraI18n {
  static const Map<String, Map<String, String>> _strings = {
    'en': {
      // App header
      'screen_title': 'Water Helper AI',
      'screen_subtitle': 'Fair water sharing for farmers',

      // Simplified 4-tab navigation
      'my_water': 'My Water',
      'farmers': 'Farmers',
      'chat': 'Talk to AI',
      'schedule': 'Schedule',

      // Legacy tab keys (kept for compatibility)
      'tab_telemetry': 'Info',
      'tab_arena': 'Talk',
      'tab_timetable': 'Schedule',
      'tab_audit': 'Record',
      'overview': 'My Water',
      'conflicts': 'Problem',
      'negotiate': 'Talk to AI',
      'xai_why': 'Why?',
      'agreement': 'Record',

      // Canal & water info (simplified)
      'canal_gate': 'Canal Gate',
      'grid_on': 'Power: ON',
      'inflow_q': 'Water Flow',
      'release_window': 'Water Time',
      'total_volume': 'Total Water',
      'rain_risk': 'Rain Expected',
      'upstream_reservoir': 'Dam Water',
      'total_released': 'Water Released',
      'storage': 'Water Stored',

      // Weather (simplified)
      'rainfall_card_title': 'Weather & Rain Info',
      'rainfall_forecast_badge': 'Live Weather',
      'stations_monitored': 'Weather Stations',
      'mean_hourly': 'Rain per hour',
      'max_peak': 'Heavy Rain',
      'cumulative': 'Total Rain',

      // Farmer info (simplified)
      'competing_stakeholders': 'Farmers Sharing Water',
      'live_iot': 'Live Sensors',
      'soil_moisture': 'Soil Wetness',
      'cwsi_stress': 'Crop Water Need',
      'canal_distance': 'Distance',
      'demand': 'Need',

      // Mediation (simplified)
      'run_mediation': 'Ask AI for Help',
      'mediating': 'AI is deciding...',
      'conflict_alert_title': 'Not Enough Water for Everyone!',
      'consensus_schedule': 'Water Turn Schedule',
      'non_overlapping_slots': 'Your Water Turns',
      'audit_pass_title': 'Water Sharing Record',
      'digital_pass_desc': 'Official record approved by all farmers.',
      'sha256_hash': 'Record ID',
      'panchayat_authorized': 'Approved by Panchayat',
      'reset_tooltip': 'Start Over',
      'select_language': 'Language',
      'live_feed': 'Live Info',
      'switch_district': 'Change Area',

      // Sliders (simplified)
      'judge_controls': 'Change Settings',
      'canal_flow_slider': 'Water Hours:',
      'head_demand_slider': 'Near Farmer Need:',
      'mid_demand_slider': 'Middle Farmer Need:',
      'tail_demand_slider': 'Far Farmer Need:',

      // Empty states
      'no_schedule_yet': 'No Schedule Yet',
      'run_to_generate': 'Talk to AI to get your water schedule.',
      'no_audit_yet': 'No Record Yet',
      'launch_to_produce': 'Talk to AI to create water record.',

      // Actions
      'view_full_schedule': 'See Full Schedule',
      'view_audit_pass': 'See Water Record',
      'start_mediation': 'Start Talking',
      'proceed_to_mediation': 'Talk to AI',
      'view_proposed_schedule': 'See Schedule',
      'why_this_schedule': 'Why this?',
      'fairness_breakdown': 'Fair Sharing',
      'final_agreement': 'Water Agreement',
      'download_pdf': 'Save PDF',
      'view_full_report': 'See Full Report',
      'add_farmer_request': '+ Add Farmer',
      'conflicts_detected': 'Problem Found',
      'send_for_approval': 'Send for Approval',

      // Units & labels
      'seepage_loss': 'loss',
      'hours': 'Hours',
      'acres': 'Acres',
      'deliberation_round': 'Round',
      'agents_reason': 'AI is thinking...',
      'xai_rationale': 'Reason',
      'crypto_hash': 'Record ID',
      'agreement_id': 'Agreement No.',
      'allocated_window': 'Total Time Given',
      'gini_index': 'Fairness Score',
      'equitable': 'Very Fair',
      'consensus_metric': 'Agreement',
      'unanimous_approval': 'All Farmers Agreed!',
      'signatures_title': 'Farmer Approvals:',
      'offline_audit_badge': 'Saved Locally',
      'crop': 'Crop',
      'flow': 'Flow',
      'cusecs': 'Water Flow',
      'reasoning': 'Reason',
      'arena_empty_desc': 'AI watches your field and helps share water fairly.',

      // Chat / voice
      'type_response': 'Type or speak...',
      'ai_analyzing': 'AI is thinking...',
      'mediation_started': 'AI is checking your field and crop...',
      'voice_listening': 'Listening...',
      'you': 'You',
      'tap_to_speak': 'Tap mic to speak',
      'send': 'Send',

      // NEW: Voice/Speaker features
      'listen_aloud': 'Listen',
      'auto_read_on': 'Speaker ON',
      'auto_read_off': 'Speaker OFF',
      'turn_off_speaker': 'Turn Off Speaker',
      'turn_on_speaker': 'Turn On Speaker',
      'stop_speaker': 'Stop Voice',
      'speaking': 'Speaking...',
      'talk_to_ai': 'Talk to AI',
      'my_schedule': 'My Schedule',
      'other_farmers': 'Other Farmers',
      'water_available': 'Water Available',
      'your_need': 'Your Need',
      'not_enough': 'Not Enough Water',
      'ai_helper': 'AI Helper',
      'canal_group': 'Canal Water Group',
      'exit_group': 'Exit Group',
      'exit_group_title': 'Leave Canal Group?',
      'exit_group_prompt': 'Are you sure you want to leave this water sharing group? You will no longer share water or chat with this group.',
      'group_registered': 'Registered Canal Group',
      'group_between_you': 'Mediation between registered members only',
    },
    'te': {
      // App header
      'screen_title': 'నీటి సహాయక AI',
      'screen_subtitle': 'రైతులకు న్యాయమైన నీటి పంపకం',

      // Simplified 4-tab navigation
      'my_water': 'నా నీరు',
      'farmers': 'రైతులు',
      'chat': 'AI తో మాట్లాడు',
      'schedule': 'షెడ్యూల్',

      // Legacy tab keys
      'tab_telemetry': 'సమాచారం',
      'tab_arena': 'మాట్లాడు',
      'tab_timetable': 'షెడ్యూల్',
      'tab_audit': 'రికార్డు',
      'overview': 'నా నీరు',
      'conflicts': 'సమస్య',
      'negotiate': 'AI తో మాట్లాడు',
      'xai_why': 'ఎందుకు?',
      'agreement': 'రికార్డు',

      // Canal & water info
      'canal_gate': 'కాలువ గేటు',
      'grid_on': 'కరెంటు: ఉంది',
      'inflow_q': 'నీటి ప్రవాహం',
      'release_window': 'నీటి సమయం',
      'total_volume': 'మొత్తం నీరు',
      'rain_risk': 'వర్షం రావచ్చు',
      'upstream_reservoir': 'ఆనకట్ట నీరు',
      'total_released': 'విడుదల నీరు',
      'storage': 'నిల్వ నీరు',

      // Weather
      'rainfall_card_title': 'వాతావరణం & వర్షం',
      'rainfall_forecast_badge': 'లైవ్ వాతావరణం',
      'stations_monitored': 'వాతావరణ కేంద్రాలు',
      'mean_hourly': 'గంటకు వర్షం',
      'max_peak': 'ఎక్కువ వర్షం',
      'cumulative': 'మొత్తం వర్షం',

      // Farmer info
      'competing_stakeholders': 'నీరు పంచుకునే రైతులు',
      'live_iot': 'సెన్సార్లు',
      'soil_moisture': 'నేల తేమ',
      'cwsi_stress': 'పంటకు నీటి అవసరం',
      'canal_distance': 'దూరం',
      'demand': 'అవసరం',

      // Mediation
      'run_mediation': 'AI సహాయం అడగండి',
      'mediating': 'AI ఆలోచిస్తోంది...',
      'conflict_alert_title': 'అందరికీ సరిపోయేంత నీరు లేదు!',
      'consensus_schedule': 'నీటి వంతు షెడ్యూల్',
      'non_overlapping_slots': 'మీ నీటి వంతులు',
      'audit_pass_title': 'నీటి పంపకం రికార్డు',
      'digital_pass_desc': 'అందరు రైతులు ఆమోదించిన రికార్డు.',
      'sha256_hash': 'రికార్డు నంబర్',
      'panchayat_authorized': 'పంచాయతీ ఆమోదం',
      'reset_tooltip': 'మళ్ళీ మొదలు',
      'select_language': 'భాష',
      'live_feed': 'లైవ్ సమాచారం',
      'switch_district': 'ప్రాంతం మార్చు',

      // Sliders
      'judge_controls': 'సెట్టింగ్‌లు మార్చు',
      'canal_flow_slider': 'నీటి గంటలు:',
      'head_demand_slider': 'దగ్గర రైతు అవసరం:',
      'mid_demand_slider': 'మధ్య రైతు అవసరం:',
      'tail_demand_slider': 'దూరపు రైతు అవసరం:',

      // Empty states
      'no_schedule_yet': 'షెడ్యూల్ లేదు',
      'run_to_generate': 'నీటి షెడ్యూల్ కోసం AI తో మాట్లాడండి.',
      'no_audit_yet': 'రికార్డు లేదు',
      'launch_to_produce': 'రికార్డు కోసం AI తో మాట్లాడండి.',

      // Actions
      'view_full_schedule': 'పూర్తి షెడ్యూల్ చూడు',
      'view_audit_pass': 'రికార్డు చూడు',
      'start_mediation': 'మాట్లాడటం మొదలు',
      'proceed_to_mediation': 'AI తో మాట్లాడు',
      'view_proposed_schedule': 'షెడ్యూల్ చూడు',
      'why_this_schedule': 'ఎందుకు?',
      'fairness_breakdown': 'న్యాయమైన పంపకం',
      'final_agreement': 'నీటి ఒప్పందం',
      'download_pdf': 'PDF సేవ్',
      'view_full_report': 'పూర్తి రిపోర్ట్',
      'add_farmer_request': '+ రైతు జోడించు',
      'conflicts_detected': 'సమస్య కనుగొనబడింది',
      'send_for_approval': 'ఆమోదం కోసం పంపు',

      // Units & labels
      'seepage_loss': 'నష్టం',
      'hours': 'గంటలు',
      'acres': 'ఎకరాలు',
      'deliberation_round': 'రౌండ్',
      'agents_reason': 'AI ఆలోచిస్తోంది...',
      'xai_rationale': 'కారణం',
      'crypto_hash': 'రికార్డు నంబర్',
      'agreement_id': 'ఒప్పందం నం.',
      'allocated_window': 'ఇచ్చిన సమయం',
      'gini_index': 'న్యాయం స్కోర్',
      'equitable': 'చాలా న్యాయం',
      'consensus_metric': 'ఒప్పందం',
      'unanimous_approval': 'అందరు రైతులు ఒప్పుకున్నారు!',
      'signatures_title': 'రైతుల ఆమోదాలు:',
      'offline_audit_badge': 'స్థానికంగా సేవ్ అయింది',
      'crop': 'పంట',
      'flow': 'ప్రవాహం',
      'cusecs': 'నీటి ప్రవాహం',
      'reasoning': 'కారణం',
      'arena_empty_desc': 'AI మీ పొలాన్ని చూస్తుంది, నీరు సరిగ్గా పంచుతుంది.',

      // Chat / voice
      'type_response': 'టైప్ చేయండి లేదా చెప్పండి...',
      'ai_analyzing': 'AI ఆలోచిస్తోంది...',
      'mediation_started': 'AI మీ పొలం, పంట చూస్తోంది...',
      'voice_listening': 'వింటోంది...',
      'you': 'మీరు',
      'tap_to_speak': 'మాట్లాడండి',
      'send': 'పంపు',

      // Voice/Speaker features
      'listen_aloud': 'వినండి',
      'auto_read_on': 'స్పీకర్ ఆన్',
      'auto_read_off': 'స్పీకర్ ఆఫ్',
      'turn_off_speaker': 'స్పీకర్ ఆపివేయండి',
      'turn_on_speaker': 'స్పీకర్ ప్రారంభించండి',
      'stop_speaker': 'వాయిస్ ఆపండి',
      'speaking': 'చెప్తోంది...',
      'talk_to_ai': 'AI తో మాట్లాడు',
      'my_schedule': 'నా షెడ్యూల్',
      'other_farmers': 'ఇతర రైతులు',
      'water_available': 'నీరు ఉంది',
      'your_need': 'మీ అవసరం',
      'not_enough': 'నీరు సరిపోదు',
      'ai_helper': 'AI సహాయకుడు',
      'canal_group': 'కాలువ నీటి సమూహం',
      'exit_group': 'సమూహం నుండి నిష్క్రమించండి',
      'exit_group_title': 'కాలువ సమూహం నుండి నిష్క్రమించాలా?',
      'exit_group_prompt': 'మీరు ఖచ్చితంగా ఈ నీటి పంపకాల సమూహం నుండి నిష్క్రమించాలనుకుంటున్నారా? మీరు ఇకపై వీరితో నీటిని పంచుకోలేరు.',
      'group_registered': 'నమోదిత కాలువ సమూహం',
      'group_between_you': 'నమోదిత సభ్యుల మధ్య మాత్రమే మధ్యవర్తిత్వం',
    },
    'hi': {
      // App header
      'screen_title': 'पानी सहायक AI',
      'screen_subtitle': 'किसानों के लिए उचित पानी बँटवारा',

      // Simplified 4-tab navigation
      'my_water': 'मेरा पानी',
      'farmers': 'किसान',
      'chat': 'AI से बात करो',
      'schedule': 'समय सारिणी',

      // Legacy tab keys
      'tab_telemetry': 'जानकारी',
      'tab_arena': 'बात करो',
      'tab_timetable': 'समय सारिणी',
      'tab_audit': 'रिकॉर्ड',
      'overview': 'मेरा पानी',
      'conflicts': 'समस्या',
      'negotiate': 'AI से बात करो',
      'xai_why': 'क्यों?',
      'agreement': 'रिकॉर्ड',

      // Canal & water info
      'canal_gate': 'नहर गेट',
      'grid_on': 'बिजली: चालू',
      'inflow_q': 'पानी का बहाव',
      'release_window': 'पानी का समय',
      'total_volume': 'कुल पानी',
      'rain_risk': 'बारिश हो सकती है',
      'upstream_reservoir': 'बाँध का पानी',
      'total_released': 'छोड़ा गया पानी',
      'storage': 'जमा पानी',

      // Weather
      'rainfall_card_title': 'मौसम और बारिश',
      'rainfall_forecast_badge': 'लाइव मौसम',
      'stations_monitored': 'मौसम केंद्र',
      'mean_hourly': 'प्रति घंटा बारिश',
      'max_peak': 'तेज़ बारिश',
      'cumulative': 'कुल बारिश',

      // Farmer info
      'competing_stakeholders': 'पानी बाँटने वाले किसान',
      'live_iot': 'सेंसर',
      'soil_moisture': 'मिट्टी की नमी',
      'cwsi_stress': 'फसल को पानी की ज़रूरत',
      'canal_distance': 'दूरी',
      'demand': 'ज़रूरत',

      // Mediation
      'run_mediation': 'AI से मदद माँगो',
      'mediating': 'AI सोच रहा है...',
      'conflict_alert_title': 'सबके लिए पानी नहीं है!',
      'consensus_schedule': 'पानी की बारी',
      'non_overlapping_slots': 'आपकी पानी की बारी',
      'audit_pass_title': 'पानी बँटवारा रिकॉर्ड',
      'digital_pass_desc': 'सभी किसानों ने मंज़ूर किया रिकॉर्ड।',
      'sha256_hash': 'रिकॉर्ड नंबर',
      'panchayat_authorized': 'पंचायत ने मंज़ूर किया',
      'reset_tooltip': 'फिर से शुरू',
      'select_language': 'भाषा',
      'live_feed': 'लाइव जानकारी',
      'switch_district': 'क्षेत्र बदलें',

      // Sliders
      'judge_controls': 'सेटिंग बदलें',
      'canal_flow_slider': 'पानी के घंटे:',
      'head_demand_slider': 'पास के किसान की ज़रूरत:',
      'mid_demand_slider': 'बीच के किसान की ज़रूरत:',
      'tail_demand_slider': 'दूर के किसान की ज़रूरत:',

      // Empty states
      'no_schedule_yet': 'समय सारिणी नहीं बनी',
      'run_to_generate': 'पानी की बारी जानने के लिए AI से बात करो।',
      'no_audit_yet': 'रिकॉर्ड नहीं है',
      'launch_to_produce': 'रिकॉर्ड बनाने के लिए AI से बात करो।',

      // Actions
      'view_full_schedule': 'पूरी समय सारिणी देखें',
      'view_audit_pass': 'रिकॉर्ड देखें',
      'start_mediation': 'बात शुरू करो',
      'proceed_to_mediation': 'AI से बात करो',
      'view_proposed_schedule': 'समय सारिणी देखें',
      'why_this_schedule': 'क्यों?',
      'fairness_breakdown': 'उचित बँटवारा',
      'final_agreement': 'पानी का समझौता',
      'download_pdf': 'PDF सेव करो',
      'view_full_report': 'पूरी रिपोर्ट',
      'add_farmer_request': '+ किसान जोड़ो',
      'conflicts_detected': 'समस्या मिली',
      'send_for_approval': 'मंज़ूरी के लिए भेजो',

      // Units & labels
      'seepage_loss': 'नुकसान',
      'hours': 'घंटे',
      'acres': 'एकड़',
      'deliberation_round': 'राउंड',
      'agents_reason': 'AI सोच रहा है...',
      'xai_rationale': 'कारण',
      'crypto_hash': 'रिकॉर्ड नंबर',
      'agreement_id': 'समझौता नं.',
      'allocated_window': 'दिया गया समय',
      'gini_index': 'निष्पक्षता स्कोर',
      'equitable': 'बहुत उचित',
      'consensus_metric': 'सहमति',
      'unanimous_approval': 'सभी किसान राज़ी!',
      'signatures_title': 'किसानों की मंज़ूरी:',
      'offline_audit_badge': 'फ़ोन में सेव है',
      'crop': 'फसल',
      'flow': 'बहाव',
      'cusecs': 'पानी बहाव',
      'reasoning': 'कारण',
      'arena_empty_desc': 'AI आपके खेत को देखता है, पानी सही से बाँटता है।',

      // Chat / voice
      'type_response': 'टाइप करो या बोलो...',
      'ai_analyzing': 'AI सोच रहा है...',
      'mediation_started': 'AI आपका खेत और फसल देख रहा है...',
      'voice_listening': 'सुन रहा है...',
      'you': 'आप',
      'tap_to_speak': 'बोलो',
      'send': 'भेजो',

      // Voice/Speaker features
      'listen_aloud': 'सुनो',
      'auto_read_on': 'स्पीकर चालू',
      'auto_read_off': 'स्पीकर बंद',
      'turn_off_speaker': 'स्पीकर बंद करें',
      'turn_on_speaker': 'स्पीकर चालू करें',
      'stop_speaker': 'आवाज रोकें',
      'speaking': 'बोल रहा है...',
      'talk_to_ai': 'AI से बात करो',
      'my_schedule': 'मेरी बारी',
      'other_farmers': 'अन्य किसान',
      'water_available': 'पानी उपलब्ध',
      'your_need': 'आपकी ज़रूरत',
      'not_enough': 'पानी कम है',
      'ai_helper': 'AI सहायक',
      'canal_group': 'नहर जल समूह',
      'exit_group': 'समूह से बाहर निकलें',
      'exit_group_title': 'नहर समूह छोड़ें?',
      'exit_group_prompt': 'क्या आप वाकई इस पानी बँटवारा समूह को छोड़ना चाहते हैं? आप अब इस समूह के साथ पानी साझा या बातचीत नहीं कर पाएँगे।',
      'group_registered': 'पंजीकृत नहर समूह',
      'group_between_you': 'केवल पंजीकृत सदस्यों के बीच मध्यस्थता',
    },
  };

  static String t(String key, [String lang = 'en']) {
    final l = _strings.containsKey(lang) ? lang : 'en';
    return _strings[l]?[key] ?? _strings['en']?[key] ?? key;
  }
}
