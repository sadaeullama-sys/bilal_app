import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDb.instance.database;
  runApp(const VeterinaryApp());
}

class AppDb {
  AppDb._();
  static final instance = AppDb._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'veterinary_care_pro.db');
    _db = await openDatabase(path, version: 2, onCreate: (db, version) async {
      await db.execute('''CREATE TABLE patients(
        id INTEGER PRIMARY KEY AUTOINCREMENT, owner TEXT NOT NULL,
        phone TEXT, animal TEXT NOT NULL, tag TEXT, age TEXT,
        complaint TEXT, notes TEXT, created_at TEXT NOT NULL)''');
      await db.execute('''CREATE TABLE medicines(
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
        barcode TEXT, company TEXT, batch TEXT, expiry TEXT, purchase REAL NOT NULL DEFAULT 0,
        price REAL NOT NULL DEFAULT 0, stock REAL NOT NULL DEFAULT 0)''');
      await db.execute('''CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT, customer TEXT,
        description TEXT NOT NULL, total REAL NOT NULL,
        paid REAL NOT NULL, created_at TEXT NOT NULL)''');
      await db.execute('''CREATE TABLE sale_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER NOT NULL,
        medicine_id INTEGER NOT NULL, medicine_name TEXT NOT NULL,
        barcode TEXT, quantity REAL NOT NULL, unit_price REAL NOT NULL,
        line_total REAL NOT NULL)''');
      await db.execute('''CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL,
        amount REAL NOT NULL, created_at TEXT NOT NULL)''');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute('ALTER TABLE medicines ADD COLUMN barcode TEXT');
        await db.execute('''CREATE TABLE IF NOT EXISTS sale_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER NOT NULL,
          medicine_id INTEGER NOT NULL, medicine_name TEXT NOT NULL,
          barcode TEXT, quantity REAL NOT NULL, unit_price REAL NOT NULL,
          line_total REAL NOT NULL)''');
      }
    });
    return _db!;
  }

  Future<int> add(String table, Map<String, Object?> values) async =>
      (await database).insert(table, values);
  Future<List<Map<String, Object?>>> all(String table) async =>
      (await database).query(table, orderBy: 'id DESC');
  Future<double> sum(String table, String column) async {
    final rows = await (await database).rawQuery(
      'SELECT COALESCE(SUM($column),0) AS total FROM $table');
    return (rows.first['total'] as num).toDouble();
  }
}

String money(num n) => 'Rs. ${NumberFormat('#,##0.##').format(n)}';

