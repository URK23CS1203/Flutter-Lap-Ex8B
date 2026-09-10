import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'database_helper.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SQLite initialization for Windows
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Firebase initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SQLite + Firebase Student App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const StudentPage(),
    );
  }
}

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController courseController = TextEditingController();

  // SQLite data
  List<Map<String, dynamic>> students = [];

  // Firebase data
  List<Map<String, dynamic>> firebaseStudents = [];

  @override
  void initState() {
    super.initState();

    loadStudents();
    loadFirebaseStudents();
  }

  // ============================================================
  // SQLITE - READ
  // ============================================================

  Future<void> loadStudents() async {
    final data = await DatabaseHelper.instance.getStudents();

    if (!mounted) return;

    setState(() {
      students = data;
    });
  }

  // ============================================================
  // FIREBASE - READ
  // ============================================================

  Future<void> loadFirebaseStudents() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('students')
          .get();

      final data = snapshot.docs.map((doc) {
        final student = doc.data();

        return {
          'id': doc.id,
          'name': student['name'] ?? '',
          'course': student['course'] ?? '',
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        firebaseStudents = data;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase read error: $e'),
        ),
      );
    }
  }

  // ============================================================
  // CREATE - SQLITE + FIREBASE
  // ============================================================

  Future<void> addStudent() async {
    final name = nameController.text.trim();
    final course = courseController.text.trim();

    if (name.isEmpty || course.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter student name and course'),
        ),
      );
      return;
    }

    try {
      // Insert into SQLite
      await DatabaseHelper.instance.insertStudent(
        name,
        course,
      );

      // Insert into Firebase Firestore
      await FirebaseFirestore.instance
          .collection('students')
          .add({
        'name': name,
        'course': course,
      });

      // Clear fields
      nameController.clear();
      courseController.clear();

      // Refresh both lists
      await loadStudents();
      await loadFirebaseStudents();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Student added to SQLite and Firebase successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  // ============================================================
  // SQLITE - UPDATE
  // ============================================================

  Future<void> editStudent(Map<String, dynamic> student) async {
    nameController.text = student['name'];
    courseController.text = student['course'];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update Student'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: courseController,
                decoration: const InputDecoration(
                  labelText: 'Course',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final course = courseController.text.trim();

                if (name.isEmpty || course.isEmpty) {
                  return;
                }

                await DatabaseHelper.instance.updateStudent(
                  student['id'],
                  name,
                  course,
                );

                nameController.clear();
                courseController.clear();

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                await loadStudents();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SQLITE - DELETE
  // ============================================================

  Future<void> deleteStudent(int id) async {
    await DatabaseHelper.instance.deleteStudent(id);
    await loadStudents();
  }

  @override
  void dispose() {
    nameController.dispose();
    courseController.dispose();
    super.dispose();
  }

  // ============================================================
  // USER INTERFACE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SQLite + Firebase Student App'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==================================================
            // INPUT
            // ==================================================

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Student Name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: courseController,
              decoration: const InputDecoration(
                labelText: 'Course',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: addStudent,
              child: const Text('Add Student'),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // SQLITE SECTION
            // ==================================================

            const Text(
              'SQLite - Local Storage',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (students.isEmpty)
              const Text('No SQLite students found.')
            else
              ...students.map(
                (student) {
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          student['id'].toString(),
                        ),
                      ),
                      title: Text(
                        student['name'],
                      ),
                      subtitle: Text(
                        student['course'],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              editStudent(student);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              deleteStudent(student['id']);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 20),

            const Divider(),

            const SizedBox(height: 20),

            // ==================================================
            // FIREBASE SECTION
            // ==================================================

            const Text(
              'Firebase - Cloud Storage',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (firebaseStudents.isEmpty)
              const Text('No Firebase students found.')
            else
              ...firebaseStudents.map(
                (student) {
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.cloud),
                      ),
                      title: Text(
                        student['name'],
                      ),
                      subtitle: Text(
                        student['course'],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: loadFirebaseStudents,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Firebase Data'),
            ),
          ],
        ),
      ),
    );
  }
}