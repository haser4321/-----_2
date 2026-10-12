import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
Future<void> main() async  {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProDaftarApp());
}
const sections = <Section>[
  Section('clients',
    'العملاء',
    'Clients',
    Icons.people_alt,
    'اسم العميل',
    'الهاتف والعنوان',
    'Client name',
    'Phone and address'),
  Section('appointments',
    'المواعيد',
    'Appointments',
    Icons.calendar_month,
    'اسم الموعد أو العميل',
    'التاريخ والوقت والتفاصيل',
    'Appointment or client',
    'Date, time and details'),
  Section('debts',
    'الديون',
    'Debts',
    Icons.account_balance_wallet,
    'اسم العميل',
    'تفاصيل الدين',
    'Client name',
    'Debt details',
    amount: true),
  Section('transactions',
    'الحسابات المالية',
    'Transactions',
    Icons.payments,
    'وصف العملية',
    'تفاصيل العملية',
    'Transaction description',
    'Transaction details',
    amount: true),
  Section('services',
    'الخدمات والأسعار',
    'Services & prices',
    Icons.home_repair_service,
    'اسم الخدمة',
    'وصف الخدمة',
    'Service name',
    'Service description',
    amount: true),
  Section('inventory',
    'المخزون',
    'Inventory',
    Icons.inventory_2,
    'اسم المنتج',
    'الكمية وتفاصيل المنتج',
    'Product name',
    'Quantity and product details',
    amount: true),
  Section('suppliers',
    'الموردون',
    'Suppliers',
    Icons.local_shipping,
    'اسم المورد',
    'رقم الهاتف والعنوان',
    'Supplier name',
    'Phone number and address'),
  Section('tasks',
    'المهام والتذكيرات',
    'Tasks & reminders',
    Icons.task_alt,
    'اسم المهمة',
    'موعد التنفيذ والتفاصيل',
    'Task name',
    'Due date and details'),
  Section('notes',
    'الملاحظات',
    'Notes',
    Icons.sticky_note_2,
    'عنوان الملاحظة',
    'محتوى الملاحظة',
    'Note title',
    'Note content'),
];
class Section  {
  final String id,
  ar,
  en,
  nameAr,
  detailAr,
  nameEn,
  detailEn;
  final IconData icon;
  final bool amount;
  const Section(this.id,
    this.ar,
    this.en,
    this.icon,
    this.nameAr,
    this.detailAr,
    this.nameEn,
    this.detailEn,
    {
      this.amount = false
  });
  String title(bool english) => english ? en : ar;
  String nameLabel(bool english) => english ? nameEn : nameAr;
  String detailLabel(bool english) => english ? detailEn : detailAr;
}
String pinHash(String pin) => sha256.convert(utf8.encode('ProDaftar_v1_$pin')).toString();
class ProDaftarApp extends StatefulWidget  {
  const ProDaftarApp( {
      super.key
  });
  @override
  State<ProDaftarApp> createState() => _ProDaftarAppState();
}
class _ProDaftarAppState extends State<ProDaftarApp>  {
  bool dark = true;
  bool english = false;
  String businessName = 'دفتر المحترف';
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: businessName,
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    theme: ThemeData(useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF287D73)),
      scaffoldBackgroundColor: const Color(0xFFF5F7F8)),
    darkTheme: ThemeData(useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF58B8A7),
        brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF101614)),
    home: Directionality(textDirection: english ? TextDirection.ltr : TextDirection.rtl,
      child: BusinessHome(
        dark: dark,
        english: english,
        businessName: businessName,
        onTheme: (v) => setState(() => dark = v),
        onLanguage: (v) => setState(() => english = v),
        onBusinessName: (v) => setState(() => businessName = v),
    )),
  );
}
class BusinessHome extends StatefulWidget  {
  final bool dark,
  english;
  final String businessName;
  final ValueChanged<bool> onTheme,
  onLanguage;
  final ValueChanged<String> onBusinessName;
  const BusinessHome( {
      super.key,
      required this.dark,
      required this.english,
      required this.businessName,
      required this.onTheme,
      required this.onLanguage,
      required this.onBusinessName
  });
  @override
  State<BusinessHome> createState() => _BusinessHomeState();
}
class _BusinessHomeState extends State<BusinessHome>  {
  SharedPreferences? prefs;
  final Map<String,
  List<Map<String,
  dynamic>>> data =  {
    for (final s in sections) s.id: <Map<String,
    dynamic>>[]
  };
  int selected = -1;
  bool loading = true,
  unlocked = false,
  hasPin = false;
  String savedPinHash = '',
  search = '';
  bool get en => widget.english;
  String t(String ar,
    String english) => en ? english : ar;
  @override
  void initState()  {
    super.initState();
    loadData();
  }
  Future<void> loadData() async  {
    prefs = await SharedPreferences.getInstance();
    for (final s in sections)  {
      try  {
        final raw = prefs!.getString('pro_${s.id}');
        if (raw != null) data[s.id] = (jsonDecode(raw) as List).map((e) => Map<String,
          dynamic>.from(e as Map)).toList();
      }
      catch (_)  {
        data[s.id] = [];
      }
    }
    final storedName = prefs!.getString('pro_business_name');
    final storedDark = prefs!.getBool('pro_dark_mode');
    final storedEnglish = prefs!.getBool('pro_english') ?? false;
    savedPinHash = prefs!.getString('pro_pin_hash') ?? '';
    hasPin = savedPinHash.isNotEmpty;
    if (storedName != null && storedName.isNotEmpty) widget.onBusinessName(storedName);
    if (storedDark != null) widget.onTheme(storedDark);
    widget.onLanguage(storedEnglish);
    if (mounted) setState(()  {
        loading = false;
        unlocked = !hasPin;
    });
  }
  Future<void> saveSection(String id) async => prefs!.setString('pro_$id',
    jsonEncode(data[id]));
  void notify(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  double amountOf(Map<String,
    dynamic> r) => (r['amount'] as num?)?.toDouble() ?? 0;
  double get income => data['transactions']!.where((r) => r['type'] == 'income').fold<double>(0,
    (s,
      r) => s + amountOf(r));
  double get expenses => data['transactions']!.where((r) => r['type'] == 'expense').fold<double>(0,
    (s,
      r) => s + amountOf(r));
  double get debts => data['debts']!.fold<double>(0,
    (s,
      r) => s + amountOf(r));
  Future<void> verifyPin(String pin) async  {
    if (pinHash(pin) == savedPinHash)  {
      if (mounted) setState(() => unlocked = true);
    }
    else notify(t('رمز الأمان غير صحيح',
        'Incorrect security PIN'));
  }
  Future<void> configurePin() async  {
    final first = TextEditingController(),
    second = TextEditingController();
    final result = await showDialog<String>(context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(hasPin ? 'تغيير رمز الأمان' : 'تفعيل رمز الأمان',
            hasPin ? 'Change security PIN' : 'Enable security PIN')),
        content: Column(mainAxisSize: MainAxisSize.min,
          children: [
            Text(t('اختر رمزًا من 4 إلى 8 أرقام. لا توجد آلية لاستعادته إذا نسيته.',
                'Choose a 4–8 digit PIN. It cannot be recovered if forgotten.')),
            const SizedBox(height: 12),
            TextField(controller: first,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 8,
              decoration: InputDecoration(labelText: t('رمز الأمان الجديد',
                  'New security PIN'))),
            TextField(controller: second,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 8,
              decoration: InputDecoration(labelText: t('تأكيد الرمز',
                  'Confirm PIN'))),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text(t('إلغاء',
                'Cancel'))),
          FilledButton(onPressed: ()  {
              final a = first.text.trim(),
              b = second.text.trim();
              if (!RegExp(r'^\d{4,8}$').hasMatch(a))  {
                notify(t('يجب أن يتكون الرمز من 4 إلى 8 أرقام',
                    'PIN must contain 4 to 8 digits'));
                return;
              }
              if (a != b)  {
                notify(t('الرمزان غير متطابقين',
                    'PINs do not match'));
                return;
              }
              Navigator.pop(ctx,
                a);
            }, child: Text(t('حفظ',
                'Save')))],
    ));
    first.dispose();
    second.dispose();
    if (result != null)  {
      savedPinHash = pinHash(result);
      hasPin = true;
      await prefs!.setString('pro_pin_hash',
        savedPinHash);
      if (mounted)  {
        setState(()  {
        });
        notify(t('تم تفعيل رمز الأمان',
            'Security PIN enabled'));
      }
    }
  }
  Future<void> removePin() async  {
    final controller = TextEditingController();
    final pin = await showDialog<String>(context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('إزالة رمز الأمان',
            'Remove security PIN')),
        content: TextField(controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: t('أدخل الرمز الحالي',
              'Enter current PIN'))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text(t('إلغاء',
                'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx,
              controller.text.trim()),
            child: Text(t('تحقق وإزالة',
                'Verify and remove')))],
    ));
    controller.dispose();
    if (pin == null) return;
    if (pinHash(pin) != savedPinHash)  {
      notify(t('رمز الأمان غير صحيح',
          'Incorrect security PIN'));
      return;
    }
    await prefs!.remove('pro_pin_hash');
    if (mounted) setState(()  {
        hasPin = false;
        savedPinHash = '';
    });
    notify(t('تمت إزالة رمز الأمان',
        'Security PIN removed'));
  }
  Future<void> addRecord(Section section,
    {
      Map<String,
      dynamic>? existing
  }) async  {
    final name = TextEditingController(text: existing?['name']?.toString() ?? '');
    final details = TextEditingController(text: existing?['details']?.toString() ?? '');
    final amount = TextEditingController(text: existing == null ? '' : '${existing['amount'] ?? 0}');
    String type = existing?['type']?.toString() ?? 'income';
    final result = await showDialog<bool>(context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx,
          setDialogState) => AlertDialog(
          title: Text(t(existing == null ? 'إضافة سجل' : 'تعديل السجل',
              existing == null ? 'Add record' : 'Edit record')),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name,
                  autofocus: true,
                  decoration: InputDecoration(labelText: section.nameLabel(en),
                    border: const OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: details,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: section.detailLabel(en),
                    border: const OutlineInputBorder())),
                if (section.amount) ...[const SizedBox(height: 12),
                  TextField(controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: t('المبلغ أو السعر أو القيمة',
                        'Amount, price or value'),
                      border: const OutlineInputBorder()))],
                if (section.id == 'transactions') ...[const SizedBox(height: 12),
                  DropdownButtonFormField<String>(value: type,
                    decoration: InputDecoration(labelText: t('نوع العملية',
                        'Transaction type'),
                      border: const OutlineInputBorder()),
                    items: [DropdownMenuItem(value: 'income',
                        child: Text(t('إيراد',
                            'Income'))),
                      DropdownMenuItem(value: 'expense',
                        child: Text(t('مصروف',
                            'Expense')))],
                    onChanged: (v)  {
                      if (v != null) setDialogState(() => type = v);
                })],
          ])),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx,
                false),
              child: Text(t('إلغاء',
                  'Cancel'))),
            FilledButton(onPressed: ()  {
                if (name.text.trim().isEmpty)  {
                  notify(t('أدخل الاسم أولاً',
                      'Enter a name first'));
                  return;
                }
                Navigator.pop(ctx,
                  true);
              }, child: Text(t('حفظ',
                  'Save')))],
    )));
    if (result == true)  {
      final record = existing ?? <String,
      dynamic> {
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'created': DateTime.now().toIso8601String(),
        'done': false
      };
      record['name'] = name.text.trim();
      record['details'] = details.text.trim();
      record['amount'] = double.tryParse(amount.text.trim().replaceAll(',',
          '.')) ?? 0.0;
      if (section.id == 'transactions') record['type'] = type;
      setState(()  {
          if (existing == null) data[section.id]!.insert(0,
            record);
      });
      await saveSection(section.id);
      if (mounted) notify(t('تم حفظ السجل',
          'Record saved'));
    }
    name.dispose();
    details.dispose();
    amount.dispose();
  }
  Future<void> deleteRecord(Section section,
    Map<String,
    dynamic> record) async  {
    final yes = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('تأكيد الحذف',
            'Confirm deletion')),
        content: Text(t('هل تريد حذف',
            'Delete') + ' "${record['name']}"?'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx,
              false),
            child: Text(t('إلغاء',
                'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx,
              true),
            child: Text(t('حذف',
                'Delete')))],
    ));
    if (yes == true)  {
      setState(() => data[section.id]!.remove(record));
      await saveSection(section.id);
    }
  }
  Future<void> toggleTask(Map<String,
    dynamic> record) async  {
    setState(() => record['done'] = !(record['done'] == true));
    await saveSection('tasks');
  }
  Map<String,
  dynamic> makeBackup() =>  {
    'format': 'ProDaftarBackup',
    'version': 1,
    'createdAt': DateTime.now().toIso8601String(),
    'businessName': widget.businessName,
    'darkMode': widget.dark,
    'english': widget.english,
    'data':  {
      for (final s in sections) s.id: data[s.id]
    },
  };
  Future<void> exportBackup() async  {
    try  {
      final content = const JsonEncoder.withIndent('  ').convert(makeBackup());
      final bytes = Uint8List.fromList(utf8.encode(content));
      final path = await FilePicker.platform.saveFile(
        dialogTitle: t('حفظ النسخة الاحتياطية',
          'Save backup'),
        fileName: 'pro_daftar_backup_${DateTime.now().toIso8601String().substring(0, 10)}.txt',
        type: FileType.custom,
        allowedExtensions: ['txt'],
        bytes: bytes,
      );
      if (path != null && mounted) notify(t('تم إنشاء ملف النسخة الاحتياطية',
          'Backup file created'));
    }
    catch (e)  {
      if (mounted) notify('${t('تعذر إنشاء النسخة الاحتياطية', 'Could not create backup')}: $e');
    }
  }
  Future<void> importBackup() async  {
    try  {
      final picked = await FilePicker.platform.pickFiles(type: FileType.custom,
        allowedExtensions: ['txt'],
        withData: true);
      if (picked == null || picked.files.isEmpty) return;
      final bytes = picked.files.single.bytes;
      if (bytes == null)  {
        notify(t('تعذر قراءة الملف',
            'Could not read file'));
        return;
      }
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map || decoded['format'] != 'ProDaftarBackup' || decoded['version'] != 1 || decoded['data'] is! Map)  {
        notify(t('هذا الملف ليس نسخة احتياطية صالحة',
            'This is not a valid backup file'));
        return;
      }
      final incoming = decoded['data'] as Map;
      for (final s in sections)  {
        if (incoming[s.id] is! List)  {
          notify(t('النسخة ناقصة أو تالفة',
              'Backup is incomplete or damaged'));
          return;
        }
        for (final item in incoming[s.id] as List)  {
          if (item is! Map || item['name'] == null)  {
            notify(t('النسخة تحتوي على بيانات غير صالحة',
                'Backup contains invalid data'));
            return;
          }
        }
      }
      final confirm = await showDialog<bool>(context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t('استرداد النسخة الاحتياطية؟',
              'Restore backup?')),
          content: Text(t('سيتم استبدال جميع السجلات الحالية بمحتويات النسخة الاحتياطية. لا يمكن التراجع عن ذلك. هل تريد المتابعة؟',
              'All current records will be replaced by the backup. This cannot be undone. Continue?')),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx,
                false),
              child: Text(t('إلغاء',
                  'Cancel'))),
            FilledButton(onPressed: () => Navigator.pop(ctx,
                true),
              child: Text(t('استرداد',
                  'Restore')))],
        ));
        if (confirm != true) return;
        for (final s in sections)  {
          data[s.id] = (incoming[s.id] as List).map((e) => Map<String,
            dynamic>.from(e as Map)).toList();
          await saveSection(s.id);
        }
        final restoredName = (decoded['businessName'] as String?)?.trim();
        if (restoredName != null && restoredName.isNotEmpty)  {
          await prefs!.setString('pro_business_name',
            restoredName);
          widget.onBusinessName(restoredName);
        }
        if (decoded['darkMode'] is bool)  {
          await prefs!.setBool('pro_dark_mode',
            decoded['darkMode'] as bool);
          widget.onTheme(decoded['darkMode'] as bool);
        }
        if (decoded['english'] is bool)  {
          await prefs!.setBool('pro_english',
            decoded['english'] as bool);
          widget.onLanguage(decoded['english'] as bool);
        }
        // Keep the PIN currently configured on this device; backups do not contain PIN data.
        if (mounted) setState(()  {
            selected = -1;
            search = '';
        });
        if (mounted) notify(t('تم استرداد النسخة الاحتياطية',
            'Backup restored successfully'));
      }
      catch (e)  {
        if (mounted) notify('${t('فشل استرداد النسخة', 'Backup restore failed')}: $e');
      }
    }
    Widget stat(String title,
      String value,
      IconData icon) => Card(child: Padding(padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [Icon(icon,
              color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(title),
            const SizedBox(height: 5),
            Text(value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))])));
    Widget dashboard() => ListView(padding: const EdgeInsets.all(16),
      children: [
        Text(t('مرحبًا بك في ${widget.businessName}',
            'Welcome to ${widget.businessName}'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(t('ملخص سريع لنشاطك التجاري',
            'A quick overview of your business')),
        const SizedBox(height: 18),
        GridView.count(crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.25,
          children: [
            stat(t('العملاء',
                'Clients'),
              '${data['clients']!.length}',
              Icons.people),
            stat(t('المواعيد',
                'Appointments'),
              '${data['appointments']!.length}',
              Icons.calendar_month),
            stat(t('الديون المسجلة',
                'Recorded debts'),
              debts.toStringAsFixed(2),
              Icons.account_balance_wallet),
            stat(t('المهام المتبقية',
                'Pending tasks'),
              '${data['tasks']!.where((r) => r['done'] != true).length}',
              Icons.task_alt),
            stat(t('إجمالي الإيرادات',
                'Total income'),
              income.toStringAsFixed(2),
              Icons.trending_up),
            stat(t('إجمالي المصروفات',
                'Total expenses'),
              expenses.toStringAsFixed(2),
              Icons.trending_down),
            stat(t('صافي العمليات',
                'Net transactions'),
              (income - expenses).toStringAsFixed(2),
              Icons.account_balance),
            stat(t('منتجات المخزون',
                'Inventory products'),
              '${data['inventory']!.length}',
              Icons.inventory_2),
        ]),
        const SizedBox(height: 12),
        Card(child: ListTile(leading: const Icon(Icons.info_outline),
            title: Text(t('معلومات مالية',
                'Financial information')),
            subtitle: Text(t('الأرقام تمثل السجلات المدخلة فقط. الديون لا تُخصم تلقائيًا من الإيرادات، وصافي العمليات ليس رصيدًا نقديًا فعليًا.',
                'Figures reflect entered records only. Debts are not automatically deducted from income, and net transactions are not an actual cash balance.')))),
        const SizedBox(height: 16),
        Text(t('الأقسام',
            'Sections'),
          style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...sections.asMap().entries.map((entry)  {
            final i = entry.key;
            final s = entry.value;
            return Card(child: ListTile(leading: CircleAvatar(child: Icon(s.icon)),
                title: Text(s.title(en)),
                subtitle: Text('${data[s.id]!.length} ${t('سجل', 'records')}'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => setState(() => selected = i)));
        }),
    ]);
    Widget sectionPage(Section section)  {
      final records = data[section.id]!.where((r)  {
          if (search.trim().isEmpty) return true;
          final q = search.trim().toLowerCase();
          return (r['name'] ?? '').toString().toLowerCase().contains(q) || (r['details'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
      return Column(children: [
          Padding(padding: const EdgeInsets.all(12),
            child: TextField(onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(hintText: '${t('بحث في', 'Search')} ${section.title(en)}',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))),
          Expanded(child: records.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min,
                children: [Icon(section.icon,
                    size: 50,
                    color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(search.isEmpty ? t('لا توجد سجلات بعد',
                      'No records yet') : t('لا توجد نتائج مطابقة',
                      'No matching results'))])) : ListView.builder(padding: const EdgeInsets.fromLTRB(12,
                0,
                12,
                90),
              itemCount: records.length,
              itemBuilder: (context,
                i)  {
                final r = records[i];
                final done = r['done'] == true;
                final value = amountOf(r);
                return Card(margin: const EdgeInsets.only(bottom: 9),
                  child: ListTile(
                    leading: section.id == 'tasks' ? Checkbox(value: done,
                      onChanged: (_) => toggleTask(r)) : CircleAvatar(child: Icon(section.icon)),
                    title: Text(r['name']?.toString() ?? '',
                      style: TextStyle(fontWeight: FontWeight.bold,
                        decoration: done ? TextDecoration.lineThrough : null)),
                    subtitle: Padding(padding: const EdgeInsets.only(top: 5),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [if ((r['details'] ?? '').toString().isNotEmpty) Text(r['details'].toString()),
                          if (section.amount) Text(section.id == 'transactions' ? '${r['type'] == 'expense' ? t('مصروف', 'Expense') : t('إيراد', 'Income')}: ${value.toStringAsFixed(2)}' : '${t('القيمة', 'Value')}: ${value.toStringAsFixed(2)}',
                            style: TextStyle(color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold))])),
                    trailing: PopupMenuButton<String>(onSelected: (v)  {
                        if (v == 'edit') addRecord(section,
                          existing: r);
                        if (v == 'delete') deleteRecord(section,
                          r);
                        if (v == 'done') toggleTask(r);
                      }, itemBuilder: (_) => [PopupMenuItem(value: 'edit',
                          child: Text(t('تعديل',
                              'Edit'))),
                        if (section.id == 'tasks') PopupMenuItem(value: 'done',
                          child: Text(done ? t('إلغاء الإنجاز',
                              'Mark incomplete') : t('إنجاز',
                              'Mark complete'))),
                        PopupMenuItem(value: 'delete',
                          child: Text(t('حذف',
                              'Delete')))]),
                ));
          })),
      ]);
    }
    Future<void> settings() async  {
      final name = TextEditingController(text: widget.businessName);
      bool dark = widget.dark,
      english = en;
      await showDialog<void>(context: context,
        builder: (ctx) => StatefulBuilder(builder: (ctx,
            setDialogState) => AlertDialog(
            title: Text(t('إعدادات التطبيق',
                'App settings')),
            content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: name,
                    decoration: InputDecoration(labelText: t('اسم النشاط التجاري',
                        'Business name'),
                      border: const OutlineInputBorder())),
                  const SizedBox(height: 10),
                  SwitchListTile(contentPadding: EdgeInsets.zero,
                    title: Text(t('الوضع الليلي',
                        'Dark mode')),
                    value: dark,
                    onChanged: (v) => setDialogState(() => dark = v)),
                  ListTile(contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.language),
                    title: Text(t('لغة التطبيق',
                        'App language')),
                    trailing: DropdownButton<bool>(value: english,
                      items: [DropdownMenuItem(value: false,
                          child: const Text('العربية')),
                        DropdownMenuItem(value: true,
                          child: const Text('English'))],
                      onChanged: (v)  {
                        if (v != null) setDialogState(() => english = v);
                  })),
                  const Divider(),
                  ListTile(contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_outline),
                    title: Text(hasPin ? t('تغيير رمز الأمان',
                        'Change security PIN') : t('تفعيل رمز الأمان',
                        'Enable security PIN')),
                    subtitle: Text(hasPin ? t('الرمز مفعّل',
                        'PIN enabled') : t('حماية عند فتح التطبيق',
                        'Protect app on opening')),
                    onTap: () async  {
                      Navigator.pop(ctx);
                      await configurePin();
                  }),
                  if (hasPin) ListTile(contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_open),
                    title: Text(t('إزالة رمز الأمان',
                        'Remove security PIN')),
                    onTap: () async  {
                      Navigator.pop(ctx);
                      await removePin();
                  }),
                  const Divider(),
                  ListTile(contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.backup),
                    title: Text(t('إنشاء نسخة احتياطية TXT',
                        'Create TXT backup')),
                    subtitle: Text(t('حفظ جميع بيانات التطبيق في ملف',
                        'Save all app data to a file')),
                    onTap: ()  {
                      Navigator.pop(ctx);
                      exportBackup();
                  }),
                  ListTile(contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.restore),
                    title: Text(t('استرداد نسخة احتياطية',
                        'Restore backup')),
                    subtitle: Text(t('اختر ملف TXT سابقًا',
                        'Choose an existing TXT file')),
                    onTap: ()  {
                      Navigator.pop(ctx);
                      importBackup();
                  }),
                  const SizedBox(height: 8),
                  Text(t('تُحفظ البيانات محليًا. احتفظ بنسخة احتياطية خارجية بانتظام.',
                      'Data is stored locally. Keep an external backup regularly.'),
                    style: const TextStyle(fontSize: 12)),
            ])),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx),
                child: Text(t('إلغاء',
                    'Cancel'))),
              FilledButton(onPressed: () async  {
                  final value = name.text.trim().isEmpty ? (english ? 'Pro Daftar' : 'دفتر المحترف') : name.text.trim();
                  await prefs!.setString('pro_business_name',
                    value);
                  await prefs!.setBool('pro_dark_mode',
                    dark);
                  await prefs!.setBool('pro_english',
                    english);
                  widget.onBusinessName(value);
                  widget.onTheme(dark);
                  widget.onLanguage(english);
                  if (mounted) setState(()  {
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                }, child: Text(t('حفظ',
                    'Save')))],
      )));
      name.dispose();
    }
    Widget lockScreen()  {
      final controller = TextEditingController();
      return Scaffold(body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360),
              child: Column(mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(radius: 38,
                    child: Icon(Icons.lock_outline,
                      size: 38)),
                  const SizedBox(height: 22),
                  Text(widget.businessName,
                    style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(t('أدخل رمز الأمان لفتح التطبيق',
                      'Enter your PIN to unlock the app')),
                  const SizedBox(height: 24),
                  TextField(controller: controller,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(labelText: t('رمز الأمان',
                        'Security PIN'),
                      border: const OutlineInputBorder()),
                    onSubmitted: (v) => verifyPin(v.trim())),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity,
                    child: FilledButton(onPressed: () => verifyPin(controller.text.trim()),
                      child: Text(t('فتح التطبيق',
                          'Unlock app')))),
                  const SizedBox(height: 16),
                  Text(t('إذا نسيت الرمز، فلا توجد استعادة تلقائية له.',
                      'If you forget the PIN, it cannot be recovered automatically.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12)),
      ])))));
    }
    @override
    Widget build(BuildContext context)  {
      if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      if (!unlocked) return lockScreen();
      final home = selected == -1;
      final section = home ? null : sections[selected];
      return Scaffold(
        appBar: AppBar(title: Text(section?.title(en) ?? widget.businessName),
          actions: [IconButton(tooltip: t('الإعدادات',
                'Settings'),
              onPressed: settings,
              icon: const Icon(Icons.settings_outlined))]),
        drawer: Drawer(child: SafeArea(child: Column(children: [
                Container(width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [const CircleAvatar(radius: 28,
                        child: Icon(Icons.business_center,
                          size: 30)),
                      const SizedBox(height: 12),
                      Text(widget.businessName,
                        style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(t('إدارة أعمالك من مكان واحد',
                          'Manage your business in one place'))])),
                const Divider(),
                ListTile(leading: const Icon(Icons.dashboard),
                  title: Text(t('لوحة التحكم',
                      'Dashboard')),
                  selected: home,
                  onTap: ()  {
                    setState(() => selected = -1);
                    Navigator.pop(context);
                }),
                Expanded(child: ListView(children: [for (int i = 0;
                        i < sections.length;
                        i++) ListTile(leading: Icon(sections[i].icon),
                        title: Text(sections[i].title(en)),
                        selected: selected == i,
                        onTap: ()  {
                          setState(()  {
                              selected = i;
                              search = '';
                          });
                          Navigator.pop(context);
                })])),
                const Divider(),
                ListTile(leading: const Icon(Icons.settings),
                  title: Text(t('الإعدادات',
                      'Settings')),
                  onTap: ()  {
                    Navigator.pop(context);
                    settings();
                }),
        ]))),
        body: home ? dashboard() : sectionPage(section!),
        floatingActionButton: !home ? FloatingActionButton.extended(onPressed: () => addRecord(section!),
          icon: const Icon(Icons.add),
          label: Text(t('إضافة سجل',
              'Add record'))) : null,
        bottomNavigationBar: NavigationBar(selectedIndex: home ? 0 : selected == 0 ? 1 : 2,
          onDestinationSelected: (i)  {
            if (i == 0) setState(() => selected = -1);
            else if (i == 1) setState(()  {
                selected = 0;
                search = '';
            });
            else settings();
          }, destinations: [NavigationDestination(icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: t('الرئيسية',
                'Home')),
            NavigationDestination(icon: const Icon(Icons.people_outline),
              selectedIcon: const Icon(Icons.people),
              label: t('العملاء',
                'Clients')),
            NavigationDestination(icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: t('الإعدادات',
                'Settings'))]),
      );
    }
  }