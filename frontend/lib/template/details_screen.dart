import 'package:flutter/material.dart';
import '../widgets/app_footer.dart';

class DetailScreenTemplate extends StatelessWidget {
  final String screenTitle;
  final Future<Map<String, dynamic>> Function(int) fetchData;
  final int itemId;
  final String titleAtTop;
  final String dynamicTitleKey;
  final List<DetailItem> detailItems;
  final List<Section> sections;

  DetailScreenTemplate({
    required this.screenTitle,
    required this.fetchData,
    required this.itemId,
    required this.titleAtTop,
    required this.dynamicTitleKey, // Initialize dynamic title key
    required this.detailItems,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(screenTitle, style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade800,
        elevation: 4,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchData(itemId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('❌ Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No data available.'));
          } else {
            final data = snapshot.data!;

            // Get dynamic title based on the customizable key, fallback to titleAtTop
            String dynamicTitle = titleAtTop;
            if (data.containsKey(dynamicTitleKey)) {
              dynamicTitle = data[dynamicTitleKey] ?? titleAtTop;
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dynamicTitle,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      SizedBox(height: 10),
                      Divider(),

                      // Displaying the detail items
                      ...detailItems.map(
                        (item) => DetailTile(item: item, data: data),
                      ),

                      SizedBox(height: 20),

                      // Displaying the sections
                      for (var section in sections) ...[
                        Text(
                          section.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                        SizedBox(height: 10),
                        section.builder(data),
                        SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}

class DetailItem {
  final String title;
  final String icon;
  final String Function(Map<String, dynamic>) subtitle;

  DetailItem({required this.title, required this.icon, required this.subtitle});
}

class Section {
  final String title;
  final Widget Function(Map<String, dynamic>) builder;

  Section({required this.title, required this.builder});
}

class DetailTile extends StatelessWidget {
  final DetailItem item;
  final Map<String, dynamic> data;

  DetailTile({required this.item, required this.data});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        IconData(int.parse(item.icon), fontFamily: 'MaterialIcons'),
        color: Colors.blue,
      ),
      title: Text(item.title),
      subtitle: Text(item.subtitle(data)),
    );
  }
}
