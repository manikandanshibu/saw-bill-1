import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'edit_tree.dart';
import 'widgets/powered_by_banner.dart';

class TreeDetails extends StatefulWidget {
  const TreeDetails({super.key});

  @override
  State<TreeDetails> createState() => _TreeDetailsState();
}

class _TreeDetailsState extends State<TreeDetails> {
  final _treeIdController = TextEditingController();
  final _treeMeasurementController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _searchType = 'treeId'; // Default search type

  Future<void> _submitTreeData() async {
    // Add validation check
    if (_treeIdController.text.isEmpty ||
        _treeMeasurementController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Both Tree ID and Tree Measurement are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Check if tree ID already exists
      final existingTreeQuery = await FirebaseFirestore.instance
          .collection('trees')
          .where('treeId', isEqualTo: _treeIdController.text)
          .get();

      if (existingTreeQuery.docs.isNotEmpty) {
        // Show confirmation dialog if tree ID exists
        final shouldProceed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            int secondsRemaining = 3;
            bool canProceed = false;

            return StatefulBuilder(
              builder: (context, setState) {
                if (!canProceed) {
                  Future.delayed(const Duration(seconds: 1), () {
                    if (!canProceed && context.mounted) {
                      setState(() {
                        secondsRemaining--;
                        if (secondsRemaining == 0) {
                          canProceed = true;
                        }
                      });
                    }
                  });
                }

                return AlertDialog(
                  title: const Text('Duplicate Tree ID'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Tree ID "${_treeIdController.text}" already exists.'),
                      const SizedBox(height: 8),
                      const Text(
                          'Are you sure you want to add another tree with the same ID?'),
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: canProceed
                          ? () {
                              Navigator.of(context).pop(true);
                            }
                          : null,
                      child: Text(canProceed
                          ? 'Proceed'
                          : 'Proceed ($secondsRemaining)'),
                    ),
                  ],
                );
              },
            );
          },
        );

        if (shouldProceed != true) {
          return;
        }
      }

      // Proceed with saving the tree data
      await FirebaseFirestore.instance.collection('trees').add({
        'treeId': _treeIdController.text,
        'treeMeasurement': _treeMeasurementController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear text fields after successful submission
      _treeIdController.clear();
      _treeMeasurementController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tree details saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving tree details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, String docId, String treeId) async {
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
              content:
                  Text('Are you sure you want to delete Tree ID: $treeId?'),
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
                              .collection('trees')
                              .doc(docId)
                              .delete();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tree deleted')),
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

  Widget _buildTreeStatus(String treeId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bills')
          .where('treeId', isEqualTo: treeId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error checking status');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Checking...');
        }

        bool isSold = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSold
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isSold ? 'Sold' : 'Available',
            style: TextStyle(
              color: isSold ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  void _showBillingDetails(String treeId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Billing Details for Tree ID: $treeId',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300, // Fixed height for the list
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bills')
                        .where('treeId', isEqualTo: treeId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Error loading billing details');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No billing records found for this tree'),
                        );
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final billData = snapshot.data!.docs[index].data()
                              as Map<String, dynamic>;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Customer: ${billData['name']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                      'Customer ID: ${billData['customerId']}'),
                                  Text(
                                      'Phone: ${billData['phoneNumber'] ?? 'N/A'}'),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Amount: \$${billData['amount']?.toString() ?? '0.00'}',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Paid: \$${billData['amountPaid']?.toString() ?? '0.00'}',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (billData['timestamp'] != null)
                                    Text(
                                      'Date: ${_formatDate(billData['timestamp'])}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
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
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tree Details'),
      ),
      body: Column(
        children: [
          // Add Search Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText:
                        'Search ${_searchType == 'treeId' ? 'by Tree ID' : 'by Size'}',
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
                      label: const Text('Search by ID'),
                      selected: _searchType == 'treeId',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _searchType = 'treeId';
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Search by Size'),
                      selected: _searchType == 'treeMeasurement',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _searchType = 'treeMeasurement';
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Existing Add Tree Form
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitTreeData,
                  child: const Text('Save Tree Details'),
                ),
              ],
            ),
          ),

          // Modified Tree List with Search
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('trees')
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
                  return const Center(child: Text('No trees found'));
                }

                var docs = snapshot.data!.docs;

                // Filter the documents based on search query
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final fieldValue =
                        data[_searchType]?.toString().toLowerCase() ?? '';
                    return fieldValue.startsWith(_searchQuery.toLowerCase());
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(child: Text('No matching trees found'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: InkWell(
                        onTap: () => _showBillingDetails(data['treeId']),
                        child: ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text('Tree ID: ${data['treeId']}'),
                              ),
                              _buildTreeStatus(data['treeId']),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Measurement: ${data['treeMeasurement']}'),
                              if (data['timestamp'] != null)
                                Text(
                                  'Added: ${_formatDate(data['timestamp'])}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditTree(
                                        documentId: doc.id,
                                        treeData: data,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _showDeleteConfirmation(
                                    context,
                                    doc.id,
                                    data['treeId'] ?? 'this tree',
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

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _treeIdController.dispose();
    _treeMeasurementController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
