
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

// Modelos de datos
class Drink {
  final String name;
  final IconData icon;
  Drink({required this.name, required this.icon});
}

class Food {
  final String name;
  final IconData icon;
  Food({required this.name, required this.icon});
}

class CartItem {
  final dynamic item;
  int quantity;
  CartItem({required this.item, this.quantity = 1});
}

// State Management con Provider
class Cart with ChangeNotifier {
  final Map<String, CartItem> _items = {};
  Map<String, CartItem> get items => _items;

  void addItem(dynamic product) {
    if (_items.containsKey(product.name)) {
      _items.update(product.name, (existing) => CartItem(item: existing.item, quantity: existing.quantity + 1));
    } else {
      _items.putIfAbsent(product.name, () => CartItem(item: product));
    }
    notifyListeners();
  }

  void removeItem(dynamic product) {
    if (_items.containsKey(product.name) && _items[product.name]!.quantity > 1) {
      _items.update(product.name, (existing) => CartItem(item: existing.item, quantity: existing.quantity - 1));
    } else {
      _items.remove(product.name);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Habilitar la persistencia de datos de Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => Cart(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bar App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const RoleSelectionScreen(),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona tu rol')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: const Text('Camarero'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WaiterScreen())),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 60),
                textStyle: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.monitor),
              label: const Text('Cocina/Barra'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MonitorScreen())),
               style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 60),
                textStyle: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaiterScreen extends StatefulWidget {
  const WaiterScreen({super.key});

  @override
  State<WaiterScreen> createState() => _WaiterScreenState();
}

class _WaiterScreenState extends State<WaiterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Drink> drinks = [
    Drink(name: 'Cerveza', icon: Icons.local_drink),
    Drink(name: 'Vino', icon: Icons.wine_bar),
    Drink(name: 'Coca-Cola', icon: Icons.local_cafe),
  ];

  final List<Food> foods = [
    Food(name: 'Hamburguesa', icon: Icons.fastfood),
    Food(name: 'Pizza', icon: Icons.local_pizza),
    Food(name: 'Ensalada', icon: Icons.spa),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista Camarero'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.local_drink), text: 'Bebidas'),
            Tab(icon: Icon(Icons.restaurant), text: 'Comida'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGrid(drinks),
                _buildGrid(foods),
              ],
            ),
          ),
          const _CartView(),
        ],
      ),
    );
  }

  Widget _buildGrid(List<dynamic> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return item is Drink ? _DrinkCard(drink: item) : _FoodCard(food: item);
      },
    );
  }
}

class _DrinkCard extends StatelessWidget {
  final Drink drink;
  const _DrinkCard({required this.drink});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => Provider.of<Cart>(context, listen: false).addItem(drink),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(drink.icon, size: 40, color: Colors.blue.shade700),
            const SizedBox(height: 10),
            Text(drink.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  final Food food;
  const _FoodCard({required this.food});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => Provider.of<Cart>(context, listen: false).addItem(food),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(food.icon, size: 40, color: Colors.orange.shade700),
            const SizedBox(height: 10),
            Text(food.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _CartView extends StatelessWidget {
  const _CartView();

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
          )
        ],
      ),
      child: Column(
        children: [
          const Text("Pedido Actual", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (cart.items.isEmpty) const Text("El carrito está vacío"),
          ...cart.items.values.map((cartItem) => ListTile(
                leading: Icon(cartItem.item.icon),
                title: Text(cartItem.item.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.remove), onPressed: () => cart.removeItem(cartItem.item)),
                    Text(cartItem.quantity.toString(), style: const TextStyle(fontSize: 18)),
                    IconButton(icon: const Icon(Icons.add), onPressed: () => cart.addItem(cartItem.item)),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          if (cart.items.isNotEmpty) _SendOrderButton(),
        ],
      ),
    );
  }
}

class _SendOrderButton extends StatefulWidget {
  @override
  __SendOrderButtonState createState() => __SendOrderButtonState();
}

