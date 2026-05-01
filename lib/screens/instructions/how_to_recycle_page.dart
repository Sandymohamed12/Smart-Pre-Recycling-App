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
      "icon": Icons.local_drink,
      "image":
          "https://cdn-icons-png.flaticon.com/512/891/891462.png",
      "description":
          "Includes bottles, containers, and packaging materials.",
      "preparation":
          "Rinse before recycling. Remove caps if required.",
      "mistakes":
          "Do not recycle plastic bags in regular bins.",
      "binColor": "Blue Bin",
    },
    {
      "title": "Glass",
      "icon": Icons.wine_bar,
      "image":
          "https://cdn-icons-png.flaticon.com/512/1046/1046857.png",
      "description":
          "Includes glass bottles and jars.",
      "preparation":
          "Rinse thoroughly. Remove lids and corks.",
      "mistakes":
          "Do not include broken mirrors or ceramics.",
      "binColor": "Green Bin",
    },
    {
      "title": "Metal",
      "icon": Icons.build,
      "image":
          "https://cdn-icons-png.flaticon.com/512/809/809957.png",
      "description":
          "Includes aluminum cans and metal packaging.",
      "preparation":
          "Rinse and flatten cans if possible.",
      "mistakes":
          "Avoid including batteries.",
      "binColor": "Yellow Bin",
    },
    {
      "title": "Organic",
      "icon": Icons.eco,
      "image":
          "https://cdn-icons-png.flaticon.com/512/2909/2909760.png",
      "description":
          "Includes food scraps and biodegradable materials.",
      "preparation":
          "Separate from plastic packaging.",
      "mistakes":
          "Do not mix with non-biodegradable waste.",
      "binColor": "Brown Bin",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = categories
        .where((item) =>
            item["title"].toLowerCase().contains(search.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("How To Recycle"),
        backgroundColor: const Color(0xFF7CB342),
      ),
      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search material...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  search = value;
                });
              },
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Icon(item["icon"], color: Colors.green),
                      ),
                      title: Text(
                        item["title"],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.all(16),
                      children: [
                        Image.network(item["image"], height: 80),
                        const SizedBox(height: 12),
                        _InfoRow("What is it?", item["description"]),
                        const SizedBox(height: 8),
                        _InfoRow("Preparation", item["preparation"]),
                        const SizedBox(height: 8),
                        _InfoRow("Common Mistakes", item["mistakes"]),
                        const SizedBox(height: 8),
                        _InfoRow("Dispose In", item["binColor"]),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 INFO ROW
class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }
}
