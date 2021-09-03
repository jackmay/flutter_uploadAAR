import 'dart:io';

var mvnDir = "/Users/xxx/mvn";
var remoteAdress = "https://xxx/";

var remoteRepository = " repository(url: \"$remoteAdress/\") {\n" +
    "                    authentication(userName: \"xxx\", password: \"xxx\")\n" +
    "                }";

Future<void> main() async {
  // writeLocalMvnAddress();
  // flutterRun();
  writeRemoteMvnAddress();
}

flutterRun() async {
  var result = await Process.run(
      "flutter",
      [
        "build",
        "aar",
      ],
      runInShell: true);
  print("${result.stdout()}");
}

void writeLocalMvnAddress() {
  var file = new File("./.android/Flutter/build.gradle");
  file.writeAsStringSync("\nproject.setProperty(\"output-dir\",\"$mvnDir\")\n",
      mode: FileMode.append);
}

Future<void> writeRemoteMvnAddress() async {
  var property = new File("./.android/local.properties");
  var propertyLines = await property.readAsLines();
  var aarInitFilePath;

  for (var line in propertyLines) {
    if (line.startsWith("flutter.sdk")) {
      var split = line.split("flutter.sdk=");
      aarInitFilePath =
          "${split[1]}/packages/flutter_tools/gradle/aar_init_script.gradle";
      await Process.run(
          "git",
          [
            "-C",
            "${split[1]}",
            "restore",
            "packages/flutter_tools/gradle/aar_init_script.gradle"
          ],
          runInShell: true);
    }
  }
  var aarInitFile = new File(aarInitFilePath);
  var aarInitString = await aarInitFile.readAsString();
  if (aarInitString.contains("repository(url:")) {
    var uploadFile = new File("./upload.txt");

    var contents = aarInitString.replaceFirst(
        RegExp(r'repository\(url:.+\)'), remoteRepository);

    if (remoteAdress.contains("snapshot")) {
      contents = contents
          .replaceFirst(
              "project.version = project.version.replace(\"-SNAPSHOT\", \"\")",
               "if (!project.version.contains(\"-SNAPSHOT\")) {\n" +
                  "        project.version = project.version + \"-SNAPSHOT\"\n" +
                  "    }")
          .replaceFirst(
              "  if (project.hasProperty(\"buildNumber\")) {\n" +
                  "        project.version = project.property(\"buildNumber\")\n" +
                  "    }",
              "");
    }

    aarInitFile.writeAsStringSync(contents);
    await flutterRun();
  }
}
