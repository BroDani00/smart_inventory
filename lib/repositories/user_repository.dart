import '../database/database_helper.dart';
import '../models/user_model.dart';

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Save user (insert)
  Future<int> saveUser(User user) async {
    final db = await _dbHelper.database;
    return await db.insert('users', user.toMap());
  }

  // Update user
  Future<int> updateUser(User user) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Get user (hanya 1 user)
  Future<User?> getUser() async {
    final db = await _dbHelper.database;
    final result = await db.query('users', limit: 1);
    
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  // Check if user exists
  Future<bool> isUserExists() async {
    final user = await getUser();
    return user != null;
  }

  // Delete user (untuk reset)
  Future<int> deleteUser() async {
    final db = await _dbHelper.database;
    return await db.delete('users');
  }
}