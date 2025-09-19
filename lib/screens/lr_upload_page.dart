import 'package:flutter/material.dart';


class LRUploadPage extends StatefulWidget {
  @override
  State<LRUploadPage> createState() => _LRUploadPageState();
}


class _LRUploadPageState extends State<LRUploadPage> {
  List<Map<String, dynamic>> uploadHistory = [];
  bool isUploading = false;

  void _uploadLR() async {
    setState(() {
      isUploading = true;
    });
    await Future.delayed(Duration(seconds: 1));
    final fileName = 'LR_Document_${DateTime.now().millisecondsSinceEpoch}.pdf';
    setState(() {
      uploadHistory.insert(0, {
        'file': fileName,
        'date': DateTime.now(),
        'status': 'Uploaded',
      });
      isUploading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('LR uploaded (dummy)')),
    );
  }

  void _showFileOptions(Map<String, dynamic> file) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
                  _showPreview(file);
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: Colors.indigo),
                title: Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Share simulated')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete'),
                onTap: () {
                  setState(() {
                    uploadHistory.remove(file);
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPreview(Map<String, dynamic> file) {
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
              Text(file['file'], style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Uploaded: ${file['date'].toString().substring(0, 19)}'),
              SizedBox(height: 8),
              Text('Status: ${file['status']}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text('LR Upload'),
        backgroundColor: Colors.indigo,
        actions: [Icon(Icons.upload_file, color: Colors.white)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text('Upload LR Document', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.upload_file),
                  label: Text('Upload'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  onPressed: isUploading ? null : _uploadLR,
                ),
                SizedBox(width: 16),
                if (isUploading)
                  CircularProgressIndicator(color: Colors.indigo),
              ],
            ),
            SizedBox(height: 24),
            Text('Upload History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo)),
            SizedBox(height: 8),
            Expanded(
              child: uploadHistory.isEmpty
                  ? Center(child: Text('No LR uploaded yet', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: uploadHistory.length,
                      itemBuilder: (context, index) {
                        final file = uploadHistory[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: ListTile(
                            leading: Icon(Icons.insert_drive_file, color: Colors.indigo),
                            title: Text(file['file']),
                            subtitle: Text('Uploaded: ${file['date'].toString().substring(0, 19)}'),
                            trailing: PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: Colors.indigo),
                              onSelected: (value) {
                                if (value == 'options') _showFileOptions(file);
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'options',
                                  child: Text('Options'),
                                ),
                              ],
                            ),
                            onTap: () => _showPreview(file),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        icon: Icon(Icons.upload_file),
        label: Text('Upload LR'),
        onPressed: isUploading ? null : _uploadLR,
      ),
    );
  }
}