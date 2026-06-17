import 'package:flutter/material.dart';

class HowToRecyclePage extends StatefulWidget {
  const HowToRecyclePage({super.key});

  @override
  State<HowToRecyclePage> createState() => _HowToRecyclePageState();
}

class _HowToRecyclePageState extends State<HowToRecyclePage> {
  String search = "";

  final List<Map<String, dynamic>> categories = [
    {
      "title": "Plastic",
      "icon": Icons.local_drink_outlined,
      "color": Colors.blue,
      "difficulty": "Easy",
      "subtitle": "Bottles, containers, caps, and packaging",
      "description":
          "Plastic waste includes bottles, containers, wrappers, caps, and packaging materials.",
      "preparation": [
        "Rinse bottles and containers before recycling.",
        "Remove caps if your local recycling center requires it.",
        "Flatten bottles to save space when possible.",
      ],
      "dos": [
        "Recycle clean bottles and containers.",
        "Check the recycling number on the plastic item.",
        "Separate plastic bags from regular plastic bins.",
      ],
      "donts": [
        "Do not recycle dirty food containers.",
        "Do not place plastic bags in normal recycling bins.",
        "Do not mix plastic with organic waste.",
      ],
      "items": ["Water Bottle", "Food Container", "Shampoo Bottle", "Bottle Cap"],
      "binColor": "Blue Bin",
    },
    {
      "title": "Glass",
      "icon": Icons.wine_bar_outlined,
      "color": Colors.green,
      "difficulty": "Easy",
      "subtitle": "Bottles, jars, and glass containers",
      "description":
          "Glass waste includes bottles, jars, and glass food containers.",
      "preparation": [
        "Rinse glass bottles and jars thoroughly.",
        "Remove metal lids, corks, and plastic caps.",
        "Keep broken glass separate for safety.",
      ],
      "dos": [
        "Recycle clean glass bottles and jars.",
        "Separate glass by color if required.",
        "Handle broken glass carefully.",
      ],
      "donts": [
        "Do not recycle mirrors with glass bottles.",
        "Do not include ceramics or light bulbs.",
        "Do not mix glass with food waste.",
      ],
      "items": ["Glass Bottle", "Jam Jar", "Sauce Jar", "Drink Bottle"],
      "binColor": "Green Bin",
    },
    {
      "title": "Metal",
      "icon": Icons.inventory_2_outlined,
      "color": Colors.orange,
      "difficulty": "Medium",
      "subtitle": "Cans, tins, foil, and metal packaging",
      "description":
          "Metal waste includes aluminum cans, food tins, foil, and metal packaging.",
      "preparation": [
        "Rinse cans before recycling.",
        "Flatten cans if possible.",
        "Remove food residue from tins.",
      ],
      "dos": [
        "Recycle empty cans and tins.",
        "Separate batteries from metal waste.",
        "Keep sharp metal pieces safely wrapped.",
      ],
      "donts": [
        "Do not recycle batteries with metal cans.",
        "Do not include electronics in metal bins.",
        "Do not recycle cans full of liquid or food.",
      ],
      "items": ["Aluminum Can", "Food Tin", "Metal Lid", "Foil Tray"],
      "binColor": "Yellow Bin",
    },
    {
      "title": "Organic",
      "icon": Icons.grass_outlined,
      "color": Colors.brown,
      "difficulty": "Easy",
      "subtitle": "Food scraps and biodegradable waste",
      "description":
          "Organic waste includes food scraps, fruit peels, vegetables, and biodegradable materials.",
      "preparation": [
        "Separate food waste from plastic packaging.",
        "Keep organic waste in a separate container.",
        "Use composting when available.",
      ],
      "dos": [
        "Separate fruit and vegetable scraps.",
        "Compost suitable organic waste.",
        "Keep organic waste away from recyclables.",
      ],
      "donts": [
        "Do not mix plastic wrappers with organic waste.",
        "Do not include glass or metal pieces.",
        "Do not leave organic waste uncovered for long periods.",
      ],
      "items": ["Food Scraps", "Fruit Peels", "Vegetables", "Coffee Grounds"],
      "binColor": "Brown Bin",
    },
    {
      "title": "Paper",
      "icon": Icons.description_outlined,
      "color": Colors.teal,
      "difficulty": "Easy",
      "subtitle": "Paper, cartons, notebooks, and cardboard",
      "description":
          "Paper waste includes paper sheets, notebooks, cartons, cardboard, and clean paper packaging.",
      "preparation": [
        "Keep paper dry and clean.",
        "Flatten cardboard boxes.",
        "Remove plastic tape when possible.",
      ],
      "dos": [
        "Recycle clean paper and cardboard.",
        "Flatten boxes before disposal.",
        "Separate paper from food waste.",
      ],
      "donts": [
        "Do not recycle greasy pizza boxes.",
        "Do not recycle wet paper.",
        "Do not mix tissues with clean paper.",
      ],
      "items": ["Cardboard Box", "Notebook", "Paper Bag", "Carton"],
      "binColor": "Paper Bin",
    },
  ];

