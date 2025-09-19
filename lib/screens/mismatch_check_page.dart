
import 'package:flutter/material.dart';

class MismatchCheckPage extends StatefulWidget {
	@override
	State<MismatchCheckPage> createState() => _MismatchCheckPageState();
}

class _MismatchCheckPageState extends State<MismatchCheckPage> {
	List<Map<String, dynamic>> mismatches = [
		{
			'id': 'M001',
			'type': 'Qty',
			'desc': 'Quantity mismatch in order #1234',
			'resolved': false,
		},
		{
			'id': 'M002',
			'type': 'Price',
			'desc': 'Price mismatch in invoice #5678',
			'resolved': false,
		},
		{
			'id': 'M003',
			'type': 'Product',
			'desc': 'Product mismatch in delivery #9101',
			'resolved': true,
		},
	];
	String filter = 'All';

	List<Map<String, dynamic>> get filteredMismatches {
		if (filter == 'All') return mismatches;
		if (filter == 'Resolved') return mismatches.where((m) => m['resolved']).toList();
		if (filter == 'Unresolved') return mismatches.where((m) => !m['resolved']).toList();
		return mismatches;
	}

	void _showOptions(Map<String, dynamic> mismatch) {
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
								leading: Icon(Icons.info, color: Colors.indigo),
								title: Text('Details'),
								onTap: () {
									Navigator.pop(context);
									_showDetails(mismatch);
								},
							),
							if (!mismatch['resolved'])
								ListTile(
									leading: Icon(Icons.check_circle, color: Colors.green),
									title: Text('Mark as Resolved'),
									onTap: () {
										setState(() {
											mismatch['resolved'] = true;
										});
										Navigator.pop(context);
										ScaffoldMessenger.of(context).showSnackBar(
											SnackBar(content: Text('Marked as resolved')),
										);
									},
								),
						],
					),
				);
			},
		);
	}

	void _showDetails(Map<String, dynamic> mismatch) {
		showDialog(
			context: context,
			builder: (context) {
				return AlertDialog(
					title: Text('Mismatch Details'),
					content: Column(
						mainAxisSize: MainAxisSize.min,
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text('ID: ${mismatch['id']}', style: TextStyle(fontWeight: FontWeight.bold)),
							SizedBox(height: 8),
							Text('Type: ${mismatch['type']}'),
							SizedBox(height: 8),
							Text('Description: ${mismatch['desc']}'),
							SizedBox(height: 8),
							Text('Status: ${mismatch['resolved'] ? 'Resolved' : 'Unresolved'}'),
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
				title: Text('Mismatch Check'),
				backgroundColor: Colors.indigo,
				actions: [Icon(Icons.error_outline, color: Colors.white)],
			),
			body: Padding(
				padding: const EdgeInsets.all(16.0),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Row(
							children: [
								Text('Filter:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
								SizedBox(width: 8),
								DropdownButton<String>(
									value: filter,
									items: ['All', 'Resolved', 'Unresolved']
											.map((f) => DropdownMenuItem(value: f, child: Text(f)))
											.toList(),
									onChanged: (val) => setState(() => filter = val ?? 'All'),
								),
							],
						),
						SizedBox(height: 16),
						Expanded(
							child: filteredMismatches.isEmpty
									? Center(child: Text('No mismatches found', style: TextStyle(color: Colors.grey)))
									: ListView.builder(
											itemCount: filteredMismatches.length,
											itemBuilder: (context, i) {
												final mismatch = filteredMismatches[i];
												return Card(
													elevation: 2,
													shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
													color: Colors.white,
													child: ListTile(
														leading: Icon(
															mismatch['resolved'] ? Icons.check_circle : Icons.error_outline,
															color: mismatch['resolved'] ? Colors.green : Colors.red,
														),
														title: Text(mismatch['desc']),
														subtitle: Text('Type: ${mismatch['type']}'),
														trailing: PopupMenuButton<String>(
															icon: Icon(Icons.more_vert, color: Colors.indigo),
															onSelected: (value) {
																if (value == 'options') _showOptions(mismatch);
															},
															itemBuilder: (context) => [
																PopupMenuItem(value: 'options', child: Text('Options')),
															],
														),
														onTap: () => _showDetails(mismatch),
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
				icon: Icon(Icons.error_outline),
				label: Text('Add Mismatch'),
				onPressed: () {
					// Simulate adding a mismatch
					setState(() {
						mismatches.insert(0, {
							'id': 'M${mismatches.length + 1}'.padLeft(4, '0'),
							'type': 'Qty',
							'desc': 'Dummy mismatch added',
							'resolved': false,
						});
					});
					ScaffoldMessenger.of(context).showSnackBar(
						SnackBar(content: Text('Dummy mismatch added')),
					);
				},
			),
		);
	}
}
