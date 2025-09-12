import 'package:flutter/material.dart';
import '../widgets/searchable_dropdown.dart';

Future<void> showCreateChallanDialog(BuildContext context) async {
	String? selectedCustomer;
	String? selectedOrder;
	String? selectedVendor;
	String notes = '';
	List<String> customers = ['Client X', 'Client Y', 'Client Z'];
	List<String> orders = ['Order 101', 'Order 102', 'Order 103'];
	List<String> vendors = ['DP Express', 'DP Fast', 'DP Quick'];
	await showDialog(
		context: context,
		builder: (context) {
			return AlertDialog(
				backgroundColor: Colors.white,
				title: Text('Create Challan', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
				content: SingleChildScrollView(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							SearchableDropdown(
								label: 'Select Customer',
								items: customers,
								value: selectedCustomer,
								labelColor: Colors.indigo,
								onChanged: (val) {
									selectedCustomer = val;
								},
							),
							SizedBox(height: 12),
							SearchableDropdown(
								label: 'Select Order',
								items: orders,
								value: selectedOrder,
								labelColor: Colors.indigo,
								onChanged: (val) {
									selectedOrder = val;
								},
							),
							SizedBox(height: 12),
							SearchableDropdown(
								label: 'Delivery Vendor',
								items: vendors,
								value: selectedVendor,
								labelColor: Colors.indigo,
								onChanged: (val) {
									selectedVendor = val;
								},
							),
							SizedBox(height: 12),
							Text('Notes (optional)', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
							TextField(
								decoration: InputDecoration(hintText: 'Add notes'),
								onChanged: (val) {
									notes = val;
								},
							),
						],
					),
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.of(context).pop(),
						child: Text('Cancel'),
					),
					ElevatedButton(
						onPressed: () {
							// TODO: Implement create challan logic
							Navigator.of(context).pop();
						},
						child: Text('Create Challan'),
					),
				],
			);
		},
	);
}