class VeterinaryApp extends StatelessWidget {
  const VeterinaryApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Veterinary Care Pro',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF16765B)),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF5F8F7),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF123B50), foregroundColor: Colors.white),
    ),
    home: const LoginPage(),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final user = TextEditingController(text: 'Admin');
  final pass = TextEditingController();
  String error = '';
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: SingleChildScrollView(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Card(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(borderRadius: BorderRadius.circular(18),
            child: Image.asset('assets/veterinary_logo.png', width: 132, height: 132,
              fit: BoxFit.contain, errorBuilder: (_, __, ___) =>
                const CircleAvatar(radius: 34, child: Icon(Icons.pets, size: 36)))),
          const SizedBox(height: 12),
          const Text('Veterinary Care Pro',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
          const Text('Clinic & Medicine Shop'),
          const SizedBox(height: 24),
          TextField(controller: user, decoration: const InputDecoration(
            labelText: 'Username / صارف نام', prefixIcon: Icon(Icons.person))),
          const SizedBox(height: 12),
          TextField(controller: pass, obscureText: true,
            decoration: const InputDecoration(labelText: 'Password / پاس ورڈ',
              prefixIcon: Icon(Icons.lock))),
          if (error.isNotEmpty) Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(error, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: FilledButton(
            onPressed: () {
              if (user.text.trim() == 'Admin' && pass.text == '1234') {
                Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const HomePage()));
              } else { setState(() => error = 'Incorrect login. Demo password: 1234'); }
            }, child: const Text('Login / داخل ہوں'))),
          const SizedBox(height: 8),
          const Text('First login: Admin / 1234',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      )),
    ))),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int tab = 0;
  final titles = ['Dashboard', 'Patients', 'Medicines', 'Sales', 'Reports'];
  @override Widget build(BuildContext context) {
    final pages = [const DashboardPage(), const PatientsPage(),
      const MedicinesPage(), const SalesPage(), const ReportsPage()];
    return Scaffold(
      appBar: AppBar(title: Text('Veterinary Care Pro • ${titles[tab]}'),
        actions: [IconButton(tooltip: 'Logout', icon: const Icon(Icons.logout),
          onPressed: () => Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const LoginPage())))]),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.pets), label: 'Patients'),
          NavigationDestination(icon: Icon(Icons.medication), label: 'Medicines'),
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'Sales'),
          NavigationDestination(icon: Icon(Icons.assessment), label: 'Reports'),
        ]),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override State<DashboardPage> createState() => _DashboardPageState();
}
class _DashboardPageState extends State<DashboardPage> {
  Future<Map<String, dynamic>> load() async {
    final patients = await AppDb.instance.all('patients');
    final medicines = await AppDb.instance.all('medicines');
    final sales = await AppDb.instance.sum('sales', 'total');
    final paid = await AppDb.instance.sum('sales', 'paid');
    return {'patients': patients.length, 'medicines': medicines.length,
      'sales': sales, 'due': sales-paid};
  }
  @override Widget build(BuildContext context) => FutureBuilder(
    future: load(), builder: (context, snap) {
      final d = snap.data ?? {'patients':0,'medicines':0,'sales':0.0,'due':0.0};
      return RefreshIndicator(onRefresh: () async => setState(() {}),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xFF123B50),
              borderRadius: BorderRadius.circular(18)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text('السلام علیکم', style: TextStyle(color: Colors.white70)),
                SizedBox(height: 5), Text('Welcome to Veterinary Care Pro',
                  style: TextStyle(color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.bold)),
                Text('Clinic & Pharmacy Management',
                  style: TextStyle(color: Colors.white70))])),
          const SizedBox(height: 16),
          GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, childAspectRatio: 1.5, crossAxisSpacing: 12,
            mainAxisSpacing: 12, children: [
              stat('Registered Patients', '${d['patients']}', Icons.pets),
              stat('Medicine Items', '${d['medicines']}', Icons.medication),
              stat('Total Sales', money(d['sales']), Icons.shopping_bag),
              stat('Customer Due', money(d['due']), Icons.account_balance_wallet),
            ]),
          const SizedBox(height: 18),
          const Text('Quick Actions / فوری کام',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ActionChip(avatar: const Icon(Icons.person_add), label: const Text('Add Patient'),
              onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PatientsPage()))),
            ActionChip(avatar: const Icon(Icons.add_box), label: const Text('Add Medicine'),
              onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MedicinesPage()))),
            ActionChip(avatar: const Icon(Icons.receipt), label: const Text('New Sale'),
              onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SalesPage()))),
          ]),
        ]));
    });
  Widget stat(String title, String value, IconData icon) => Card(
    child: Padding(padding: const EdgeInsets.all(14), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
      children: [Icon(icon, color: const Color(0xFF16765B)), const SizedBox(height: 7),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        FittedBox(child: Text(value, style: const TextStyle(
          fontSize: 19, fontWeight: FontWeight.bold))) ])));
}

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});
  @override State<PatientsPage> createState() => _PatientsPageState();
}
class _PatientsPageState extends State<PatientsPage> {
  Future<void> addPatient() async {
    final owner = TextEditingController(), phone = TextEditingController(),
      animal = TextEditingController(text: 'Cow / گائے'), tag = TextEditingController(),
      complaint = TextEditingController(), age = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Animal Patient / نیا مریض'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        field(owner, 'Owner name / مالک کا نام'),
        field(phone, 'Phone / موبائل'),
        field(animal, 'Animal type / جانور کی قسم'),
        field(tag, 'Tag or ID / شناختی نمبر'),
        field(age, 'Age / عمر'),
        field(complaint, 'Complaint / بیماری یا شکایت'),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false),
        child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true),
        child: const Text('Save'))]));
    if (ok == true && owner.text.trim().isNotEmpty && animal.text.trim().isNotEmpty) {
      await AppDb.instance.add('patients', {'owner':owner.text.trim(),
        'phone':phone.text.trim(),'animal':animal.text.trim(),'tag':tag.text.trim(),
        'age':age.text.trim(),'complaint':complaint.text.trim(),'notes':'',
        'created_at':DateTime.now().toIso8601String()});
      setState(() {});
    }
  }
  @override Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(onPressed: addPatient,
      icon: const Icon(Icons.add), label: const Text('Add Patient')),
    body: FutureBuilder(future: AppDb.instance.all('patients'),
      builder: (context, snap) {
        final rows = snap.data ?? [];
        if (rows.isEmpty) return const Center(child: Text('No patients yet / ابھی کوئی مریض نہیں'));
        return ListView.builder(itemCount: rows.length, itemBuilder: (_, i) {
          final r = rows[i];
          return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.pets)),
            title: Text('${r['animal']} • ${r['owner']}'),
            subtitle: Text('${r['phone']}  |  ${r['complaint']}'),
            trailing: Text('#${r['id']}')));
        });
      }));
}