  List<Map<String, dynamic>> get filteredCategories {
    final query = search.toLowerCase().trim();

    if (query.isEmpty) return categories;

    return categories.where((item) {
      final title = item["title"].toString().toLowerCase();
      final subtitle = item["subtitle"].toString().toLowerCase();
      final items = (item["items"] as List).join(" ").toLowerCase();

      return title.contains(query) ||
          subtitle.contains(query) ||
          items.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredCategories;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: const Text("How To Recycle"),
        backgroundColor: const Color(0xFF7CB342),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _heroHeader(),
          const SizedBox(height: 18),
          _searchBar(),
          const SizedBox(height: 18),
          _overviewCards(),
          const SizedBox(height: 22),
          _sectionTitle("Recycling Categories"),
          const SizedBox(height: 12),
          if (filtered.isEmpty) _emptyState(),
          ...filtered.map((item) => _materialCard(item)),
          const SizedBox(height: 18),
          _popularItemsCard(),
          const SizedBox(height: 16),
          _assistantCard(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _heroHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -8,
            child: Icon(
              Icons.recycling,
              size: 120,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Recycling Guide ♻️",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Learn how to prepare, sort, and dispose of waste materials correctly.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: "Search material, item, or recycling tip...",
        prefixIcon: const Icon(Icons.search),
        suffixIcon: search.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => search = ""),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) => setState(() => search = value),
    );
  }

  Widget _overviewCards() {
    return Row(
      children: [
        Expanded(
          child: _miniInfoCard(
            icon: Icons.category_outlined,
            title: "${categories.length}",
            subtitle: "Materials",
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniInfoCard(
            icon: Icons.lightbulb_outline,
            title: "25+",
            subtitle: "Tips",
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniInfoCard(
            icon: Icons.school_outlined,
            title: "Easy",
            subtitle: "Guide",
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _miniInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
    );
  }

  Widget _materialCard(Map<String, dynamic> item) {
    final color = item["color"] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: _cardDecoration(),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(item["icon"], color: color),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  item["title"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              _badge(item["difficulty"], color),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              item["subtitle"],
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          trailing: const Icon(Icons.keyboard_arrow_down, size: 22),
          children: [
            _detailBlock(
              icon: Icons.info_outline,
              title: "What is it?",
              text: item["description"],
              color: color,
            ),
            const SizedBox(height: 12),
            _stepsBlock(
              title: "Preparation Steps",
              steps: item["preparation"],
              icon: Icons.checklist_outlined,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _doDontBlock(item),
            const SizedBox(height: 12),
            _commonItems(item),
            const SizedBox(height: 12),
            _binCard(item["binColor"], color),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _detailBlock({
    required IconData icon,
    required String title,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: _infoText(title, text)),
        ],
      ),
    );
  }

  Widget _stepsBlock({
    required String title,
    required List steps,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: color.withOpacity(0.15),
                        child: Text(
                          "${entry.key + 1}",
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entry.value.toString())),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _doDontBlock(Map<String, dynamic> item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _listCard(
            title: "Do",
            icon: Icons.check_circle_outline,
            color: Colors.green,
            list: item["dos"],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _listCard(
            title: "Don't",
            icon: Icons.cancel_outlined,
            color: Colors.redAccent,
            list: item["donts"],
          ),
        ),
      ],
    );
  }

  Widget _listCard({
    required String title,
    required IconData icon,
    required Color color,
    required List list,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 8),
          ...list.take(3).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    "• $item",
                    style: const TextStyle(fontSize: 12, height: 1.3),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _commonItems(Map<String, dynamic> item) {
    final color = item["color"] as Color;
    final items = item["items"] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Common Items", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (text) => Chip(
                  label: Text(text),
                  backgroundColor: color.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  side: BorderSide.none,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _binCard(String bin, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.delete_outline, color: color),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Recommended disposal",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(bin, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _popularItemsCard() {
    final items = [
      {"name": "Plastic Bottle", "icon": Icons.local_drink_outlined},
      {"name": "Glass Jar", "icon": Icons.wine_bar_outlined},
      {"name": "Metal Can", "icon": Icons.inventory_2_outlined},
      {"name": "Cardboard", "icon": Icons.description_outlined},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Popular Recycling Items",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items
                .map(
                  (item) => Chip(
                    avatar: Icon(item["icon"] as IconData, size: 18),
                    label: Text(item["name"].toString()),
                    backgroundColor: Colors.green.withOpacity(0.08),
                    side: BorderSide.none,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _assistantCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 34),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              "Need help with a specific item?\nAsk Eco Assistant for recycling guidance.",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Eco Assistant feature coming soon 🤖"),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          Icon(Icons.search_off, size: 44, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            "No material found",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            "Try searching for plastic, glass, metal, paper, or organic.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _infoText(String title, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(height: 1.35)),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.055),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}