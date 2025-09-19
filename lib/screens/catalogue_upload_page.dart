import 'package:flutter/material.dart';

class CatalogueUploadPage extends StatefulWidget {
  @override
  State<CatalogueUploadPage> createState() => _CatalogueUploadPageState();
}

class _CatalogueUploadPageState extends State<CatalogueUploadPage> {
  List<String> pdfs = [
    'Catalogue_2025.pdf',
    'Jeans_Range.pdf',
    'Shirts_Range.pdf',
  ];
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final filtered = pdfs.where((pdf) => pdf.toLowerCase().contains(searchController.text.toLowerCase())).toList();
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text('Catalogue Upload'),
        backgroundColor: Colors.indigo,
        actions: [Icon(Icons.upload_file, color: Colors.white)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.upload_file, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('Upload & Search PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                ],
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search PDF',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.upload_file, color: Colors.white),
              label: Text('Upload PDF',style: TextStyle(color: Colors.white),),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              onPressed: () {
                setState(() {
                  pdfs.add('New_Catalogue_${DateTime.now().millisecondsSinceEpoch}.pdf');
                });
              },
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('PDF List', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                ],
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('No PDFs found', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: Colors.white,
                        child: ListTile(
                          leading: Icon(Icons.picture_as_pdf, color: Colors.indigo),
                          title: Text(filtered[i], style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: IconButton(
                            icon: Icon(Icons.download, color: Colors.green),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Downloaded ${filtered[i]} (dummy)')),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
