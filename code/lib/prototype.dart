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
          ],
        ),
      ),
    );
  }
}
