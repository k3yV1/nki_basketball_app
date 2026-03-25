import 'package:flutter/material.dart';
import 'package:nki_basketball/services/subscriptions/subscriptions_service.dart';
import 'package:nki_basketball/services/users/users_service.dart';

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({Key? key}) : super(key: key);

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  late Future<List<Subscription>> _subscriptionsFuture;
  final UsersService _usersService = UsersService();
  bool _isEditMode = false;
  final Set<int> _selectedUserIds = <int>{};

  @override
  void initState() {
    super.initState();
    _subscriptionsFuture = SubscriptionsService().fetchSubscriptions();
  }

  void _refreshSubscriptions() {
    setState(() {
      _subscriptionsFuture = SubscriptionsService().fetchSubscriptions();
    });
  }

  Future<void> _deactivateSelectedSubscriptions() async {
    if (_selectedUserIds.isEmpty) return;

    try {
      for (final userId in _selectedUserIds) {
        await _usersService.updateSubscription(userId, false);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Деактивировано: ${_selectedUserIds.length}')),
      );

      setState(() {
        _isEditMode = false;
        _selectedUserIds.clear();
      });
      _refreshSubscriptions();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось деактивировать абонементы')),
      );
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _selectedUserIds.clear();
      }
    });
  }

  Future<void> _handleEditAction() async {
    if (!_isEditMode) {
      _toggleEditMode();
      return;
    }

    if (_selectedUserIds.isEmpty) {
      _toggleEditMode();
      return;
    }

    await _deactivateSelectedSubscriptions();
  }

  Future<void> _showAddUserDialog() async {
    try {
      final users = await _usersService.fetchUsers();
      final activeSubscriptions = await SubscriptionsService()
          .fetchSubscriptions();
      final activeUserIds = activeSubscriptions
          .where((sub) => sub.isPaid)
          .map((sub) => sub.user_id)
          .toSet();

      final availableUsers = users
          .where((u) => !u.subscription && !activeUserIds.contains(u.id))
          .toList();

      if (!mounted) return;

      if (availableUsers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нет доступных пользователей для добавления'),
          ),
        );
        return;
      }

      final selectedUser = await showDialog<User>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Добавить пользователя'),
            content: SizedBox(
              width: 360,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: availableUsers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = availableUsers[index];
                  return ListTile(
                    title: Text('${user.name} ${user.last_name}'),
                    subtitle: Text(user.email),
                    trailing: const Icon(Icons.add),
                    onTap: () {
                      Navigator.of(context).pop(user);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
            ],
          );
        },
      );

      if (selectedUser == null) {
        return;
      }

      await _usersService.activateSubscription(selectedUser.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${selectedUser.name} ${selectedUser.last_name} добавлен в активные',
          ),
        ),
      );
      _refreshSubscriptions();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось добавить пользователя: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Активные абонементы',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _handleEditAction,
            child: Text(
              _isEditMode
                  ? (_selectedUserIds.isNotEmpty
                        ? 'Деактивировать абонемент'
                        : 'Отмена')
                  : 'Изменить',
              style: TextStyle(
                color: _isEditMode
                    ? (_selectedUserIds.isNotEmpty
                          ? Colors.redAccent
                          : Colors.orangeAccent)
                    : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: _showAddUserDialog,
            tooltip: 'Добавить пользователя',
            icon: const Icon(Icons.person_add_alt_1),
          ),
        ],
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
            colors: [Color(0xff2c5364), Color(0xff203e43), Color(0xff0f2027)],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<Subscription>>(
            future: _subscriptionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              } else if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Ошибка при загрузке данных',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              } else {
                final subscriptions = snapshot.data!
                    .where((sub) => sub.isPaid)
                    .toList();
                final activeCount = subscriptions.length;

                if (subscriptions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Активных абонементов: 0/15',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Нет информации об активных абонементах',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _showAddUserDialog,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'Добавить пользователя',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 8,
                        left: 24,
                        right: 24,
                        bottom: 8,
                      ),
                      child: Text(
                        'Активных абонементов: $activeCount/15',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(
                          top: 0,
                          bottom: 40,
                          left: 24,
                          right: 24,
                        ),
                        itemCount: subscriptions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final sub = subscriptions[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${sub.name} ${sub.last_name}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 150,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: _isEditMode
                                        ? Checkbox(
                                            value: _selectedUserIds.contains(
                                              sub.user_id,
                                            ),
                                            activeColor: Colors.white,
                                            checkColor: Colors.black,
                                            side: const BorderSide(
                                              color: Colors.white,
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                            onChanged: (value) {
                                              setState(() {
                                                if (value ?? false) {
                                                  _selectedUserIds.add(
                                                    sub.user_id,
                                                  );
                                                } else {
                                                  _selectedUserIds.remove(
                                                    sub.user_id,
                                                  );
                                                }
                                              });
                                            },
                                          )
                                        : Text(
                                            sub.isPaid
                                                ? 'Оплачено ✅'
                                                : 'Не оплачено ❌',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              color: sub.isPaid
                                                  ? Colors.greenAccent
                                                  : Colors.redAccent,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
