import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/powered_by_banner.dart';

class EditBill extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> billData;

  const EditBill({
    super.key,
    required this.documentId,
    required this.billData,
  });

  @override
  State<EditBill> createState() => _EditBillState();
}

class _EditBillState extends State<EditBill> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _customerIdController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _treeIdController;
  late TextEditingController _treeMeasurementController;
  late TextEditingController _treeQuantityController;
  late TextEditingController _amountPaidController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.billData['name']);
    _amountController =
        TextEditingController(text: widget.billData['amount'].toString());
    _customerIdController =
        TextEditingController(text: widget.billData['customerId']);
    _phoneNumberController =
        TextEditingController(text: widget.billData['phoneNumber']);
    _treeIdController = TextEditingController(text: widget.billData['treeId']);
    _treeMeasurementController =
        TextEditingController(text: widget.billData['treeMeasurement']);
    _treeQuantityController = TextEditingController(
        text: widget.billData['treeQuantity']?.toString() ?? '1');
    _amountPaidController = TextEditingController(
        text: widget.billData['amountPaid']?.toString() ?? '0.0');
  }

  Future<void> _updateBill() async {
    try {
      await FirebaseFirestore.instance
          .collection('bills')
          .doc(widget.documentId)
          .update({
        'name': _nameController.text,
        'amount': double.parse(_amountController.text),
        'customerId': _customerIdController.text,
        'phoneNumber': _phoneNumberController.text,
        'treeId': _treeIdController.text,
        'treeMeasurement': _treeMeasurementController.text,
        'treeQuantity': _treeQuantityController.text.isEmpty
            ? 1
            : int.parse(_treeQuantityController.text),
        'amountPaid': _amountPaidController.text.isEmpty
            ? 0.0
            : double.parse(_amountPaidController.text),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating bill: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Bill'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _customerIdController,
                    decoration: const InputDecoration(
                      labelText: 'Customer ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _treeIdController,
                    decoration: const InputDecoration(
                      labelText: 'Tree ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _treeMeasurementController,
                    decoration: const InputDecoration(
                      labelText: 'Tree Measurement',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _treeQuantityController,
                    decoration: const InputDecoration(
                      labelText: 'Tree Quantity (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Total Amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountPaidController,
                    decoration: const InputDecoration(
                      labelText: 'Amount Paid',
                      border: OutlineInputBorder(),
                      hintText: 'Leave empty if no payment made',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _updateBill,
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ),
          const PoweredByBanner(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _customerIdController.dispose();
    _phoneNumberController.dispose();
    _treeIdController.dispose();
    _treeMeasurementController.dispose();
    _treeQuantityController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }
}
