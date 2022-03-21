import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/file_controller.dart';
import 'package:flutter_code_editor/editor/editor.dart';
import 'package:flutter_code_editor/editor/file_explorer/file_explorer.dart';
import 'package:flutter_code_editor/editor/preview/preview.dart';
import 'package:flutter_code_editor/enums/language.dart';
import 'package:flutter_code_editor/models/file_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as dev;

// ignore: must_be_immutable
class EditorViewController extends StatefulWidget {
  EditorViewController(
      {Key? key,
      this.title = '',
      this.codePreview = true,
      this.tabBarColor = const Color.fromRGBO(0x0a, 0x0a, 0x23, 1),
      this.scaffoldBackgrounColor = const Color.fromRGBO(0x3b, 0x3b, 0x4f, 1),
      this.recentlyOpenedFiles = const [],
      this.file,
      this.tabBarLineColor = Colors.white})
      : super(key: key);

  final String title;

  final bool codePreview;

  final Color tabBarColor;

  final Color tabBarLineColor;

  final Color scaffoldBackgrounColor;

  List<FileIDE> recentlyOpenedFiles;

  final FileIDE? file;

  @override
  State<StatefulWidget> createState() => EditorViewControllerState();
}

class EditorViewControllerState extends State<EditorViewController> {
  Editor? editor;

  @override
  void initState() {
    super.initState();
    editor = Editor(
      language: Language.html,
      openedFile: widget.file,
      onChange: () {},
    );

    setRecentlyOpenedFilesInDir();
  }

  Future<void> setRecentlyOpenedFilesInDir() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (widget.file == null) return;

    String key = (widget.file?.parentDirectory as String) + '-recently-opened';

    List<String> recentlyOpenedFiles = [];

    List<String>? cache = prefs.getStringList(key);

    recentlyOpenedFiles
        .add(json.encode(FileIDE.fileToMap(widget.file as FileIDE)));

    cache?.forEach((file) {
      if (!recentlyOpenedFiles.contains(file)) {
        recentlyOpenedFiles.add(file);
      }
    });

    List<FileIDE> cachedFileStringToFile(List<String> stringFileList) {
      List<FileIDE> files = [];

      for (var file in stringFileList) {
        var fileToJson = json.decode(file);

        files.add(FileIDE.fromJSON(fileToJson));
      }

      return files;
    }

    prefs.setStringList(key, recentlyOpenedFiles);

    setState(() {
      widget.recentlyOpenedFiles = cachedFileStringToFile(recentlyOpenedFiles);
    });
  }

  Future<void> removeRecentlyOpenedFile(String fileName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
  }

  bool fileIsFocused(String fileName) {
    return fileName == widget.file?.fileName;
  }

  void pushNewView(FileIDE tappedFile) {
    Navigator.pushReplacement(
        context,
        PageRouteBuilder(
            transitionDuration: Duration.zero,
            pageBuilder: (context, animation1, animation2) =>
                EditorViewController(
                  file: tappedFile,
                )));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            backgroundColor: widget.scaffoldBackgrounColor,
            drawer: Drawer(child: FileExplorer()),
            appBar: AppBar(
              leading: Builder(
                builder: (BuildContext context) => IconButton(
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    icon: const Icon(Icons.folder)),
              ),
              backgroundColor: widget.tabBarColor,
              toolbarHeight: 50,
            ),
            body: editor?.openedFile != null && widget.codePreview
                ? DefaultTabController(
                    length: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          color: widget.tabBarColor,
                          height: 50,
                          child: fileTabBar(),
                        ),
                        Container(
                          color: widget.tabBarColor,
                          child: const TabBar(
                              tabs: <Text>[Text('editor'), Text('preview')]),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              editor as Widget,
                              CodePreview(
                                filePath:
                                    editor?.openedFile!.filePath as String,
                              )
                            ],
                          ),
                        )
                      ],
                    ))
                : const Center(
                    child: Text('open file'),
                  )));
  }

  ListView fileTabBar() {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      scrollDirection: Axis.horizontal,
      itemCount: widget.recentlyOpenedFiles.length,
      itemBuilder: (context, index) => SizedBox(
        height: 25,
        width: 100,
        child: TextButton(
          onPressed: () {
            pushNewView(widget.recentlyOpenedFiles[index]);
          },
          style: TextButton.styleFrom(
              backgroundColor:
                  fileIsFocused(widget.recentlyOpenedFiles[index].fileName)
                      ? widget.scaffoldBackgrounColor
                      : widget.tabBarColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.zero),
              )),
          child: Text(
            widget.recentlyOpenedFiles[index].fileName,
            maxLines: 1,
            style: const TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
