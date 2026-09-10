class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  DatabaseHelper._privateConstructor();

  Future<List<Map<String, dynamic>>> getStudents() async {
    return [];
  }

  Future<int> insertStudent(String name, String course) async {
    return 0;
  }

  Future<int> updateStudent(int id, String name, String course) async {
    return 0;
  }

  Future<int> deleteStudent(int id) async {
    return 0;
  }
}

void initializeSQLite() {}
