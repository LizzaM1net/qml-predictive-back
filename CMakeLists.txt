cmake_minimum_required(VERSION 3.21)
project(qml_predictive_back VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)
qt_standard_project_setup(REQUIRES 6.9)

qt_add_executable(qml_predictive_back
    main.cpp
    BackGestureHandler.h
    BackGestureHandler.cpp
)

qt_add_qml_module(qml_predictive_back
    URI org.example.predictiveback
    VERSION 1.0
    QML_FILES
        Main.qml
        EdgeHighlight.qml
        SuccessAnimation.qml
    RESOURCES
        qtquickcontrols2.conf
)

target_link_libraries(qml_predictive_back PRIVATE Qt6::Quick)

if(ANDROID)
    set_target_properties(qml_predictive_back PROPERTIES
        QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android"
        QT_ANDROID_MIN_SDK_VERSION 33
        QT_ANDROID_TARGET_SDK_VERSION 34
    )
endif()
