import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'Contact.dart';

class DatabaseHelper {
  static final DatabaseHelper _databaseHelper = DatabaseHelper._();

  DatabaseHelper._();

  late Database db;

  factory DatabaseHelper() {
    return _databaseHelper;
  }

  Future<void> initDB() async {
    String path = await getDatabasesPath();
    db = await openDatabase(
      join(path, 'contact.db'),
      onCreate: (database, version) async {
        await database.execute(
          """
            CREATE TABLE contact (
              id INTEGER PRIMARY KEY AUTOINCREMENT, 
              first_name TEXT NOT NULL,
              last_name TEXT NOT NULL,
              company TEXT NOT NULL,
              phone TEXT NOT NULL,
              email TEXT NOT NULL,
              address TEXT NOT NULL,
              birthday TEXT NOT NULL
            )
          """,
        );
      },
      version: 1,
    );
  }

  Future<int> insert(Contact contact) async {
    int result = await db.insert('contact', contact.toMap());
    return result;
  }

  Future<int> update(Contact contact) async {
    int result = await db.update(
      'contact',
      contact.toMap(),
      where: "id = ?",
      whereArgs: [contact.id],
    );
    return result;
  }

  Future<List<Contact>> retrieve() async {
    final List<Map<String, Object?>> queryResult = await db.query('contact');
    return queryResult.map((e) => Contact.fromMap(e)).toList();
  }

  Future<void> delete(int id) async {
    await db.delete(
      'contact',
      where: "id = ?",
      whereArgs: [id],
    );
  }
}