class MedicinesPage extends StatefulWidget {
  const MedicinesPage({super.key});
  @override State<MedicinesPage> createState() => _MedicinesPageState();
}
class _MedicinesPageState extends State<MedicinesPage> {
  Future<void> addMedicine() async {
    final name = TextEditingController(), barcode = TextEditingController(),
      company = TextEditingController(), batch = TextEditingController(), expiry = TextEditingController(),
      purchase = TextEditingController(text: '0'), price = TextEditingController(text: '0'),
      stock = TextEditingController(text: '0');
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Medicine / نئی دوائی'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        field(name,'Medicine name / دوائی'),
        Row(children: [Expanded(child: field(barcode,'Barcode / بارکوڈ')),
          IconButton(tooltip: 'Scan barcode', icon: const Icon(Icons.qr_code_scanner),
            onPressed: () async {
              final code = await Navigator.push<String>(context,
                MaterialPageRoute(builder: (_) => const BarcodeScannerPage()));
              if (code != null) barcode.text = code;
            })]),
        field(company,'Company / کمپنی'),
        field(batch,'Batch number / بیچ نمبر'), field(expiry,'Expiry YYYY-MM-DD'),
        field(purchase,'Purchase price / خرید قیمت', keyboard: TextInputType.number),
        field(price,'Sale price / فروخت قیمت', keyboard: TextInputType.number),
        field(stock,'Stock quantity / مقدار', keyboard: TextInputType.number),
      ])),
      actions: [TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Save'))]));
    if (ok == true && name.text.trim().isNotEmpty) {
      await AppDb.instance.add('medicines', {'name':name.text.trim(),
        'barcode':barcode.text.trim(),'company':company.text.trim(),'batch':batch.text.trim(),'expiry':expiry.text.trim(),
        'purchase':double.tryParse(purchase.text) ?? 0,'price':double.tryParse(price.text) ?? 0,
        'stock':double.tryParse(stock.text) ?? 0});
      setState(() {});
    }
  }
  @override Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(onPressed:addMedicine,
      icon:const Icon(Icons.add),label:const Text('Add Medicine')),
    body: FutureBuilder(future:AppDb.instance.all('medicines'),builder:(context,snap){
      final rows=snap.data??[];
      if(rows.isEmpty) return const Center(child:Text('No medicines added / دوائیاں شامل کریں'));
      return ListView.builder(itemCount:rows.length,itemBuilder:(_,i){
        final r=rows[i]; final low=(r['stock'] as num)<=5;
        return Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.medication)),
          title:Text('${r['name']} (${r['company']})'),
          subtitle:Text('Barcode: ${r['barcode'] ?? ''} • Batch: ${r['batch']} • Expiry: ${r['expiry']}\\nStock: ${r['stock']} • ${money(r['price'] as num)}'),
          isThreeLine:true,trailing:low?const Icon(Icons.warning,color:Colors.orange):null));
      });
    }));
}

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});
  @override State<SalesPage> createState() => _SalesPageState();
}
class _SalesPageState extends State<SalesPage> {
  final customer = TextEditingController();
  final paid = TextEditingController(text: '0');
  final Map<int, Map<String, dynamic>> cart = {};

