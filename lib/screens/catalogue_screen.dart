import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class CatalogueScreen extends StatefulWidget {
  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  final List<Map<String, dynamic>> designs = [
    {
      'id': '1',
      'name': 'Saree Design 1',
      'category': 'Saree',
      'image': null,
      'tags': ['Indigo', 'Cotton'],
    },
    {
      'id': '2',
      'name': 'Kurta Design 2',
      'category': 'Kurta',
      'image': null,
      'tags': ['Gray', 'Silk'],
    },
  ];

  String searchText = '';
  String selectedCategory = 'All';

  List<Map<String, dynamic>> get filteredDesigns {
    return designs.where((d) {
      final matchesSearch = d['name'].toLowerCase().contains(searchText.toLowerCase());
      final matchesCategory = selectedCategory == 'All' || d['category'] == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...{for (var d in designs) d['category']}];
    return UniversalScaffold(
      selectedIndex: 2,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search designs',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => searchText = val),
                ),
                SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: selectedCategory == cat,
                        onSelected: (_) => setState(() => selectedCategory = cat),
                      ),
                    )).toList(),
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredDesigns.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final design = filteredDesigns[i];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo[100],
                            child: Icon(Icons.image, color: Colors.indigo),
                          ),
                          title: Text(design['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Category: ${design['category']}\nTags: ${(design['tags'] as List).join(', ')}'),
                          trailing: IconButton(
                            icon: Icon(Icons.share),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Share link copied (dummy).')),
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, '/catalogue_detail', arguments: design['id']);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Upload Design'),
                    content: Text('Upload design (dummy action).'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                  ),
                );
              },
              icon: Icon(Icons.upload_file),
              label: Text('Upload'),
              backgroundColor: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }
}
