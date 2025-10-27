class ClassModel {
  final String id;
  final String name;

  ClassModel({required this.id, required this.name});
  factory ClassModel.fromJson(Map<String, dynamic> json){
    return ClassModel(
      id:json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'name': name, 
    };
  }

}