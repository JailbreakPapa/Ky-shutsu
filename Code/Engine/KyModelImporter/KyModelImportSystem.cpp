#include <KyModelImporter/Importer.h>

NS_KYMODELIMP_DLL nsUniquePtr<KyImporter> kyshutsu::modelimporter::CreateImporter(
  const char* szFilename)
{
    // TODO: Add and Reference Assimp and UFBX importers here.
    return nsUniquePtr<KyImporter>(new KyImporter());
}