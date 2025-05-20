import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rellssserr/ReelsCubit.dart';
import 'package:rellssserr/ReelsPage.dart';


class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تطبيق الريلز'),
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(fontSize: 18),
          ),
          onPressed: () {
            // تحميل الفيديوهات قبل الانتقال إلى صفحة الريلز
            context.read<ReelsCubit>().loadVideos();
            
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ReelsPage(),
              ),
            );
          },
          child: const Text('مشاهدة الريلز'),
        ),
      ),
    );
  }
}