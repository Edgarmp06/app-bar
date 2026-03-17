import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';

// --- MODELOS ---
class Product {
  final String name;
  final IconData icon;
  final double price;
  final String destination; // 'barra' o 'cocina'
  Product({
    required this.name,
    required this.icon,
    required this.price,
    required this.destination,
  });
}

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
}

// --- GESTIÓN DE ESTADO (CARRITO) ---
class Cart with ChangeNotifier {
  final Map<String, CartItem> _items = {};
  int _selectedTable = 1;

  Map<String, CartItem> get items => _items;
  int get selectedTable => _selectedTable;

  void setTable(int table) {
    _selectedTable = table;
    notifyListeners();
  }

  void addItem(Product product) {
    if (_items.containsKey(product.name)) {
      _items.update(
        product.name,
        (ex) => CartItem(product: ex.product, quantity: ex.quantity + 1),
      );
    } else {
      _items.putIfAbsent(product.name, () => CartItem(product: product));
    }
    notifyListeners();
  }

  void removeItem(Product product) {
    if (_items.containsKey(product.name) &&
        _items[product.name]!.quantity > 1) {
      _items.update(
        product.name,
        (ex) => CartItem(product: ex.product, quantity: ex.quantity - 1),
      );
    } else {
      _items.remove(product.name);
    }
    notifyListeners();
  }

  double get total => _items.values.fold(
    0,
    (sum, item) => sum + (item.product.price * item.quantity),
  );
  void clear() {
    _items.clear();
    notifyListeners();
  }
}

// --- MAIN ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(create: (context) => Cart(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const RoleSelectionScreen(),
    );
  }
}

// --- SELECCIÓN DE ROL ---
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade900, Colors.indigo.shade500],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, size: 100, color: Colors.white),
            const SizedBox(height: 30),
            _roleButton(
              context,
              "CAMARERO",
              Icons.person,
              const WaiterScreen(),
            ),
            const SizedBox(height: 20),
            _roleButton(
              context,
              "COCINA",
              Icons.soup_kitchen,
              const MonitorScreen(type: 'cocina'),
            ),
            const SizedBox(height: 20),
            _roleButton(
              context,
              "BARRA / PAGOS",
              Icons.local_bar,
              const BarraCobrosScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleButton(
    BuildContext context,
    String text,
    IconData icon,
    Widget screen,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(280, 70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      icon: Icon(icon),
      label: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// --- PANTALLA CAMARERO ---
class WaiterScreen extends StatefulWidget {
  const WaiterScreen({super.key});
  @override
  State<WaiterScreen> createState() => _WaiterScreenState();
}

class _WaiterScreenState extends State<WaiterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Product> barraItems = [
    Product(
      name: 'Caña',
      icon: Icons.local_drink,
      price: 1.50,
      destination: 'barra',
    ),
    Product(
      name: 'Vino',
      icon: Icons.wine_bar,
      price: 2.50,
      destination: 'barra',
    ),
    Product(
      name: 'Refresco',
      icon: Icons.liquor,
      price: 2.00,
      destination: 'barra',
    ),
    Product(
      name: 'Café',
      icon: Icons.coffee,
      price: 1.20,
      destination: 'barra',
    ),
  ];
  final List<Product> cocinaItems = [
    Product(
      name: 'Bravas',
      icon: Icons.restaurant,
      price: 6.50,
      destination: 'cocina',
    ),
    Product(
      name: 'Bocadillo',
      icon: Icons.lunch_dining,
      price: 5.50,
      destination: 'cocina',
    ),
    Product(
      name: 'Ensalada',
      icon: Icons.flatware,
      price: 7.00,
      destination: 'cocina',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Camarero"),
        actions: [
          DropdownButton<int>(
            value: cart.selectedTable,
            dropdownColor: Colors.indigo,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            items: List.generate(
              15,
              (i) => DropdownMenuItem(
                value: i + 1,
                child: Text("Mesa ${i + 1}  "),
              ),
            ),
            onChanged: (v) => cart.setTable(v!),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "BARRA"),
            Tab(text: "COCINA"),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildGrid(barraItems), _buildGrid(cocinaItems)],
            ),
          ),
          _buildBotonMenuEspecial(context),
          const _CartSummaryView(),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Product> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, i) => _ProductCard(product: products[i]),
    );
  }

  Widget _buildBotonMenuEspecial(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: () => _showMenuDialog(context),
        child: const Text(
          "🔥 AÑADIR MENÚ DEL DÍA (12.00€)",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showMenuDialog(BuildContext context) {
    bool cafe = false;
    bool postre = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Opciones de Menú"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text("¿Quiere Postre?"),
                value: postre,
                onChanged: (v) => setState(() => postre = v!),
              ),
              CheckboxListTile(
                title: const Text("¿Quiere Café?"),
                value: cafe,
                onChanged: (v) => setState(() => cafe = v!),
              ),
              if (postre && cafe)
                const Text(
                  "⚠️ Se cobrará +1.20€ suplemento",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                final cart = Provider.of<Cart>(context, listen: false);
                cart.addItem(
                  Product(
                    name: "Menú Completo",
                    icon: Icons.star,
                    price: 12.0,
                    destination: 'cocina',
                  ),
                );
                if (postre && cafe)
                  cart.addItem(
                    Product(
                      name: "Suplemento Café (Menú)",
                      icon: Icons.coffee,
                      price: 1.20,
                      destination: 'barra',
                    ),
                  );
                Navigator.pop(context);
              },
              child: const Text("Añadir al Pedido"),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Provider.of<Cart>(context, listen: false).addItem(product),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              product.icon,
              size: 30,
              color: product.destination == 'barra'
                  ? Colors.blue
                  : Colors.orange,
            ),
            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("${product.price.toStringAsFixed(2)}€"),
          ],
        ),
      ),
    );
  }
}

