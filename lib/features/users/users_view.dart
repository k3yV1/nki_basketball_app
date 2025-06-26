import 'package:flutter/material.dart';
import 'package:nki_basketball/services/users/users_service.dart';

class UsersView extends StatefulWidget {
  const UsersView({Key? key}) : super(key: key);

  @override
  _UsersViewState createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  late Future<List<User>> _usersFuture;
  bool _isEditing = false;
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _usersFuture = UsersService().fetchUsers().then((users) {
      _users = List<User>.from(users);
      return _users;
    });
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveChanges() async {
    for (final user in _users) {
      await UsersService().updateSubscription(user.id, user.is_paid);
    }

    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Изменения сохранены')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _isEditing ? _saveChanges : _toggleEdit,
            child: Text(
              _isEditing ? 'Сохранить' : 'Изменить',
              style: const TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff2c5364),
              Color(0xff203e43),
              Color(0xff0f2027),
            ],
          ),
        ),
        child: FutureBuilder<List<User>>(
          future: _usersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            } else if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Ошибка при загрузке данных',
                  style: TextStyle(color: Colors.white),
                ),
              );
            } else {
              return ListView.builder(
                itemCount: _users.length,
                padding: const EdgeInsets.only(top: kToolbarHeight + 32, bottom: 40),
                itemBuilder: (context, index) {
                  final user = _users[index];

                  return ListTile(
                    title: Text('${user.name} ${user.last_name}', style: const TextStyle(color: Colors.white)),
                    subtitle: Text(user.email, style: const TextStyle(color: Colors.white70)),
                    trailing: _isEditing
                        ? Checkbox(
                            value: user.is_paid,
                            onChanged: (value) {
                              setState(() {
                                user.is_paid = value ?? false;
                              });
                            },
                          )
                        : Icon(
                            user.is_paid ? Icons.check_circle : Icons.cancel,
                            color: user.is_paid ? Colors.green : Colors.red,
                          ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
