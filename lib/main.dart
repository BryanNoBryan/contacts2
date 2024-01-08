import 'dart:developer';
import 'dart:math' show Random;

import 'package:contacts2/NotificationService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sms/flutter_sms.dart';

import 'DatabaseHelper.dart';
import 'Contact.dart';

// import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // tz.initializeTimeZones();
  await DatabaseHelper().initDB();
  // await NotificationService().initNotification();
  runApp(const SqliteDemoApp());
}

class SqliteDemoApp extends StatelessWidget {
  const SqliteDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQLite demo',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const MainApp(title: 'SQLite demo'),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late DatabaseHelper dbHelper;
  bool isEditing = false;
  late Contact contact;

  final first_name = TextEditingController();
  final last_name = TextEditingController();
  final company = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final birthdayController =
      TextEditingController(text: DateTime.now().toString());
  DateTime birthday = DateTime.now();

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
                child: Column(
              children: [
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Form(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          TextFormField(
                            controller: first_name,
                            decoration: const InputDecoration(
                                hintText: 'first_name',
                                labelText: 'first_name'),
                          ),
                          TextFormField(
                            controller: last_name,
                            decoration: const InputDecoration(
                                hintText: 'last_name', labelText: 'last_name'),
                          ),
                          TextFormField(
                            controller: company,
                            decoration: const InputDecoration(
                                hintText: 'company', labelText: 'company'),
                          ),
                          TextFormField(
                            controller: phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                                hintText: 'phone', labelText: 'phone'),
                          ),
                          TextFormField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                                hintText: 'email', labelText: 'email'),
                          ),
                          TextFormField(
                            controller: address,
                            keyboardType: TextInputType.streetAddress,
                            decoration: const InputDecoration(
                                hintText: 'address', labelText: 'address'),
                          ),
                          TextFormField(
                            onTap: () async {
                              log('tapped');
                              final DateTime? newDate = await showDatePicker(
                                context: context,
                                initialDate: birthday,
                                firstDate: birthday,
                                lastDate: birthday,
                                helpText: 'Select a date',
                              );
                              birthday = newDate ?? birthday;
                              birthdayController.text = birthday.toString();
                            },
                            controller: birthdayController,
                            readOnly: true,
                            decoration:
                                const InputDecoration(labelText: 'Birthday'),
                          ),

                          // TextFormField(
                          //   controller: ageController,
                          //   keyboardType: TextInputType.number,
                          //   inputFormatters: [
                          //     FilteringTextInputFormatter.allow(
                          //         RegExp(r'[0-9]')),
                          //   ],
                          //   decoration: const InputDecoration(
                          //       hintText: 'Enter your age', labelText: 'Age'),
                          // ),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: ElevatedButton(
                                      onPressed: addOrEditUser,
                                      child: const Text('Submit'),
                                    )),
                              ])
                        ]))),
                Expanded(
                  flex: 1,
                  child: SafeArea(child: userWidget()),
                )
              ],
            )),
          ],
        ));
  }

  Future<void> addOrEditUser() async {
    String VALfirst_name = first_name.text;
    String VALlast_name = last_name.text;
    String VALcompany = company.text;
    String VALphone = phone.text;
    String VALemail = email.text;
    String VALaddress = address.text;

    if (!isEditing) {
      Contact user = Contact(
          first_name: VALfirst_name,
          last_name: VALlast_name,
          company: VALcompany,
          phone: VALphone,
          email: VALemail,
          address: VALaddress,
          birthday: birthday);
      await addUser(user);
    } else {
      // contact.email = email;
      // contact.age = int.parse(age);
      // contact.name = name;
      await updateUser(contact);
    }

    _sendSMS('Super Idol', ['1111111111']);

    // log('reached here');
    // await NotificationService().scheduleNotification(
    //     title: 'Happy Birthday!',
    //     body: '${first_name.text} ${last_name.text}',
    //     scheduledNotificationDateTime:
    //         DateTime.now().add(const Duration(seconds: 2)));

    // log('reached here2');
    resetData();
    setState(() {});
  }

  Future<void> _sendSMS(String msg, List<String> recipients) async {
    try {
      String _result = await sendSMS(
        message: msg,
        recipients: recipients,
        sendDirect: false,
      );
    } catch (error) {
      print(error.toString());
    }
  }

  Future<int> addUser(Contact user) async {
    return await dbHelper.insert(user);
  }

  Future<int> updateUser(Contact user) async {
    return await dbHelper.update(user);
  }

  void resetData() {
    first_name.clear();
    last_name.clear();
    company.clear();
    phone.clear();
    email.clear();
    address.clear();
    birthdayController.clear();
    isEditing = false;
  }

  Widget userWidget() {
    return FutureBuilder(
      future: dbHelper.retrieve(),
      builder: (BuildContext context, AsyncSnapshot<List<Contact>> snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
              itemCount: snapshot.data?.length,
              itemBuilder: (context, position) {
                return Dismissible(
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: const Icon(Icons.delete_forever),
                    ),
                    key: UniqueKey(),
                    onDismissed: (DismissDirection direction) async {
                      await dbHelper.delete(snapshot.data![position].id!);
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // onTap: () => populateFields(snapshot.data![position]),
                      child: Container(
                        margin: EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.amber[50]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  12.0, 12.0, 12.0, 6.0),
                              child: Text(
                                snapshot.data![position].first_name,
                                style: const TextStyle(
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  12.0, 12.0, 12.0, 6.0),
                              child: Text(
                                snapshot.data![position].last_name,
                                style: const TextStyle(
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  12.0, 12.0, 12.0, 6.0),
                              child: Text(
                                snapshot.data![position].company,
                                style: const TextStyle(
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  12.0, 12.0, 12.0, 6.0),
                              child: Text(
                                snapshot.data![position].phone,
                                style: const TextStyle(
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  12.0, 12.0, 12.0, 6.0),
                              child: Text(
                                snapshot.data![position].email,
                                style: const TextStyle(
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  12.0, 12.0, 12.0, 6.0),
                              child: Text(
                                snapshot.data![position].address,
                                style: const TextStyle(
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  12.0, 12.0, 12.0, 6.0),
                              child: Text(
                                snapshot.data![position].birthday.toString(),
                                style: const TextStyle(
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Divider(
                              height: 2.0,
                              color: Colors.grey,
                            )
                          ],
                        ),
                      ),
                    ));
              });
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  // void populateFields(Contact user) {
  //   contact = user;
  //   nameController.text = contact.name;
  //   ageController.text = contact.age.toString();
  //   emailController.text = contact.email;
  //   isEditing = true;
  // }
}