  double get total => cart.values.fold(0.0,
    (v, item) => v + (item['price'] as double) * (item['qty'] as double));

  Future<void> scanAndAdd() async {
    final code = await Navigator.push<String>(context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()));
    if (code == null || code.isEmpty) return;
    final db = await AppDb.instance.database;
    final rows = await db.query('medicines',
      where: 'barcode = ?', whereArgs: [code], limit: 1);
    if (rows.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Medicine not found for barcode: $code')));
      return;
    }
    addMedicine(Map<String, dynamic>.from(rows.first));
  }

  void addMedicine(Map<String, dynamic> medicine) {
    final id = medicine['id'] as int;
    final stock = (medicine['stock'] as num).toDouble();
    final existing = cart[id];
    final qty = (existing?['qty'] as double? ?? 0) + 1;
    if (qty > stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough stock / اسٹاک کم ہے')));
      return;
    }
    setState(() {
      cart[id] = {'id': id, 'name': medicine['name'],
        'barcode': medicine['barcode'] ?? '',
        'price': (medicine['price'] as num).toDouble(),
        'qty': qty, 'stock': stock};
    });
  }

  Future<void> selectMedicine() async {
    final rows = await AppDb.instance.all('medicines');
    if (!mounted) return;
    await showModalBottomSheet(context: context, builder: (ctx) =>
      SafeArea(child: ListView(children: [
        const ListTile(title: Text('Select medicine / دوائی منتخب کریں')),
        ...rows.map((m) => ListTile(
          title: Text('${m['name']} • ${money(m['price'] as num)}'),
          subtitle: Text('Stock: ${m['stock']} • Barcode: ${m['barcode'] ?? ''}'),
          onTap: () { Navigator.pop(ctx); addMedicine(Map<String,dynamic>.from(m)); }))
      ])));
  }

  Future<void> checkout() async {
    if (cart.isEmpty) return;
    final paidAmount = double.tryParse(paid.text) ?? 0;
    if (paidAmount < 0 || paidAmount > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid received amount')));
      return;
    }
    final db = await AppDb.instance.database;
    await db.transaction((txn) async {
      final saleId = await txn.insert('sales', {
        'customer': customer.text.trim(), 'description': 'Medicine sale',
        'total': total, 'paid': paidAmount,
        'created_at': DateTime.now().toIso8601String()
      });
      for (final item in cart.values) {
        final qty = item['qty'] as double;
        final lineTotal = qty * (item['price'] as double);
        await txn.insert('sale_items', {
          'sale_id': saleId, 'medicine_id': item['id'],
          'medicine_name': item['name'], 'barcode': item['barcode'],
          'quantity': qty, 'unit_price': item['price'],
          'line_total': lineTotal
        });
        await txn.rawUpdate('UPDATE medicines SET stock = stock - ? WHERE id = ?',
          [qty, item['id']]);
      }
    });
    if (!mounted) return;
    setState(() { cart.clear(); customer.clear(); paid.text = '0'; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sale saved and stock updated / فروخت محفوظ ہوگئی')));
  }

  @override Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(
      onPressed: scanAndAdd, icon: const Icon(Icons.qr_code_scanner),
      label: const Text('Scan Medicine')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      TextField(controller: customer, decoration: const InputDecoration(
        labelText: 'Customer / کسٹمر', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: selectMedicine,
        icon: const Icon(Icons.add), label: const Text('Add medicine manually')),
      const SizedBox(height: 8),
      if (cart.isEmpty) const Padding(padding: EdgeInsets.all(24),
        child: Center(child: Text('Scan a medicine barcode to add it to sale'))),
      ...cart.values.map((item) => Card(child: ListTile(
        title: Text(item['name'].toString()),
        subtitle: Text('${item['qty']} × ${money(item['price'] as double)}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(onPressed: () => setState(() {
            final q = (item['qty'] as double) - 1;
            if (q <= 0) { cart.remove(item['id']); } else { item['qty'] = q; }
          }), icon: const Icon(Icons.remove_circle_outline)),
          IconButton(onPressed: () => addMedicine({
            'id': item['id'], 'name': item['name'], 'barcode': item['barcode'],
            'price': item['price'], 'stock': item['stock']
          }), icon: const Icon(Icons.add_circle_outline)),
        ])))),
      const Divider(),
      ListTile(title: const Text('Total / کل رقم'),
        trailing: Text(money(total), style: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 18))),
      TextField(controller: paid, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Received Rs. / وصول رقم',
          border: OutlineInputBorder())),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: cart.isEmpty ? null : checkout,
        icon: const Icon(Icons.check), label: const Text('Complete Sale / فروخت مکمل کریں')),
      const SizedBox(height: 80),
    ]),
  );
}

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});
  @override State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}
