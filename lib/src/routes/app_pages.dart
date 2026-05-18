import 'package:get/get.dart';
import 'app_routes.dart';
import '../pages/home_page.dart';
import '../bindings/home_binding.dart';

class AppPages {
  static const initial = AppRoutes.home;

  static final routes = [
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
  ];
}
