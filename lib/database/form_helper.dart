import 'package:flutter/material.dart';
import '../const/Palette.dart';

class FormHelper {
  static Widget textInput(
    BuildContext context,
    Object initialValue,
    Function onChanged, {
    bool isTextArea = false,
    bool isNumberInput = false,
    Function? onValidate,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      initialValue: initialValue != "null" ? initialValue.toString() : "",
      decoration: fieldDecoration(context, "", ""),
      maxLines: !isTextArea ? 1 : 3,
      keyboardType: isNumberInput ? TextInputType.number : TextInputType.text,
      onChanged: (String value) {
        return onChanged(value);
      },
      validator: (value) {
        return onValidate!(value);
      },
    );
  }

  static InputDecoration fieldDecoration(
    BuildContext context,
    String hintText,
    String helperText, {
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      contentPadding: EdgeInsets.all(6),
      hintText: hintText,
      helperText: helperText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 1,
        ),
      ),
      border: OutlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 1,
        ),
      ),
    );
  }

  static Widget fieldLabel(String labelName) {
    return new Padding(
      padding: EdgeInsets.fromLTRB(0, 5, 0, 10),
      child: Text(
        labelName,
        style: new TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15.0,
        ),
      ),
    );
  }

  static void showMessage(BuildContext context, String title, String message, String buttonText, Function onPressed, {bool isConfirmationDialog = false, String buttonText2 = "", Function? onPressed2}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: EdgeInsets.fromLTRB(20, 0, 20, 12),
          actionsPadding: EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: Palette.blue.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_none_outlined, color: Palette.blue, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Palette.dark_blue, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Palette.dark_grey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                return onPressed();
              },
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: 14,
                  color: Palette.dark_grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Visibility(
              visible: isConfirmationDialog,
              child: ElevatedButton(
                onPressed: () {
                  return onPressed2!();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  buttonText2,
                  style: TextStyle(
                    fontSize: 14,
                    color: Palette.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
