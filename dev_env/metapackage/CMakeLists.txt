cmake_minimum_required(VERSION 3.8)
project(metapackage)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# find dependencies
find_package(ament_cmake REQUIRED)
find_package(joy REQUIRED)

find_package(joy REQUIRED)
find_package(teleop_twist_joy REQUIRED)
find_package(teleop_twist_keyboard REQUIRED)
find_package(ros2_control REQUIRED)
find_package(ros2_controllers REQUIRED)
find_package(controller_manager REQUIRED)
find_package(joint_state_controller REQUIRED)
find_package(robot_state_publisher REQUIRED)
find_package(joint_state_publisher_gui REQUIRED)
find_package(tf_transformations REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(rosbridge_suite REQUIRED)
find_package(xacro REQUIRED)
find_package(rviz2 REQUIRED)

# uncomment the following section in order to fill in
# further dependencies manually.
# find_package(<dependency> REQUIRED)

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  # the following line skips the linter which checks for copyrights
  # comment the line when a copyright and license is added to all source files
  set(ament_cmake_copyright_FOUND TRUE)
  # the following line skips cpplint (only works in a git repo)
  # comment the line when this package is in a git repo and when
  # a copyright and license is added to all source files
  set(ament_cmake_cpplint_FOUND TRUE)
  ament_lint_auto_find_test_dependencies()
endif()

ament_package()
