class Debug {
  Map<String, dynamic> send(Map<String, dynamic> content) {
    print(content);
    return content;
  }

  Map<String, dynamic> formatException() {
    return send({"message": "Некорректный формат JSON"});
  }

  Map<String, dynamic> internalServerError() {
    return send({"message": "Internal server error"});
  }
}
