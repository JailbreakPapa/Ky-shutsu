#include <KyModelImporter/Importer.h>

namespace kyshutsu
{
  nsResult KyImporter::Import(
    const ImportOptions& options, nsLogInterface* pLogInterface, nsProgress* pProgress)
  {
    nsResult res = NS_FAILURE;

    nsLogInterface* pPrevLogSystem = nsLog::GetThreadLocalLogSystem();

    if (pLogInterface)
    {
      nsLog::SetThreadLocalLogSystem(pLogInterface);
    }

    {
      m_pProgress = pProgress;
      m_Options = options;

      NS_LOG_BLOCK("ModelImport", m_Options.m_sSourceFile);

      res = DoImport();
    }


    nsLog::SetThreadLocalLogSystem(pPrevLogSystem);

    return res;
  }

  

} // namespace kyshutsu