import 'package:flutter/material.dart';
import 'package:nki_basketball/services/subscriptions/subscriptions_service.dart';

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({Key? key}) : super(key: key);

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  late Future<List<Subscription>> _subscriptionsFuture;

  @override
  void initState() {
    super.initState();
    _subscriptionsFuture = SubscriptionsService().fetchSubscriptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Активные абонементы', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
        child: FutureBuilder<List<Subscription>>(
          future: _subscriptionsFuture,
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
              final subscriptions = snapshot.data!
                  .where((sub) => sub.isPaid)
                  .toList();

              if (subscriptions.isEmpty) {
                return const Center(
                  child: Text(
                    'Нет информации об активных абонементах',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.only(top: kToolbarHeight + 80, bottom: 40),
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
                        Text(
                          sub.isPaid ? 'Оплачено ✅' : 'Не оплачено ❌',
                          style: TextStyle(
                            color: sub.isPaid ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );;
            }
          },
        ),
      ),
    );
  }
}
