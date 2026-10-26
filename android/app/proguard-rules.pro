# ProGuard / R8 rules for VKU Expense AI

# ML Kit Text Recognition optional non-Latin script warning suppressions
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.**

# Keep ML Kit text recognition classes
-keep class com.google.mlkit.vision.text.** { *; }

# Keep Flutter method channel handlers
-keep class vn.edu.vku.vku_expense_ocr.** { *; }
