import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class ContributionPage extends StatefulWidget {
  const ContributionPage({super.key});

  @override
  State<ContributionPage> createState() => _ContributionPageState();
}

class _ContributionPageState extends State<ContributionPage> {

  List<Video> videos = [
    Video(name: 'اهلا.mp4', uploadDate: DateFormat('dd-MMM-yy HH:mm').format(DateTime.now()), status: 'Uploaded'),
    Video(
        name: 'السلام عليكم.mp4',
        uploadDate: DateFormat('dd-MMM-yy HH:mm').format(DateTime.now().subtract(const Duration(days: 1))),
        status: 'Approved'),
    Video(
        name: 'باي.mp4',
        uploadDate: DateFormat('dd-MMM-yy HH:mm').format(DateTime.now().subtract(const Duration(days: 2))),
        status: 'Rejected'),
  ];

  void pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );

    if (result != null) {
      PlatformFile video = result.files.first;
      // Handle the video file here
      setState(() {
        videos.add(Video(name: video.name, uploadDate: DateFormat('dd-MMM-yy HH:mm').format(DateTime.now()), status: 'Uploaded'));
      });
    } else {
      // User canceled the picker
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0),
              //decoration: BoxDecoration(border: Border.all(color: Colors.deepPurple)),
              child: const Text(
                'Click the "+" button to upload a new Emirati Sign Language video.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24.0),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepPurple),
                  borderRadius: BorderRadius.circular(10.0)),
              child: SingleChildScrollView(
                physics: const ScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: DataTable(
                    sortColumnIndex: 1, // Sort by upload date
                    sortAscending: false, // Most recent first
                    columns: const [
                      DataColumn(label: Text('Video Name')),
                      DataColumn(label: Text('Upload Date')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: videos
                        .map((video) => DataRow(cells: [
                              DataCell(Text(video.name)),
                              DataCell(Text(video.uploadDate.toString())),
                              DataCell(Text(video.status)),
                            ]))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: () {
          pickVideo();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class Video {
  final String name;
  final String uploadDate;
  final String status;

  Video({required this.name, required this.uploadDate, required this.status});
}
