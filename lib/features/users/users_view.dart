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
    await UsersService().updateSubscription(user.id, user.subscription);
  }

  setState(() {
    _isEditing = false;
    _usersFuture = UsersService().fetchUsers(); // обновим список
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
        ),
        extendBodyBehindAppBar: true,
        body: Container(
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
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: FutureBuilder<List<User>>(
                    future: _usersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(color: Colors.white));
                      } else if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Ошибка при загрузке данных',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      } else {
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _users.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Colors.white24),
                          itemBuilder: (context, index) {
                            final user = _users[index];

                            return ListTile(
                              title: Text('${user.name} ${user.last_name}',
                                  style: const TextStyle(color: Colors.white)),
                              subtitle: Text(user.email,
                                  style: const TextStyle(color: Colors.white70)),
                              trailing: _isEditing
                            ? Theme(
                                data: ThemeData(
                                  unselectedWidgetColor: Colors.white,
                                ),
                                child: Checkbox(
                                  value: user.subscription,
                                  activeColor: Colors.white,
                                  checkColor: Colors.black,
                                  side: const BorderSide(color: Colors.white, width: 2),
                                  onChanged: (value) {
                                    setState(() {
                                      user.subscription = value ?? false;
                                    });
                                  },
                                ),
                              )
                            : Icon(
                                user.subscription ? Icons.check_circle : Icons.cancel,
                                color: user.subscription ? Colors.green : Colors.red,
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  child: ElevatedButton(
                    onPressed: _isEditing ? _saveChanges : _toggleEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _isEditing ? 'Сохранить' : 'Изменить',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
}
