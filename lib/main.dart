import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rellssserr/HomePage.dart';
import 'package:rellssserr/ReelsCubit.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تعيين الاتجاهات المفضلة للوضع العمودي فقط
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ReelsCubit>(
          create: (context) => ReelsCubit(),
        ),
      ],
      child: MaterialApp(
        title: 'تطبيق الريلز',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Cairo', // إذا كنت ترغب في استخدام خط عربي
        ),
        home: const HomePage(),
      ),
    );
  }
}