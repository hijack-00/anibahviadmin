import 'package:flutter/material.dart';


class PDFSharePage extends StatefulWidget {
  @override
  State<PDFSharePage> createState() => _PDFSharePageState();
}

class _PDFSharePageState extends State<PDFSharePage> {
  List<String> pdfs = [
    'Catalogue_2025.pdf',
    'Price_List.pdf',
    'Delivery_Challan.pdf',
  ];

  void _showOptions(String pdf, int index) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.remove_red_eye, color: Colors.indigo),
                title: Text('Preview'),
                onTap: () {
                  Navigator.pop(context);
                  _showPreview(pdf);
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: Colors.green),
                title: Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Shared $pdf (dummy)')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete'),
                onTap: () {
                  setState(() {
                    pdfs.removeAt(index);
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted $pdf')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPreview(String pdf) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Preview'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf, size: 48, color: Colors.indigo),
              SizedBox(height: 8),
              Text(pdf, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Simulated preview'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void _addPDF() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController pdfController = TextEditingController();
        return AlertDialog(
          title: Text('Add PDF'),
          content: TextField(
            controller: pdfController,
            decoration: InputDecoration(labelText: 'PDF Name'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('Add'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              onPressed: () {
                final name = pdfController.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    pdfs.insert(0, name);
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added $name')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text('PDF Share'),
        backgroundColor: Colors.indigo,
        actions: [Icon(Icons.picture_as_pdf, color: Colors.white)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: pdfs.isEmpty
            ? Center(child: Text('No PDFs available', style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                itemCount: pdfs.length,
                itemBuilder: (context, i) {
                  final pdf = pdfs[i];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf, color: Colors.indigo),
                      title: Text(pdf),
                      subtitle: Text('PDF file'),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.indigo),
                        onSelected: (value) {
                          if (value == 'options') _showOptions(pdf, i);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'options', child: Text('Options')),
                        ],
                      ),
                      onTap: () => _showPreview(pdf),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        icon: Icon(Icons.add),
        label: Text('Add PDF'),
        onPressed: _addPDF,
      ),
    );
  }
}
