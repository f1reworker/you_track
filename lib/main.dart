// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:email_validator/email_validator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
import 'package:async/async.dart';

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

List imageFromClipboard = [];

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _fioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mailController = TextEditingController();
  final _themeController = TextEditingController();
  final _textController = TextEditingController();
  final List<XFile> _pickedImages = [];

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
              _pickedImages.isNotEmpty
                  ? SizedBox(
                      height: 200,
                      child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          itemCount: _pickedImages.length,
                          itemBuilder: (context, index) => Stack(children: [
                                Container(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Image.network(
                                            _pickedImages[index].path))),
                                IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _pickedImages.removeAt(index);
                                      });
                                    },
                                    icon: const Icon(Icons.close))
                              ]),
                          separatorBuilder: (context, index) =>
                              const Divider(color: Colors.transparent)),
                    )
                  : const SizedBox(),
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
    final fromPicker = await ImagePicker().pickMultiImage();
    if (fromPicker != null) {
      setState(() {
        _pickedImages.addAll(fromPicker);
      });
    }
  }

  Widget _buildInputNumber(BuildContext context) {
    return Padding(
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
  }

  Widget _buildInputText(String hintText, TextEditingController controller,
      TextInputType type, int minLines) {
    html.document.onPaste.listen((html.ClipboardEvent e) {
      if (e.clipboardData?.items![0].type == 'image/png') {
        html.File image = e.clipboardData!.items![0].getAsFile()!;

        setState(() {
          imageFromClipboard.add(image);
        });
      }
    });
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        toolbarOptions: const ToolbarOptions(
            copy: true, paste: true, cut: true, selectAll: true),
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
  }

  saveForm() async {
    final isValid = _formKey.currentState!.validate();
    if (isValid) {
      httpPost(_fioController.text, _phoneController.text, _mailController.text,
          _themeController.text, _textController.text, _pickedImages);
    }
  }

  uploadImage(String imageFilePath, Uint8List imageBytes, String id) async {
    String url =
        "http://172.18.1.207/api/issues/$id/attachments?fields=id,name";
    PickedFile imageFile = PickedFile(imageFilePath);
    var stream = http.ByteStream(DelegatingStream.typed(imageFile.openRead()));

    var uri = Uri.parse(url);
    int length = imageBytes.length;
    var request = http.MultipartRequest("POST", uri);
    var multipartFile = http.MultipartFile('files', stream, length,
        filename: basename(imageFile.path),
        contentType: MediaType('image', 'png'));

    request.files.add(multipartFile);
    request.headers.addAll({
      'Accept': "application/json",
      'Authorization':
          'Bearer perm:YWRtaW4=.NDctMTM=.DBhGgPTunKliw4DKjQa1R6D7Dkcu93',
      'Content-Type': 'multipart/form-data'
    });
    var response = await request.send();
    print(response.statusCode);
    response.stream.transform(utf8.decoder).listen((value) {
      print(value);
    });
  }

  httpPost(String fio, String phone, String email, String theme, String text,
      List<XFile> filename) async {
    String url = "http://172.18.1.207/api/issues";
    var body = json.encode({
      "project": {"id": "0-72"},
      "summary": theme,
      "description": "ФИО: $fio \nТелефон: $phone\nEmail: $email\n$text"
    });
    try {
      var responce = await http.post(Uri.parse(url),
          headers: {
            'Accept': "application/json",
            'Authorization':
                'Bearer perm:YWRtaW4=.NDctMTM=.DBhGgPTunKliw4DKjQa1R6D7Dkcu93',
            'Content-Type': 'application/json'
          },
          body: body);
      if (responce.statusCode == 200) {
        final body = json.decode(responce.body);
        String id = body["id"];
        if (filename.isNotEmpty) {
          for (int i = 0; i < filename.length; i++) {
            uploadImage(filename[i].path, await filename[i].readAsBytes(), id);
          }
        }
      }
      setState(() {
        _pickedImages.clear();
        _themeController.text = "";
        _textController.text = "";
      });
    } catch (error) {
      print("error: $error");
    }
  }
}
