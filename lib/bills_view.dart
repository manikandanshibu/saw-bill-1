import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_bill.dart';
import 'widgets/powered_by_banner.dart';

class BillsView extends StatefulWidget {
  const BillsView({super.key});

  @override
  State<BillsView> createState() => _BillsViewState();
}

class _BillsViewState extends State<BillsView> {
  String _searchQuery = '';
  String _searchType = 'name'; // Default search type
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _searchType = 'date';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills List'),
      ),
      body: Column(
        children: [
          // Search Bar with Type Selection
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText:
                        'Search ${_searchType == 'date' ? 'by date' : 'by $_searchType'}',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchController.text.isNotEmpty ||
                            _selectedDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedDate = null;
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ChoiceChip(
                        label: const Text('Name'),
                        selected: _searchType == 'name',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _searchType = 'name';
                              _selectedDate = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Customer ID'),
                        selected: _searchType == 'customerId',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _searchType = 'customerId';
                              _selectedDate = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Tree ID'),
                        selected: _searchType == 'treeId',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _searchType = 'treeId';
                              _selectedDate = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(_selectedDate == null
                            ? 'Date'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                        selected: _searchType == 'date',
                        onSelected: (selected) {
                          if (selected) {
                            _selectDate(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bills List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bills')
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
                  return const Center(child: Text('No bills found'));
                }

                // Filter the documents based on search query and type
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  if (_searchQuery.isEmpty && _selectedDate == null) {
                    return true;
                  }

                  if (_searchType == 'date' && _selectedDate != null) {
                    final timestamp = data['timestamp'] as Timestamp?;
                    if (timestamp == null) return false;
                    final billDate = timestamp.toDate();
                    return billDate.year == _selectedDate!.year &&
                        billDate.month == _selectedDate!.month &&
                        billDate.day == _selectedDate!.day;
                  }

                  final fieldValue =
                      data[_searchType]?.toString().toLowerCase() ?? '';
                  return fieldValue.contains(_searchQuery.toLowerCase());
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No matching bills found'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Dismissible(
                      key: Key(doc.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        FirebaseFirestore.instance
                            .collection('bills')
                            .doc(doc.id)
                            .delete();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Bill deleted'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .collection('bills')
                                    .doc(doc.id)
                                    .set(data);
                              },
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(data['name'] ?? 'No name'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Total Amount: ₹${data['amount']?.toString() ?? '0.00'}'),
                              Text(
                                  'Amount Paid: ₹${data['amountPaid']?.toString() ?? '0.00'}'),
                              Text(
                                  'Balance: ₹${(data['amount'] ?? 0.0) - (data['amountPaid'] ?? 0.0)}'),
                              Text(
                                  'Customer ID: ${data['customerId'] ?? 'N/A'}'),
                              Text('Tree ID: ${data['treeId'] ?? 'N/A'}'),
                              Text(
                                  'Tree Quantity: ${data['treeQuantity']?.toString() ?? '1'}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                data['timestamp'] != null
                                    ? _formatDate(data['timestamp'])
                                    : 'No date',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditBill(
                                        documentId: doc.id,
                                        billData: data,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          isThreeLine: true,
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

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'No date';

    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    return 'Invalid date';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
