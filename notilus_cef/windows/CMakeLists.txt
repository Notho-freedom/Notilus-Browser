# Plugin CEF Quantum pour Flutter Windows
# Architecture multi-processus : Worker CEF (MT) + Plugin Flutter (MD)
cmake_minimum_required(VERSION 3.14)
project(notilus_cef_plugin LANGUAGES CXX)

# Options de build
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Chemins CEF
set(CEF_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/cef" CACHE PATH "Chemin vers CEF")

# Vérifier que CEF est présent
if(NOT EXISTS "${CEF_ROOT}/CMakeLists.txt")
  message(WARNING "CEF non trouvé dans ${CEF_ROOT}")
  message(WARNING "Téléchargez CEF depuis https://cef-builds.spotifycdn.com/")
endif()

# ============================================================================
# PARTIE 1: CEF WORKER (MT - Multi-threaded static)
# ============================================================================

if(EXISTS "${CEF_ROOT}/CMakeLists.txt")
  # Configurer CEF pour le worker
  set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CEF_ROOT}/cmake")
  find_package(CEF REQUIRED)
  
  # Sauvegarder la configuration actuelle
  set(CMAKE_BUILD_TYPE_SAVED ${CMAKE_BUILD_TYPE})
  set(CMAKE_CONFIGURATION_TYPES_SAVED ${CMAKE_CONFIGURATION_TYPES})
  
  # Forcer Release pour libcef_dll_wrapper (CEF n'est fourni qu'en Release)
  # Même en mode Debug Flutter, on compile libcef_dll_wrapper en Release
  set(CMAKE_BUILD_TYPE Release)
  set(CMAKE_CONFIGURATION_TYPES Release)
  
  # Inclure le wrapper CEF (sera compilé en Release uniquement)
  add_subdirectory(${CEF_LIBCEF_DLL_WRAPPER_PATH} libcef_dll_wrapper)
  
  # Restaurer la configuration (pour cef_worker qui peut être Debug)
  set(CMAKE_BUILD_TYPE ${CMAKE_BUILD_TYPE_SAVED})
  set(CMAKE_CONFIGURATION_TYPES ${CMAKE_CONFIGURATION_TYPES_SAVED})
  
  # Forcer libcef_dll_wrapper à utiliser Release même si le parent est Debug
  if(TARGET libcef_dll_wrapper)
    set_target_properties(libcef_dll_wrapper PROPERTIES
      MSVC_RUNTIME_LIBRARY "MultiThreaded"
    )
    
    # Exclure libcef_dll_wrapper de la configuration Debug
    if(CMAKE_CONFIGURATION_TYPES)
      set_target_properties(libcef_dll_wrapper PROPERTIES
        EXCLUDE_FROM_DEFAULT_BUILD_DEBUG TRUE
      )
    endif()
  endif()
  
  # Créer l'exécutable worker CEF
  # Note: cef_worker doit être compilé uniquement en Release car libcef_dll_wrapper
  # n'est disponible qu'en Release. En mode Debug Flutter, on utilise quand même
  # la version Release de cef_worker.
  add_executable(cef_worker
    cef_worker.cpp
  )
  
  # Exclure cef_worker de la configuration Debug
  # Il sera toujours compilé en Release
  if(CMAKE_CONFIGURATION_TYPES)
    set_target_properties(cef_worker PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD_DEBUG TRUE
    )
  endif()
  
  # Inclure les répertoires pour le worker
  target_include_directories(cef_worker PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CEF_ROOT}"
  )
  
  # Lier CEF (MT) - Toujours utiliser la version Release
  if(TARGET libcef_dll_wrapper AND DEFINED CEF_LIB_RELEASE)
    # Utiliser uniquement la version Release de libcef
    target_link_libraries(cef_worker PRIVATE
      "${CEF_LIB_RELEASE}"
      libcef_dll_wrapper
      ${CEF_STANDARD_LIBS}
    )
    
    add_dependencies(cef_worker libcef_dll_wrapper)
  endif()
  
  # Forcer MT pour le worker CEF - TOUJOURS en Release même en Debug
  # car libcef_dll_wrapper n'est disponible qu'en Release
  set_target_properties(cef_worker PROPERTIES
    MSVC_RUNTIME_LIBRARY "MultiThreaded"
  )
  
  # Options de compilation pour le worker (toujours Release)
  target_compile_definitions(cef_worker PRIVATE
    UNICODE
    _UNICODE
    NOMINMAX
    # Forcer _ITERATOR_DEBUG_LEVEL=0 pour correspondre à libcef_dll_wrapper (Release)
    _ITERATOR_DEBUG_LEVEL=0
    _HAS_ITERATOR_DEBUGGING=0
    # Désactiver les fonctions de debug CRT (forcer Release)
    NDEBUG
  )
  
  # Forcer les options de compilation Release
  target_compile_options(cef_worker PRIVATE
    /W4
    /EHsc
    # Forcer MT (Release uniquement)
    /MT
  )
  
  # Exclure les bibliothèques MD et debug par défaut
  target_link_options(cef_worker PRIVATE
    /NODEFAULTLIB:msvcrt
    /NODEFAULTLIB:msvcrtd
    /NODEFAULTLIB:libcmtd
  )
  
  # Copier les DLLs CEF au build du worker
  add_custom_command(TARGET cef_worker POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${CEF_ROOT}/Release/libcef.dll"
      "$<TARGET_FILE_DIR:cef_worker>/libcef.dll"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${CEF_ROOT}/Release/chrome_elf.dll"
      "$<TARGET_FILE_DIR:cef_worker>/chrome_elf.dll"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${CEF_ROOT}/Release/d3dcompiler_47.dll"
      "$<TARGET_FILE_DIR:cef_worker>/d3dcompiler_47.dll"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${CEF_ROOT}/Release/libEGL.dll"
      "$<TARGET_FILE_DIR:cef_worker>/libEGL.dll"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${CEF_ROOT}/Release/libGLESv2.dll"
      "$<TARGET_FILE_DIR:cef_worker>/libGLESv2.dll"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${CEF_ROOT}/Release/vk_swiftshader.dll"
      "$<TARGET_FILE_DIR:cef_worker>/vk_swiftshader.dll"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${CEF_ROOT}/Release/vulkan-1.dll"
      "$<TARGET_FILE_DIR:cef_worker>/vulkan-1.dll"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${CEF_ROOT}/Release/snapshot_blob.bin"
      "$<TARGET_FILE_DIR:cef_worker>/snapshot_blob.bin"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${CEF_ROOT}/Release/v8_context_snapshot.bin"
      "$<TARGET_FILE_DIR:cef_worker>/v8_context_snapshot.bin"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${CEF_ROOT}/Release/vk_swiftshader_icd.json"
      "$<TARGET_FILE_DIR:cef_worker>/vk_swiftshader_icd.json"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${CEF_ROOT}/Resources/icudtl.dat"
      "$<TARGET_FILE_DIR:cef_worker>/icudtl.dat"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${CEF_ROOT}/Resources/chrome_100_percent.pak"
      "$<TARGET_FILE_DIR:cef_worker>/chrome_100_percent.pak"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${CEF_ROOT}/Resources/chrome_200_percent.pak"
      "$<TARGET_FILE_DIR:cef_worker>/chrome_200_percent.pak"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${CEF_ROOT}/Resources/resources.pak"
      "$<TARGET_FILE_DIR:cef_worker>/resources.pak"
    COMMAND ${CMAKE_COMMAND} -E copy_directory
      "${CEF_ROOT}/Resources/locales"
      "$<TARGET_FILE_DIR:cef_worker>/locales"
  )
