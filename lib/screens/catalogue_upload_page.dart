import 'package:flutter/material.dart';
import '../widgets/barcode_generator.dart';

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
  TextEditingController barcodeController = TextEditingController();
  String manualBarcode = '';
  String generatedBarcode = '';

  @override
  Widget build(BuildContext context) {
    final filtered = pdfs
        .where(
          (pdf) =>
              pdf.toLowerCase().contains(searchController.text.toLowerCase()),
        )
        .toList();
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text('Catalogue Upload'),
        backgroundColor: Colors.indigo,
        actions: [Icon(Icons.upload_file, color: Colors.white)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.qr_code, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text(
                      'Generate EAN13 Barcode',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: barcodeController,
                decoration: InputDecoration(
                  labelText: 'Enter EAN13 Barcode',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.qr_code),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLength: 13,
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  setState(() {
                    manualBarcode = val;
                  });
                },
              ),
              SizedBox(height: 8),
              ElevatedButton.icon(
                icon: Icon(Icons.qr_code, color: Colors.white),
                label: Text(
                  'Generate Barcode',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: () {
                  if (manualBarcode.length == 13 &&
                      int.tryParse(manualBarcode) != null) {
                    setState(() {
                      generatedBarcode = manualBarcode;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please enter a valid 13-digit EAN13 number.',
                        ),
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: 8),
              if (generatedBarcode.length == 13 &&
                  int.tryParse(generatedBarcode) != null)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EAN13 Barcode:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        SizedBox(height: 8),
                        Center(
                          child: SizedBox(
                            height: 80,
                            child: BarcodeGenerator(barcode: generatedBarcode),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                    Text(
                      'Upload & Search PDF',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
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
                label: Text(
                  'Upload PDF',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: () {
                  setState(() {
                    pdfs.add(
                      'New_Catalogue_${DateTime.now().millisecondsSinceEpoch}.pdf',
                    );
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
                    Text(
                      'PDF List',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              SizedBox(height: 8),
              Container(
                height: 300,
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No PDFs found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.white,
                          child: ListTile(
                            leading: Icon(
                              Icons.picture_as_pdf,
                              color: Colors.indigo,
                            ),
                            title: Text(
                              filtered[i],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.download, color: Colors.green),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Downloaded ${filtered[i]} (dummy)',
                                    ),
                                  ),
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
      ),
    );
  }
}
