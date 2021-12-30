import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:image_picker_web/image_picker_web.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:email_validator/email_validator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_web/image_picker_web.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const MyHomePage(title: 'YouTrack'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _fioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mailController = TextEditingController();
  final _themeController = TextEditingController();
  final _textController = TextEditingController();
  final _pickedImages = <Image>[];

  @override
  void dispose() {
    _fioController.dispose();
    _phoneController.dispose();
    _mailController.dispose();
    _themeController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            shrinkWrap: true,
            children: [
              _buildInputText("ФИО", _fioController, TextInputType.text, 1),
              _buildInputNumber(context),
              _buildInputText(
                  "почта", _mailController, TextInputType.emailAddress, 1),
              _buildInputText(
                  "тема задачи", _themeController, TextInputType.text, 2),
              _buildInputText(
                  "текст задачи", _textController, TextInputType.text, 3),
              Container(
                padding: const EdgeInsets.only(left: 10),
                alignment: Alignment.centerLeft,
                height: 60,
                width: 180,
                child: ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Выбрать изображение'),
                ),
              ),
              Container(
                  alignment: Alignment.centerLeft,
                  height: _pickedImages.isNotEmpty ? 200 : 0,
                  child: _pickedImages.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _pickedImages[0],
                        )
                      : const SizedBox()),
              Container(
                  padding: const EdgeInsets.only(left: 10),
                  alignment: Alignment.centerLeft,
                  height: 60,
                  width: 480,
                  child: ElevatedButton.icon(
                    onPressed: () => saveForm(),
                    icon: const Icon(Icons.done),
                    label: const Text('Сохранить'),
                  )),
            ],
          ),
        ));
  }

  Future<void> _pickImage() async {
    final fromPicker = await ImagePickerWeb.getImageAsWidget();
    if (fromPicker != null) {
      setState(() {
        _pickedImages.clear();
        _pickedImages.add(fromPicker);
      });
    }
  }

  Widget _buildInputNumber(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          validator: (value) =>
              isPhoneValid(value!) ? null : "Телефон некорректен",
          minLines: 1,
          maxLines: 2,
          style: const TextStyle(fontSize: 24),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: const BorderSide(width: 1, color: Colors.grey),
              borderRadius: BorderRadius.circular(15),
            ),
            hintText: "телефон",
          ),
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          autocorrect: false,
          inputFormatters: [PhoneInputFormatter()],
        ),
      );

  Widget _buildInputText(String hintText, TextEditingController controller,
          TextInputType type, int minLines) =>
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          minLines: minLines,
          maxLines: 100,
          validator: (value) {
            if (value != null && value.isEmpty) {
              return "поле  не заполнено";
            } else {
              if (hintText == "почта") {
                if (!EmailValidator.validate(value!)) {
                  return "почта некорректна";
                }
              }
            }
          },
          keyboardType: type,
          controller: controller,
          style: const TextStyle(fontSize: 24),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: const BorderSide(width: 1, color: Colors.grey),
              borderRadius: BorderRadius.circular(15),
            ),
            hintText: hintText,
          ),
        ),
      );

  saveForm() {
    final isValid = _formKey.currentState!.validate();
    if (isValid) {
      print(_fioController.text +
          "   " +
          _phoneController.text +
          "   " +
          _mailController.text +
          "  " +
          _themeController.text +
          "   " +
          _textController.text);
      print(_pickedImages);
      setState(() {
        _pickedImages.clear();
        _themeController.text = "";
        _textController.text = "";
      });
    }
  }
}
