class BytesConverter {
  /// Converts a Hex String (e.g., "414243") to an ASCII String (e.g., "ABC")
  /// Matches C# BytesConverter.HexToASCII
  static String hexToASCII(String hex) {
    // Remove any spaces if they exist in the hex string
    String cleanHex = hex.replaceAll(' ', '');
    
    String ascii = "";

    try {
      for (int i = 0; i < cleanHex.length; i += 2) {
        // Extract two characters
        String part = cleanHex.substring(i, i + 2);

        // Convert hex part to integer and then to a character
        int charCode = int.parse(part, radix: 16);
        ascii += String.fromCharCode(charCode);
      }
    } catch (e) {
      // If parsing fails (e.g., malformed hex), return what we have or an empty string
      print("Error converting Hex to ASCII: $e");
    }

    return ascii;
  }
}