endif()

# ============================================================================
# PARTIE 2: PLUGIN FLUTTER (MD - Multi-threaded DLL)
# ============================================================================

# Sources du plugin
set(PLUGIN_SOURCES
  "notilus_cef_plugin_new.cpp"
  "shared_texture.cpp"
)

# Note: notilus_cef_plugin_new.cpp remplace notilus_cef_plugin.cpp
# L'ancien fichier peut être supprimé après vérification

# Headers
set(PLUGIN_HEADERS
  "shared_texture.h"
  "notilus_cef_plugin.h"
)

# Créer la bibliothèque du plugin
add_library(notilus_cef_plugin SHARED
  ${PLUGIN_SOURCES}
  ${PLUGIN_HEADERS}
)

# Inclure les répertoires Flutter
# Le plugin est dans: windows/flutter/ephemeral/.plugin_symlinks/notilus_cef/windows/
get_filename_component(FLUTTER_EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../ephemeral" ABSOLUTE)

target_include_directories(notilus_cef_plugin PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  "${FLUTTER_EPHEMERAL_DIR}"
)

# Exposer le répertoire include pour que Flutter puisse trouver le header
target_include_directories(notilus_cef_plugin PUBLIC
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

# Lier Flutter (MD par défaut)
target_link_libraries(notilus_cef_plugin PRIVATE
  flutter
  flutter_wrapper_plugin
)

# Forcer MD pour le plugin Flutter
set_target_properties(notilus_cef_plugin PROPERTIES
  MSVC_RUNTIME_LIBRARY "MultiThreadedDLL$<$<CONFIG:Debug>:Debug>"
)

# Options de compilation Windows pour le plugin
if(WIN32)
  target_compile_definitions(notilus_cef_plugin PRIVATE
    UNICODE
    _UNICODE
    NOMINMAX
  )
  
  target_compile_options(notilus_cef_plugin PRIVATE
    /W4
    /EHsc
  )
endif()

# Définir le nom de la fonction d'export
target_compile_definitions(notilus_cef_plugin PRIVATE
  FLUTTER_PLUGIN_IMPL
)

# Copier cef_worker.exe au build du plugin
if(TARGET cef_worker)
  add_custom_command(TARGET notilus_cef_plugin POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "$<TARGET_FILE:cef_worker>"
      "$<TARGET_FILE_DIR:notilus_cef_plugin>/cef_worker.exe"
  )
endif()
