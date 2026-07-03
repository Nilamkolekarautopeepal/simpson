const bool defaultBool = false;
const int defaultInt = 0;
const double defaultDouble = 0;
const String defaultString = '';
const Map<String, dynamic> defaultMap = {};
const List defaultList = [];

/// extension methods for Map

extension MapExtension on Map {
  //for String Value from Map
  // Reads a [key] value of [String] type from [Map].
  // If value is NULL or not [String] type return default value [defaultString]

  String getString(String key) {
    Map data = this;
    if (data.isEmpty) {
      data = defaultMap;
    }
    if (data.containsKey(key)) {
      if (data[key] != null) {
        return data[key].toString();
      } else {
        return defaultString;
      }
    }
    return defaultString;
  }

//for bool value from Map
  // Reads a [key] value of [bool] type from [Map].
  // If value is NULL or not [bool] type return default value [defaultBool]
  bool getBool(String key) {
    Map data = this;
    if (data.isEmpty) {
      data = defaultMap;
    }
    if (data.containsKey(key)) {
      if (data[key] != null) {
        if (data[key] is bool) {
          return data[key] ?? defaultBool;
        }
      }
    }
    return defaultBool;
  }

//for Integer value from Map
  // Reads a [key] value of [int] type from [Map].
  // If value is NULL or not [int] type return default value [defaultInt]
  int getInt(String key) {
    Map data = this;
    if (data.isEmpty) {
      data = defaultMap;
    }
    if (data.containsKey(key)) {
      if (data[key] != null) {
        // toInt(data[key])
        return data[key] ?? defaultInt;
      }
    }
    return defaultInt;
  }

//for Double Value from Map
  // Reads a [key] value of [double] type from [Map].
  // If value is NULL or not [double] type return default value [defaultDouble]
  double getDouble(String key) {
    Map data = this;
    if (data.isEmpty) {
      data = defaultMap;
    }
    if (data.containsKey(key)) {
      if (data[key] != null) {
        if (data[key] is double) {
          return data[key] ?? defaultDouble;
        }
      }
    }
    return defaultDouble;
  }

//for List from Map
  // Reads a [key] value of [List] type from [Map].
  // If value is NULL or not [List] type return default value [defaultList]

  List getList(String key) {
    Map data = this;

    if (data.isEmpty) {
      data = {};
    }
    if (data.containsKey(key)) {
      if (data[key] is List) {
        return data[key] ?? defaultList;
      }
    }

    return defaultList;
  }

//for Map from Map
  // Reads a [key] value of [Map] type from [Map].

  Map<String, dynamic> getMap(String key) {
    Map data = this;
    if (data.isEmpty) {
      data = {};
    }
    if (data.containsKey(key)) {
      if (data[key] is Map<String, dynamic>) {
        return data[key] ?? defaultMap;
      }
    }
    return defaultMap;
  }
}

//Extension Method For List
extension ListExtension on List {
  //for String Value from list
  // Reads a [key] value of [String] type from [List].
  // If value is NULL or not [String] type return default value [defaultString]
  String getString(String key, int index) {
    List data = this;
    if (data.isEmpty) {
      data = defaultList;
    }
    if (data[index][key] != null) {
      if (data[index][key] is String) {
        return data[index][key] ?? defaultString;
      }
    }
    return defaultString;
  }

//for Int Value from list
  // Reads a [key] value of [int] type from [List].
  // If value is NULL or not [int] type return default value [defaultInt]
  int getInt(String key, int index) {
    List data = this;
    if (data.isEmpty) {
      data = defaultList;
    }
    if (data[index][key] != null) {
      if (data[index][key] is int) {
        return data[index][key] ?? defaultInt;
      }
    }
    return defaultInt;
  }

  //for Bool Value from list
  // Reads a [key] value of [bool] type from [List].
  // If value is NULL or not [bool] type return default value
  bool getBool(String key, int index) {
    List data = this;
    if (data[index][key] != null) {
      if (data[index][key] is bool) {
        return data[index][key] ?? defaultBool;
      }
    }
    return defaultBool;
  }

//for Double Value from list
  // Reads a [key] value of [double] type from [List].
  // If value is NULL or not [double] type return default value [defaultDouble]
  double getDouble(String key, int index) {
    List data = this;
    if (data.isEmpty) {
      data = defaultList;
    }
    if (data[index][key] != null) {
      if (data[index][key] is double) {
        return data[index][key] ?? defaultDouble;
      }
    }
    return defaultDouble;
  }

  //for Map from list
  // Reads a [key] value of [Map] type from [List].
  // If value is NULL or not [Map] type return default value [defaultMap]
  Map<String, dynamic> getMap(int index) {
    List data = this;
    if (data.isEmpty) {
      data = defaultList;
    }
    if (data[index] is Map) {
      return data[index] ?? defaultMap;
    }
    return defaultMap;
  }
}
