class Contact {
  int? id;
  String first_name;
  String last_name;
  String company;
  String phone;
  String email;
  String address;
  DateTime birthday;

  Contact(
      {this.id,
      required this.first_name,
      required this.last_name,
      required this.company,
      required this.phone,
      required this.email,
      required this.address,
      required this.birthday});

  Contact.fromMap(Map<String, dynamic> res)
      : id = res["id"],
        first_name = res["first_name"],
        last_name = res["last_name"],
        company = res["company"],
        phone = res["phone"],
        email = res["email"],
        address = res["address"],
        birthday = DateTime.parse(res["birthday"]);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'first_name': first_name,
      'last_name': last_name,
      'company': company,
      'phone': phone,
      'email': email,
      'address': address,
      'birthday': birthday.toIso8601String()
    };
  }
}
