import 'package:anibhaviadmin/screens/catalogue_page.dart';
import 'package:anibhaviadmin/screens/users_page.dart';
import 'package:flutter/material.dart';

class SalesOrderPage extends StatefulWidget {
  @override
  State<SalesOrderPage> createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage> {
  // Dummy data and controllers for each section
  String? selectedCustomer;
  TextEditingController customerController = TextEditingController();
  String? selectedCatalogue;
  String notes = '';
  String? lrFile;
  String? transportName;
  String? selectedPDF;
  bool convertedToChallan = false;
  String? barcode;
  String? mismatchStatus;
  String? lotNo;
  // String franchisee = '';
  bool isEditable = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text('Sales Order'),
        backgroundColor: Colors.indigo,
        actions: [
          if (!isEditable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(Icons.lock, color: Colors.white),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
              // Customer create/search (clickable)
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => UsersPage(showActive: true),
                      ),
                    );
                  },
                  child: ListTile(
                    minTileHeight: 80,
                    leading: Icon(Icons.person, color: Colors.indigo),
                    title: Text("Customer Create/Search"),
                    trailing: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: isEditable ? () {} : null,
                    ),
                  ),
                ),
              ),
            SizedBox(height: 12),
            // Catalogue section
            Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CataloguePage(),
                      ),
                    );
                  },
                  child: ListTile(
                    minTileHeight: 80,
                    leading: Icon(Icons.person, color: Colors.indigo),
                    title: Text("Catalogues"),
                    trailing: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: isEditable ? () {} : null,
                    ),
                  ),
                ),
              ),
            SizedBox(height: 12),
            // Notes option
            // Card(
            //   child: ListTile(
            //     leading: Icon(Icons.note, color: Colors.indigo),
            //     title: TextField(
            //       decoration: InputDecoration(labelText: 'Notes', border: InputBorder.none),
            //       onChanged: isEditable ? (val) => setState(() => notes = val) : null,
            //       enabled: isEditable,
            //     ),
            //   ),
            // ),
            // SizedBox(height: 12),
            // LR upload option
            // Card(
            //   child: ListTile(
            //     leading: Icon(Icons.upload_file, color: Colors.indigo),
            //     title: Text(lrFile ?? 'No LR uploaded'),
            //     trailing: ElevatedButton(
            //       child: Text('Upload',style: TextStyle(color: Colors.white),),
            //       style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            //       onPressed: isEditable
            //           ? () {
            //               setState(() {
            //                 lrFile = 'LR_${DateTime.now().millisecondsSinceEpoch}.pdf';
            //               });
            //             }
            //           : null,
            //     ),
            //   ),
            // ),
            SizedBox(height: 12),
            // Transport name entry
            // Card(
            //   child: ListTile(
            //     leading: Icon(Icons.local_shipping, color: Colors.indigo),
            //     title: TextField(
            //       decoration: InputDecoration(labelText: 'Transport Name', border: InputBorder.none),
            //       onChanged: isEditable ? (val) => setState(() => transportName = val) : null,
            //       enabled: isEditable,
            //     ),
            //   ),
            // ),
            // SizedBox(height: 12),
            // PDF share
            // Card(
            //   child: ListTile(
            //     leading: Icon(Icons.picture_as_pdf, color: Colors.indigo),
            //     title: DropdownButtonFormField<String>(
            //       value: selectedPDF,
            //       items: ['Catalogue_2025.pdf', 'Price_List.pdf', 'Delivery_Challan.pdf']
            //           .map((p) => DropdownMenuItem(value: p, child: Text(p)))
            //           .toList(),
            //       decoration: InputDecoration(labelText: 'Share PDF'),
            //       onChanged: isEditable ? (val) => setState(() => selectedPDF = val) : null,
            //     ),
            //     trailing: IconButton(
            //       icon: Icon(Icons.share, color: Colors.green),
            //       onPressed: isEditable && selectedPDF != null ? () {} : null,
            //     ),
            //   ),
            // ),
            // SizedBox(height: 12),
            // Sales order to Delivery Challan convert
            Card(
              child: ListTile(
                leading: Icon(Icons.swap_horiz, color: Colors.indigo),
                title: Text(convertedToChallan ? 'Converted to Delivery Challan' : 'Convert to Delivery Challan'),
                trailing: ElevatedButton(
                  child: Text('Convert',style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  onPressed: isEditable && !convertedToChallan
                      ? () {
                          setState(() {
                            convertedToChallan = true;
                            isEditable = false;
                          });
                        }
                      : null,
                ),
              ),
            ),
            SizedBox(height: 12),
            // Barcode scan + manual option
            Card(
              child: ListTile(
                leading: Icon(Icons.qr_code_scanner, color: Colors.indigo),
                title: TextField(
                  decoration: InputDecoration(labelText: 'Barcode / Manual Entry', border: InputBorder.none),
                  onChanged: isEditable ? (val) => setState(() => barcode = val) : null,
                  enabled: isEditable,
                ),
                trailing: IconButton(
                  icon: Icon(Icons.qr_code, color: Colors.indigo),
                  onPressed: isEditable ? () {} : null,
                ),
              ),
            ),
            SizedBox(height: 12),
            // Mismatch check (SO vs DC)
            Card(
              child: ListTile(
                leading: Icon(Icons.error_outline, color: Colors.indigo),
                title: Text('Mismatch Check (SO vs DC)'),
                subtitle: Text(mismatchStatus ?? 'No mismatch detected'),
                trailing: ElevatedButton(
                  child: Text('Check',style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  onPressed: isEditable
                      ? () {
                          setState(() {
                            mismatchStatus = 'No mismatch found (dummy)';
                          });
                        }
                      : null,
                ),
              ),
            ),
            SizedBox(height: 12),
            // Lot no.
            Card(
              child: ListTile(
                leading: Icon(Icons.confirmation_number, color: Colors.indigo),
                title: TextField(
                  decoration: InputDecoration(labelText: 'Lot No.', border: InputBorder.none),
                  onChanged: isEditable ? (val) => setState(() => lotNo = val) : null,
                  enabled: isEditable,
                ),
              ),
            ),
            SizedBox(height: 12),
            // Franchisee selection during Sales Order
            // Card(
            //   child: ListTile(
            //     leading: Icon(Icons.store, color: Colors.indigo),
            //     title: DropdownButtonFormField<String>(
            //       value: franchisee.isEmpty ? null : franchisee,
            //       items: ['Franchisee A', 'Franchisee B', 'Franchisee C']
            //           .map((f) => DropdownMenuItem(value: f, child: Text(f)))
            //           .toList(),
            //       decoration: InputDecoration(labelText: 'Select Franchisee'),
            //       onChanged: isEditable ? (val) => setState(() => franchisee = val ?? '') : null,
            //     ),
            //   ),
            // ),
            // SizedBox(height: 12),
            // Editable until DC created
            Card(
              color: isEditable ? Colors.green.shade50 : Colors.red.shade50,
              child: ListTile(
                leading: Icon(isEditable ? Icons.edit : Icons.lock, color: isEditable ? Colors.green : Colors.red),
                title: Text(isEditable ? 'Editable' : 'Locked (DC Created)'),
                subtitle: Text('You can edit until Delivery Challan is created.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
