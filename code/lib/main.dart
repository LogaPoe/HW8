import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ActivityManagerApp());
}

class ActivityManagerApp extends StatelessWidget {
  const ActivityManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Activity Organizer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ActivityDashboard(title: 'Activity Organizer'),
    );
  }
}

class ActivityDashboard extends StatefulWidget {
  const ActivityDashboard({super.key, required this.title});
  final String title;

  @override
  State<ActivityDashboard> createState() => _ActivityDashboardState();
}

class _ActivityDashboardState extends State<ActivityDashboard> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final TextEditingController _activityNameController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  final TextEditingController _searchDateController = TextEditingController();
  final TextEditingController _searchTagController = TextEditingController();
  final TextEditingController _searchNameController = TextEditingController();

  String _feedbackMessage = '';

  Future<void> _createActivity() async {
    try {
      await FirebaseFirestore.instance.collection('activities').add({
        'date': _dateController.text,
        'startTime': _startController.text,
        'endTime': _endController.text,
        'name': _activityNameController.text,
        'tags': _tagsController.text,
      });

      setState(() {
        _feedbackMessage = 'Activity added: ${_activityNameController.text}';
      });
    } catch (e) {
      setState(() {
        _feedbackMessage = 'Error adding activity: $e';
      });
    }
  }

  Future<void> _listActivities() async {
    try {
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('activities').get();
      List<QueryDocumentSnapshot> activities = snapshot.docs;

      _showActivityDialog(activities);
    } catch (e) {
      setState(() {
        _feedbackMessage = 'Unable to retrieve activities: $e';
      });
    }
  }

  void _showActivityDialog(List<QueryDocumentSnapshot> activities) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('All Activities'),
          content: SingleChildScrollView(
            child: ListBody(
              children: activities.map((activity) {
                Map<String, dynamic> data = activity.data() as Map<String, dynamic>;
                String activityId = activity.id;

                return ListTile(
                  title: Text(data['name'] ?? 'Unnamed Activity'),
                  subtitle: Text(
                    '${data['date']} from ${data['startTime']} to ${data['endTime']} [Tags: ${data['tags']}]',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _deleteActivity(activityId);
                      Navigator.of(context).pop();
                      _listActivities();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteActivity(String activityId) async {
    try {
      await FirebaseFirestore.instance.collection('activities').doc(activityId).delete();
      setState(() {
        _feedbackMessage = 'Successfully Deleted';
      });
    } catch (e) {
      setState(() {
        _feedbackMessage = 'Unable to delete activity: $e';
      });
    }
  }

  Future<void> _searchActivities() async {
    try {
      Query query = FirebaseFirestore.instance.collection('activities');

      if (_searchDateController.text.isNotEmpty) {
        query = query.where('date', isEqualTo: _searchDateController.text);
      }
      if (_searchTagController.text.isNotEmpty) {
        List<String> tags = _searchTagController.text.split(',').map((tag) => tag.trim()).toList();
        query = query.where('tags', arrayContainsAny: tags);
      }
      if (_searchNameController.text.isNotEmpty) {
        query = query.where('name', isEqualTo: _searchNameController.text);
      }

      QuerySnapshot snapshot = await query.get();
      _showSearchResults(snapshot.docs);
    } catch (e) {
      setState(() {
        _feedbackMessage = 'Unable to search activities: $e';
      });
    }
  }

  void _showSearchResults(List<QueryDocumentSnapshot> results) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Search Results'),
          content: SingleChildScrollView(
            child: ListBody(
              children: results.map((result) {
                Map<String, dynamic> data = result.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(data['name'] ?? 'Unnamed Activity'),
                  subtitle: Text(
                    '${data['date']} from ${data['startTime']} to ${data['endTime']} [Tags: ${data['tags']}]',
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
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
        centerTitle: true,
        title: Text(widget.title),
    backgroundColor: Theme.of(context).colorScheme.primary,
    ),
    body: Center(
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    ElevatedButton(
    onPressed: _listActivities,
    child: const Text('Show All Activities'),
    ),
    const SizedBox(height: 20),
    ElevatedButton(
    onPressed: _createActivity,
    child: const Text('Add Activity'),
    ),
    const SizedBox(height: 20),
    ElevatedButton(
    onPressed: _searchActivities,
    child: const Text('Search Activities'),
    ),
    const SizedBox(height: 20),
    Text(_feedbackMessage),
    ],
    ),
    ),
    );
  }
}



