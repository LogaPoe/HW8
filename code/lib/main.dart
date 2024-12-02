import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TaskScreen(),
    );
  }
}

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskTagsController = TextEditingController();
  final TextEditingController _dateInputController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  Future<void> addTask() async {
    final startTime = _startTimeController.text;
    final endTime = _endTimeController.text;
    final taskName = _taskNameController.text;
    final tags = _taskTagsController.text;
    final date = _dateInputController.text;

    if (taskName.isEmpty || tags.isEmpty || date.isEmpty || startTime.isEmpty || endTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('tasks').add({
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'task': taskName,
        'tags': tags,
      });

      _taskNameController.clear();
      _taskTagsController.clear();
      _dateInputController.clear();
      _startTimeController.clear();
      _endTimeController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding task: $e')),
      );
    }
  }

  Future<void> showSearchDialog() async {
    final TextEditingController searchTagController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Tasks by Tag'),
          content: TextField(
            controller: searchTagController,
            decoration: const InputDecoration(labelText: 'Enter Tag'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(searchTagController.text);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    ).then((tag) async {
      if (tag != null && tag.isNotEmpty) {
        await searchTasks(tag);
      }
    });
  }

  Future<void> searchTasks(String searchTag) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('tags', isEqualTo: searchTag)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tasks found with this tag')),
        );
        return;
      }

      showResultsDialog(querySnapshot.docs);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching tasks: $e')),
      );
    }
  }

  Future<void> showResultsDialog(List<QueryDocumentSnapshot> docs) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Results'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                return ListTile(
                  title: Text(doc['task']),
                  subtitle: Text(
                      'Date: ${doc['date']}\nStart: ${doc['startTime']} - End: ${doc['endTime']}'),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> showReportDialog() async {
    final TextEditingController startDateController = TextEditingController();
    final TextEditingController endDateController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Generate Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: startDateController,
                decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM-DD)'),
              ),
              TextField(
                controller: endDateController,
                decoration: const InputDecoration(labelText: 'End Date (YYYY-MM-DD)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'startDate': startDateController.text,
                  'endDate': endDateController.text,
                });
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    ).then((dates) async {
      if (dates != null &&
          dates['startDate'].isNotEmpty &&
          dates['endDate'].isNotEmpty) {
        final startDate = DateTime.tryParse(dates['startDate']);
        final endDate = DateTime.tryParse(dates['endDate']);

        if (startDate == null || endDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid date format')),
          );
          return;
        }

        await generateReport(startDate, endDate);
      }
    });
  }

  Future<void> generateReport(DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tasks found in this date range')),
        );
        return;
      }

      showResultsDialog(querySnapshot.docs);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Tracker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _taskNameController,
              decoration: const InputDecoration(labelText: 'Task Name'),
            ),
            TextField(
              controller: _taskTagsController,
              decoration: const InputDecoration(labelText: 'Tags'),
            ),
            TextField(
              controller: _dateInputController,
              decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
            ),
            TextField(
              controller: _startTimeController,
              decoration: const InputDecoration(labelText: 'Start Time (HH:mm)'),
            ),
            TextField(
              controller: _endTimeController,
              decoration: const InputDecoration(labelText: 'End Time (HH:mm)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: addTask,
              child: const Text('Add Task'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: showSearchDialog,
              child: const Text('Search Tasks by Tag'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: showReportDialog,
              child: const Text('Generate Report'),
            ),
          ],
        ),
      ),
    );
  }
}







