import 'package:flutter/material.dart';

class SearchableDropdown extends StatefulWidget {
  final String label;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final Color? labelColor;
  const SearchableDropdown({
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.labelColor,
    Key? key,
  }) : super(key: key);

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  void _openDropdown() async {
    String? selected = widget.value;
    String search = '';
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        List<String> filtered = widget.items;
        return StatefulBuilder(
          builder: (context, setModalState) {
            filtered = widget.items
                .where((item) => item.toLowerCase().contains(search.toLowerCase()))
                .toList();
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label, style: TextStyle(fontWeight: FontWeight.bold, color: widget.labelColor ?? Colors.indigo, fontSize: 16)),
                  SizedBox(height: 8),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) {
                      setModalState(() => search = val);
                    },
                  ),
                  SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final item = filtered[idx];
                        return ListTile(
                          title: Text(item),
                          trailing: selected == item ? Icon(Icons.check, color: Colors.indigo) : null,
                          onTap: () {
                            Navigator.of(context).pop(item);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((val) {
      if (val != null) widget.onChanged(val);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openDropdown,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(color: widget.labelColor ?? Colors.indigo, fontWeight: FontWeight.bold),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.indigo),
        ),
        child: Text(widget.value ?? 'Select', style: TextStyle(fontSize: 15)),
      ),
    );
  }
}
