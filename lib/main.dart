import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bills_view.dart';
import 'tree_details.dart';
import 'customer_details.dart';
import 'home.dart';
import 'widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for web
  await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: "AIzaSyDOaPXq5z4QE5IFyusu1GIsYmDY-107igw",
        authDomain: "saw-bill.firebaseapp.com",
        projectId: "saw-bill",
        storageBucket: "saw-bill.firebasestorage.app",
        messagingSenderId: "1068280424749",
        appId: "1:1068280424749:web:25f84996f3c61154008ba4",
        measurementId: "G-Y54K9RRP36"),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saw Mill Management',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: FutureBuilder(
        future: Future.delayed(const Duration(seconds: 2)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          return const HomePage();
        },
      ),
    );
  }
}

class BillingForm extends StatefulWidget {
  const BillingForm({super.key});

  @override
  _BillingFormState createState() => _BillingFormState();
}

class _BillingFormState extends State<BillingForm> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _customerIdController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _treeIdController = TextEditingController();
  final _treeMeasurementController = TextEditingController();
  final _treeQuantityController = TextEditingController();
  final _amountPaidController = TextEditingController();

  Future<bool> _isCustomerIdUnique(String customerId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('customers')
        .where('customerId', isEqualTo: customerId)
        .get();
    return querySnapshot.docs.isEmpty;
  }

  Future<bool> _showDuplicateCustomerWarning(
      Map<String, dynamic> existingCustomer) async {
    int secondsRemaining = 3;
    bool canProceed = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (!canProceed) {
              Future.delayed(const Duration(seconds: 1), () {
                if (secondsRemaining > 0) {
                  setState(() {
                    secondsRemaining--;
                  });
                  if (secondsRemaining == 0) {
                    setState(() {
                      canProceed = true;
                    });
                  }
                }
              });
            }

            return AlertDialog(
              title: const Text('Customer ID Already Exists'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('A customer with this ID already exists:'),
                  const SizedBox(height: 8),
                  Text('Name: ${existingCustomer['name']}'),
                  Text('Phone: ${existingCustomer['phoneNumber'] ?? 'N/A'}'),
                  const SizedBox(height: 16),
                  const Text('Do you want to proceed with the bill?'),
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
                  child: Text(canProceed ? 'OK' : 'OK ($secondsRemaining)'),
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? false;
  }

  Future<void> _submitData() async {
    if (_customerIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer ID is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Check for existing customer
      final customersQuery = await FirebaseFirestore.instance
          .collection('customers')
          .where('customerId', isEqualTo: _customerIdController.text)
          .get();

      if (customersQuery.docs.isNotEmpty) {
        final existingCustomer = customersQuery.docs.first.data();

        // Only show warning if names don't match
        if (existingCustomer['name'] != _nameController.text) {
          // Show warning dialog if customer exists with different name
          final shouldProceed =
              await _showDuplicateCustomerWarning(existingCustomer);

          if (!shouldProceed) {
            return; // User cancelled the operation
          }
        }

        // Update existing customer
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(customersQuery.docs.first.id)
            .update({
          'name': _nameController.text,
          'phoneNumber': _phoneNumberController.text,
        });
      } else {
        // Add new customer
        await FirebaseFirestore.instance.collection('customers').add({
          'customerId': _customerIdController.text,
          'name': _nameController.text,
          'phoneNumber': _phoneNumberController.text,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Handle tree details
      final treesQuery = await FirebaseFirestore.instance
          .collection('trees')
          .where('treeId', isEqualTo: _treeIdController.text)
          .get();

      if (treesQuery.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('trees').add({
          'treeId': _treeIdController.text,
          'treeMeasurement': _treeMeasurementController.text,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('trees')
            .doc(treesQuery.docs.first.id)
            .update({
          'treeMeasurement': _treeMeasurementController.text,
        });
      }

      // Add the bill
      await FirebaseFirestore.instance.collection('bills').add({
        'name': _nameController.text,
        'amount': double.parse(_amountController.text),
        'amountPaid': _amountPaidController.text.isEmpty
            ? 0.0
            : double.parse(_amountPaidController.text),
        'customerId': _customerIdController.text,
        'phoneNumber': _phoneNumberController.text,
        'treeId': _treeIdController.text,
        'treeMeasurement': _treeMeasurementController.text,
        'treeQuantity': _treeQuantityController.text.isEmpty
            ? 1
            : int.parse(_treeQuantityController.text),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear all text fields after successful submission
      _nameController.clear();
      _amountController.clear();
      _amountPaidController.clear();
      _customerIdController.clear();
      _phoneNumberController.clear();
      _treeIdController.clear();
      _treeMeasurementController.clear();
      _treeQuantityController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill data saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
        );
      }
    }
  }

  void _searchCustomer(String customerId) {
    if (customerId.isEmpty) {
      _nameController.clear();
      _phoneNumberController.clear();
      return;
    }

    // First, search in customers collection
    FirebaseFirestore.instance
        .collection('customers')
        .where('customerId', isGreaterThanOrEqualTo: customerId)
        .where('customerId', isLessThanOrEqualTo: '$customerId\uf8ff')
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        // Get the first matching customer's details
        final customerData = querySnapshot.docs.first.data();
        setState(() {
          _nameController.text = customerData['name'] ?? '';
          _phoneNumberController.text = customerData['phoneNumber'] ?? '';
        });
      } else {
        // If not found in customers collection, search in bills collection
        FirebaseFirestore.instance
            .collection('bills')
            .where('customerId', isGreaterThanOrEqualTo: customerId)
            .where('customerId', isLessThanOrEqualTo: '$customerId\uf8ff')
            .get()
            .then((billsSnapshot) {
          if (billsSnapshot.docs.isNotEmpty) {
            // Get the first matching customer's details from bills
            final billData = billsSnapshot.docs.first.data();
            setState(() {
              _nameController.text = billData['name'] ?? '';
              _phoneNumberController.text = billData['phoneNumber'] ?? '';
            });
          }
        });
      }
    });
  }

  void _searchTree(String treeId) {
    if (treeId.isEmpty) {
      _treeMeasurementController.clear();
      return;
    }

    // Query Firestore for matching tree IDs from trees collection
    FirebaseFirestore.instance
        .collection('trees')
        .where('treeId', isGreaterThanOrEqualTo: treeId)
        .where('treeId', isLessThanOrEqualTo: '$treeId\uf8ff')
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        // Get the first matching tree's details
        final treeData = querySnapshot.docs.first.data();
        setState(() {
          _treeMeasurementController.text = treeData['treeMeasurement'] ?? '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing Form'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CustomerDetails()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.forest),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TreeDetails()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BillsView()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _customerIdController,
              decoration: const InputDecoration(
                labelText: 'Customer ID',
                border: OutlineInputBorder(),
              ),
              onChanged: _searchCustomer,
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
              onChanged: _searchTree,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _submitData,
                  child: const Text('Submit'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const BillsView()),
                    );
                  },
                  child: const Text('View Bills'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _amountPaidController.dispose();
    _customerIdController.dispose();
    _phoneNumberController.dispose();
    _treeIdController.dispose();
    _treeMeasurementController.dispose();
    _treeQuantityController.dispose();
    super.dispose();
  }
}
