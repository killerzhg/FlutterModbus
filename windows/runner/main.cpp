#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <iostream>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);

    int screenWidth = GetSystemMetrics(SM_CXSCREEN);
    int screenHeight = GetSystemMetrics(SM_CYSCREEN);

    //static_cast强制类型转换 std::round四舍五入
    int windowWidth = static_cast<int>(std::round(screenWidth/2));
    int windowHeight =static_cast<int>(std::round(screenHeight/2)) ;

    int windowX = (screenWidth - windowWidth) / 2;
    int windowY = (screenHeight - windowHeight) / 2;

  Win32Window::Point origin(windowX, windowY);
  Win32Window::Size size(windowWidth, windowHeight);

  if (!window.Create(L"flutter_modbus", origin, size)) {
        std::cerr << "Failed to create window." << std::endl;
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  //不加这句窗口大小以及位置都不生效
  MoveWindow(window.GetHandle(), windowX, windowY, windowWidth, windowHeight, TRUE);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
