library sembast.io_file_system_test;

// basically same as the io runner but with extra output
//import 'package:tekartik_test/test_config.dart';
import 'package:tekartik_test/test_utils.dart';
import 'package:sembast/src/file_system.dart';
import 'dart:async';
import 'package:path/path.dart';
import 'dart:convert';

void defineTests(FileSystem fs) {

  String DATA_FOLDER = 'data';
  String OUT_FOLDER = 'out';

  String _rootPath() {
    if (fs.scriptFile != null) {
      return dirname(fs.scriptFile.path);
    }
    return fs.currentDirectory.path;
  }

  String dataPath = join(_rootPath(), DATA_FOLDER);
  String outDataPath = join(dataPath, OUT_FOLDER);

  String namePath(String name) => join(outDataPath, name);

  File nameFile(String name) => fs.newFile(namePath(name));
  Directory nameDir(String name) => fs.newDirectory(namePath(name));

  Future<File> createFile(File file) {
    return file.create(recursive: true).then((File file_) {
      expect(file, file_);
      return file_;
    });
  }

  Future<File> createFileName(String name) => createFile(nameFile(name));

  Future expectDirExists(Directory dir, [bool exists = true]) {
    return dir.exists().then((bool exists_) {
      expect(exists_, exists);
    });
  }

  Future expectFileExists(File file, [bool exists = true]) {
    return file.exists().then((bool exists_) {
      expect(exists_, exists);
    });
  }

  Future<File> expectFileNameExists(String name, [bool exists = true]) => expectFileExists(nameFile(name), exists);

  Stream<List<int>> openRead(File file) {
    return file.openRead();
  }

  Stream<String> openReadLines(File file) {
    return openRead(file).transform(UTF8.decoder).transform(new LineSplitter());
  }

  IOSink openWrite(File file) {
    return file.openWrite(mode: FileMode.WRITE);
  }

  IOSink openAppend(File file) {
    return file.openWrite(mode: FileMode.APPEND);
  }

  Future<File> deleteFile(File file) {
    return file.delete(recursive: true).then((File file_) {
      expect(file, file_);
      return file_;
    });
  }

  Future<Directory> deleteDirectory(Directory dir) {
    return dir.delete(recursive: true).then((Directory dir_) {
      expect(dir, dir_);
      return dir_;
    });
  }
  Future clearOutFolder() {
    return deleteDirectory(fs.newDirectory(outDataPath)).catchError((FileSystemException e, st) {
      //devPrint("${e}\n${st}");
    });
  }

  Future<List<String>> readContent(File file) {
    List<String> content = [];
    return openReadLines(file).listen((String line) {
      content.add(line);
    }).asFuture(content);
  }

  Future writeContent(File file, List<String> content) {
    IOSink sink = openWrite(file);
    content.forEach((String line) {
      sink.writeln(line);
    });
    return sink.close();
  }

  Future appendContent(File file, List<String> content) {
    IOSink sink = openAppend(file);
    content.forEach((String line) {
      sink.writeln(line);
    });
    return sink.close();
  }

  setUp(() {
    return clearOutFolder();
  });

  tearDown(() {
  });


  group('fs', () {

    group('file_system', () {
      test('currentDirectory', () {
        expect(fs.currentDirectory, isNotNull);
      });

      test('scriptFile', () {
        //expect(fs.scriptFile, isNotNull);
      });

      test('rootPath', () {
        expect(_rootPath(), isNotNull);
      });

      test('type', () {
        return fs.type(namePath("test")).then((FileSystemEntityType type) {
          expect(type, FileSystemEntityType.NOT_FOUND);
        });
      });
    });

    group('dir', () {
      test('dir exists', () {
        return expectDirExists(nameDir("test"), false);
      });

      test('dir create', () {
        Directory dir = nameDir("test");
        return dir.create(recursive: true).then((_) {
          return expectDirExists(dir, true).then((_) {
            // second time fine too
            return dir.create(recursive: true);
          });
        });
      });

      test('sub dir create', () {
        Directory mainDir = nameDir("test");
        Directory subDir = fs.newDirectory(join(mainDir.path, "test"));

        return subDir.create(recursive: true).then((_) {
          return expectDirExists(mainDir, true).then((_) {
          });
        });
      });

      test('dir delete', () {
        Directory dir = nameDir("test");
        return dir.delete(recursive: true).then((_) {
          fail('');
        }, onError: (FileSystemException e) {
        }).then((_) {
          return expectDirExists(dir, false);
        }).then((_) {
          return dir.create(recursive: true).then((_) {
            return expectDirExists(dir, true).then((_) {
            });
          }).then((_) {
            return dir.delete(recursive: true).then((_) {
              return expectDirExists(dir, false);
            });
          });
        });
      });

      test('sub dir delete', () {
        Directory mainDir = nameDir("test");
        Directory subDir = nameDir(join(mainDir.path, "test"));

        return subDir.create(recursive: true).then((_) {
          return mainDir.delete(recursive: true).then((_) {
            return expectDirExists(subDir, false);
          });
        });
      });

    });
    group('file', () {
      test('file exists', () {
        return expectFileNameExists("test", false);
      });

      test('file create', () {
        return createFileName("test").then((File file) {
          return file.exists().then((bool exists) {
            expect(exists, true);
          });
        });
      });

      test('file delete', () {
        File file = nameFile("test");
        return deleteFile(file).then((_) {
          fail('');
        }, onError: (FileSystemException e) {
        }).then((_) {
          return expectFileExists(file, false).then((_) {
            return createFile(file);
          }).then((_) {
            return expectFileExists(file, true);
          });
        });
      });

      test('file delete 2', () {
        File file = nameFile(join("sub", "test"));
        return deleteFile(file).then((_) {
          fail('');
        }, onError: (FileSystemException e) {
        }).then((_) {
          return expectFileExists(file, false).then((_) {
            return createFile(file);
          }).then((_) {
            return expectFileExists(file, true);
          });
        });
      });

      test('open read 1', () {
        File file = nameFile("test");
        bool ok;
        return openRead(file).listen((_) {
          fail('');
        }, onError: (e) {
          //devPrint(e);
        }, onDone: () {
          // devPrint('done');
        }).asFuture().catchError((e) {
          //devPrint(e);
          ok = true;
        }).then((_) {
          expect(ok, isTrue);
        });
//        return openRead(file).listen((_) {
//          fail('');
//        }, onError: (e) {
//          devPrint(e);
//        }).asFuture();

      });

      test('open write 1', () {
        File file = nameFile("test");
        IOSink sink = openWrite(file);
        //sink.writeln("test");
        return sink.close().then((_) {
          fail('');
        }, onError: (FileSystemException e, st) {
          devPrint("${e}");
        });
      });

      test('open write 2', () {
        return createFileName("test").then((File file) {
          IOSink sink = openWrite(file);
          sink.writeln("test");
          return sink.close().then((_) {
            return readContent(file).then((List<String> content) {
              expect(content, ["test"]);
            });
          });
        });
      });

      test('open write 3', () {
        return createFileName("test").then((File file) {
          return writeContent(file, ["test1"]).then((_) {
            // override existing
            return writeContent(file, ["test2"]).then((_) {
              return readContent(file).then((List<String> content) {
                expect(content, ["test2"]);
              });
            });
          });
        });
      });

      test('open append 1', () {
        File file = nameFile("test");
        IOSink sink = openAppend(file);
        //sink.writeln("test");
        return sink.close().then((_) {
          fail('');
        }, onError: (FileSystemException e, st) {
          devPrint("${e}");
        });
      });

      test('open append 2', () {
        return createFileName("test").then((File file) {
          IOSink sink = openAppend(file);
          sink.writeln("test");
          return sink.close().then((_) {
            return readContent(file).then((List<String> content) {
              expect(content, ["test"]);
            });
          });
        });
      });

      test('open append 3', () {
        return createFileName("test").then((File file) {
          return writeContent(file, ["test1"]).then((_) {
            return appendContent(file, ["test2"]).then((_) {
              return readContent(file).then((List<String> content) {
                expect(content, ["test1", "test2"]);
              });
            });
          });
        });
      });

    });
  });

}