class Message {
  Message({
    required this.told,
    required this.msg,
    required this.read,
    required this.type,
    required this.fromId,
    required this.sent,
  });

  late final String told;
  late final String msg;
  late final String read;
  late final String fromId;
  late final String sent;
  late final MyType  type;

  Message.fromJson(Map<String, dynamic> json){
      told = json['told'].toString();
      msg = json['msg'].toString();
      read = json['read'].toString();
      type = json['type'] == MyType.image.name ? MyType.image : MyType.text;
      fromId = json['fromId'].toString();
      sent = json['sent'].toString();
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['told'] = told;
    data['msg'] = msg;
    data['read'] = read;
    data['type'] = type.name;
    data['fromId'] = fromId;
    data['sent'] = sent;
    return data;
  }

}

enum MyType  { text, image }

