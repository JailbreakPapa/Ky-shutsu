/*
    This code is part of Kyshutsu Engine.

    Copyright (c) 2020-2025 WD Studios Corp. and/or its licensors. All rights reserved in
    all media. The coded instructions, statements, computer programs, and/or related
    material (collectively the "Data") in these files are under the MIT License.
*/

#include <KyModelImporter/KyModelImporterDLL.h>
#include <Foundation/Types/UniquePtr.h>
#include <KyModelImporter/Importer.h>

namespace kyshutsu {
    namespace modelimporter
    {
        NS_KYMODELIMP_DLL nsUniquePtr<KyImporter> CreateImporter(const char* szFilename);
    }
}
