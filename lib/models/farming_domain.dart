import 'package:flutter/material.dart';

enum FarmingDomainType {
  crops,
  horticulture,
  dairyLivestock,
  poultry,
  aquaculture,
  organicNatural,
  hydroponics,
  specialized,
}

class FarmingDomainInfo {
  final FarmingDomainType type;
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final List<String> keyFeatures;

  const FarmingDomainInfo({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.keyFeatures,
  });

  static List<FarmingDomainInfo> get allDomains => [
        const FarmingDomainInfo(
          type: FarmingDomainType.crops,
          id: 'crops',
          title: 'Crops & Grains',
          subtitle: 'Paddy, Wheat, Maize, Cotton & Cash Crops',
          icon: Icons.grass_rounded,
          primaryColor: Color(0xFF2E7D32),
          secondaryColor: Color(0xFF81C784),
          keyFeatures: [
            'Leaf Disease AI Doctor',
            'Crop Calendar & Sowing',
            'NPK Fertilizer Calculator',
            'Satellite GIS NDVI',
          ],
        ),
        const FarmingDomainInfo(
          type: FarmingDomainType.horticulture,
          id: 'horticulture',
          title: 'Horticulture & Orchards',
          subtitle: 'Fruits, Vegetables, Flowers & Plantations',
          icon: Icons.nature_rounded,
          primaryColor: Color(0xFFE65100),
          secondaryColor: Color(0xFFFFB74D),
          keyFeatures: [
            'Canopy & Pruning Cycles',
            'Polyhouse & Greenhouse Climate',
            'Flowering & Fruit-Set Booster',
            'Perishable Cold-Chain Linkage',
          ],
        ),
        const FarmingDomainInfo(
          type: FarmingDomainType.dairyLivestock,
          id: 'dairy_livestock',
          title: 'Dairy & Livestock',
          subtitle: 'Cattle, Buffalo, Goat, Sheep & Swine',
          icon: Icons.pets_rounded,
          primaryColor: Color(0xFF1565C0),
          secondaryColor: Color(0xFF64B5F6),
          keyFeatures: [
            'Herd & Cattle Tag Registry',
            'Daily Milk Yield & Fat/SNF Log',
            'Balanced Feed Ration Calculator',
            'Veterinary AI Health Doctor',
          ],
        ),
        const FarmingDomainInfo(
          type: FarmingDomainType.poultry,
          id: 'poultry',
          title: 'Poultry Farming',
          subtitle: 'Broilers, Layers & Country Chicken',
          icon: Icons.egg_rounded,
          primaryColor: Color(0xFFD84315),
          secondaryColor: Color(0xFFFF8A65),
          keyFeatures: [
            'Flock Batch & Mortality Tracker',
            'Feed Conversion Ratio (FCR)',
            'Daily Egg Laying Counter',
            'Brooding & Climate Guide',
          ],
        ),
        const FarmingDomainInfo(
          type: FarmingDomainType.aquaculture,
          id: 'aquaculture',
          title: 'Aquaculture & Fisheries',
          subtitle: 'Freshwater Fish, Shrimp, Prawns & Biofloc',
          icon: Icons.water_rounded,
          primaryColor: Color(0xFF00838F),
          secondaryColor: Color(0xFF4DD0E1),
          keyFeatures: [
            'Pond Water Quality Telemetry (DO/pH)',
            'Biomass Feeding Chart',
            'Shrimp & Fish Disease AI',
            'Aeration & Plankton Balancer',
          ],
        ),
        const FarmingDomainInfo(
          type: FarmingDomainType.organicNatural,
          id: 'organic_natural',
          title: 'Organic & Natural (ZBNF)',
          subtitle: 'Zero Budget, Permaculture & Bio-Inputs',
          icon: Icons.eco_rounded,
          primaryColor: Color(0xFF33691E),
          secondaryColor: Color(0xFFAED581),
          keyFeatures: [
            'Jeevamrutha & Neemastra Recipes',
            'Scalable Concoction Formulator',
            'Soil Microbiome Health',
            'Organic Audit & Certification Log',
          ],
        ),
        const FarmingDomainInfo(
          type: FarmingDomainType.hydroponics,
          id: 'hydroponics',
          title: 'Hydroponics & Smart CEA',
          subtitle: 'Vertical Farming, NFT, DWC & Polyhouse',
          icon: Icons.science_rounded,
          primaryColor: Color(0xFF6A1B9A),
          secondaryColor: Color(0xFFBA68C8),
          keyFeatures: [
            'Nutrient EC, TDS & pH Monitor',
            'Leafy Greens & Herb Recipes',
            'LED & Climate Schedule',
            'DWC & NFT Dosing Tracker',
          ],
        ),
        const FarmingDomainInfo(
          type: FarmingDomainType.specialized,
          id: 'specialized',
          title: 'Micro-Farming (Bees & Mushrooms)',
          subtitle: 'Apiculture, Sericulture & Mushrooms',
          icon: Icons.hive_rounded,
          primaryColor: Color(0xFFF57F17),
          secondaryColor: Color(0xFFFFD54F),
          keyFeatures: [
            'Beehive Inspection & Honey Harvest',
            'Mushroom Substrate & Humidity Log',
            'Silkworm Rearing Bed Schedules',
            'High-Value Niche Farm Guides',
          ],
        ),
      ];

  static FarmingDomainInfo getDomain(FarmingDomainType type) {
    return allDomains.firstWhere(
      (d) => d.type == type,
      orElse: () => allDomains.first,
    );
  }

  static FarmingDomainInfo getDomainById(String id) {
    return allDomains.firstWhere(
      (d) => d.id == id,
      orElse: () => allDomains.first,
    );
  }
}