class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool found = false;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scan Medicine Barcode')),
    body: Stack(children: [
      MobileScanner(onDetect: (capture) {
        if (found) return;
        final code = capture.barcodes
          .map((b) => b.rawValue).whereType<String>()
          .firstWhere((v) => v.isNotEmpty, orElse: () => '');
        if (code.isNotEmpty) {
          found = true;
          Navigator.pop(context, code);
        }
      }),
      Center(child: Container(width: 270, height: 150,
        decoration: BoxDecoration(border: Border.all(color: Colors.greenAccent, width: 3),
          borderRadius: BorderRadius.circular(16)))),
      const Positioned(left: 20, right: 20, bottom: 35,
        child: Text('Place the barcode inside the frame',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    ]),
  );
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});
  @override Widget build(BuildContext context)=>FutureBuilder(
    future:Future.wait([AppDb.instance.sum('sales','total'),
      AppDb.instance.sum('sales','paid'),AppDb.instance.sum('expenses','amount')]),
    builder:(context,snap){
      final v=snap.data??[0.0,0.0,0.0];
      return ListView(padding:const EdgeInsets.all(16),children:[
        reportTile('Total Sales / کل فروخت',money(v[0]),Icons.shopping_bag),
        reportTile('Received / وصولی',money(v[1]),Icons.payments),
        reportTile('Customer Due / بقایا',money(v[0]-v[1]),Icons.account_balance_wallet),
        reportTile('Expenses / اخراجات',money(v[2]),Icons.money_off),
        const Padding(padding:EdgeInsets.all(12),child:Text(
          'Profit reporting needs medicine purchase-cost and expense entries to be completed in the next version.',
          style:TextStyle(color:Colors.black54))),
      ]);
    });
}
Widget reportTile(String title,String value,IconData icon)=>Card(
  child:ListTile(leading:Icon(icon,color:const Color(0xFF16765B)),
    title:Text(title),trailing:Text(value,style:const TextStyle(fontWeight:FontWeight.bold))));

Widget field(TextEditingController c,String label,{TextInputType? keyboard})=>
  Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(
    controller:c,keyboardType:keyboard,decoration:InputDecoration(
      labelText:label,border:const OutlineInputBorder())));