class __SendOrderButtonState extends State<_SendOrderButton> with SingleTickerProviderStateMixin {
  bool _isSending = false;
  bool _isDone = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _sendOrder() {
    if (_isSending) return;

    final cart = Provider.of<Cart>(context, listen: false);
    final orderItems = cart.items.values.map((item) => {
      'name': item.item.name,
      'quantity': item.quantity,
      'type': item.item is Drink ? 'drink' : 'food',
    }).toList();

    // Inmediatamente actualiza la UI a un estado de éxito
    setState(() {
      _isSending = true;
      _isDone = true;
    });
    _animationController.forward();
    
    // Limpia el carrito localmente
    cart.clear();

    // Envía los datos a Firebase en segundo plano
    FirebaseFirestore.instance.collection('orders').add({
      'items': orderItems,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    // ignore: body_might_complete_normally_catch_error
    }).catchError((error) {
      // Opcional: Manejar el error, por ejemplo, mostrando un snackbar
      // o registrando el error para un reintento posterior.
      debugPrint("Error al enviar el pedido: $error");
        });
    
    // Resetea el botón después de la animación de éxito
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _isSending = false;
              _isDone = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: _isSending
          ? ScaleTransition(
              scale: Tween(begin: 0.0, end: 1.0).animate(_animationController),
              child: _isDone ? const Icon(Icons.check, color: Colors.white) : const SizedBox.shrink(),
            )
          : const Icon(Icons.send),
      label: Text(_isSending ? (_isDone ? 'Enviado' : 'Enviando...') : 'Enviar Pedido'),
      onPressed: _sendOrder,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isDone ? Colors.green : Theme.of(context).primaryColor,
        minimumSize: const Size(double.infinity, 50),
        textStyle: const TextStyle(fontSize: 18),
      ),
    );
  }
}

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Monitor Cocina/Barra'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.local_drink), text: 'Barra'),
              Tab(icon: Icon(Icons.restaurant), text: 'Cocina'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OrdersTab(type: 'drink'),
            _OrdersTab(type: 'food'),
          ],
        ),
      ),
    );
  }
}

class _OrdersTab extends StatefulWidget {
  final String type;
  const _OrdersTab({required this.type});

  @override
  __OrdersTabState createState() => __OrdersTabState();
}

class __OrdersTabState extends State<_OrdersTab> {
  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playSound() {
    // El archivo de sonido debe estar en assets/sounds/notification.mp3
    _audioPlayer.play(AssetSource('sounds/notification.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'pending')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Error al cargar pedidos');
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;

        // Lógica para reproducir sonido solo para nuevos pedidos en la categoría correcta
        for (var change in snapshot.data!.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final items = change.doc['items'] as List<dynamic>;
            if (items.any((item) => item['type'] == widget.type)) {
              _playSound();
            }
          }
        }
        
        final filteredDocs = docs.where((doc) {
          final items = doc['items'] as List<dynamic>;
          return items.any((item) => item['type'] == widget.type);
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(child: Text('No hay pedidos pendientes'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            // Usar una Key para optimizar el rendimiento del ListView
            return _OrderCard(key: ValueKey(doc.id), doc: doc, type: widget.type);
          },
        );
      },
    );
  }
}

class _OrderCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final String type;

  const _OrderCard({super.key, required this.doc, required this.type});

  @override
  __OrderCardState createState() => __OrderCardState();
}

class __OrderCardState extends State<_OrderCard> {
  Timer? _timer;
  Duration? _timeElapsed;

  @override
  void initState() {
    super.initState();
    final timestamp = widget.doc['timestamp'] as Timestamp?;
    if (timestamp != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _timeElapsed = DateTime.now().difference(timestamp.toDate());
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = (widget.doc['items'] as List<dynamic>)
        .where((item) => item['type'] == widget.type)
        .toList();
    
    if (items.isEmpty) return const SizedBox.shrink();

    final timestamp = widget.doc['timestamp'] as Timestamp?;
    final timeFormatted = timestamp != null ? DateFormat.Hms().format(timestamp.toDate()) : '--:--';
    
    bool isLate = _timeElapsed != null && _timeElapsed!.inMinutes >= 10;

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      color: isLate ? Colors.red.shade100 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isLate ? BorderSide(color: Colors.red.shade700, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(
                  'Pedido: $timeFormatted',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (_timeElapsed != null)
                  Text(
                    '${_timeElapsed!.inMinutes.toString().padLeft(2, '0')}:${(_timeElapsed!.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isLate ? Colors.red.shade900: Colors.black87),
                  )
              ],
            ),
            const Divider(thickness: 1.5),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                '${item['quantity']}x ${item['name']}',
                style: const TextStyle(fontSize: 18),
              ),
            )),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Completar Pedido'),
                onPressed: () => widget.doc.reference.update({'status': 'completed'}),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
