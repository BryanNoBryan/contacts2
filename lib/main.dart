import 'dart:developer';
import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';

import 'DatabaseHelper.dart';
import 'Contact.dart';

import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().initDB();

  AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      null,
      [
        NotificationChannel(
            channelGroupKey: 'basic_channel_group',
            channelKey: 'basic_channel',
            channelName: 'Basic notifications',
            channelDescription: 'Notification channel for basic tests',
            defaultColor: Color(0xFF9D50DD),
            ledColor: Colors.white)
      ],
      // Channel groups are only visual and are not required
      channelGroups: [
        NotificationChannelGroup(
            channelGroupKey: 'basic_channel_group',
            channelGroupName: 'Basic group')
      ],
      debug: true);
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      // This is just a basic example. For real apps, you must show some
      // friendly dialog box before call the request method.
      // This is very important to not harm the user experience
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });

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
  late Contact contact = Contact(
      first_name: '',
      last_name: '',
      company: '',
      phone: '',
      email: '',
      address: '',
      birthday: DateTime.now());

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

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: (ReceivedAction receivedAction) async {
        log('1');
      },
      onNotificationCreatedMethod:
          (ReceivedNotification receivedNotification) async {
        log('2');
      },
      onNotificationDisplayedMethod:
          (ReceivedNotification receivedNotification) async {
        if (receivedNotification.id == 11) {
          _sendSMS('Super Idol', ['1111111111']);
        }
        log('3');
      },
      onDismissActionReceivedMethod: (ReceivedAction receivedAction) async {
        log('4');
      },
    );
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

                              final DateTime? newDate =
                                  await showDateTimePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: birthday,
                                lastDate: DateTime.now()
                                    .add(const Duration(hours: 10000000)),
                              );
                              birthday = newDate ?? birthday;
                              birthdayController.text = birthday.toString();
                            },
                            controller: birthdayController,
                            readOnly: true,
                            decoration:
                                const InputDecoration(labelText: 'Birthday'),
                          ),
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

  Future<DateTime?> showDateTimePicker({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    initialDate ??= DateTime.now();
    firstDate ??= initialDate.subtract(const Duration(days: 365 * 100));
    lastDate ??= firstDate.add(const Duration(days: 365 * 200));

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate.isBefore(initialDate) ? initialDate : DateTime.now(),
      lastDate: lastDate,
    );

    if (selectedDate == null) return null;

    if (!context.mounted) return selectedDate;

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDate),
    );

    return selectedTime == null
        ? selectedDate
        : DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
  }

  Future<void> addOrEditUser() async {
    String VALfirst_name = first_name.text;
    String VALlast_name = last_name.text;
    String VALcompany = company.text;
    String VALphone = phone.text;
    String VALemail = email.text;
    String VALaddress = address.text;

    contact.first_name = VALfirst_name;
    contact.last_name = VALlast_name;
    contact.company = VALcompany;
    contact.phone = VALphone;
    contact.email = VALemail;
    contact.address = VALaddress;
    contact.birthday = birthday;

    if (!isEditing) {
      await addUser(contact);
    } else {
      await updateUser(contact);
    }

    // _sendSMS('Super Idol', ['1111111111']);

    AwesomeNotifications().createNotification(
        content: NotificationContent(
      id: 10,
      channelKey: 'basic_channel',
      actionType: ActionType.Default,
      title: 'Notification set for your birthday!',
      body: '${contact.first_name} ${contact.last_name}',
    ));

    String localTimeZone =
        await AwesomeNotifications().getLocalTimeZoneIdentifier();
    String utcTimeZone =
        await AwesomeNotifications().getLocalTimeZoneIdentifier();

    log(localTimeZone);
    log(utcTimeZone);

    DateTime time = DateTime.now();

    //BIRTHDAY SCHEDULING
    // time.add(birthday.difference(DateTime.now()));

    //USING THIS JUST FOR FASTER TESTING
    time.add(const Duration(seconds: 3));

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 11,
        channelKey: 'basic_channel',
        title: 'Happy Birthday!',
        body: '${contact.first_name} ${contact.last_name}',
        wakeUpScreen: true,
        category: NotificationCategory.Event,
      ),
      schedule:
          // NotificationInterval(interval: 5, timeZone: localTimeZone, repeats: false), OR
          NotificationCalendar(
        day: time.day,
        month: time.month,
        year: time.year,
        hour: time.hour,
        second: time.second,
        timeZone: localTimeZone,
        preciseAlarm: true,
      ),
    );

    log('reached here2');
    resetData();
    setState(() {});
  }

  Future<void> _sendSMS(String msg, List<String> recipients) async {
    try {
      String _result = await sendSMS(
        message: msg,
        recipients: recipients,
        sendDirect: true,
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
                      onTap: () => populateFields(snapshot.data![position]),
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
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  12.0, 12.0, 12.0, 6.0),
                              child: Text(
                                snapshot.data![position].last_name,
                                style: const TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  12.0, 12.0, 12.0, 6.0),
                              child: Text(
                                snapshot.data![position].company,
                                style: const TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  12.0, 12.0, 12.0, 6.0),
                              child: Text(
                                snapshot.data![position].phone,
                                style: const TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  12.0, 12.0, 12.0, 6.0),
                              child: Text(
                                snapshot.data![position].email,
                                style: const TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  12.0, 12.0, 12.0, 6.0),
                              child: Text(
                                snapshot.data![position].address,
                                style: const TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  12.0, 12.0, 12.0, 6.0),
                              child: Text(
                                snapshot.data![position].birthday.toString(),
                                style: const TextStyle(
                                    fontSize: 12.0,
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

  void populateFields(Contact user) {
    contact = user;
    first_name.text = contact.first_name;
    last_name.text = contact.last_name;
    company.text = contact.company;
    phone.text = contact.phone;
    email.text = contact.email;
    address.text = contact.address;
    contact.birthday = birthday;
    birthdayController.text = birthday.toString();

    isEditing = true;
  }
}
