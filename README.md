# 🌾 Farmer AI — Intelligent Agricultural Assistant

> **Hackathon Project | PS14 — Autonomous Water-Sharing Dispute Mediation Agent for Farmers**

A comprehensive Flutter-based agricultural intelligence platform designed to empower Indian farmers with AI-driven tools for crop management, water allocation negotiation, market insights, and real-time field monitoring.

---

## 🏆 PS14: Autonomous Water-Sharing Dispute Mediation (Jala-Mitra AI)

This platform implements **PS14** — an end-to-end autonomous mediation system for water-sharing disputes among canal-irrigated farmers.

### Core Features (PS14)
| Feature | Description |
|---|---|
| 🤖 **Multi-Agent Negotiation** | Each farmer has an autonomous AI proxy (agent bot) that negotiates on their behalf |
| 📡 **Real-Time IoT Telemetry** | Monitors soil moisture %, CWSI, evapotranspiration, canal discharge (cusecs), reservoir head levels |
| ⚖️ **Constraint & Rule Engine** | Warabandi scheduling + Crop Water Stress Index (CWSI) priority weighting |
| 🗣️ **Autonomous Mediation** | Jala-Mitra AI detects conflicts, proposes fair schedules, handles objections & counter-proposals |
| 📊 **Conflict Detection** | Identifies demand-supply deficits, timeline overlaps, and tail-reach equity violations |
| 📝 **Decision Explanation** | Every allocation is justified with agronomic and hydraulic reasoning |
| ✅ **Agreement & Audit Record** | Tamper-evident digital water certificate with Aadhaar/Kisan Token signatures and audit hash |
| 🗓️ **Gantt Schedule View** | Visual water timetable showing who gets water, when, and from which sluice gate |

---

## 📱 Platform Features

### 🌿 Crop & Field Management
- **Crop Disease Detection** — AI-powered image analysis for 40+ crop diseases
- **Crop Recommendation** — Soil-based crop suitability engine
- **Yield & Profit Predictor** — ML-based harvest forecasting
- **Crop Calendar** — Seasonal planning and advisory

### 💧 Water & Soil Intelligence
- **Jala-Mitra Mediation Engine** — Autonomous water-sharing dispute resolution
- **Soil Moisture & Telemetry** — Real-time field sensor integration
- **Irrigation Scheduling** — Optimal watering time recommendations

### 🐄 Livestock & Specialty Farming
- **Dairy & Livestock Management** — Milk yield prediction, medical advisory, diet optimization
- **Poultry Management** — Flock health, feed, and profitability tracking
- **Aquaculture Module** — Fish/shrimp pond management and disease detection
- **Horticulture & Organic** — Specialized tools for fruits, vegetables, and organic farming

### 📈 Market & Commerce
- **Live Market Prices** — Real-time mandi prices from data.gov.in API
- **Proximity Sorting** — Nearest mandis ranked by GPS distance
- **Government Schemes** — Agricultural schemes browser and eligibility checker
- **Agri-Marketplace** — Input purchasing for seeds, fertilizers, and equipment

### 🤖 AI Assistant
- **Multilingual Chat** — Support for Telugu, Hindi, Marathi, Tamil, Bengali, Gujarati, Kannada, Malayalam, Punjabi, Odia
- **Groq-powered LLM** — Fast, context-aware agricultural Q&A
- **Offline-First Mode** — Local server fallback for rural connectivity

### 🌍 Community & Alerts
- **Community Forum** — Farmer peer knowledge sharing
- **Risk Alerts** — Weather, pest, and disease early warning system
- **Labour & Machinery Booking** — On-demand agricultural services

---

## 🏗️ Architecture

```
farmer_ai/
├── lib/
│   ├── models/
│   │   ├── water_mediation/
│   │   │   ├── telemetry_data.dart       # CanalTelemetry, FarmerAgentProfile, FieldTelemetry
│   │   │   └── negotiation_message.dart  # NegotiationMessage, WaterScheduleSlot, WaterSharingAgreement
│   │   └── ...
│   ├── services/
│   │   ├── realtime_water_mediation_engine.dart  # 🤖 Autonomous Jala-Mitra AI Engine
│   │   ├── ai_service.dart                        # Groq LLM integration
│   │   ├── api_service.dart                       # Market & backend APIs
│   │   ├── weather_service.dart                   # OpenWeatherMap integration
│   │   └── agro_monitoring_service.dart           # Satellite soil/NDVI monitoring
│   ├── screens/
│   │   ├── water_mediation_screen.dart            # 💧 PS14 Jala-Mitra UI
│   │   ├── home_screen.dart
│   │   ├── disease_screen.dart
│   │   ├── yield_profit_screen.dart
│   │   ├── dairy_livestock_screen.dart
│   │   ├── poultry_screen.dart
│   │   ├── aquaculture_screen.dart
│   │   └── ...
│   └── utils/
│       └── constants.dart  # API keys, base URLs, theme tokens
└── farmerai_backend/        # FastAPI Python backend
    └── main.py              # AI models, disease detection, LLM proxy
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.5.0`
- Python `>=3.10` (for backend)
- Android SDK / Chrome (for web demo)

### 1. Clone & Install Flutter Dependencies
```bash
git clone <repo-url>
cd farmer_ai
flutter pub get
```

### 2. Start the Backend (Local Server)
```bash
cd farmerai_backend
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```

### 3. Configure API Endpoint
In `lib/utils/constants.dart`:
```dart
// For Android device on same Wi-Fi:
static const String localUrl = 'http://11.11.1.108:8000';

// For Chrome web (localhost):
static const String localUrl = 'http://127.0.0.1:8000';

static String get baseUrl => localUrl;
```

### 4. Run the App
```bash
# Android
flutter run

# Chrome Web (recommended for demo)
flutter run -d chrome
```

---

## 🔑 API Keys Used

| Service | Purpose |
|---|---|
| [data.gov.in](https://data.gov.in) | Live mandi commodity prices |
| [OpenWeatherMap](https://openweathermap.org/api) | Weather forecasting |
| [Groq](https://groq.com) | LLM AI chat assistant |
| [AgroMonitoring](https://agromonitoring.com) | Satellite NDVI/soil data |
| [Ambee](https://www.getambee.com) | Environmental risk data |
| [Google Maps](https://developers.google.com/maps) | Farm location mapping |

---

## 🌐 Supported Languages

Telugu · Hindi · Marathi · Tamil · Bengali · Gujarati · Kannada · Malayalam · Punjabi · Odia · **English**

---

## 📋 PS14 Demo Scenario

The default demo loads **3 competing farmers** on a shared canal branch:

| Farmer | Crop | Reach | Stress Level | Requested Hours |
|---|---|---|---|---|
| Ramesh Reddy | Sugarcane | Head Reach | Moderate (CWSI: 0.32) | 14h |
| Sita Ramulu | Paddy (Rice) | Mid Reach | **CRITICAL** (CWSI: 0.86) | 15h |
| Venkat Rao | Red Chilli | Tail Reach | High (CWSI: 0.68) | 13h |

**Total Demand: 42h | Available: 24h | Deficit: 18h (75% overdraft)**

The Jala-Mitra AI autonomously detects the conflict and runs a 5-round negotiation to produce a fair, tamper-evident water schedule.

---

## 🛠️ Built With

- **Flutter 3.x** — Cross-platform UI
- **FastAPI + Python** — ML inference backend
- **Groq API** — LLM-powered AI assistant
- **Provider** — State management
- **SharedPreferences** — Offline persistence

---

*Built for Smart India Hackathon — Empowering 140M+ Indian farmers with AI.*
