import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'widgets/powered_by_banner.dart';

class CustomerDetails extends StatefulWidget {
  const CustomerDetails({super.key});

  @override
  State<CustomerDetails> createState() => _CustomerDetailsState();
}

class _CustomerDetailsState extends State<CustomerDetails> {
  final _customerIdController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _searchType = 'name'; // Default search type

  Future<bool> _isCustomerIdUnique(String customerId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('customers')
        .where('customerId', isEqualTo: customerId)
        .get();
    return querySnapshot.docs.isEmpty;
  }

  Future<void> _submitCustomerData() async {
    if (_customerIdController.text.isEmpty ||
        _customerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer ID and Name are required')),
      );
      return;
    }

    try {
      // Check if customer ID is unique
      final isUnique = await _isCustomerIdUnique(_customerIdController.text);

      if (!isUnique) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Error: Customer ID already exists. Please use a unique ID.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await FirebaseFirestore.instance.collection('customers').add({
        'customerId': _customerIdController.text,
        'name': _customerNameController.text,
        'phoneNumber': _phoneNumberController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear text fields after successful submission
      _customerIdController.clear();
      _customerNameController.clear();
      _phoneNumberController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer details saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving customer details: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, String docId, String customerName) async {
    int secondsRemaining = 3;
    bool canDelete = false;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (!canDelete) {
              Future.delayed(const Duration(seconds: 1), () {
                if (!canDelete && context.mounted) {
                  // Check if still mounted
                  setState(() {
                    secondsRemaining--;
                    if (secondsRemaining == 0) {
                      canDelete = true;
                    }
                  });
                }
              });
            }

            return AlertDialog(
              title: const Text('Confirm Delete'),
              content: Text('Are you sure you want to delete $customerName?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: canDelete
                      ? () async {
                          await FirebaseFirestore.instance
                              .collection('customers')
                              .doc(docId)
                              .delete();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Customer deleted')),
                            );
                          }
                        }
                      : null,
                  child: Text(canDelete ? 'OK' : 'OK ($secondsRemaining)'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCustomerPaymentInfo(String customerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bills')
          .where('customerId', isEqualTo: customerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('Unable to load payment info');
        }

        double totalAmount = 0;
        double totalPaid = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalAmount += (data['amount'] ?? 0).toDouble();
          totalPaid += (data['amountPaid'] ?? 0).toDouble();
        }

        double remainingAmount = totalAmount - totalPaid;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Amount: ₹${totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Paid: ₹${totalPaid.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Remaining: ₹${remainingAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
      ),
      body: Column(
        children: [
          // Search Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText:
                        'Search ${_searchType == 'name' ? 'by name' : 'by customer ID'}',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Search by Name'),
                      selected: _searchType == 'name',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _searchType = 'name';
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Search by ID'),
                      selected: _searchType == 'customerId',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _searchType = 'customerId';
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Add Customer Form
          Padding(
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
                  controller: _customerNameController,
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitCustomerData,
                  child: const Text('Save Customer Details'),
                ),
              ],
            ),
          ),

          // Customer List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('customers')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No customers found'));
                }

                var docs = snapshot.data!.docs;

                // Filter the documents based on search query
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final fieldValue =
                        data[_searchType]?.toString().toLowerCase() ?? '';
                    return fieldValue.contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(
                      child: Text('No matching customers found'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Text(
                                '${data['name']} (ID: ${data['customerId']})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Phone: ${data['phoneNumber'] ?? 'N/A'}'),
                                  const SizedBox(height: 8),
                                  _buildCustomerPaymentInfo(data['customerId']),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _showDeleteConfirmation(
                                    context,
                                    doc.id,
                                    data['name'] ?? 'this customer',
                                  );
                                },
                              ),
                              isThreeLine: true,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const PoweredByBanner(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    _customerNameController.dispose();
    _phoneNumberController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
