// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:flutter_uploader_example/server_behavior.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UploadScreen extends StatefulWidget {
  UploadScreen({
    Key key,
    @required this.uploader,
    @required this.uploadURL,
    @required this.onUploadStarted,
  }) : super(key: key);

  final FlutterUploader uploader;
  final Uri uploadURL;
  final VoidCallback onUploadStarted;

  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  ImagePicker imagePicker = ImagePicker();

  ServerBehavior _serverBehavior = ServerBehavior.defaultOk200;

  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid) {
      imagePicker.getLostData().then((lostData) {
        if (lostData == null) {
          return;
        }

        if (lostData.type == RetrieveType.image) {
          _handleFileUpload([lostData.file.path]);
        }
        if (lostData.type == RetrieveType.video) {
          _handleFileUpload([lostData.file.path]);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Uploader'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Configure test Server Behavior',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                DropdownButton<ServerBehavior>(
                  items: ServerBehavior.all.map((e) {
                    return DropdownMenuItem(
                        child: Text('${e.title}'), value: e);
                  }).toList(),
                  onChanged: (newBehavior) {
                    setState(() => _serverBehavior = newBehavior);
                  },
                  value: _serverBehavior,
                ),
                Divider(),
                Text(
                  'multipart/form-data uploads',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  children: <Widget>[
                    RaisedButton(
                      onPressed: () => getImage(binary: false),
                      child: Text('upload image'),
                    ),
                    RaisedButton(
                      onPressed: () => getVideo(binary: false),
                      child: Text('upload video'),
                    ),
                    RaisedButton(
                      onPressed: () => getMultiple(binary: false),
                      child: Text('upload multi'),
                    ),
                  ],
                ),
                Divider(height: 40),
                Text(
                  'binary uploads',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                Text('this will upload selected files as binary'),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  children: <Widget>[
                    RaisedButton(
                      onPressed: () => getImage(binary: true),
                      child: Text('upload image'),
                    ),
                    RaisedButton(
                      onPressed: () => getVideo(binary: true),
                      child: Text('upload video'),
                    ),
                    RaisedButton(
                      onPressed: () => getMultiple(binary: true),
                      child: Text('upload multi'),
                    ),
                  ],
                ),
                Divider(height: 40),
                Text('Cancellation'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    RaisedButton(
                      onPressed: () => widget.uploader.cancelAll(),
                      child: Text('Cancel All'),
                    ),
                    Container(width: 20.0),
                    RaisedButton(
                      onPressed: () {
                        widget.uploader.clearUploads();
                      },
                      child: Text('Clear Uploads'),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future getImage({@required bool binary}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('binary', binary);

    var image = await imagePicker.getImage(source: ImageSource.gallery);

    if (image != null) {
      _handleFileUpload([image.path]);
    }
  }

  Future getVideo({@required bool binary}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('binary', binary);

    var video = await imagePicker.getVideo(source: ImageSource.gallery);

    if (video != null) {
      _handleFileUpload([video.path]);
    }
  }

  Future getMultiple({@required bool binary}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('binary', binary);

    final files = await FilePicker.getMultiFilePath(allowCompression: false);
    if (files?.isNotEmpty == true) {
      if (binary) {
        for (var path in files.values) {
          _handleFileUpload([path]);
        }
      } else {
        _handleFileUpload(files.values.toList());
      }
    }
  }

  void _handleFileUpload(List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    final binary = prefs.getBool('binary') ?? false;

    await widget.uploader.enqueue(_buildUpload(binary, paths));

    widget.onUploadStarted();
  }

  Upload _buildUpload(bool binary, List<String> paths) {
    final tag = 'upload';

    var url = binary
        ? widget.uploadURL.replace(path: widget.uploadURL.path + 'Binary')
        : widget.uploadURL;

    url = url.replace(queryParameters: {
      'simulate': _serverBehavior.name,
    });

    if (binary) {
      return RawUpload(
        url: url.toString(),
        path: paths.first,
        method: UploadMethod.POST,
        tag: tag,
      );
    } else {
      return MultipartFormDataUpload(
        url: url.toString(),
        data: {'name': 'john'},
        files: paths.map((e) => FileItem(path: e, field: 'file')).toList(),
        method: UploadMethod.POST,
        tag: tag,
      );
    }
  }
}
