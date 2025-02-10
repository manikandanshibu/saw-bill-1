import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTree extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> treeData;

  const EditTree({
    super.key,
    required this.documentId,
    required this.treeData,
  });

  @override
  State<EditTree> createState() => _EditTreeState();
}

class _EditTreeState extends State<EditTree> {
  late TextEditingController _treeIdController;
  late TextEditingController _treeMeasurementController;

  @override
  void initState() {
    super.initState();
    _treeIdController = TextEditingController(text: widget.treeData['treeId']);
    _treeMeasurementController =
        TextEditingController(text: widget.treeData['treeMeasurement']);
  }

  Future<void> _updateTree() async {
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
      // Check for duplicate tree ID if ID was changed
      if (_treeIdController.text != widget.treeData['treeId']) {
        final existingTreeQuery = await FirebaseFirestore.instance
            .collection('trees')
            .where('treeId', isEqualTo: _treeIdController.text)
            .get();

        if (existingTreeQuery.docs.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This Tree ID already exists'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      await FirebaseFirestore.instance
          .collection('trees')
          .doc(widget.documentId)
          .update({
        'treeId': _treeIdController.text,
        'treeMeasurement': _treeMeasurementController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tree details updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating tree details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Tree'),
      ),
      body: Padding(
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
              onPressed: _updateTree,
              child: const Text('Update Tree Details'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _treeIdController.dispose();
    _treeMeasurementController.dispose();
    super.dispose();
  }
}
