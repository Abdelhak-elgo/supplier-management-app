class Validators {
  // Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  // Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email may be optional
    }
    
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    
    if (!emailRegExp.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    
    return null;
  }
  
  // Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone may be optional
    }
    
    final phoneRegExp = RegExp(r'^\+?[0-9]{10,15}$');
    
    if (!phoneRegExp.hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    
    return null;
  }
  
  // Validate numeric value
  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    if (double.tryParse(value) == null) {
      return '$fieldName must be a number';
    }
    
    return null;
  }
  
  // Validate positive numeric value
  static String? validatePositiveNumeric(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final number = double.tryParse(value);
    
    if (number == null) {
      return '$fieldName must be a number';
    }
    
    if (number <= 0) {
      return '$fieldName must be greater than zero';
    }
    
    return null;
  }
  
  // Validate integer
  static String? validateInteger(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    if (int.tryParse(value) == null) {
      return '$fieldName must be a whole number';
    }
    
    return null;
  }
  
  // Validate positive integer
  static String? validatePositiveInteger(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final number = int.tryParse(value);
    
    if (number == null) {
      return '$fieldName must be a whole number';
    }
    
    if (number <= 0) {
      return '$fieldName must be greater than zero';
    }
    
    return null;
  }
  
  // Validate non-negative integer
  static String? validateNonNegativeInteger(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final number = int.tryParse(value);
    
    if (number == null) {
      return '$fieldName must be a whole number';
    }
    
    if (number < 0) {
      return '$fieldName cannot be negative';
    }
    
    return null;
  }
  
  // Validate price
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }
    
    final number = double.tryParse(value);
    
    if (number == null) {
      return 'Price must be a number';
    }
    
    if (number < 0) {
      return 'Price cannot be negative';
    }
    
    return null;
  }
  
  // Validate quantity
  static String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantity is required';
    }
    
    final number = int.tryParse(value);
    
    if (number == null) {
      return 'Quantity must be a whole number';
    }
    
    if (number < 0) {
      return 'Quantity cannot be negative';
    }
    
    return null;
  }
  
  // Validate min stock level
  static String? validateMinStockLevel(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Minimum stock level is required';
    }
    
    final number = int.tryParse(value);
    
    if (number == null) {
      return 'Minimum stock level must be a whole number';
    }
    
    if (number < 0) {
      return 'Minimum stock level cannot be negative';
    }
    
    return null;
  }
}
