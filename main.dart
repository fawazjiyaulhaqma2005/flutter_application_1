import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/product_provider.dart';
import 'models/product_model.dart';
import 'screens/list_product_screen.dart';
import 'screens/detail_product_screen.dart';
import 'screens/tools_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ProductProvider(),
      child: const ProductApp(),
    ),
  );
}

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ListProductScreen(),
    ),
    GoRoute(
      path: '/detail/:id',
      builder: (context, state) =>
          DetailProductScreen(id: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/tools',
      builder: (context, state) => const ToolsScreen(),
    ),
    GoRoute(
      path: '/edit/:id',
      builder: (context, state) {
        final product = state.extra as Product;
        return EditProductScreen(product: product);
      },
    ),
    GoRoute(
      path: '/add',
      builder: (context, state) => const AddProductScreen(),
    ),
  ],
);

class ProductApp extends StatelessWidget {
  const ProductApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Produk DummyJSON',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4255D4)),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F8FC),
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      routerConfig: appRouter,
    );
  }
}

class EditProductScreen extends StatefulWidget {
  final Product product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late final TextEditingController titleController;
  late final TextEditingController priceController;
  late final TextEditingController stockController;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.product.title);
    priceController =
        TextEditingController(text: widget.product.price.toString());
    stockController =
        TextEditingController(text: widget.product.stock.toString());
  }

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    stockController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final title = titleController.text.trim();
    final price = double.tryParse(priceController.text);
    final stock = int.tryParse(stockController.text);
    if (title.isEmpty || price == null || stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nama, harga, dan stok dengan benar.')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      await context.read<ProductProvider>().updateProduct(widget.product.id, {
        'title': title,
        'price': price,
        'stock': stock,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Respons update diterima (perubahan API bersifat mock).'),
          ),
        );
        context.go('/');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengubah produk.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Edit Produk')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Nama produk'),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga'),
            ),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stok'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: saving ? null : save,
              child: Text(saving ? 'Menyimpan...' : 'Simpan perubahan'),
            ),
          ],
        ),
      );
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final titleController = TextEditingController();
  final priceController = TextEditingController(text: '9.99');
  bool saving = false;

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> add() async {
    final title = titleController.text.trim();
    final price = double.tryParse(priceController.text);
    if (title.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan harga produk wajib diisi.')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      final result = await context.read<ProductProvider>().addProduct({
        'title': title,
        'price': price,
        'category': 'beauty',
      });
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Produk ditambahkan (mock)'),
            content: Text('API mengembalikan ID ${result.id}. Data tidak disimpan permanen.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) context.go('/');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menambahkan produk.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Tambah Produk')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Nama produk'),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: saving ? null : add,
              child: Text(saving ? 'Mengirim...' : 'Tambah produk'),
            ),
          ],
        ),
      );
}
