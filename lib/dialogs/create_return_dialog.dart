import 'package:flutter/material.dart';
import '../widgets/searchable_dropdown.dart';

Future<void> showCreateReturnDialog(BuildContext context) async {
	String? selectedCustomer;
	String? selectedOrder;
	String? selectedRefund;
	List<String> customers = ['Client X', 'Client Y', 'Client Z'];
	List<String> orders = ['Order 101', 'Order 102', 'Order 103'];
	List<String> refundMethods = ['Bank Transfer', 'UPI', 'Cash'];
	await showDialog(
		context: context,
		builder: (context) {
			return AlertDialog(
				backgroundColor: Colors.white,
				title: Text('Create Return', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
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
								label: 'Refund Method',
								items: refundMethods,
								value: selectedRefund,
								labelColor: Colors.indigo,
								onChanged: (val) {
									selectedRefund = val;
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
							// TODO: Implement create return logic
							Navigator.of(context).pop();
						},
						child: Text('Create Return'),
					),
				],
			);
		},
	);
}
