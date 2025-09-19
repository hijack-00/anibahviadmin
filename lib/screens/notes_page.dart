import 'package:flutter/material.dart';


class NotesPage extends StatefulWidget {
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<String> notes = [
    'Call customer for confirmation',
    'LR uploaded',
    'Transport assigned',
    'Auto-update: Lot changed',
  ];
  TextEditingController controller = TextEditingController();

  void _showNoteSheet({int? editIndex}) {
    if (editIndex != null) controller.text = notes[editIndex];
    else controller.clear();
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(editIndex == null ? 'Add Note' : 'Edit Note', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Note',
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                    onPressed: () {
                      setState(() {
                        if (editIndex == null && controller.text.trim().isNotEmpty) {
                          notes.add(controller.text.trim());
                        } else if (editIndex != null) {
                          notes[editIndex] = controller.text.trim();
                        }
                        controller.clear();
                      });
                      Navigator.pop(context);
                    },
                    child: Text(editIndex == null ? 'Add' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteNote(int index) {
    setState(() {
      notes.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text('Notes'),
        backgroundColor: Colors.indigo,
        actions: [
          Icon(Icons.note, color: Colors.white),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 8),
            Expanded(
              child: notes.isEmpty
                  ? Center(child: Text('No notes found'))
                  : ListView.separated(
                      itemCount: notes.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8),
                      itemBuilder: (context, i) => Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.shade100,
                            child: Icon(Icons.note, color: Colors.indigo),
                          ),
                          title: Text(notes[i], style: TextStyle(fontWeight: FontWeight.w500)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.indigo),
                                onPressed: () => _showNoteSheet(editIndex: i),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteNote(i),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        child: Icon(Icons.add),
        onPressed: () => _showNoteSheet(),
        tooltip: 'Add Note',
      ),
    );
  }
}