class _CartSummaryView extends StatelessWidget {
  const _CartSummaryView();
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);
    if (cart.items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.grey.shade100,
      child: Column(
        children: [
          Text(
            "MESA ${cart.selectedTable} - TOTAL: ${cart.total.toStringAsFixed(2)}€",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
            onPressed: () async {
              final batch = FirebaseFirestore.instance.batch();
              for (var item in cart.items.values) {
                final ref = FirebaseFirestore.instance
                    .collection('orders')
                    .doc();
                batch.set(ref, {
                  'mesa': cart.selectedTable,
                  'producto': item.product.name,
                  'cantidad': item.quantity,
                  'precio': item.product.price,
                  'destino': item.product.destination,
                  'status': 'pending',
                  'timestamp': FieldValue.serverTimestamp(),
                });
              }
              await batch.commit();
              cart.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Pedido enviado a Barra y Cocina"),
                ),
              );
            },
            child: const Text("ENVIAR PEDIDO"),
          ),
        ],
      ),
    );
  }
}

// --- MONITOR (PARA COCINA) ---
class MonitorScreen extends StatelessWidget {
  final String type;
  const MonitorScreen({super.key, required this.type});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(type == 'cocina' ? "COCINA" : "BARRA"),
        backgroundColor: type == 'cocina' ? Colors.orange : Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('destino', isEqualTo: type)
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              var d = docs[i];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(child: Text("${d['mesa']}")),
                  title: Text(
                    "${d['cantidad']}x ${d['producto']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.check_circle,
                      size: 35,
                      color: Colors.green,
                    ),
                    onPressed: () =>
                        d.reference.update({'status': 'completed'}),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- BARRA Y COBROS ---
class BarraCobrosScreen extends StatelessWidget {
  const BarraCobrosScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Monitor Barra y Cobros"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "PEDIDOS BEBIDA"),
              Tab(text: "COBRAR MESA"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const MonitorScreen(type: 'barra'),
            _buildSeccionCobros(),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionCobros() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isNotEqualTo: 'paid')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        Map<int, double> mesaTotales = {};
        for (var doc in snapshot.data!.docs) {
          int m = doc['mesa'];
          double p = (doc['precio'] as num).toDouble();
          int c = doc['cantidad'];
          mesaTotales[m] = (mesaTotales[m] ?? 0) + (p * c);
        }
        var mesas = mesaTotales.keys.toList()..sort();
        return ListView.builder(
          itemCount: mesas.length,
          itemBuilder: (context, i) => Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(
                "MESA ${mesas[i]}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              subtitle: Text(
                "Total: ${mesaTotales[mesas[i]]!.toStringAsFixed(2)}€",
                style: const TextStyle(fontSize: 18, color: Colors.red),
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  var batch = FirebaseFirestore.instance.batch();
                  var query = await FirebaseFirestore.instance
                      .collection('orders')
                      .where('mesa', isEqualTo: mesas[i])
                      .get();
                  for (var d in query.docs) {
                    batch.delete(d.reference);
                  }
                  await batch.commit();
                },
                child: const Text("PAGADO"),
              ),
            ),
          ),
        );
      },
    );
  }
}
